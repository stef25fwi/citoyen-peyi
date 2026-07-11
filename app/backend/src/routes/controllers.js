import express from 'express';
import crypto from 'crypto';
import { FieldValue } from 'firebase-admin/firestore';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';
import {
  communeScopeFromUser,
  isSuperAdmin,
  requireCommuneAdmin,
  requireCommuneScope,
  requireFirebaseAuth,
} from '../middlewares/requireFirebaseAuth.js';
import { hashControllerCode } from '../services/keyHashing.js';
import { resolveCanonicalCommune } from '../services/communeDirectory.js';
import { archiveDeletedRecord } from '../services/deletionArchive.js';
import { logger } from '../services/logger.js';

const router = express.Router();
const COLLECTION = 'controleurCodes';

const ensureConfigured = (_req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ message: 'Backend Firebase Admin non configure.' });
  }
  return next();
};

const sanitize = (value, max) => (typeof value === 'string' ? value.trim().substring(0, max) : '');
const normalizeIds = (raw) => (Array.isArray(raw) ? raw : [])
  .map((value) => sanitize(value, 128))
  .filter(Boolean)
  .slice(0, 100);

export const generateControllerCode = () => {
  const hash = crypto.createHash('sha256').update(crypto.randomBytes(32)).digest('hex');
  return hash.substring(0, 16).toUpperCase();
};

const stripLegacyPrefix = (value) => {
  if (typeof value !== 'string') return '';
  const upper = value.trim().toUpperCase();
  return upper.startsWith('CTRL-') ? upper.substring(5) : upper;
};

const maskCode = (code) => {
  const clean = stripLegacyPrefix(code);
  if (clean.length < 4) return clean;
  return `${clean.substring(0, 2)}••••${clean.substring(clean.length - 2)}`;
};

const serializeController = (doc) => {
  const data = doc.data() || {};
  const sanitizedId = stripLegacyPrefix(doc.id);
  const rawMasked = typeof data.displayCodeMasked === 'string' && data.displayCodeMasked.startsWith('CTRL-')
    ? data.displayCodeMasked.substring(5)
    : data.displayCodeMasked;
  return {
    id: sanitizedId,
    displayCodeMasked: rawMasked || (data.code ? maskCode(data.code) : ''),
    label: data.label,
    commune: data.commune,
    createdAt: data.createdAt,
    usedAt: data.usedAt,
    enabled: data.enabled !== false,
  };
};

const loadControllerDoc = async (db, rawCode) => {
  const cleanCode = stripLegacyPrefix(sanitize(rawCode, 64));
  if (!cleanCode) return null;
  const candidates = [cleanCode, `CTRL-${cleanCode}`];
  for (const candidate of candidates) {
    const ref = db.collection(COLLECTION).doc(candidate);
    const doc = await ref.get();
    if (doc.exists) return { ref, doc, code: candidate };
  }
  return null;
};

const assertControllerScope = (req, res, data) => {
  if (isSuperAdmin(req.user)) return true;
  const scope = communeScopeFromUser(req.user);
  if (data.commune?.code !== scope) {
    res.status(403).json({ message: 'Ce controleur appartient a une autre commune.' });
    return false;
  }
  return true;
};

const archiveAndDisableController = async (db, req, loaded, reason = 'manual_delete') => {
  const data = loaded.doc.data() || {};
  await archiveDeletedRecord(db, {
    kind: 'consultation_agent',
    sourceCollection: COLLECTION,
    recordId: stripLegacyPrefix(loaded.code),
    data: { id: stripLegacyPrefix(loaded.code), ...data },
    deletedBy: req.user?.uid || 'super_admin',
    reason,
  });
  await loaded.ref.set({
    enabled: false,
    disabledAt: FieldValue.serverTimestamp(),
    deletedAt: FieldValue.serverTimestamp(),
    deletedBy: req.user?.uid || 'super_admin',
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  try {
    await import('../services/firebaseAdmin.js').then(({ getFirebaseAdminAuth }) => getFirebaseAdminAuth().revokeRefreshTokens(`controller:${loaded.code}`));
  } catch (revokeError) {
    logger.warn({ err: revokeError, controllerCode: loaded.code }, 'controller_token_revocation_failed');
  }
};

const generateUnusedControllerCode = async (db) => {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const code = generateControllerCode();
    const doc = await db.collection(COLLECTION).doc(code).get();
    if (!doc.exists) return code;
  }
  const error = new Error('Generation de code controleur impossible.');
  error.status = 503;
  throw error;
};

router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin, requireCommuneScope);

const resolveCommuneScope = (req) => {
  if (isSuperAdmin(req.user)) {
    return {
      communeName: sanitize(req.body?.communeName, 200),
      communeCode: sanitize(req.body?.communeCode, 64),
      codePostal: sanitize(req.body?.codePostal, 16),
    };
  }
  return {
    communeName: sanitize(req.body?.communeName, 200) || communeScopeFromUser(req.user),
    communeCode: communeScopeFromUser(req.user),
    codePostal: sanitize(req.body?.codePostal, 16),
  };
};

router.get('/', async (req, res, next) => {
  try {
    const db = getFirebaseAdminDb();
    let query = db.collection(COLLECTION);
    if (!isSuperAdmin(req.user)) {
      const scope = communeScopeFromUser(req.user);
      if (!scope) return res.status(403).json({ message: 'Aucune commune attachee au compte.' });
      query = query.where('commune.code', '==', scope);
    }
    const snapshot = await query.limit(500).get();
    return res.json({
      controllers: snapshot.docs
        .filter((doc) => (doc.data() || {}).enabled !== false)
        .map(serializeController),
    });
  } catch (error) {
    return next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const label = sanitize(req.body?.label, 200);
    if (!label) return res.status(400).json({ message: 'Libelle du controleur requis.' });

    const scope = resolveCommuneScope(req);
    if (!scope.communeName) {
      return res.status(400).json({ message: 'Commune requise pour creer un controleur.' });
    }

    const db = getFirebaseAdminDb();
    // Consolidation : rattache l'agent a l'identite canonique de la commune
    // (celle de l'admin communal existant) pour ne pas eparpiller des variantes.
    const commune = await resolveCanonicalCommune(db, {
      communeCode: scope.communeCode,
      communeName: scope.communeName,
      codePostal: scope.codePostal,
    });

    const code = generateControllerCode();
    const payload = {
      id: code,
      codeHash: hashControllerCode(code),
      displayCodeMasked: maskCode(code),
      label,
      commune: {
        name: commune.communeName,
        code: commune.communeCode,
        codePostal: commune.codePostal,
      },
      createdAt: FieldValue.serverTimestamp(),
      createdBy: req.user?.uid || 'admin',
      usedAt: null,
      enabled: true,
    };
    await db.collection(COLLECTION).doc(code).set(payload);
    return res.status(201).json({ controller: { ...payload, code } });
  } catch (error) {
    return next(error);
  }
});

router.post('/bulk-delete', async (req, res, next) => {
  try {
    const ids = normalizeIds(req.body?.ids);
    if (ids.length === 0) return res.status(400).json({ message: 'Aucun agent selectionne.' });
    const db = getFirebaseAdminDb();
    let deleted = 0;
    const missing = [];
    for (const id of ids) {
      const loaded = await loadControllerDoc(db, id);
      if (!loaded) {
        missing.push(id);
        continue;
      }
      const data = loaded.doc.data() || {};
      if (!assertControllerScope(req, res, data)) return undefined;
      await archiveAndDisableController(db, req, loaded, 'bulk_delete');
      deleted += 1;
    }
    return res.json({ ok: true, deleted, missing });
  } catch (error) {
    return next(error);
  }
});

router.post('/:controllerCode/regenerate', async (req, res, next) => {
  try {
    const db = getFirebaseAdminDb();
    const loaded = await loadControllerDoc(db, req.params.controllerCode);
    if (!loaded) return res.status(404).json({ message: 'Controleur introuvable.' });

    const data = loaded.doc.data() || {};
    if (!assertControllerScope(req, res, data)) return undefined;

    const newCode = await generateUnusedControllerCode(db);
    const newRef = db.collection(COLLECTION).doc(newCode);
    const timestamp = FieldValue.serverTimestamp();
    const replacementPayload = {
      ...data,
      id: newCode,
      codeHash: hashControllerCode(newCode),
      displayCodeMasked: maskCode(newCode),
      usedAt: null,
      enabled: true,
      disabledAt: null,
      regeneratedAt: timestamp,
      regeneratedBy: req.user?.uid || 'admin',
      replacedControllerCode: stripLegacyPrefix(loaded.code),
      updatedAt: timestamp,
    };

    const batch = db.batch();
    batch.set(newRef, replacementPayload);
    batch.set(loaded.ref, {
      enabled: false,
      disabledAt: timestamp,
      replacedByControllerCode: newCode,
      updatedAt: timestamp,
    }, { merge: true });
    await batch.commit();

    try {
      await import('../services/firebaseAdmin.js').then(({ getFirebaseAdminAuth }) => getFirebaseAdminAuth().revokeRefreshTokens(`controller:${loaded.code}`));
    } catch (revokeError) {
      logger.warn({ err: revokeError, controllerCode: loaded.code }, 'controller_token_revocation_failed');
    }

    return res.json({
      controller: {
        ...serializeController({ id: newCode, data: () => replacementPayload }),
        code: newCode,
      },
    });
  } catch (error) {
    return next(error);
  }
});

router.delete('/:controllerCode', async (req, res, next) => {
  try {
    const db = getFirebaseAdminDb();
    const loaded = await loadControllerDoc(db, req.params.controllerCode);
    if (!loaded) return res.status(404).json({ message: 'Controleur introuvable.' });
    const data = loaded.doc.data() || {};
    if (!assertControllerScope(req, res, data)) return undefined;
    await archiveAndDisableController(db, req, loaded, 'manual_delete');
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

export default router;
