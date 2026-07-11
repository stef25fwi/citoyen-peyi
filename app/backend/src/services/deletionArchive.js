import crypto from 'crypto';
import { FieldValue } from 'firebase-admin/firestore';

export const DELETED_RECORDS_COLLECTION = 'deleted_records';

const sanitizeIdPart = (value) => String(value || 'record')
  .trim()
  .replace(/[^a-zA-Z0-9_-]+/g, '-')
  .replace(/^-+|-+$/g, '')
  .substring(0, 80) || 'record';

export const archiveDeletedRecord = async (db, {
  kind,
  sourceCollection,
  recordId,
  data,
  deletedBy,
  reason = 'manual_delete',
}) => {
  const safeKind = sanitizeIdPart(kind || sourceCollection || 'record');
  const safeRecordId = sanitizeIdPart(recordId);
  const archiveId = `${safeKind}-${safeRecordId}-${Date.now()}-${crypto.randomBytes(4).toString('hex')}`;

  await db.collection(DELETED_RECORDS_COLLECTION).doc(archiveId).set({
    id: archiveId,
    kind: safeKind,
    sourceCollection: sourceCollection || kind || '',
    recordId: String(recordId || ''),
    reason,
    deletedBy: deletedBy || '',
    deletedAt: FieldValue.serverTimestamp(),
    data: data || {},
  });

  return archiveId;
};

const readDate = (value) => {
  if (!value) return '';
  if (typeof value?.toDate === 'function') return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  return String(value);
};

export const serializeDeletedRecord = (doc) => {
  const data = doc.data() || {};
  return {
    id: doc.id,
    kind: data.kind || '',
    sourceCollection: data.sourceCollection || '',
    recordId: data.recordId || '',
    reason: data.reason || '',
    deletedBy: data.deletedBy || '',
    deletedAt: readDate(data.deletedAt),
    data: data.data || {},
  };
};
