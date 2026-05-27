import crypto from 'crypto';
import express from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { env } from '../config/env.js';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';
import { logger } from '../services/logger.js';

const router = express.Router();

const ACCESS_COLLECTION = 'citizen_access_codes';
const POLL_COLLECTION = 'polls';
const POLL_VOTE_COLLECTION = 'poll_votes';
const TOKEN_TTL_MS = 30 * 60 * 1000;

export const jsonBase64Url = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
export const normalizeCode = (value) => String(value || '').trim().toUpperCase();
export const hashCode = (code) => {
  if (!env.accessCodePepper) {
    throw new Error('ACCESS_CODE_PEPPER is required');
  }
  return crypto.createHmac('sha256', env.accessCodePepper).update(normalizeCode(code)).digest('hex');
};
const tokenSecret = () => env.voteAccessTokenSecret;

const toIso = (value) => {
  if (!value) return '';
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return String(value);
};

const readDate = (value) => {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  const date = value instanceof Date ? value : new Date(String(value));
  return Number.isNaN(date.getTime()) ? null : date;
};

const isConfigured = (_req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ ok: false, errorCode: 'BACKEND_NOT_CONFIGURED', message: 'Validation securisee indisponible.' });
  }
  return next();
};

export const signAccessToken = (payload) => {
  const body = jsonBase64Url({ ...payload, exp: Date.now() + TOKEN_TTL_MS });
  const signature = crypto.createHmac('sha256', tokenSecret()).update(body).digest('base64url');
  return `${body}.${signature}`;
};

export const verifyAccessToken = (token) => {
  const [body, signature] = String(token || '').split('.');
  if (!body || !signature) return null;
  const expected = crypto.createHmac('sha256', tokenSecret()).update(body).digest('base64url');
  if (Buffer.byteLength(signature) !== Buffer.byteLength(expected)) return null;
  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected))) return null;
  const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  if (!payload.exp || payload.exp < Date.now()) return null;
  return payload;
};

export const isPollOpen = (poll) => {
  const status = String(poll.status || '').toLowerCase();
  if (!['active', 'open'].includes(status)) return false;
  const now = new Date();
  const opensAt = readDate(poll.opensAt || poll.openDate);
  const closesAt = readDate(poll.closesAt || poll.closeDate);
  if (opensAt && opensAt > now) return false;
  if (closesAt && closesAt < now) return false;
  return true;
};

export const optionBelongsToPoll = (poll, optionId) => Array.isArray(poll.options)
  && poll.options.some((option) => String(option.id || '') === optionId);

const normalizeAccessDoc = (doc) => {
  if (!doc?.exists) return null;
  const data = doc.data() || {};
  return {
    id: doc.id,
    accessCodeHash: data.accessCodeHash || '',
    communeId: data.communeId || '',
    communeName: data.communeName || '',
    status: data.status || 'active',
    createdAt: toIso(data.createdAt),
    lastUsedAt: data.lastUsedAt ? toIso(data.lastUsedAt) : null,
    data,
  };
};

const findAccessCode = async (db, code) => {
  const normalized = normalizeCode(code);
  const accessCodeHash = hashCode(normalized);
  const byHash = await db.collection(ACCESS_COLLECTION).where('accessCodeHash', '==', accessCodeHash).limit(1).get();
  if (!byHash.empty) return normalizeAccessDoc(byHash.docs[0]);

  return null;
};

const loadEligiblePolls = async (db, access, requestedPollId = '') => {
  const snapshot = requestedPollId
    ? await db.collection(POLL_COLLECTION).where('id', '==', requestedPollId).limit(1).get()
    : await db.collection(POLL_COLLECTION).where('communeId', '==', access.communeId).limit(50).get();

  const openPollDocs = snapshot.docs
    .map((doc) => {
      const poll = { id: doc.id, ...doc.data() };
      const pollId = poll.id || doc.id;
      const sameCommune = !access.communeId || !poll.communeId || poll.communeId === access.communeId;
      if (!sameCommune || !isPollOpen(poll)) return null;
      return { poll, pollId };
    })
    .filter(Boolean);

  if (openPollDocs.length === 0) {
    return [];
  }

  const voteRefs = openPollDocs.map(({ pollId }) => db.collection(POLL_VOTE_COLLECTION).doc(`${pollId}_${access.id}`));
  const voteDocs = await db.getAll(...voteRefs);
  const voteMap = new Map(voteDocs.map((doc, index) => [openPollDocs[index].pollId, doc.exists]));

  const polls = [];
  for (const { poll, pollId } of openPollDocs) {
    const safeOptions = Array.isArray(poll.options)
      ? poll.options
          .filter((option) => option && (option.id || option.label))
          .map((option) => ({
            id: String(option.id || ''),
            label: String(option.label || ''),
          }))
      : [];
    polls.push({
      pollId,
      title: poll.projectTitle || poll.title || 'Consultation',
      description: poll.description || '',
      question: poll.question || '',
      status: 'open',
      hasVoted: voteMap.get(pollId) === true,
      options: safeOptions,
    });
  }
  return polls;
};

router.use(isConfigured);

router.post('/validate', async (req, res) => {
  const code = normalizeCode(req.body?.code);
  const pollId = typeof req.body?.pollId === 'string' ? req.body.pollId.trim() : '';
  if (!code) {
    return res.status(400).json({ ok: false, errorCode: 'INVALID_CODE', message: 'Code citoyen requis.' });
  }

  try {
    const db = getFirebaseAdminDb();
    const access = await findAccessCode(db, code);
    if (!access) {
      return res.status(404).json({ ok: false, errorCode: 'INVALID_CODE', message: 'Code inconnu. Contactez un agent d’accueil.' });
    }
    if (['revoked', 'replaced', 'disabled'].includes(access.status)) {
      return res.status(403).json({ ok: false, errorCode: 'REVOKED_CODE', message: 'Ce code n’est plus actif. Contactez un agent d’accueil.' });
    }
    if (access.status === 'expired') {
      return res.status(403).json({ ok: false, errorCode: 'EXPIRED_CODE', message: 'Ce code est expiré. Contactez un agent d’accueil.' });
    }

    const eligiblePolls = await loadEligiblePolls(db, access, pollId);
    if (pollId && eligiblePolls.length === 0) {
      return res.status(409).json({ ok: false, errorCode: 'POLL_CLOSED', message: 'Cette consultation n’est pas ouverte pour ce code.' });
    }
    if (!pollId && eligiblePolls.length === 0) {
      return res.status(409).json({ ok: false, errorCode: 'NO_OPEN_POLL', message: 'Aucune consultation ouverte pour votre commune actuellement.' });
    }

    return res.json({
      ok: true,
      accessToken: signAccessToken({ accessCodeId: access.id, communeId: access.communeId }),
      accessCodeId: access.id,
      communeId: access.communeId,
      communeName: access.communeName,
      eligiblePolls,
    });
  } catch (error) {
    logger.error({ err: error }, 'vote_access_validation_failed');
    return res.status(500).json({ ok: false, errorCode: 'NETWORK_ERROR', message: 'Validation du code impossible.' });
  }
});

router.post('/submit', async (req, res) => {
  const token = verifyAccessToken(req.body?.accessToken);
  const pollId = typeof req.body?.pollId === 'string' ? req.body.pollId.trim() : '';
  const optionId = typeof req.body?.optionId === 'string' ? req.body.optionId.trim() : '';
  if (!token?.accessCodeId || !pollId || !optionId) {
    return res.status(400).json({ ok: false, errorCode: 'INVALID_REQUEST', message: 'Demande de vote incomplete.' });
  }

  try {
    const db = getFirebaseAdminDb();
    const voteDocId = `${pollId}_${token.accessCodeId}`;
    const result = await db.runTransaction(async (transaction) => {
      const accessRef = db.collection(ACCESS_COLLECTION).doc(token.accessCodeId);
      const pollRef = db.collection(POLL_COLLECTION).doc(pollId);
      const voteRef = db.collection(POLL_VOTE_COLLECTION).doc(voteDocId);
      const [accessDoc, pollDoc, voteDoc] = await Promise.all([
        transaction.get(accessRef),
        transaction.get(pollRef),
        transaction.get(voteRef),
      ]);

      if (!accessDoc.exists) return { status: 404, errorCode: 'INVALID_CODE', message: 'Code citoyen introuvable.' };
      const access = accessDoc.data() || {};
      if (['revoked', 'replaced', 'disabled', 'expired'].includes(access.status)) {
        return { status: 403, errorCode: 'REVOKED_CODE', message: 'Ce code n’est plus actif.' };
      }
      if (!pollDoc.exists) return { status: 404, errorCode: 'POLL_CLOSED', message: 'Consultation introuvable.' };
      const poll = { id: pollDoc.id, ...pollDoc.data() };
      if (!isPollOpen(poll)) return { status: 409, errorCode: 'POLL_CLOSED', message: 'Cette consultation est fermee.' };
      if (access.communeId && poll.communeId && access.communeId !== poll.communeId) {
        return { status: 403, errorCode: 'INVALID_CODE', message: 'Ce code n’est pas rattache a cette commune.' };
      }
      if (!optionBelongsToPoll(poll, optionId)) {
        return { status: 400, errorCode: 'INVALID_OPTION', message: 'Option invalide.' };
      }
      if (voteDoc.exists) {
        return { status: 409, errorCode: 'ALREADY_VOTED', message: 'Vous avez deja vote pour cette consultation.' };
      }

      const options = (poll.options || []).map((option) => (
        String(option.id || '') === optionId
          ? { ...option, votes: Number(option.votes || 0) + 1 }
          : option
      ));

      transaction.set(voteRef, {
        pollId,
        accessCodeId: token.accessCodeId,
        communeId: access.communeId || poll.communeId || '',
        votedAt: FieldValue.serverTimestamp(),
        optionId,
        source: req.body?.source === 'mobile' ? 'mobile' : 'web',
      });
      transaction.set(pollRef, {
        options,
        totalVoted: Number(poll.totalVoted || 0) + 1,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      transaction.set(accessRef, {
        lastUsedAt: FieldValue.serverTimestamp(),
        usedForLogin: true,
      }, { merge: true });
      return { status: 200 };
    });

    if (result.status !== 200) {
      return res.status(result.status).json({ ok: false, errorCode: result.errorCode, message: result.message });
    }
    return res.status(201).json({ ok: true, receiptId: crypto.randomUUID(), message: 'Votre vote est enregistre anonymement.' });
  } catch (error) {
    logger.error({ err: error }, 'vote_submission_failed');
    return res.status(500).json({ ok: false, errorCode: 'NETWORK_ERROR', message: 'Enregistrement du vote impossible.' });
  }
});

export default router;
