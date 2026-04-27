import crypto from 'crypto';
import express from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { hasValidSuperAdminKey, requireSuperAdminKey } from '../middlewares/requireSuperAdminKey.js';
import { getFirebaseAdminAuth, getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';

const router = express.Router();

const ACCESS_COLLECTION = 'citizen_access_codes';
const FINGERPRINT_COLLECTION = 'citizen_fingerprints';
const DUPLICATE_COLLECTION = 'duplicate_code_requests';
const ACTIVITY_COLLECTION = 'controller_activity_logs';
const CONTROLLER_COLLECTION = 'controleurCodes';

const duplicateReasons = new Set([
  'lost_code',
  'unreadable_code',
  'citizen_claims_no_access',
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

const requireAuth = async (req, res, next) => {
  const header = req.headers.authorization || '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    return res.status(401).json({ message: 'Token Firebase requis.' });
  }

  try {
    req.user = await getFirebaseAdminAuth().verifyIdToken(match[1]);
    return next();
  } catch (error) {
    console.error('Token Firebase invalide.', error);
    return res.status(401).json({ message: 'Token Firebase invalide.' });
  }
};

const hasRole = (user, role) => user?.role === role || user?.[role] === true;
const isSuperAdmin = (user) => hasRole(user, 'super_admin');
const isAdmin = (user) => hasRole(user, 'admin') || isSuperAdmin(user);
const isController = (user) => hasRole(user, 'controller') || user?.controller === true;

const controllerIdFromUser = (user) => {
  if (typeof user?.controleurCodeId === 'string' && user.controleurCodeId.trim()) {
    return user.controleurCodeId.trim();
  }
  if (typeof user?.controllerId === 'string' && user.controllerId.trim()) {
    return user.controllerId.trim();
  }
  if (typeof user?.uid === 'string' && user.uid.startsWith('controller:')) {
    return user.uid.substring('controller:'.length);
  }
  return user?.uid || '';
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

const fingerprintFor = (sourceKeyMasked) => crypto
  .createHash('sha256')
  .update(String(sourceKeyMasked).trim().toUpperCase())
  .digest('hex');

const accessCodeFor = (sourceKeyMasked) => fingerprintFor(sourceKeyMasked).substring(0, 8).toUpperCase();

const regeneratedCodeFor = (sourceKeyMasked, regenerationIndex) => crypto
  .createHash('sha256')
  .update(`${String(sourceKeyMasked).trim().toUpperCase()}-REGEN-${regenerationIndex}`)
  .digest('hex')
  .substring(0, 8)
  .toUpperCase();

const toIso = (value) => {
  if (!value) return new Date().toISOString();
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return String(value);
};

const materializeDoc = (doc) => ({ id: doc.id, ...doc.data() });

const serializeAccess = (data, { privileged = false } = {}) => ({
  ...data,
  createdAt: toIso(data.createdAt),
  approvedAt: data.approvedAt ? toIso(data.approvedAt) : undefined,
  updatedAt: data.updatedAt ? toIso(data.updatedAt) : undefined,
  fingerprint: privileged ? data.fingerprint : undefined,
  sourceKeyMasked: privileged ? data.sourceKeyMasked : undefined,
});

const serializeDuplicate = (data, { privileged = false } = {}) => ({
  ...data,
  requestedAt: toIso(data.requestedAt),
  reviewedAt: data.reviewedAt ? toIso(data.reviewedAt) : undefined,
  updatedAt: data.updatedAt ? toIso(data.updatedAt) : undefined,
  fingerprint: privileged ? data.fingerprint : undefined,
  sourceKeyMasked: privileged ? data.sourceKeyMasked : undefined,
  existingAccessCode: privileged ? data.existingAccessCode : undefined,
});

const serializeLog = (data) => ({
  ...data,
  createdAt: toIso(data.createdAt),
  updatedAt: data.updatedAt ? toIso(data.updatedAt) : undefined,
  fingerprint: undefined,
  sourceKeyMasked: undefined,
});

const loadControllerProfile = async (user) => {
  const id = controllerIdFromUser(user);
  const fallback = {
    id,
    name: user?.name || 'Controleur',
    communeId: user?.communeCode || 'unknown-commune',
    communeName: user?.communeCode || 'Commune non renseignee',
  };

  if (!id) return fallback;

  const doc = await getFirebaseAdminDb().collection(CONTROLLER_COLLECTION).doc(id).get();
  if (!doc.exists) return fallback;

  const data = doc.data() || {};
  return {
    id,
    name: data.label || fallback.name,
    communeId: data.commune?.code || data.commune?.name || fallback.communeId,
    communeName: data.commune?.name || fallback.communeName,
  };
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
    accessCode: payload.accessCode || null,
    fingerprint: payload.fingerprint || null,
    sourceKeyMasked: payload.sourceKeyMasked || null,
    createdAt: FieldValue.serverTimestamp(),
    metadata: payload.metadata || {},
  });
};

router.use(isConfigured, requireAuth);

router.post('/codes', async (req, res) => {
  if (!isController(req.user)) {
    return res.status(403).json({ message: 'Generation reservee aux controleurs.' });
  }

  try {
    const source = buildSource(req.body || {});
    const duplicateReason = duplicateReasons.has(req.body?.duplicateReason) ? req.body.duplicateReason : 'other';
    const controllerComment = typeof req.body?.controllerComment === 'string' && req.body.controllerComment.trim()
      ? req.body.controllerComment.trim().substring(0, 500)
      : null;
    const fingerprint = fingerprintFor(source.sourceKeyMasked);
    const accessCode = accessCodeFor(source.sourceKeyMasked);
    const controller = await loadControllerProfile(req.user);
    const db = getFirebaseAdminDb();

    const result = await db.runTransaction(async (transaction) => {
      const fingerprintRef = db.collection(FINGERPRINT_COLLECTION).doc(fingerprint);
      const fingerprintDoc = await transaction.get(fingerprintRef);

      if (fingerprintDoc.exists) {
        const existing = fingerprintDoc.data() || {};
        const requestRef = db.collection(DUPLICATE_COLLECTION).doc();
        const request = {
          id: requestRef.id,
          fingerprint,
          sourceKeyMasked: source.sourceKeyMasked,
          existingAccessCode: existing.latestAccessCode || existing.firstAccessCode || '',
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
          accessCode: existing.latestAccessCode || existing.firstAccessCode || null,
          fingerprint,
          sourceKeyMasked: source.sourceKeyMasked,
          metadata: { duplicateRequestId: requestRef.id },
        });
        writeActivity(transaction, db, {
          ...controller,
          controllerId: controller.id,
          controllerName: controller.name,
          actionType: 'duplicate_request_created',
          accessCode: existing.latestAccessCode || existing.firstAccessCode || null,
          fingerprint,
          sourceKeyMasked: source.sourceKeyMasked,
          metadata: { duplicateRequestId: requestRef.id, reason: duplicateReason },
        });

        return {
          status: 'duplicate_request_created',
          duplicateRequest: serializeDuplicate({ ...request, requestedAt: new Date().toISOString() }, { privileged: false }),
        };
      }

      const access = {
        accessCode,
        fingerprint,
        sourceKeyMasked: source.sourceKeyMasked,
        firstNameInitial: source.firstNameInitial,
        lastNameInitial: source.lastNameInitial,
        birthYear: source.birthYear,
        phoneSuffix: source.phoneSuffix,
        communeId: controller.communeId,
        communeName: controller.communeName,
        createdByControllerId: controller.id,
        createdByControllerName: controller.name,
        createdAt: FieldValue.serverTimestamp(),
        status: 'active',
        usedForLogin: false,
        regenerationIndex: 0,
      };
      const fingerprintRecord = {
        fingerprint,
        sourceKeyMasked: source.sourceKeyMasked,
        firstAccessCode: accessCode,
        latestAccessCode: accessCode,
        communeId: controller.communeId,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
        regenerationCount: 0,
      };

      transaction.set(db.collection(ACCESS_COLLECTION).doc(accessCode), access);
      transaction.set(fingerprintRef, fingerprintRecord);
      writeActivity(transaction, db, {
        ...controller,
        controllerId: controller.id,
        controllerName: controller.name,
        actionType: 'code_created',
        accessCode,
        fingerprint,
        sourceKeyMasked: source.sourceKeyMasked,
      });

      return {
        status: 'created',
        accessCode: serializeAccess({ ...access, createdAt: new Date().toISOString() }, { privileged: false }),
      };
    });

    return res.status(result.status === 'created' ? 201 : 200).json(result);
  } catch (error) {
    console.error('Generation de code citoyen impossible.', error);
    return res.status(error.status || 500).json({ message: error.message || 'Generation de code citoyen impossible.' });
  }
});

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
    return res.json({ requests: snapshot.docs.map((doc) => serializeDuplicate(materializeDoc(doc), { privileged })) });
  } catch (error) {
    console.error('Lecture des demandes doublon impossible.', error);
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

      const fingerprintRef = db.collection(FINGERPRINT_COLLECTION).doc(request.fingerprint);
      const fingerprintDoc = await transaction.get(fingerprintRef);
      if (!fingerprintDoc.exists) {
        const error = new Error('Empreinte citoyenne introuvable.');
        error.status = 404;
        throw error;
      }

      const fingerprint = fingerprintDoc.data() || {};
      const nextIndex = Number(fingerprint.regenerationCount || 0) + 1;
      const newCode = regeneratedCodeFor(request.sourceKeyMasked, nextIndex);
      const previousCode = fingerprint.latestAccessCode || request.existingAccessCode;
      const newAccess = {
        accessCode: newCode,
        fingerprint: request.fingerprint,
        sourceKeyMasked: request.sourceKeyMasked,
        firstNameInitial: request.sourceKeyMasked.substring(0, 1),
        lastNameInitial: request.sourceKeyMasked.substring(1, 2),
        birthYear: request.sourceKeyMasked.substring(2, 6),
        phoneSuffix: request.sourceKeyMasked.substring(6),
        communeId: request.communeId,
        communeName: request.communeName,
        createdByControllerId: request.requestedByControllerId,
        createdByControllerName: request.requestedByControllerName,
        createdAt: FieldValue.serverTimestamp(),
        status: 'active',
        usedForLogin: false,
        regeneratedFromCode: previousCode,
        regenerationIndex: nextIndex,
        approvedBySuperAdminId: req.user.uid,
        approvedAt: FieldValue.serverTimestamp(),
      };
      const requestUpdate = {
        status: 'approved',
        reviewedBySuperAdminId: req.user.uid,
        reviewedAt: FieldValue.serverTimestamp(),
        newAccessCode: newCode,
        updatedAt: FieldValue.serverTimestamp(),
      };

      transaction.set(db.collection(ACCESS_COLLECTION).doc(newCode), newAccess);
      transaction.set(fingerprintRef, {
        ...fingerprint,
        latestAccessCode: newCode,
        updatedAt: FieldValue.serverTimestamp(),
        regenerationCount: nextIndex,
      }, { merge: true });
      if (previousCode) {
        transaction.set(db.collection(ACCESS_COLLECTION).doc(previousCode), { status: 'replaced', updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      }
      transaction.set(requestRef, requestUpdate, { merge: true });
      writeActivity(transaction, db, {
        communeId: request.communeId,
        communeName: request.communeName,
        controllerId: request.requestedByControllerId,
        controllerName: request.requestedByControllerName,
        actionType: 'regeneration_approved',
        accessCode: newCode,
        fingerprint: request.fingerprint,
        sourceKeyMasked: request.sourceKeyMasked,
        metadata: { duplicateRequestId: requestDoc.id, previousCode },
      });

      return { id: requestDoc.id, ...request, ...requestUpdate, newAccessCode: newCode };
    });

    if (!updated) return res.status(404).json({ message: 'Demande introuvable.' });
    return res.json({ request: serializeDuplicate(updated, { privileged: true }) });
  } catch (error) {
    console.error('Validation de regeneration impossible.', error);
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
      accessCode: request.existingAccessCode || null,
      fingerprint: request.fingerprint || null,
      sourceKeyMasked: request.sourceKeyMasked || null,
      createdAt: FieldValue.serverTimestamp(),
      metadata: { duplicateRequestId: requestDoc.id, reason: rejectionReason },
    });

    return res.json({ request: serializeDuplicate({ id: requestDoc.id, ...request, ...update }, { privileged: true }) });
  } catch (error) {
    console.error('Refus de regeneration impossible.', error);
    return res.status(500).json({ message: 'Refus de regeneration impossible.' });
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
    console.error('Lecture analytics controleurs impossible.', error);
    return res.status(500).json({ message: 'Lecture analytics controleurs impossible.' });
  }
});

export default router;
