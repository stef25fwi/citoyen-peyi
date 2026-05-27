import crypto from 'crypto';
import express from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { env } from '../config/env.js';
import {
  controllerIdFromUser,
  isAdmin,
  isController,
  isSuperAdmin,
  requireFirebaseAuth,
} from '../middlewares/requireFirebaseAuth.js';
import { hasValidSuperAdminKey, requireSuperAdminKey } from '../middlewares/requireSuperAdminKey.js';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';
import { logger } from '../services/logger.js';

const router = express.Router();

const ACCESS_COLLECTION = 'citizen_access_codes';
const FINGERPRINT_COLLECTION = 'citizen_fingerprints';
const DUPLICATE_COLLECTION = 'duplicate_code_requests';
const ACTIVITY_COLLECTION = 'controller_activity_logs';
const CONTROLLER_COLLECTION = 'controleurCodes';
const ACCESS_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

const duplicateReasons = new Set([
  'lost_code',
  'unreadable_code',
  'citizen_claims_no_access',
  'new_citizen_code_creation',
  'controller_error',
  'other',
]);

const activityTypes = new Set([
  'code_created',
  'duplicate_detected',
  'duplicate_request_created',
  'regeneration_approved',
  'regeneration_rejected',
  'login_code_used',
]);

const isConfigured = (_req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ message: 'Firebase Admin n\'est pas configure sur le backend.' });
  }
  return next();
};


const normalizeInitial = (value) => {
  const trimmed = String(value || '').trim().toUpperCase();
  return trimmed ? Array.from(trimmed)[0] : '';
};

const normalizeDigits = (value, expectedLength, keepLast = false) => {
  const digits = String(value || '').replace(/\D/g, '');
  if (digits.length < expectedLength) return digits;
  return keepLast ? digits.slice(-expectedLength) : digits.slice(0, expectedLength);
};

const buildSource = ({ firstName, lastName, birthYear, phoneSuffix }) => {
  const firstNameInitial = normalizeInitial(firstName);
  const lastNameInitial = normalizeInitial(lastName);
  const year = normalizeDigits(birthYear, 4);
  const suffix = normalizeDigits(phoneSuffix, 2, true);

  if (!firstNameInitial || !lastNameInitial || year.length !== 4 || suffix.length !== 2) {
    const error = new Error('Informations minimales invalides.');
    error.status = 400;
    throw error;
  }

  return {
    sourceKeyMasked: `${firstNameInitial}${lastNameInitial}${year}${suffix}`,
    firstNameInitial,
    lastNameInitial,
    birthYear: year,
    phoneSuffix: suffix,
  };
};

export function generateSecureAccessCode(length = 10) {
  const bytes = crypto.randomBytes(length * 2);
  let code = '';

  for (const byte of bytes) {
    if (code.length >= length) break;
    code += ACCESS_CODE_ALPHABET[byte % ACCESS_CODE_ALPHABET.length];
  }

  return code.length < length ? generateSecureAccessCode(length) : code;
}

export function hashAccessCode(accessCode) {
  if (!env.accessCodePepper) {
    throw new Error('ACCESS_CODE_PEPPER is required');
  }

  return crypto
    .createHmac('sha256', env.accessCodePepper)
    .update(String(accessCode || '').trim().toUpperCase())
    .digest('hex');
}

export function createCitizenFingerprint(source) {
  if (!env.citizenFingerprintPepper) {
    throw new Error('CITIZEN_FINGERPRINT_PEPPER is required');
  }

  return crypto
    .createHmac('sha256', env.citizenFingerprintPepper)
    .update(String(source || '').trim().toUpperCase())
    .digest('hex');
}

const newAccessCodeRef = (db) => db.collection(ACCESS_COLLECTION).doc(`cac_${crypto.randomUUID()}`);

const toIso = (value) => {
  if (!value) return new Date().toISOString();
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return String(value);
};

const materializeDoc = (doc) => ({ id: doc.id, ...doc.data() });

const serializeAccess = (data) => ({
  id: data.id,
  accessCode: data.accessCode,
  displayCodeMasked: data.displayCodeMasked,
  communeId: data.communeId,
  communeName: data.communeName,
  createdByControllerId: data.createdByControllerId,
  createdByControllerName: data.createdByControllerName,
  status: data.status,
  usedForLogin: data.usedForLogin,
  regenerationIndex: data.regenerationIndex,
  createdAt: toIso(data.createdAt),
  approvedAt: data.approvedAt ? toIso(data.approvedAt) : undefined,
  updatedAt: data.updatedAt ? toIso(data.updatedAt) : undefined,
});

const serializeDuplicate = (data) => ({
  id: data.id,
  requestedByControllerId: data.requestedByControllerId,
  requestedByControllerName: data.requestedByControllerName,
  communeId: data.communeId,
  communeName: data.communeName,
  existingAccessCodeId: data.existingAccessCodeId,
  requestedAt: toIso(data.requestedAt),
  status: data.status,
  duplicateReason: data.duplicateReason,
  controllerComment: data.controllerComment,
  reviewedAt: data.reviewedAt ? toIso(data.reviewedAt) : undefined,
  updatedAt: data.updatedAt ? toIso(data.updatedAt) : undefined,
  rejectionReason: data.rejectionReason,
});

const serializeLog = (data) => ({
  ...data,
  createdAt: toIso(data.createdAt),
  updatedAt: data.updatedAt ? toIso(data.updatedAt) : undefined,
  citizenFingerprintHash: undefined,
});

const loadControllerProfile = async (user) => {
  const id = controllerIdFromUser(user);
  if (!id) return null;

  const doc = await getFirebaseAdminDb().collection(CONTROLLER_COLLECTION).doc(id).get();
  if (!doc.exists) return null;

  const data = doc.data() || {};
  if (data.enabled === false) return null;

  const communeId = data.commune?.code || data.commune?.name || user?.communeCode || '';
  const tokenCommune = user?.communeId || user?.communeCode || '';
  if (tokenCommune && communeId && tokenCommune !== communeId) return null;

  return {
    id,
    name: data.label || user?.name || 'Controleur',
    communeId: communeId || 'unknown-commune',
    communeName: data.commune?.name || user?.communeCode || 'Commune non renseignee',
  };
};

const requireActiveController = async (req, res, next) => {
  if (!isController(req.user) || isAdmin(req.user) || isSuperAdmin(req.user)) {
    return next();
  }

  try {
    const controller = await loadControllerProfile(req.user);
    if (!controller) {
      return res.status(403).json({ error: 'CONTROLLER_DISABLED', message: 'Ce compte controleur est desactive.' });
    }
    req.controllerProfile = controller;
    return next();
  } catch (error) {
    logger.warn({ err: error }, 'controller_profile_check_failed');
    return res.status(403).json({ error: 'CONTROLLER_DISABLED', message: 'Ce compte controleur est desactive.' });
  }
};

const writeActivity = (transaction, db, payload) => {
  const ref = db.collection(ACTIVITY_COLLECTION).doc();
  transaction.set(ref, {
    id: ref.id,
    communeId: payload.communeId,
    communeName: payload.communeName,
    controllerId: payload.controllerId,
    controllerName: payload.controllerName,
    actionType: payload.actionType,
    accessCodeId: payload.accessCodeId || null,
    createdAt: FieldValue.serverTimestamp(),
    metadata: payload.metadata || {},
  });
};

router.use(isConfigured, requireFirebaseAuth, requireActiveController);

const createCitizenAccessCodeHandler = async (req, res) => {
  if (!isController(req.user)) {
    return res.status(403).json({ message: 'Generation reservee aux controleurs.' });
  }

  try {
    const input = req.body?.citizenFingerprintInput || req.body || {};
    const source = buildSource({
      firstName: input.firstNameInitial || input.firstName,
      lastName: input.lastNameInitial || input.lastName,
      birthYear: input.birthYear,
      phoneSuffix: input.phoneLastTwo || input.phoneSuffix,
    });
    const duplicateReason = duplicateReasons.has(req.body?.duplicateReason) ? req.body.duplicateReason : 'other';
    const controllerComment = typeof req.body?.controllerComment === 'string' && req.body.controllerComment.trim()
      ? req.body.controllerComment.trim().substring(0, 500)
      : null;
    const verification = typeof req.body?.verification === 'object' && req.body.verification != null ? req.body.verification : {};
    const citizenFingerprintHash = createCitizenFingerprint(source.sourceKeyMasked);
    const accessCode = generateSecureAccessCode(10);
    const accessCodeHash = hashAccessCode(accessCode);
    const displayCodeMasked = `${accessCode.substring(0, 2)}••••${accessCode.substring(accessCode.length - 2)}`;
    const controller = req.controllerProfile || await loadControllerProfile(req.user);
    if (!controller) {
      return res.status(403).json({ error: 'CONTROLLER_DISABLED', message: 'Ce compte controleur est desactive.' });
    }
    const db = getFirebaseAdminDb();

    const result = await db.runTransaction(async (transaction) => {
      const fingerprintRef = db.collection(FINGERPRINT_COLLECTION).doc(citizenFingerprintHash);
      const fingerprintDoc = await transaction.get(fingerprintRef);

      if (fingerprintDoc.exists) {
        const fingerprint = fingerprintDoc.data() || {};
        const existingAccessCodeId = fingerprint.latestAccessCodeId || fingerprint.firstAccessCodeId || '';
        const existingAccessDoc = existingAccessCodeId
          ? await transaction.get(db.collection(ACCESS_COLLECTION).doc(existingAccessCodeId))
          : null;
        const existingDisplayCodeMasked = existingAccessDoc?.exists
          ? (existingAccessDoc.data() || {}).displayCodeMasked || ''
          : '';
        const requestRef = db.collection(DUPLICATE_COLLECTION).doc();
        const request = {
          id: requestRef.id,
          citizenFingerprintHash,
          existingAccessCodeId,
          existingDisplayCodeMasked,
          requestedByControllerId: controller.id,
          requestedByControllerName: controller.name,
          communeId: controller.communeId,
          communeName: controller.communeName,
          requestedAt: FieldValue.serverTimestamp(),
          status: 'pending',
          duplicateReason,
          controllerComment,
        };

        transaction.set(requestRef, request);
        writeActivity(transaction, db, {
          ...controller,
          controllerId: controller.id,
          controllerName: controller.name,
          actionType: 'duplicate_detected',
          metadata: { duplicateRequestId: requestRef.id },
        });
        writeActivity(transaction, db, {
          ...controller,
          controllerId: controller.id,
          controllerName: controller.name,
          actionType: 'duplicate_request_created',
          metadata: { duplicateRequestId: requestRef.id, reason: duplicateReason },
        });

        return {
          status: 'duplicate_request_created',
          duplicateRequest: serializeDuplicate({ ...request, requestedAt: new Date().toISOString() }),
        };
      }

      const accessRef = newAccessCodeRef(db);

      const access = {
        id: accessRef.id,
        accessCodeHash,
        displayCodeMasked,
        citizenFingerprintHash,
        communeId: controller.communeId,
        communeName: controller.communeName,
        createdByControllerId: controller.id,
        createdByControllerName: controller.name,
        createdAt: FieldValue.serverTimestamp(),
        status: 'active',
        usedForLogin: false,
        replacedByCodeId: null,
        replacedAt: null,
        lastUsedAt: null,
        regenerationIndex: 0,
        metadata: {
          verification: {
            identityDocumentType: verification.identityDocumentType || null,
            residenceProofType: verification.residenceProofType || null,
            hasIdentityDocument: Boolean(verification.hasIdentityDocument),
            hasResidenceProof: Boolean(verification.hasResidenceProof),
            notes: typeof verification.notes === 'string' ? verification.notes.substring(0, 500) : null,
          },
        },
      };
      const fingerprintRecord = {
        citizenFingerprintHash,
        firstAccessCodeId: accessRef.id,
        latestAccessCodeId: accessRef.id,
        communeId: controller.communeId,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        regenerationCount: 0,
      };

      transaction.set(accessRef, access);
      transaction.set(fingerprintRef, fingerprintRecord);
      writeActivity(transaction, db, {
        ...controller,
        controllerId: controller.id,
        controllerName: controller.name,
        actionType: 'code_created',
        accessCodeId: accessRef.id,
      });

      return {
        status: 'created',
        accessCode: serializeAccess({ ...access, accessCode, createdAt: new Date().toISOString() }),
      };
    });

    return res.status(result.status === 'created' ? 201 : 200).json(result);
  } catch (error) {
    logger.error({ err: error }, 'citizen_code_generation_failed');
    return res.status(error.status || 500).json({ message: error.message || 'Generation de code citoyen impossible.' });
  }
};

router.post('/codes', createCitizenAccessCodeHandler);

router.get('/duplicates', async (req, res) => {
  const privileged = isSuperAdmin(req.user);
  if (!privileged && !isController(req.user)) {
    return res.status(403).json({ message: 'Acces refuse.' });
  }
  if (privileged && !hasValidSuperAdminKey(req)) {
    return res.status(401).json({ message: 'Cle super administrateur invalide.' });
  }

  try {
    const db = getFirebaseAdminDb();
    let query = db.collection(DUPLICATE_COLLECTION);
    if (privileged) {
      if (req.query.communeId) query = query.where('communeId', '==', String(req.query.communeId));
      if (req.query.controllerId) query = query.where('requestedByControllerId', '==', String(req.query.controllerId));
    } else {
      query = query.where('requestedByControllerId', '==', controllerIdFromUser(req.user));
    }
    if (req.query.status && req.query.status !== 'all') {
      query = query.where('status', '==', String(req.query.status));
    }

    const snapshot = await query.orderBy('requestedAt', 'desc').limit(200).get();
    return res.json({ requests: snapshot.docs.map((doc) => serializeDuplicate(materializeDoc(doc))) });
  } catch (error) {
    logger.error({ err: error }, 'duplicate_requests_read_failed');
    return res.status(500).json({ message: 'Lecture des demandes doublon impossible.' });
  }
});

router.post('/duplicates/:requestId/approve', requireSuperAdminKey, async (req, res) => {
  if (!isSuperAdmin(req.user)) {
    return res.status(403).json({ message: 'Decision reservee au super administrateur.' });
  }

  try {
    const db = getFirebaseAdminDb();
    const updated = await db.runTransaction(async (transaction) => {
      const requestRef = db.collection(DUPLICATE_COLLECTION).doc(req.params.requestId);
      const requestDoc = await transaction.get(requestRef);
      if (!requestDoc.exists) return null;
      const request = requestDoc.data() || {};
      if (request.status !== 'pending') return { id: requestDoc.id, ...request };

      const citizenFingerprintHash = request.citizenFingerprintHash;
      if (!citizenFingerprintHash) {
        const error = new Error('Empreinte citoyenne invalide.');
        error.status = 400;
        throw error;
      }
      const fingerprintRef = db.collection(FINGERPRINT_COLLECTION).doc(citizenFingerprintHash);
      const fingerprintDoc = await transaction.get(fingerprintRef);
      if (!fingerprintDoc.exists) {
        const error = new Error('Empreinte citoyenne introuvable.');
        error.status = 404;
        throw error;
      }

      const fingerprint = fingerprintDoc.data() || {};
      const nextIndex = Number(fingerprint.regenerationCount || 0) + 1;
      const newCode = generateSecureAccessCode(10);
      const newAccessRef = newAccessCodeRef(db);
      const previousCodeId = fingerprint.latestAccessCodeId || request.existingAccessCodeId;
      const newAccess = {
        id: newAccessRef.id,
        accessCodeHash: hashAccessCode(newCode),
        displayCodeMasked: `${newCode.substring(0, 2)}••••${newCode.substring(newCode.length - 2)}`,
        citizenFingerprintHash,
        communeId: request.communeId,
        communeName: request.communeName,
        createdByControllerId: request.requestedByControllerId,
        createdByControllerName: request.requestedByControllerName,
        createdAt: FieldValue.serverTimestamp(),
        status: 'active',
        usedForLogin: false,
        replacedByCodeId: null,
        replacedAt: null,
        lastUsedAt: null,
        regeneratedFromCodeId: previousCodeId,
        regenerationIndex: nextIndex,
        approvedBySuperAdminId: req.user.uid,
        approvedAt: FieldValue.serverTimestamp(),
      };
      const requestUpdate = {
        status: 'approved',
        reviewedBySuperAdminId: req.user.uid,
        reviewedAt: FieldValue.serverTimestamp(),
        newAccessCodeId: newAccessRef.id,
        updatedAt: FieldValue.serverTimestamp(),
      };

      transaction.set(newAccessRef, newAccess);
      transaction.set(fingerprintRef, {
        ...fingerprint,
        latestAccessCodeId: newAccessRef.id,
        updatedAt: FieldValue.serverTimestamp(),
        regenerationCount: nextIndex,
      }, { merge: true });
      if (previousCodeId) {
        transaction.set(db.collection(ACCESS_COLLECTION).doc(previousCodeId), {
          status: 'replaced',
          replacedByCodeId: newAccessRef.id,
          replacedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });
      }
      transaction.set(requestRef, requestUpdate, { merge: true });
      writeActivity(transaction, db, {
        communeId: request.communeId,
        communeName: request.communeName,
        controllerId: request.requestedByControllerId,
        controllerName: request.requestedByControllerName,
        actionType: 'regeneration_approved',
        accessCodeId: newAccessRef.id,
        metadata: { duplicateRequestId: requestDoc.id, previousCodeId },
      });

      return { id: requestDoc.id, ...request, ...requestUpdate };
    });

    if (!updated) return res.status(404).json({ message: 'Demande introuvable.' });
    return res.json({ request: serializeDuplicate(updated) });
  } catch (error) {
    logger.error({ err: error }, 'duplicate_request_approval_failed');
    return res.status(error.status || 500).json({ message: error.message || 'Validation de regeneration impossible.' });
  }
});

router.post('/duplicates/:requestId/reject', requireSuperAdminKey, async (req, res) => {
  if (!isSuperAdmin(req.user)) {
    return res.status(403).json({ message: 'Decision reservee au super administrateur.' });
  }

  const rejectionReason = typeof req.body?.rejectionReason === 'string' ? req.body.rejectionReason.trim().substring(0, 500) : '';
  if (!rejectionReason) {
    return res.status(400).json({ message: 'Motif de refus requis.' });
  }

  try {
    const db = getFirebaseAdminDb();
    const requestRef = db.collection(DUPLICATE_COLLECTION).doc(req.params.requestId);
    const requestDoc = await requestRef.get();
    if (!requestDoc.exists) return res.status(404).json({ message: 'Demande introuvable.' });
    const request = requestDoc.data() || {};
    const update = {
      status: 'rejected',
      reviewedBySuperAdminId: req.user.uid,
      reviewedAt: FieldValue.serverTimestamp(),
      rejectionReason,
      updatedAt: FieldValue.serverTimestamp(),
    };
    await requestRef.set(update, { merge: true });
    await db.collection(ACTIVITY_COLLECTION).add({
      communeId: request.communeId,
      communeName: request.communeName,
      controllerId: request.requestedByControllerId,
      controllerName: request.requestedByControllerName,
      actionType: 'regeneration_rejected',
      createdAt: FieldValue.serverTimestamp(),
      metadata: { duplicateRequestId: requestDoc.id, reason: rejectionReason },
    });

    return res.json({ request: serializeDuplicate({ id: requestDoc.id, ...request, ...update }) });
  } catch (error) {
    logger.error({ err: error }, 'duplicate_request_rejection_failed');
    return res.status(500).json({ message: 'Refus de regeneration impossible.' });
  }
});

router.post('/codes/:accessCode/revoke', requireSuperAdminKey, async (req, res) => {
  if (!isSuperAdmin(req.user)) {
    return res.status(403).json({ message: 'Reserve au super administrateur.' });
  }
  const accessCode = String(req.params.accessCode || '').trim().toUpperCase();
  if (!accessCode) {
    return res.status(400).json({ message: 'Code citoyen requis.' });
  }
  const reason = typeof req.body?.reason === 'string' ? req.body.reason.trim().substring(0, 500) : '';
  try {
    const db = getFirebaseAdminDb();
    const accessCodeHash = hashAccessCode(accessCode);
    const snapshot = await db.collection(ACCESS_COLLECTION).where('accessCodeHash', '==', accessCodeHash).limit(1).get();
    if (snapshot.empty) return res.status(404).json({ message: 'Code introuvable.' });
    const ref = snapshot.docs[0].ref;
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ message: 'Code introuvable.' });
    await ref.set({
      status: 'revoked',
      revokedAt: FieldValue.serverTimestamp(),
      revokedBy: req.user.uid,
      revokedReason: reason,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return res.json({ ok: true });
  } catch (error) {
    logger.error({ err: error }, 'citizen_code_revocation_failed');
    return res.status(500).json({ message: 'Revocation impossible.' });
  }
});

router.get('/activity', async (req, res) => {
  const privileged = isSuperAdmin(req.user) || isAdmin(req.user);
  if (!privileged && !isController(req.user)) {
    return res.status(403).json({ message: 'Acces refuse.' });
  }
  if (isSuperAdmin(req.user) && !hasValidSuperAdminKey(req)) {
    return res.status(401).json({ message: 'Cle super administrateur invalide.' });
  }

  try {
    const db = getFirebaseAdminDb();
    let query = db.collection(ACTIVITY_COLLECTION);
    if (privileged) {
      if (req.query.communeId) query = query.where('communeId', '==', String(req.query.communeId));
      if (req.query.controllerId) query = query.where('controllerId', '==', String(req.query.controllerId));
    } else {
      query = query.where('controllerId', '==', controllerIdFromUser(req.user));
    }
    if (req.query.actionType && activityTypes.has(String(req.query.actionType))) {
      query = query.where('actionType', '==', String(req.query.actionType));
    }

    const snapshot = await query.orderBy('createdAt', 'desc').limit(250).get();
    const startDate = req.query.startDate ? new Date(String(req.query.startDate)) : null;
    const endDate = req.query.endDate ? new Date(String(req.query.endDate)) : null;
    const logs = snapshot.docs
      .map((doc) => serializeLog(materializeDoc(doc)))
      .filter((log) => {
        const created = new Date(log.createdAt);
        if (Number.isNaN(created.getTime())) return false;
        if (startDate && created < startDate) return false;
        if (endDate) {
          const end = new Date(endDate);
          end.setDate(end.getDate() + 1);
          if (created > end) return false;
        }
        return true;
      });

    return res.json({ logs });
  } catch (error) {
    logger.error({ err: error }, 'controller_activity_read_failed');
    return res.status(500).json({ message: 'Lecture analytics controleurs impossible.' });
  }
});

export default router;
