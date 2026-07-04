// Stockage des snapshots applicatifs dans un bucket GCS prive dedie.
//
// Reutilise l'app Firebase Admin (firebase-admin/storage) : aucune dependance
// supplementaire. Les snapshots ne sont jamais exposes en clair sur l'API
// publique ; on renvoie une URL signee de courte duree au super admin.

import crypto from 'crypto';
import { env } from '../config/env.js';
import { getFirebaseAdminStorage } from './firebaseAdmin.js';
import { logger } from './logger.js';

const SNAPSHOT_PREFIX = 'snapshots/';
const SIGNED_URL_TTL_MS = 10 * 60 * 1000;
const MAX_SNAPSHOT_SIZE = 500 * 1024 * 1024; // 500MB
const MAX_DOCUMENTS_PER_SNAPSHOT = 100_000;

const resolveProjectId = () => process.env.GOOGLE_CLOUD_PROJECT
  || process.env.GCLOUD_PROJECT
  || process.env.FIREBASE_PROJECT_ID
  || env.firebaseAdminProjectId
  || '';

export const backupBucketName = () => {
  if (env.backupBucket) return env.backupBucket;
  const projectId = resolveProjectId();
  if (!projectId) {
    throw new Error('BACKUP_BUCKET est requis (ou un projectId resoluble) pour stocker les snapshots.');
  }
  return `${projectId}-backups`;
};

const getBucket = () => getFirebaseAdminStorage().bucket(backupBucketName());

export const newSnapshotId = (now = new Date()) => {
  const stamp = now.toISOString().replace(/[:.]/g, '-');
  return `snapshot-${stamp}-${crypto.randomBytes(4).toString('hex')}`;
};

const pathForId = (id) => `${SNAPSHOT_PREFIX}${id}.json`;

export const saveSnapshot = async (id, snapshot) => {
  if (!snapshot || typeof snapshot !== 'object') {
    throw new Error('Snapshot invalide: pas un objet');
  }
  if (typeof snapshot.totalDocuments !== 'number' || snapshot.totalDocuments < 0) {
    throw new Error('Snapshot invalide: totalDocuments manquant ou invalide');
  }
  if (snapshot.totalDocuments > MAX_DOCUMENTS_PER_SNAPSHOT) {
    throw new Error(
      `Snapshot trop volumineux: ${snapshot.totalDocuments} documents > ${MAX_DOCUMENTS_PER_SNAPSHOT}`
    );
  }

  const file = getBucket().file(pathForId(id));
  const body = JSON.stringify(snapshot);
  const size = Buffer.byteLength(body);

  if (size > MAX_SNAPSHOT_SIZE) {
    throw new Error(
      `Snapshot trop volumineux: ${(size / 1024 / 1024).toFixed(2)}MB > ${(MAX_SNAPSHOT_SIZE / 1024 / 1024).toFixed(0)}MB`
    );
  }

  await file.save(body, {
    contentType: 'application/json',
    resumable: false,
    metadata: {
      cacheControl: 'no-store',
      metadata: {
        snapshotId: id,
        version: String(snapshot.version ?? ''),
        createdAt: snapshot.createdAt ?? '',
        totalDocuments: String(snapshot.totalDocuments ?? ''),
      },
    },
  });

  logger.debug({ snapshotId: id, sizeBytes: size, sizeMB: (size / 1024 / 1024).toFixed(2) }, 'backup_snapshot_saved');
  return { id, path: pathForId(id), bucket: backupBucketName(), size };
};

export const listSnapshots = async () => {
  const [files] = await getBucket().getFiles({ prefix: SNAPSHOT_PREFIX });
  return files
    .map((file) => {
      const meta = file.metadata || {};
      const custom = meta.metadata || {};
      const id = custom.snapshotId || file.name.replace(SNAPSHOT_PREFIX, '').replace(/\.json$/, '');
      return {
        id,
        createdAt: custom.createdAt || meta.timeCreated || '',
        totalDocuments: Number(custom.totalDocuments || 0),
        version: Number(custom.version || 0),
        size: Number(meta.size || 0),
      };
    })
    .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));
};

export const loadSnapshot = async (id) => {
  const file = getBucket().file(pathForId(id));
  const [exists] = await file.exists();
  if (!exists) return null;

  try {
    const [metadata] = await file.getMetadata();
    const size = Number(metadata.size || 0);

    if (size > MAX_SNAPSHOT_SIZE) {
      throw new Error(
        `Snapshot trop volumineux: ${(size / 1024 / 1024).toFixed(2)}MB > ${(MAX_SNAPSHOT_SIZE / 1024 / 1024).toFixed(0)}MB`
      );
    }

    const [buffer] = await file.download();
    const content = buffer.toString('utf8');

    if (!content.trim().startsWith('{')) {
      throw new Error('Snapshot invalide: pas du JSON valide (ne commence pas par {)');
    }

    const snapshot = JSON.parse(content);
    logger.debug({ snapshotId: id, sizeBytes: size }, 'backup_snapshot_loaded');
    return snapshot;
  } catch (error) {
    if (error instanceof SyntaxError) {
      logger.error({ snapshotId: id, err: error }, 'backup_snapshot_json_parse_error');
      throw new Error(`Snapshot ${id} JSON invalide: ${error.message}`);
    }
    throw error;
  }
};

export const getSignedDownloadUrl = async (id, { ttlMs = SIGNED_URL_TTL_MS } = {}) => {
  const file = getBucket().file(pathForId(id));
  const [exists] = await file.exists();
  if (!exists) return null;
  const [url] = await file.getSignedUrl({
    version: 'v4',
    action: 'read',
    expires: Date.now() + ttlMs,
  });
  return url;
};

export const deleteSnapshot = async (id) => {
  const file = getBucket().file(pathForId(id));
  const [exists] = await file.exists();
  if (!exists) return false;
  await file.delete();
  return true;
};
