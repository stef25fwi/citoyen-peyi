// Sauvegarde & restauration applicative (Niveau 2).
//
// Ce module produit des snapshots JSON versionnes de Firestore et les rejoue de
// maniere idempotente et sure. La logique de (de)serialisation et de
// planification de restauration est PURE (testable sans Firestore/GCS) ; les
// I/O Firestore sont concentrees dans collectSnapshot/restoreSnapshot.
//
// IMPORTANT : un snapshot ne contient JAMAIS de secrets/peppers. Les codes y
// figurent uniquement sous forme de hash (deja hashes en base). Restaurer ces
// hash ne retablit les connexions que si les MEMES peppers (Secret Manager)
// sont encore configures.

import { logger } from './logger.js';

export const SNAPSHOT_VERSION = 1;

// Marqueur JSON pour les Timestamp/Date Firestore : { "$ts": "<ISO>" }.
const TS_KEY = '$ts';

// Specs de collections sauvegardees. `scopeField` permet une restauration
// selective par commune (Phase 3) ; `group` lit une sous-collection via
// collectionGroup ; `writePath` resout le chemin d'ecriture a la restauration.
export const COLLECTION_SPECS = [
  { key: 'communeAdmins', scopeField: 'communeCode' },
  { key: 'adminProfiles' },
  { key: 'controleurCodes', scopeField: 'commune.code' },
  { key: 'controleurActivities' },
  { key: 'deleted_records' },
  { key: 'polls', scopeField: 'communeId' },
  { key: 'registrationCodes' },
  { key: 'citizen_access_codes', scopeField: 'communeId' },
  { key: 'citizen_fingerprints', scopeField: 'communeId' },
  { key: 'duplicate_code_requests', scopeField: 'communeId' },
  { key: 'controller_activity_logs', scopeField: 'communeId' },
  { key: 'poll_participations', scopeField: 'communeId' },
  { key: 'poll_ballots', scopeField: 'communeId' },
  { key: 'poll_votes' },
  { key: 'poll_votes_legacy_archives' },
  { key: 'citizen_poll_access', scopeField: 'communeId' },
  { key: 'notification_subscriptions', scopeField: 'communeId' },
  { key: 'public_news', scopeField: 'communeId' },
  { key: 'support_tickets', scopeField: 'communeId' },
  {
    key: 'support_ticket_messages',
    group: 'messages',
    writePath: (id, data) => ['support_tickets', String(data?.ticketId || ''), 'messages', id],
  },
];

const isPlainObject = (value) => value !== null
  && typeof value === 'object'
  && !Array.isArray(value);

const isFirestoreTimestamp = (value) => isPlainObject(value)
  && typeof value.toDate === 'function';

const getByPath = (data, path) => String(path).split('.').reduce(
  (acc, key) => (acc == null ? undefined : acc[key]),
  data,
);

// ---------- (De)serialisation ----------

export const serializeValue = (value) => {
  if (value === null || value === undefined) return value;
  if (value instanceof Date) return { [TS_KEY]: value.toISOString() };
  if (isFirestoreTimestamp(value)) return { [TS_KEY]: value.toDate().toISOString() };
  if (Array.isArray(value)) return value.map(serializeValue);
  if (isPlainObject(value)) {
    const out = {};
    for (const [key, nested] of Object.entries(value)) {
      out[key] = serializeValue(nested);
    }
    return out;
  }
  return value;
};

export const serializeDocData = (data) => serializeValue(data || {});

export const deserializeValue = (value, { Timestamp } = {}) => {
  if (value === null || value === undefined) return value;
  if (Array.isArray(value)) return value.map((item) => deserializeValue(item, { Timestamp }));
  if (isPlainObject(value)) {
    const keys = Object.keys(value);
    if (keys.length === 1 && keys[0] === TS_KEY && typeof value[TS_KEY] === 'string') {
      const date = new Date(value[TS_KEY]);
      if (Timestamp && typeof Timestamp.fromDate === 'function') {
        return Timestamp.fromDate(date);
      }
      return date;
    }
    const out = {};
    for (const [key, nested] of Object.entries(value)) {
      out[key] = deserializeValue(nested, { Timestamp });
    }
    return out;
  }
  return value;
};

export const deserializeDocData = (data, deps = {}) => deserializeValue(data || {}, deps);

// ---------- Planification de restauration (pure) ----------

// Extrait un horodatage comparable (ms) depuis updatedAt puis createdAt, quelle
// que soit sa forme (marqueur $ts, Timestamp Firestore, Date, chaine ISO).
export const comparableTime = (data) => {
  const value = data?.updatedAt ?? data?.createdAt;
  if (!value) return 0;
  if (isPlainObject(value) && typeof value[TS_KEY] === 'string') {
    const parsed = Date.parse(value[TS_KEY]);
    return Number.isNaN(parsed) ? 0 : parsed;
  }
  if (isFirestoreTimestamp(value)) return value.toDate().getTime();
  if (value instanceof Date) return value.getTime();
  const parsed = Date.parse(String(value));
  return Number.isNaN(parsed) ? 0 : parsed;
};

// existing/backup : [{ id, data }]. Retourne le plan sans rien ecrire.
export const planRestore = ({ existing = [], backup = [], mode = 'merge', force = false }) => {
  const existingMap = new Map(existing.map((doc) => [doc.id, doc.data || {}]));
  const writes = [];
  const skipped = [];
  const deletes = [];

  for (const doc of backup) {
    const current = existingMap.get(doc.id);
    if (!current) {
      writes.push(doc);
      continue;
    }
    if (force) {
      writes.push(doc);
      continue;
    }
    // Garde anti-ecrasement : ne pas remplacer un document plus recent.
    if (comparableTime(current) > comparableTime(doc.data)) {
      skipped.push({ id: doc.id, reason: 'existing_newer' });
    } else {
      writes.push(doc);
    }
  }

  if (mode === 'mirror') {
    const backupIds = new Set(backup.map((doc) => doc.id));
    for (const doc of existing) {
      if (!backupIds.has(doc.id)) deletes.push(doc.id);
    }
  }

  return { writes, deletes, skipped };
};

// ---------- I/O Firestore ----------

const refForDoc = (db, spec, id, data) => {
  if (typeof spec.writePath === 'function') {
    const segments = spec.writePath(id, data).filter((segment) => segment !== '' && segment != null);
    return db.doc(segments.join('/'));
  }
  return db.collection(spec.key).doc(id);
};

const applyScope = (query, spec, scope) => {
  let scoped = query;
  if (scope?.communeId && spec.scopeField && !spec.scopeField.includes('.')) {
    scoped = scoped.where(spec.scopeField, '==', scope.communeId);
  }
  return scoped;
};

const matchesScope = (spec, doc, scope) => {
  if (scope?.communeId && spec.scopeField && spec.scopeField.includes('.')) {
    if (getByPath(doc.data, spec.scopeField) !== scope.communeId) return false;
  }
  if (Array.isArray(scope?.pollIds) && scope.pollIds.length > 0) {
    const ids = new Set(scope.pollIds.map(String));
    if (spec.key === 'polls') return ids.has(String(doc.data?.id || doc.id));
    if (['poll_participations', 'poll_ballots', 'citizen_poll_access'].includes(spec.key)) {
      return ids.has(String(doc.data?.pollId || ''));
    }
  }
  return true;
};

const readCollection = async (db, spec, scope) => {
  const base = spec.group ? db.collectionGroup(spec.group) : db.collection(spec.key);
  const snapshot = await applyScope(base, spec, scope).get();
  return snapshot.docs
    .map((doc) => ({ id: doc.id, data: doc.data() || {} }))
    .filter((doc) => matchesScope(spec, doc, scope));
};

export const collectSnapshot = async ({ db, specs = COLLECTION_SPECS, scope = {}, now = new Date() }) => {
  const MAX_DOCUMENTS = 100_000;
  const collections = {};
  const counts = {};
  let totalDocuments = 0;

  logger.info({ specsCount: specs.length, scope }, 'backup_collecting_start');
  const startTime = Date.now();

  for (const spec of specs) {
    const collStart = Date.now();
    const docs = await readCollection(db, spec, scope);
    const docCount = docs.length;
    const collDuration = Date.now() - collStart;

    totalDocuments += docCount;
    if (totalDocuments > MAX_DOCUMENTS) {
      throw new Error(
        `Snapshot trop volumineux: ${totalDocuments} documents > ${MAX_DOCUMENTS}`
      );
    }

    logger.debug({
      collection: spec.key,
      docCount,
      durationMs: collDuration,
    }, 'backup_collection_read');

    collections[spec.key] = docs.map((doc) => ({ id: doc.id, data: serializeDocData(doc.data) }));
    counts[spec.key] = docCount;
  }

  const totalDuration = Date.now() - startTime;
  logger.info({
    totalDocuments,
    collectionsCount: specs.length,
    durationMs: totalDuration,
    counts,
  }, 'backup_collecting_complete');

  return {
    version: SNAPSHOT_VERSION,
    createdAt: now.toISOString(),
    scope,
    collectionKeys: specs.map((spec) => spec.key),
    counts,
    totalDocuments,
    collections,
  };
};

const chunk = (items, size) => {
  const out = [];
  for (let index = 0; index < items.length; index += size) {
    out.push(items.slice(index, index + size));
  }
  return out;
};

const readExisting = async (db, spec, backupDocs, mode) => {
  if (mode === 'mirror') {
    // Mirror doit connaitre tous les documents existants pour calculer les
    // suppressions. Limite aux collections top-level (pas de group).
    if (spec.group) return [];
    const snapshot = await db.collection(spec.key).get();
    return snapshot.docs.map((doc) => ({ id: doc.id, data: doc.data() || {} }));
  }
  const existing = [];
  for (const docs of chunk(backupDocs, 30)) {
    const reads = await Promise.all(docs.map((doc) => refForDoc(db, spec, doc.id, doc.data).get()));
    existing.push(...reads.filter((doc) => doc.exists).map((doc) => ({ id: doc.id, data: doc.data() || {} })));
  }
  return existing;
};

export const restoreSnapshot = async ({ db, snapshot, Timestamp, options = {} }) => {
  const mode = options.mode === 'mirror' ? 'mirror' : 'merge';
  const force = options.force === true;
  const dryRun = options.dryRun !== false;
  const allowed = Array.isArray(options.collections) && options.collections.length > 0
    ? new Set(options.collections)
    : null;

  const report = {
    dryRun,
    mode,
    force,
    collections: {},
    totals: { writes: 0, deletes: 0, skipped: 0 },
  };

  for (const spec of COLLECTION_SPECS) {
    if (allowed && !allowed.has(spec.key)) continue;
    const backupDocs = snapshot.collections?.[spec.key] || [];
    const existing = await readExisting(db, spec, backupDocs, mode);
    const plan = planRestore({ existing, backup: backupDocs, mode, force });

    report.collections[spec.key] = {
      writes: plan.writes.length,
      deletes: plan.deletes.length,
      skipped: plan.skipped.length,
    };
    report.totals.writes += plan.writes.length;
    report.totals.deletes += plan.deletes.length;
    report.totals.skipped += plan.skipped.length;

    if (dryRun) continue;

    const ops = [];
    for (const doc of plan.writes) {
      ops.push({ type: 'set', ref: refForDoc(db, spec, doc.id, doc.data), data: deserializeDocData(doc.data, { Timestamp }) });
    }
    for (const id of plan.deletes) {
      ops.push({ type: 'delete', ref: refForDoc(db, spec, id, {}) });
    }

    for (const batchOps of chunk(ops, 450)) {
      const batch = db.batch();
      for (const op of batchOps) {
        if (op.type === 'delete') batch.delete(op.ref);
        else batch.set(op.ref, op.data, { merge: true });
      }
      await batch.commit();
    }
  }

  return report;
};
