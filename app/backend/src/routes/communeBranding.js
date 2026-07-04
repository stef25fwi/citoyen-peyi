import crypto from 'crypto';
import express from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { env, isFirebaseAdminConfigured } from '../config/env.js';
import {
  communeScopeFromUser,
  isSuperAdmin,
  requireCommuneAdmin,
  requireFirebaseAuth,
} from '../middlewares/requireFirebaseAuth.js';
import {
  getFirebaseAdminDb,
  getFirebaseAdminStorage,
} from '../services/firebaseAdmin.js';

const router = express.Router();
const BRANDING_COLLECTION = 'commune_branding';
const ALLOWED_LOGO_TYPES = { 'image/webp': 'webp' };
const MAX_LOGO_BYTES = 4 * 1024 * 1024;
const logoBodyParser = express.json({ limit: '8mb' });

const ensureConfigured = (_req, res, next) => {
  if (!isFirebaseAdminConfigured()) {
    return res.status(503).json({ message: 'Backend Firebase Admin non configure.' });
  }
  return next();
};

const sanitizeString = (value, max) =>
  typeof value === 'string' ? value.trim().substring(0, max) : '';

const safeStorageSegment = (value) => {
  const safe = String(value || '').trim().replace(/[^A-Za-z0-9_-]+/g, '_');
  return safe || 'commune';
};

const normalizeCommuneName = (value) =>
  String(value || '')
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .substring(0, 120);

const resolveStorageBucketName = () => {
  if (env.storageBucket) return env.storageBucket;
  const projectId = process.env.GOOGLE_CLOUD_PROJECT
    || process.env.GCLOUD_PROJECT
    || process.env.FIREBASE_PROJECT_ID
    || env.firebaseAdminProjectId
    || '';
  return projectId ? `${projectId}.firebasestorage.app` : '';
};

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

router.post('/logo', logoBodyParser, requireMatchingCommune, async (req, res, next) => {
  try {
    const contentType = sanitizeString(req.body?.contentType, 40).toLowerCase();
    const extension = ALLOWED_LOGO_TYPES[contentType];
    if (!extension) {
      return res.status(400).json({
        message: 'Le logo doit etre converti en WebP avant televersement.',
      });
    }

    const rawData = typeof req.body?.data === 'string' ? req.body.data : '';
    const base64 = rawData.includes(',')
      ? rawData.substring(rawData.indexOf(',') + 1)
      : rawData;
    if (!base64) {
      return res.status(400).json({ message: 'Donnees de logo manquantes.' });
    }

    const buffer = Buffer.from(base64, 'base64');
    if (buffer.length === 0 || buffer.length > MAX_LOGO_BYTES) {
      return res.status(400).json({
        message: 'Logo vide ou superieur a 4 Mo apres conversion WebP.',
      });
    }

    const bucketName = resolveStorageBucketName();
    if (!bucketName) {
      return res.status(503).json({ message: 'Bucket Storage non configure cote backend.' });
    }

    const communeId = safeStorageSegment(
      req.communeScope || sanitizeString(req.body?.communeId, 64),
    );
    const communeName = sanitizeString(req.body?.communeName, 200);
    if (!communeName) {
      return res.status(400).json({ message: 'Nom de collectivité requis.' });
    }

    const fileName = `logo_${Date.now()}_${crypto.randomBytes(4).toString('hex')}.${extension}`;
    const objectPath = `commune_branding/${communeId}/${fileName}`;
    const downloadToken = crypto.randomUUID();
    const file = getFirebaseAdminStorage().bucket(bucketName).file(objectPath);

    await file.save(buffer, {
      resumable: false,
      contentType,
      metadata: {
        contentType,
        cacheControl: 'public, max-age=31536000',
        metadata: {
          module: 'commune_branding',
          firebaseStorageDownloadTokens: downloadToken,
          communeId,
          communeName,
        },
      },
    });

    const url = `https://firebasestorage.googleapis.com/v0/b/${encodeURIComponent(bucketName)}`
      + `/o/${encodeURIComponent(objectPath)}?alt=media&token=${downloadToken}`;

    const branding = {
      communeId,
      communeName,
      normalizedCommuneName: normalizeCommuneName(communeName),
      logoUrl: url,
      logoContentType: contentType,
      logoStoragePath: objectPath,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: req.user?.uid || 'admin',
    };

    await getFirebaseAdminDb().collection(BRANDING_COLLECTION).doc(communeId).set(branding, { merge: true });

    return res.status(201).json({
      branding: {
        ...branding,
        updatedAt: new Date().toISOString(),
      },
    });
  } catch (error) {
    return next(error);
  }
});

export default router;