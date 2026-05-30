import test from 'node:test';
import assert from 'node:assert/strict';

process.env.SUPER_ADMIN_KEY = process.env.SUPER_ADMIN_KEY || 'test-super-admin-key';
process.env.VOTE_ACCESS_TOKEN_SECRET = process.env.VOTE_ACCESS_TOKEN_SECRET || 'test-vote-secret';
process.env.ACCESS_CODE_PEPPER = process.env.ACCESS_CODE_PEPPER || 'test-access-code-pepper';
process.env.CITIZEN_FINGERPRINT_PEPPER = process.env.CITIZEN_FINGERPRINT_PEPPER || 'test-citizen-fingerprint-pepper';
process.env.PARTICIPATION_PEPPER = process.env.PARTICIPATION_PEPPER || 'test-participation-pepper';
process.env.FIREBASE_ADMIN_PROJECT_ID = process.env.FIREBASE_ADMIN_PROJECT_ID || 'test-project';
process.env.FIREBASE_ADMIN_CLIENT_EMAIL = process.env.FIREBASE_ADMIN_CLIENT_EMAIL || 'test@example.com';
process.env.FIREBASE_ADMIN_PRIVATE_KEY = process.env.FIREBASE_ADMIN_PRIVATE_KEY || '-----BEGIN PRIVATE KEY-----\nTEST\n-----END PRIVATE KEY-----\n';

const script = await import('../src/scripts/retireLegacyPollVotes.js');

test('parseArgs keeps legacy poll_votes retirement dry-run by default', () => {
  assert.deepEqual(script.parseArgs([]), {
    archiveSummary: false,
    deleteDocs: false,
    confirmBackup: false,
    limit: 0,
  });
  assert.deepEqual(script.parseArgs(['--archive-summary', '--delete', '--confirm-backup', '--limit=25']), {
    archiveSummary: true,
    deleteDocs: true,
    confirmBackup: true,
    limit: 25,
  });
});

test('buildLegacyVoteArchiveSummary stores only aggregate metadata', () => {
  const summary = script.buildLegacyVoteArchiveSummary([
    {
      id: 'poll-1_access-1',
      data: {
        pollId: 'poll-1',
        accessCodeId: 'access-1',
        optionId: 'opt-1',
        communeId: 'commune-1',
      },
    },
    {
      id: 'poll-1_access-2',
      data: {
        pollId: 'poll-1',
        accessCodeId: 'access-2',
        optionId: 'opt-2',
        userAgent: 'browser',
      },
    },
  ]);

  assert.equal(summary.totalDocuments, 2);
  assert.deepEqual(summary.pollCounts, { 'poll-1': 2 });
  assert.equal(summary.sensitiveFieldCounts.accessCodeId, 2);
  assert.equal(summary.sensitiveFieldCounts.userAgent, 1);
  assert.equal(summary.legacyClassification, 'pseudonymized_not_anonymous');
  assert.equal(summary.sampleDocumentIds, undefined);
  assert.equal(JSON.stringify(summary).includes('access-1'), false);
  assert.equal(JSON.stringify(summary).includes('access-2'), false);
  assert.equal(JSON.stringify(summary).includes('opt-1'), false);
  assert.equal(JSON.stringify(summary).includes('opt-2'), false);
});