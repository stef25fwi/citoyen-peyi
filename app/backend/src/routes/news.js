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
const NEWS_COLLECTION = 'public_news';

const ensureConfigured = (_req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ message: 'Backend Firebase Admin non configure.' });
  }
  return next();
};

const sanitize = (value, max) => (typeof value === 'string' ? value.trim().substring(0, max) : '');

router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin);

router.post('/', async (req, res, next) => {
  try {
    const title = sanitize(req.body?.title, 200);
    const body = sanitize(req.body?.body, 5000);
    if (!title || !body) {
      return res.status(400).json({ message: 'Titre et contenu requis.' });
    }
    const communeId = isSuperAdmin(req.user)
      ? sanitize(req.body?.communeId, 64)
      : communeScopeFromUser(req.user);
    const communeName = sanitize(req.body?.communeName, 200);
    const id = `news-${crypto.randomBytes(8).toString('hex')}`;

    const db = getFirebaseAdminDb();
    const payload = {
      id,
      title,
      body,
      communeId,
      communeName,
      publishedAt: FieldValue.serverTimestamp(),
      authorId: req.user?.uid || 'admin',
    };
    await db.collection(NEWS_COLLECTION).doc(id).set(payload);
    return res.status(201).json({ ok: true, id });
  } catch (error) {
    return next(error);
  }
});

router.patch('/:newsId', async (req, res, next) => {
  try {
    const db = getFirebaseAdminDb();
    const ref = db.collection(NEWS_COLLECTION).doc(req.params.newsId);
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ message: 'Actualite introuvable.' });
    const data = doc.data() || {};
    if (!isSuperAdmin(req.user) && communeScopeFromUser(req.user) && data.communeId !== communeScopeFromUser(req.user)) {
      return res.status(403).json({ message: 'Acces refuse.' });
    }
    const update = { updatedAt: FieldValue.serverTimestamp() };
    if (typeof req.body?.title === 'string') update.title = sanitize(req.body.title, 200);
    if (typeof req.body?.body === 'string') update.body = sanitize(req.body.body, 5000);
    await ref.set(update, { merge: true });
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

router.delete('/:newsId', async (req, res, next) => {
  try {
    const db = getFirebaseAdminDb();
    const ref = db.collection(NEWS_COLLECTION).doc(req.params.newsId);
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ message: 'Actualite introuvable.' });
    const data = doc.data() || {};
    if (!isSuperAdmin(req.user) && communeScopeFromUser(req.user) && data.communeId !== communeScopeFromUser(req.user)) {
      return res.status(403).json({ message: 'Acces refuse.' });
    }
    await ref.delete();
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

export default router;
