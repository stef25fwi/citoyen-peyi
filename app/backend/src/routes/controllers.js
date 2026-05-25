import express from 'express';
import crypto from 'crypto';
import { FieldValue } from 'firebase-admin/firestore';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';
import {
  communeScopeFromUser,
  isSuperAdmin,
  requireCommuneAdmin,
  requireFirebaseAuth,
} from '../middlewares/requireFirebaseAuth.js';

const router = express.Router();
const COLLECTION = 'controleurCodes';
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

const ensureConfigured = (_req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ message: 'Backend Firebase Admin non configure.' });
  }
  return next();
};

const sanitize = (value, max) => (typeof value === 'string' ? value.trim().substring(0, max) : '');

const generateControllerCode = () => {
  const buf = crypto.randomBytes(8);
  const segment = Array.from(buf).map((b) => CODE_ALPHABET[b % CODE_ALPHABET.length]).join('');
  return `CTRL-${segment}`;
};

router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin);

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
      controllers: snapshot.docs.map((doc) => {
        const data = doc.data() || {};
        return {
          id: doc.id,
          code: data.code,
          label: data.label,
          commune: data.commune,
          createdAt: data.createdAt,
          usedAt: data.usedAt,
        };
      }),
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

    const code = generateControllerCode();
    const db = getFirebaseAdminDb();
    const payload = {
      id: code,
      code,
      label,
      commune: {
        name: scope.communeName,
        code: scope.communeCode,
        codePostal: scope.codePostal,
      },
      createdAt: FieldValue.serverTimestamp(),
      createdBy: req.user?.uid || 'admin',
      usedAt: null,
    };
    await db.collection(COLLECTION).doc(code).set(payload);
    return res.status(201).json({ controller: payload });
  } catch (error) {
    return next(error);
  }
});

router.delete('/:controllerCode', async (req, res, next) => {
  try {
    const code = sanitize(req.params.controllerCode, 64);
    const db = getFirebaseAdminDb();
    const ref = db.collection(COLLECTION).doc(code);
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ message: 'Controleur introuvable.' });
    const data = doc.data() || {};
    if (!isSuperAdmin(req.user)) {
      const scope = communeScopeFromUser(req.user);
      if (data.commune?.code !== scope) {
        return res.status(403).json({ message: 'Ce controleur appartient a une autre commune.' });
      }
    }
    await ref.delete();
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

export default router;
