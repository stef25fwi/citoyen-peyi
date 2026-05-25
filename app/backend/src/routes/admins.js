import express from 'express';
import crypto from 'crypto';
import { FieldValue } from 'firebase-admin/firestore';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';
import { requireFirebaseAuth, requireSuperAdmin } from '../middlewares/requireFirebaseAuth.js';
import { requireSuperAdminKey } from '../middlewares/requireSuperAdminKey.js';

const router = express.Router();
const COLLECTION = 'communeAdmins';
const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

const ensureConfigured = (_req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ message: 'Backend Firebase Admin non configure.' });
  }
  return next();
};

const sanitize = (value, max) => (typeof value === 'string' ? value.trim().substring(0, max) : '');
const generateAccessKey = () => {
  const buf = crypto.randomBytes(16);
  const part1 = Array.from(buf.slice(0, 8)).map((b) => CODE_ALPHABET[b % CODE_ALPHABET.length]).join('');
  const part2 = Array.from(buf.slice(8, 12)).map((b) => CODE_ALPHABET[b % CODE_ALPHABET.length]).join('');
  return `ADM-${part1}-${part2}`;
};
const hashAccessKey = (key) => crypto.createHash('sha256').update(key).digest('hex');

router.use(ensureConfigured, requireFirebaseAuth, requireSuperAdmin, requireSuperAdminKey);

router.get('/', async (_req, res, next) => {
  try {
    const db = getFirebaseAdminDb();
    const snapshot = await db.collection(COLLECTION).limit(500).get();
    res.json({
      admins: snapshot.docs.map((doc) => {
        const data = doc.data() || {};
        return {
          id: doc.id,
          label: data.label,
          communeName: data.communeName,
          communeCode: data.communeCode,
          codePostal: data.codePostal,
          createdAt: data.createdAt,
          lastUsedAt: data.lastUsedAt,
        };
      }),
    });
  } catch (error) {
    next(error);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const label = sanitize(req.body?.label, 200);
    const communeName = sanitize(req.body?.communeName, 200);
    const communeCode = sanitize(req.body?.communeCode, 64);
    const codePostal = sanitize(req.body?.codePostal, 16);

    if (!label || !communeName) {
      return res.status(400).json({ message: 'Libelle et commune sont requis.' });
    }

    const accessKey = generateAccessKey();
    const id = `adm-${crypto.randomBytes(8).toString('hex')}`;
    const db = getFirebaseAdminDb();

    await db.collection(COLLECTION).doc(id).set({
      id,
      label,
      communeName,
      communeCode,
      codePostal,
      accessKeyHash: hashAccessKey(accessKey),
      createdAt: FieldValue.serverTimestamp(),
      createdBy: req.user?.uid || 'super_admin',
    });

    return res.status(201).json({
      id,
      label,
      communeName,
      communeCode,
      codePostal,
      accessKey,
    });
  } catch (error) {
    return next(error);
  }
});

router.delete('/:adminId', async (req, res, next) => {
  try {
    const db = getFirebaseAdminDb();
    const ref = db.collection(COLLECTION).doc(req.params.adminId);
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ message: 'Profil introuvable.' });
    await ref.delete();
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

export default router;
