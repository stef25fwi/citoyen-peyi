import crypto from 'crypto';
import { FieldPath, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';

const LEGACY_COLLECTION = 'registrationCodes';
const ACCESS_COLLECTION = 'citizen_access_codes';
const BATCH_SIZE = 200;

const normalizeCode = (value) => String(value || '').trim().toUpperCase();
const hashCode = (code) => crypto.createHash('sha256').update(normalizeCode(code)).digest('hex');

const toTimestamp = (value) => {
  if (!value) return FieldValue.serverTimestamp();
  if (value instanceof Timestamp) return value;
  const date = typeof value?.toDate === 'function' ? value.toDate() : new Date(String(value));
  if (Number.isNaN(date.getTime())) return FieldValue.serverTimestamp();
  return Timestamp.fromDate(date);
};

const maskCode = (code) => `${code.substring(0, 2)}••••${code.substring(Math.max(code.length - 2, 2))}`;

const buildAccessPayload = (legacyId, data, code) => ({
  accessCode: code,
  codeHash: hashCode(code),
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

const dryRun = process.argv.includes('--dry-run');

if (!isFirebaseAdminConfigured()) {
  console.error('Firebase Admin n\'est pas configure. Migration impossible.');
  process.exit(1);
}

const db = getFirebaseAdminDb();
let migrated = 0;
let skipped = 0;
let ignored = 0;
let scanned = 0;

let batch = db.batch();
let pendingWrites = 0;
let cursor = null;

while (true) {
  let query = db.collection(LEGACY_COLLECTION).orderBy(FieldPath.documentId()).limit(BATCH_SIZE);
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

    const accessRef = db.collection(ACCESS_COLLECTION).doc(code);
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
      migratedAccessCodeId: code,
      migratedToCollection: ACCESS_COLLECTION,
    }, { merge: true });
    pendingWrites += 2;

    if (pendingWrites >= BATCH_SIZE) {
      await batch.commit();
      batch = db.batch();
      pendingWrites = 0;
    }
  }

  cursor = snapshot.docs.last;
}

if (!dryRun && pendingWrites > 0) {
  await batch.commit();
}

if (scanned == 0) {
  console.log('Aucun document registrationCodes a migrer.');
  process.exit(0);
}

console.log(JSON.stringify({
  ok: true,
  dryRun,
  scanned,
  migrated,
  skipped,
  ignored,
}, null, 2));