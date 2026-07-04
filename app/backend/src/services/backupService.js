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
  // Merge : seuls les documents cibles du backup sont necessaires (garde
  // anti-ecrasement). Lecture par lots via getAll.
  const refs = backupDocs.map((doc) => refForDoc(db, spec, doc.id, doc.data));
  const existing = [];
  for (const refBatch of chunk(refs, 300)) {
    if (refBatch.length === 0) continue;
    const snapshots = await db.getAll(...refBatch);
    for (const snap of snapshots) {
      if (snap.exists) existing.push({ id: snap.id, data: snap.data() || {} });
    }
  }
  return existing;
};

const applyPlan = async (db, spec, plan, { Timestamp }) => {
  const errors = [];

  // Appliquer les écritures
  const writes = plan.writes.map((doc) => ({
    ref: refForDoc(db, spec, doc.id, doc.data),
    data: deserializeDocData(doc.data, { Timestamp }),
  }));

  for (let i = 0; i < chunk(writes, 450).length; i++) {
    const writeBatch = chunk(writes, 450)[i];
    try {
      const batch = db.batch();
      for (const item of writeBatch) batch.set(item.ref, item.data);
      await batch.commit();
    } catch (error) {
      errors.push({
        phase: 'write',
        batch: i,
        size: writeBatch.length,
        error: error.message,
      });
    }
  }

  // Appliquer les suppressions
  const deleteRefs = plan.deletes.map((id) => refForDoc(db, spec, id, {}));
  for (let i = 0; i < chunk(deleteRefs, 450).length; i++) {
    const deleteBatch = chunk(deleteRefs, 450)[i];
    try {
      const batch = db.batch();
      for (const ref of deleteBatch) batch.delete(ref);
      await batch.commit();
    } catch (error) {
      errors.push({
        phase: 'delete',
        batch: i,
        size: deleteBatch.length,
        error: error.message,
      });
    }
  }

  // Lever une erreur si des batches ont échoué
  if (errors.length > 0) {
    throw new Error(
      `${errors.length} batch(s) ont échoué: ${errors.map((e) => `${e.phase}[${e.batch}]: ${e.error}`).join('; ')}`
    );
  }
};

export const restoreSnapshot = async ({
  db,
  snapshot,
  Timestamp,
  specs = COLLECTION_SPECS,
  options = {},
}) => {
  // Validations de snapshot
  if (!snapshot || typeof snapshot !== 'object') {
    throw new Error('Snapshot invalide: pas un objet');
  }
  if (!snapshot.collections || typeof snapshot.collections !== 'object') {
    throw new Error('Snapshot invalide: pas de propriété collections');
  }
  if (snapshot.version !== 1) {
    throw new Error(
      `Version snapshot incompatible: ${snapshot.version} (attendu: 1)`
    );
  }

  const mode = options.mode === 'mirror' ? 'mirror' : 'merge';
  const force = options.force === true;
  const dryRun = options.dryRun !== false; // sur par defaut
  const only = Array.isArray(options.collections) && options.collections.length > 0
    ? new Set(options.collections)
    : null;

  // Sécurité: mode mirror interdit sur snapshots partiels
  const isPartialSnapshot = snapshot.scope && Object.keys(snapshot.scope).length > 0;
  if (mode === 'mirror' && isPartialSnapshot) {
    throw new Error(
      'Mode mirror interdit sur snapshot partiel (avec scope communeId ou pollIds). '
      + 'Utilisez merge pour les snapshots scoped, ou restaurez un snapshot complet en mirror.'
    );
  }

  const report = { dryRun, mode, force, isPartialSnapshot, collections: {}, totals: { writes: 0, deletes: 0, skipped: 0 } };

  logger.info({
    mode,
    force,
    dryRun,
    isPartialSnapshot,
    collectionsCount: specs.length,
    scope: snapshot.scope,
  }, 'backup_restoring_start');

  const startTime = Date.now();

  for (const spec of specs) {
    const backupDocs = snapshot?.collections?.[spec.key];
    if (!Array.isArray(backupDocs)) continue;
    if (only && !only.has(spec.key)) continue;

    const collStart = Date.now();
    const existing = await readExisting(db, spec, backupDocs, mode);
    const plan = planRestore({ existing, backup: backupDocs, mode, force });

    try {
      if (!dryRun) await applyPlan(db, spec, plan, { Timestamp });
    } catch (error) {
      logger.error({
        collection: spec.key,
        err: error,
        plan: { writes: plan.writes.length, deletes: plan.deletes.length },
      }, 'backup_restore_apply_failed');
      throw error;
    }

    const collDuration = Date.now() - collStart;
    logger.debug({
      collection: spec.key,
      writes: plan.writes.length,
      deletes: plan.deletes.length,
      skipped: plan.skipped.length,
      durationMs: collDuration,
    }, 'backup_collection_restored');

    report.collections[spec.key] = {
      writes: plan.writes.length,
      deletes: plan.deletes.length,
      skipped: plan.skipped.length,
    };
    report.totals.writes += plan.writes.length;
    report.totals.deletes += plan.deletes.length;
    report.totals.skipped += plan.skipped.length;
  }

  const totalDuration = Date.now() - startTime;
  logger.info({
    mode,
    dryRun,
    durationMs: totalDuration,
    totals: report.totals,
  }, 'backup_restoring_complete');

  return report;
};
