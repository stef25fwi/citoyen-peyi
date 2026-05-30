import { FieldValue } from 'firebase-admin/firestore';
import { getFirebaseAdminDb, isFirebaseAdminConfigured } from '../services/firebaseAdmin.js';

const LEGACY_COLLECTION = 'poll_votes';
const ARCHIVE_COLLECTION = 'poll_votes_legacy_archives';
const SENSITIVE_FIELDS = [
  'accessCodeId',
  'accessCode',
  'accessCodeHash',
  'citizenFingerprintHash',
  'participationHash',
  'displayCodeMasked',
  'createdByControllerId',
  'createdByControllerName',
  'accessToken',
  'receiptId',
  'ip',
  'userAgent',
];

export const parseArgs = (argv = []) => ({
  archiveSummary: argv.includes('--archive-summary'),
  deleteDocs: argv.includes('--delete'),
  confirmBackup: argv.includes('--confirm-backup'),
  limit: Number(argv.find((arg) => arg.startsWith('--limit='))?.split('=')[1] || 0) || 0,
});

export const buildLegacyVoteArchiveSummary = (legacyVotes = []) => {
  const pollCounts = {};
  const sensitiveFieldCounts = Object.fromEntries(SENSITIVE_FIELDS.map((field) => [field, 0]));

  for (const vote of legacyVotes) {
    const data = vote.data || {};
    const pollId = String(data.pollId || 'unknown');
    pollCounts[pollId] = (pollCounts[pollId] || 0) + 1;

    for (const field of SENSITIVE_FIELDS) {
      if (data[field] !== undefined && data[field] !== null && data[field] !== '') {
        sensitiveFieldCounts[field] += 1;
      }
    }
  }

  return {
    collection: LEGACY_COLLECTION,
    totalDocuments: legacyVotes.length,
    pollCounts,
    sensitiveFieldCounts,
    legacyClassification: 'pseudonymized_not_anonymous',
    archivePolicy: 'summary_only_no_access_code_id_no_option_id_no_per_vote_copy',
  };
};

const loadLegacyVotes = async (db, { limit = 0 } = {}) => {
  let query = db.collection(LEGACY_COLLECTION);
  if (limit > 0) query = query.limit(limit);
  const snapshot = await query.get();
  return snapshot.docs.map((doc) => ({ id: doc.id, data: doc.data() || {}, ref: doc.ref }));
};

const commitDeletes = async (db, legacyVotes) => {
  let deleted = 0;
  for (let index = 0; index < legacyVotes.length; index += 450) {
    const batch = db.batch();
    for (const vote of legacyVotes.slice(index, index + 450)) {
      batch.delete(vote.ref);
      deleted += 1;
    }
    await batch.commit();
  }
  return deleted;
};

export const retireLegacyPollVotes = async ({ db, options }) => {
  const legacyVotes = await loadLegacyVotes(db, options);
  const summary = buildLegacyVoteArchiveSummary(legacyVotes);

  if (!options.confirmBackup && (options.archiveSummary || options.deleteDocs)) {
    throw new Error('--confirm-backup est requis avant archivage ou suppression de poll_votes.');
  }

  let archiveId = '';
  if (options.archiveSummary) {
    const archiveRef = db.collection(ARCHIVE_COLLECTION).doc();
    archiveId = archiveRef.id;
    await archiveRef.set({
      ...summary,
      id: archiveId,
      archivedAt: FieldValue.serverTimestamp(),
    });
  }

  const deleted = options.deleteDocs ? await commitDeletes(db, legacyVotes) : 0;
  return { ...summary, archiveId, deleted };
};

const run = async () => {
  const options = parseArgs(process.argv.slice(2));
  if (!isFirebaseAdminConfigured()) {
    throw new Error('Firebase Admin doit etre configure pour auditer poll_votes.');
  }

  const result = await retireLegacyPollVotes({
    db: getFirebaseAdminDb(),
    options,
  });

  console.log(JSON.stringify({
    ok: true,
    dryRun: !options.archiveSummary && !options.deleteDocs,
    ...result,
  }, null, 2));
};

if (import.meta.url === `file://${process.argv[1]}`) {
  run().catch((error) => {
    console.error(error.message || error);
    process.exit(1);
  });
}