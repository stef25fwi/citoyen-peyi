import express from 'express';
import crypto from 'crypto';
import { FieldValue } from 'firebase-admin/firestore';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';
import {
  communeScopeFromUser,
  isCommuneAdmin,
  isSuperAdmin,
  requireCommuneAdmin,
  requireFirebaseAuth,
} from '../middlewares/requireFirebaseAuth.js';

const router = express.Router();
const POLL_COLLECTION = 'polls';

const ensureConfigured = (_req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ message: 'Backend Firebase Admin non configure.' });
  }
  return next();
};

const sanitizeString = (value, max) => (typeof value === 'string' ? value.trim().substring(0, max) : '');
const sanitizeDate = (value) => {
  if (typeof value !== 'string') return '';
  const trimmed = value.trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) return '';
  const date = new Date(`${trimmed}T00:00:00Z`);
  return Number.isNaN(date.getTime()) ? '' : trimmed;
};

const buildOptions = (rawOptions, existingOptions = []) => {
  if (!Array.isArray(rawOptions)) return [];
  return rawOptions
    .map((option, index) => {
      const label = sanitizeString(option?.label ?? option, 200);
      if (!label) return null;
      const id = sanitizeString(option?.id, 64) || existingOptions[index]?.id || `opt-${crypto.randomBytes(6).toString('hex')}`;
      const votes = Number(option?.votes) >= 0 ? Number(option.votes) : (existingOptions[index]?.votes ?? 0);
      return { id, label, votes };
    })
    .filter(Boolean);
};

const scopeFromAdmin = (user) => (isSuperAdmin(user) ? '' : communeScopeFromUser(user));

const requireMatchingCommune = (req, res, next) => {
  if (isSuperAdmin(req.user)) return next();
  const scope = communeScopeFromUser(req.user);
  if (!scope) {
    return res.status(403).json({ message: 'Aucune commune attachee au compte administrateur.' });
  }
  req.communeScope = scope;
  return next();
};

router.use(ensureConfigured, requireFirebaseAuth, requireCommuneAdmin);

router.get('/', async (req, res, next) => {
  try {
    const db = getFirebaseAdminDb();
    let query = db.collection(POLL_COLLECTION);
    const scope = scopeFromAdmin(req.user);
    if (scope) query = query.where('communeId', '==', scope);
    const snapshot = await query.limit(500).get();
    const polls = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ polls });
  } catch (error) {
    next(error);
  }
});

router.post('/', requireMatchingCommune, async (req, res, next) => {
  try {
    const projectTitle = sanitizeString(req.body?.projectTitle, 200);
    const question = sanitizeString(req.body?.question, 300);
    const options = buildOptions(req.body?.options);
    const openDate = sanitizeDate(req.body?.openDate);
    const closeDate = sanitizeDate(req.body?.closeDate);

    if (!projectTitle || !question || options.length < 2 || !openDate || !closeDate) {
      return res.status(400).json({ message: 'Champs obligatoires manquants ou invalides.' });
    }

    const db = getFirebaseAdminDb();
    const communeId = req.communeScope || sanitizeString(req.body?.communeId, 64);
    const communeName = sanitizeString(req.body?.communeName, 200);
    const id = `poll-${crypto.randomBytes(8).toString('hex')}`;

    const poll = {
      id,
      projectTitle,
      description: sanitizeString(req.body?.description, 2000),
      question,
      options,
      targetPopulation: sanitizeString(req.body?.targetPopulation, 300),
      openDate,
      closeDate,
      status: 'draft',
      communeId,
      communeName,
      totalVoters: Math.max(0, Math.min(10000000, Number(req.body?.totalVoters) || 0)),
      totalVoted: 0,
      createdAt: FieldValue.serverTimestamp(),
      createdBy: req.user?.uid || 'admin',
      updatedAt: FieldValue.serverTimestamp(),
    };

    await db.collection(POLL_COLLECTION).doc(id).set(poll);
    res.status(201).json({ poll: { ...poll, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() } });
  } catch (error) {
    next(error);
  }
});

const loadPollForUpdate = async (req, res) => {
  const db = getFirebaseAdminDb();
  const ref = db.collection(POLL_COLLECTION).doc(req.params.pollId);
  const doc = await ref.get();
  if (!doc.exists) {
    res.status(404).json({ message: 'Consultation introuvable.' });
    return null;
  }
  const data = doc.data() || {};
  if (!isSuperAdmin(req.user) && communeScopeFromUser(req.user) && data.communeId !== communeScopeFromUser(req.user)) {
    res.status(403).json({ message: 'Cette consultation appartient a une autre commune.' });
    return null;
  }
  return { ref, data };
};

router.patch('/:pollId', async (req, res, next) => {
  try {
    const loaded = await loadPollForUpdate(req, res);
    if (!loaded) return undefined;

    const { ref, data } = loaded;
    const update = { updatedAt: FieldValue.serverTimestamp() };
    if (typeof req.body?.projectTitle === 'string') update.projectTitle = sanitizeString(req.body.projectTitle, 200);
    if (typeof req.body?.description === 'string') update.description = sanitizeString(req.body.description, 2000);
    if (typeof req.body?.question === 'string') update.question = sanitizeString(req.body.question, 300);
    if (typeof req.body?.targetPopulation === 'string') update.targetPopulation = sanitizeString(req.body.targetPopulation, 300);
    if (req.body?.openDate) update.openDate = sanitizeDate(req.body.openDate) || data.openDate;
    if (req.body?.closeDate) update.closeDate = sanitizeDate(req.body.closeDate) || data.closeDate;
    if (Number.isFinite(Number(req.body?.totalVoters))) update.totalVoters = Math.max(0, Number(req.body.totalVoters));

    if (Array.isArray(req.body?.options)) {
      if ((data.totalVoted || 0) > 0) {
        return res.status(409).json({ message: 'Impossible de modifier les options apres le premier vote.' });
      }
      update.options = buildOptions(req.body.options, data.options || []);
      if (update.options.length < 2) {
        return res.status(400).json({ message: 'Au moins deux options sont requises.' });
      }
    }

    await ref.set(update, { merge: true });
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

const updateStatus = (status) => async (req, res, next) => {
  try {
    const loaded = await loadPollForUpdate(req, res);
    if (!loaded) return undefined;
    await loaded.ref.set({ status, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
    return res.json({ ok: true, status });
  } catch (error) {
    return next(error);
  }
};

router.post('/:pollId/publish', updateStatus('active'));
router.post('/:pollId/close', updateStatus('closed'));
router.post('/:pollId/archive', updateStatus('archived'));

router.delete('/:pollId', async (req, res, next) => {
  try {
    const loaded = await loadPollForUpdate(req, res);
    if (!loaded) return undefined;
    if ((loaded.data.totalVoted || 0) > 0) {
      return res.status(409).json({ message: 'Impossible de supprimer une consultation qui contient des votes.' });
    }
    await loaded.ref.delete();
    return res.json({ ok: true });
  } catch (error) {
    return next(error);
  }
});

export default router;
