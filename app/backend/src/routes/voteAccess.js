import crypto from 'crypto';
import express from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { env } from '../config/env.js';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';
import { logger } from '../services/logger.js';

const router = express.Router();

const ACCESS_COLLECTION = 'citizen_access_codes';
const POLL_COLLECTION = 'polls';
const PARTICIPATION_COLLECTION = 'poll_participations';
const BALLOT_COLLECTION = 'poll_ballots';
const TOKEN_TTL_MS = 30 * 60 * 1000;

export const jsonBase64Url = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
export const normalizeCode = (value) => String(value || '').trim().toUpperCase();
export const hashCode = (code) => {
  if (!env.accessCodePepper) {
    throw new Error('ACCESS_CODE_PEPPER is required');
  }
  return crypto.createHmac('sha256', env.accessCodePepper).update(normalizeCode(code)).digest('hex');
};
export const createParticipationHash = (pollId, accessCodeId) => {
  if (!env.participationPepper) {
    throw new Error('PARTICIPATION_PEPPER is required');
  }
  return crypto
    .createHmac('sha256', env.participationPepper)
    .update(`${String(pollId || '').trim()}:${String(accessCodeId || '').trim()}`)
    .digest('hex');
};

export const createParticipationDocId = (pollId, participationHash) => `${String(pollId || '').trim()}_${participationHash}`;

export const createAnonymousBallotId = () => crypto.randomBytes(16).toString('hex');

export const buildParticipationRecord = ({ pollId, participationHash, communeId }) => ({
  pollId,
  participationHash,
  communeId,
  consumedAt: FieldValue.serverTimestamp(),
});

export const buildAnonymousBallotRecord = ({ pollId, optionId, communeId }) => ({
  pollId,
  optionId,
  communeId,
  castAt: FieldValue.serverTimestamp(),
});
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

export const signPollAccessToken = ({ pollId, communeId, participationHash }) => signAccessToken({
  pollId,
  communeId,
  participationHash,
});

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
  const now = new Date();
  const scheduledAt = readDate(poll.scheduledPublishDate || poll.publishDate);
  const scheduledIsDue = status === 'scheduled' && scheduledAt && scheduledAt <= now;
  if (!['active', 'open'].includes(status) && !scheduledIsDue) return false;
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
    pollScope: data.pollScope || 'all_open_polls',
    eligiblePollIds: Array.isArray(data.eligiblePollIds) ? data.eligiblePollIds : [],
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

  // Portee du code : si "single_poll", on restreint aux consultations eligibles.
  const scopedIds = access.pollScope === 'single_poll'
    && Array.isArray(access.eligiblePollIds)
    && access.eligiblePollIds.length > 0
    ? new Set(access.eligiblePollIds.map((value) => String(value)))
    : null;

  const openPollDocs = snapshot.docs
    .map((doc) => {
      const poll = { id: doc.id, ...doc.data() };
      const pollId = poll.id || doc.id;
      const sameCommune = !access.communeId || !poll.communeId || poll.communeId === access.communeId;
      if (!sameCommune || !isPollOpen(poll)) return null;
      if (scopedIds && !scopedIds.has(String(pollId)) && !scopedIds.has(String(doc.id))) return null;
      return { poll, pollId };
    })
    .filter(Boolean);

  if (openPollDocs.length === 0) {
    return [];
  }

  const participationRefs = openPollDocs.map(({ pollId }) => db
    .collection(PARTICIPATION_COLLECTION)
    .doc(createParticipationDocId(pollId, createParticipationHash(pollId, access.id))));
  const participationDocs = await db.getAll(...participationRefs);
  const participationMap = new Map(participationDocs.map((doc, index) => [openPollDocs[index].pollId, doc.exists]));

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
      photoUrls: Array.isArray(poll.photoUrls)
        ? poll.photoUrls.filter((url) => typeof url === 'string').slice(0, 6)
        : [],
      status: 'open',
      hasVoted: participationMap.get(pollId) === true,
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
      return res.status(409).json({ ok: false, errorCode: 'POLL_CLOSED', message: 'Cette consultation n’est pas ouverte pour ce code.', communeId: access.communeId, communeName: access.communeName });
    }
    if (!pollId && eligiblePolls.length === 0) {
      return res.status(409).json({ ok: false, errorCode: 'NO_OPEN_POLL', message: 'Aucune consultation ouverte pour votre commune actuellement.', communeId: access.communeId, communeName: access.communeName });
    }

    const eligiblePollsWithTokens = eligiblePolls.map((poll) => {
      const participationHash = createParticipationHash(poll.pollId, access.id);
      return {
        ...poll,
        accessToken: signPollAccessToken({
          pollId: poll.pollId,
          communeId: access.communeId,
          participationHash,
        }),
      };
    });
    const primaryPoll = eligiblePollsWithTokens.length === 1 ? eligiblePollsWithTokens[0] : null;

    return res.json({
      ok: true,
      accessToken: primaryPoll?.accessToken || '',
      communeId: access.communeId,
      communeName: access.communeName,
      eligiblePolls: eligiblePollsWithTokens,
    });
  } catch (error) {
    logger.error({ err: error }, 'vote_access_validation_failed');
    return res.status(500).json({ ok: false, errorCode: 'NETWORK_ERROR', message: 'Validation du code impossible.' });
  }
});

const ID_PATTERN = /^[A-Za-z0-9_-]{1,64}$/;

export const submitAnonymousVote = async ({ db, token, pollId, optionId }) => {
  const participationHash = token?.participationHash;
  const participationDocId = createParticipationDocId(pollId, participationHash);

  return db.runTransaction(async (transaction) => {
    const pollRef = db.collection(POLL_COLLECTION).doc(pollId);
    const participationRef = db.collection(PARTICIPATION_COLLECTION).doc(participationDocId);
    const ballotRef = db.collection(BALLOT_COLLECTION).doc(createAnonymousBallotId());
    const [pollDoc, participationDoc] = await Promise.all([
      transaction.get(pollRef),
      transaction.get(participationRef),
    ]);

    if (!pollDoc.exists) return { status: 404, errorCode: 'POLL_CLOSED', message: 'Consultation introuvable.' };
    const poll = { id: pollDoc.id, ...pollDoc.data() };
    if (!isPollOpen(poll)) return { status: 409, errorCode: 'POLL_CLOSED', message: 'Cette consultation est fermee.' };
    if (token.communeId && poll.communeId && token.communeId !== poll.communeId) {
      return { status: 403, errorCode: 'INVALID_CODE', message: 'Ce code n’est pas rattache a cette commune.' };
    }
    if (!optionBelongsToPoll(poll, optionId)) {
      return { status: 400, errorCode: 'INVALID_OPTION', message: 'Option invalide.' };
    }
    if (participationDoc.exists) {
      return { status: 409, errorCode: 'ALREADY_VOTED', message: 'Vous avez deja vote pour cette consultation.' };
    }

    const options = (poll.options || []).map((option) => (
      String(option.id || '') === optionId
        ? { ...option, votes: Number(option.votes || 0) + 1 }
        : option
    ));

    transaction.set(participationRef, buildParticipationRecord({
      pollId,
      participationHash,
      communeId: token.communeId || poll.communeId || '',
    }));
    transaction.set(ballotRef, buildAnonymousBallotRecord({
      pollId,
      optionId,
      communeId: token.communeId || poll.communeId || '',
    }));
    transaction.set(pollRef, {
      options,
      totalVoted: Number(poll.totalVoted || 0) + 1,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return { status: 200 };
  });
};

router.post('/submit', async (req, res) => {
  const token = verifyAccessToken(req.body?.accessToken);
  const pollId = typeof req.body?.pollId === 'string' ? req.body.pollId.trim() : '';
  const optionId = typeof req.body?.optionId === 'string' ? req.body.optionId.trim() : '';
  const participationHash = token?.participationHash;
  if (!token || token.pollId !== pollId || !participationHash || !pollId || !optionId) {
    return res.status(400).json({ ok: false, errorCode: 'INVALID_REQUEST', message: 'Demande de vote incomplete.' });
  }
  if (!/^[a-f0-9]{64}$/.test(participationHash)) {
    return res.status(400).json({ ok: false, errorCode: 'INVALID_REQUEST', message: 'Jeton de vote invalide.' });
  }
  if (!ID_PATTERN.test(pollId) || !ID_PATTERN.test(optionId)) {
    return res.status(400).json({ ok: false, errorCode: 'INVALID_REQUEST', message: 'Identifiants invalides.' });
  }

  try {
    const db = getFirebaseAdminDb();
    const result = await submitAnonymousVote({ db, token, pollId, optionId });

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
