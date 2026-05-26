import crypto from 'crypto';
import { pathToFileURL } from 'url';
import { FieldPath, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { env } from '../config/env.js';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';

const LEGACY_COLLECTION = 'registrationCodes';
const ACCESS_COLLECTION = 'citizen_access_codes';
const BATCH_SIZE = 200;

export const normalizeCode = (value) => String(value || '').trim().toUpperCase();
export const hashCode = (code) => crypto.createHash('sha256').update(normalizeCode(code)).digest('hex');
export const hashAccessCode = (code) => {
  if (!env.accessCodePepper) throw new Error('ACCESS_CODE_PEPPER is required');
  return crypto.createHmac('sha256', env.accessCodePepper).update(normalizeCode(code)).digest('hex');
};

export const toTimestamp = (value) => {
  if (!value) return FieldValue.serverTimestamp();
  if (value instanceof Timestamp) return value;
  const date = typeof value?.toDate === 'function' ? value.toDate() : new Date(String(value));
  if (Number.isNaN(date.getTime())) return FieldValue.serverTimestamp();
  return Timestamp.fromDate(date);
};

export const maskCode = (code) => `${code.substring(0, 2)}••••${code.substring(Math.max(code.length - 2, 2))}`;

export const buildAccessPayload = (legacyId, data, code) => ({
  accessCodeHash: hashAccessCode(code),
  displayCodeMasked: maskCode(code),
  communeId: data.communeId || '',
  communeName: data.communeName || '',
  status: data.status === 'revoked' ? 'revoked' : 'active',
  createdAt: toTimestamp(data.validatedAt || data.createdAt),
  createdByControllerId: data.verifiedByControleurCode || '',
  createdByControllerName: data.verifiedByControleurLabel || '',
  replacedByCodeId: null,
  replacedAt: null,
  lastUsedAt: data.votedAt ? toTimestamp(data.votedAt) : null,
  usedForLogin: Boolean(data.activatedAt || data.votedAt),
  metadata: {
    migratedFrom: LEGACY_COLLECTION,
    legacyRegistrationCodeId: legacyId,
    legacyDocumentType: data.documentType || null,
    legacyQrPayloadPresent: Boolean(data.qrPayload),
    legacyExpiresAt: data.expiresAt || null,
  },
});

export async function migrateRegistrationCodesToCitizenAccessCodes({ db, dryRun = false } = {}) {
  const targetDb = db ?? getFirebaseAdminDb();
  let migrated = 0;
  let skipped = 0;
  let ignored = 0;
  let scanned = 0;

  let batch = targetDb.batch();
  let pendingWrites = 0;
  let cursor = null;

  while (true) {
    let query = targetDb.collection(LEGACY_COLLECTION).orderBy(FieldPath.documentId()).limit(BATCH_SIZE);
    if (cursor != null) {
      query = query.startAfter(cursor);
    }

    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    for (const doc of snapshot.docs) {
      scanned += 1;
      const data = doc.data() || {};
      const code = normalizeCode(data.code);

      if (!code || data.status !== 'validated') {
        ignored += 1;
        continue;
      }

      const accessCodeHash = hashAccessCode(code);
      const accessRef = targetDb.collection(ACCESS_COLLECTION).doc(`cac_legacy_${accessCodeHash.substring(0, 24)}`);
      const accessDoc = await accessRef.get();
      if (accessDoc.exists) {
        skipped += 1;
        continue;
      }

      migrated += 1;
      if (dryRun) {
        continue;
      }

      batch.set(accessRef, buildAccessPayload(doc.id, data, code), { merge: true });
      batch.set(doc.ref, {
        migratedAt: FieldValue.serverTimestamp(),
        migratedAccessCodeId: accessRef.id,
        migratedToCollection: ACCESS_COLLECTION,
      }, { merge: true });
      pendingWrites += 2;

      if (pendingWrites >= BATCH_SIZE) {
        await batch.commit();
        batch = targetDb.batch();
        pendingWrites = 0;
      }
    }

    cursor = snapshot.docs[snapshot.docs.length - 1];
  }

  if (!dryRun && pendingWrites > 0) {
    await batch.commit();
  }

  return {
    ok: true,
    dryRun,
    scanned,
    migrated,
    skipped,
    ignored,
  };
}

const isExecutedAsScript = process.argv[1]
  ? import.meta.url === pathToFileURL(process.argv[1]).href
  : false;

async function runCli() {
  if (!isFirebaseAdminConfigured()) {
    process.stderr.write('Firebase Admin n\'est pas configure. Migration impossible.\n');
    process.exit(1);
  }

  const dryRun = process.argv.includes('--dry-run');
  const result = await migrateRegistrationCodesToCitizenAccessCodes({ dryRun });

  if (result.scanned == 0) {
    process.stdout.write('Aucun document registrationCodes a migrer.\n');
    process.exit(0);
  }

  process.stdout.write(`${JSON.stringify(result, null, 2)}\n`);
}

if (isExecutedAsScript) {
  await runCli();
}