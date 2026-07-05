import express from 'express';
import { Timestamp } from 'firebase-admin/firestore';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';
import { requireFirebaseAuth, requireSuperAdmin } from '../middlewares/requireFirebaseAuth.js';
import { logger } from '../services/logger.js';
import { COLLECTION_SPECS, collectSnapshot, restoreSnapshot } from '../services/backupService.js';
import {
  deleteSnapshot,
  getSignedDownloadUrl,
  listSnapshots,
  loadSnapshot,
  newSnapshotId,
  saveSnapshot,
} from '../services/backupStorage.js';

const router = express.Router();

const VALID_KEYS = new Set(COLLECTION_SPECS.map((spec) => spec.key));

const ensureConfigured = (_req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ message: 'Backend Firebase Admin non configure.' });
  }
  return next();
};

const sanitizeString = (value, max) => (typeof value === 'string' ? value.trim().substring(0, max) : '');

const parseScope = (raw) => {
  if (typeof raw !== 'object' || raw === null) return {};
  const scope = {};
  const communeId = sanitizeString(raw.communeId, 128);
  if (communeId) scope.communeId = communeId;
  if (Array.isArray(raw.pollIds)) {
    const pollIds = raw.pollIds.map((value) => sanitizeString(value, 128)).filter(Boolean).slice(0, 100);
    if (pollIds.length > 0) scope.pollIds = pollIds;
  }
  return scope;
};

const parseCollections = (raw) => {
  if (!Array.isArray(raw)) return null;
  const keys = raw.map((value) => sanitizeString(value, 64)).filter((key) => VALID_KEYS.has(key));
  return keys.length > 0 ? keys : null;
};

router.use(ensureConfigured, requireFirebaseAuth, requireSuperAdmin);

// Cree un snapshot maintenant et le stocke dans le bucket prive.
router.post('/', async (req, res, next) => {
  try {
    const scope = parseScope(req.body?.scope);
    const collections = parseCollections(req.body?.collections);
    const specs = collections
      ? COLLECTION_SPECS.filter((spec) => collections.includes(spec.key))
      : COLLECTION_SPECS;

    const now = new Date();
    const snapshot = await collectSnapshot({ db: getFirebaseAdminDb(), specs, scope, now });
    const id = newSnapshotId(now);
    const stored = await saveSnapshot(id, snapshot);

    logger.info({ snapshotId: id, total: snapshot.totalDocuments }, 'backup_snapshot_created');
    return res.status(201).json({
      id,
      createdAt: snapshot.createdAt,
      totalDocuments: snapshot.totalDocuments,
      counts: snapshot.counts,
      scope,
      storage: { bucket: stored.bucket, path: stored.path, size: stored.size },
    });
  } catch (error) {
    logger.error({ err: error }, 'backup_snapshot_creation_failed');
    return next(error);
  }
});

// Liste les snapshots (metadonnees uniquement).
router.get('/', async (_req, res, next) => {
  try {
    return res.json({ snapshots: await listSnapshots() });
  } catch (error) {
    logger.error({ err: error }, 'backup_snapshot_list_failed');
    return next(error);
  }
});

// Renvoie une URL signee de courte duree pour telecharger le snapshot.
router.get('/:id', async (req, res, next) => {
  try {
    const url = await getSignedDownloadUrl(sanitizeString(req.params.id, 200));
    if (!url) return res.status(404).json({ message: 'Snapshot introuvable.' });
    return res.json({ url, expiresInMs: 10 * 60 * 1000 });
  } catch (error) {
    logger.error({ err: error }, 'backup_snapshot_signed_url_failed');
    return next(error);
  }
});

// Restaure un snapshot. dryRun par defaut ; mirror exige force=true.
router.post('/:id/restore', async (req, res, next) => {
  try {
    const id = sanitizeString(req.params.id, 200);
    const snapshot = await loadSnapshot(id);
    if (!snapshot) return res.status(404).json({ message: 'Snapshot introuvable.' });

    const mode = req.body?.mode === 'mirror' ? 'mirror' : 'merge';
    const force = req.body?.force === true;
    const dryRun = req.body?.dryRun !== false;
    const collections = parseCollections(req.body?.collections);

    if (mode === 'mirror' && !force && !dryRun) {
      return res.status(400).json({
        error: 'MIRROR_REQUIRES_FORCE',
        message: 'Le mode mirror supprime les documents absents du snapshot : force=true est requis.',
      });
    }

    const report = await restoreSnapshot({
      db: getFirebaseAdminDb(),
      snapshot,
      Timestamp,
      options: { mode, force, dryRun, collections },
    });

    logger.info({ snapshotId: id, mode, dryRun, totals: report.totals }, 'backup_snapshot_restored');
    return res.json({ id, report });
  } catch (error) {
    logger.error({ err: error }, 'backup_snapshot_restore_failed');
    return next(error);
  }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const deleted = await deleteSnapshot(sanitizeString(req.params.id, 200));
    if (!deleted) return res.status(404).json({ message: 'Snapshot introuvable.' });
    return res.json({ ok: true });
  } catch (error) {
    logger.error({ err: error }, 'backup_snapshot_delete_failed');
    return next(error);
  }
});

export default router;
