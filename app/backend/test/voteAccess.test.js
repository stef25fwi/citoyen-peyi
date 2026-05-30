import test from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'crypto';

process.env.SUPER_ADMIN_KEY = process.env.SUPER_ADMIN_KEY || 'test-super-admin-key';
process.env.VOTE_ACCESS_TOKEN_SECRET = process.env.VOTE_ACCESS_TOKEN_SECRET || 'test-vote-secret';
process.env.ACCESS_CODE_PEPPER = process.env.ACCESS_CODE_PEPPER || 'test-access-code-pepper';
process.env.CITIZEN_FINGERPRINT_PEPPER = process.env.CITIZEN_FINGERPRINT_PEPPER || 'test-citizen-fingerprint-pepper';
process.env.PARTICIPATION_PEPPER = process.env.PARTICIPATION_PEPPER || 'test-participation-pepper';
process.env.FIREBASE_ADMIN_PROJECT_ID = process.env.FIREBASE_ADMIN_PROJECT_ID || 'test-project';
process.env.FIREBASE_ADMIN_CLIENT_EMAIL = process.env.FIREBASE_ADMIN_CLIENT_EMAIL || 'test@example.com';
process.env.FIREBASE_ADMIN_PRIVATE_KEY = process.env.FIREBASE_ADMIN_PRIVATE_KEY || '-----BEGIN PRIVATE KEY-----\\nTEST\\n-----END PRIVATE KEY-----\\n';

const voteAccess = await import('../src/routes/voteAccess.js');

test('normalizeCode trims and uppercases values', () => {
  assert.equal(voteAccess.normalizeCode(' ab12cd34 '), 'AB12CD34');
});

test('hashCode uses peppered HMAC instead of legacy SHA-256', () => {
  const code = 'AB12CD34';
  const legacyHash = crypto.createHash('sha256').update(code).digest('hex');
  assert.notEqual(voteAccess.hashCode(code), legacyHash);
  assert.equal(voteAccess.hashCode(code), voteAccess.hashCode(' ab12cd34 '));
});

test('createParticipationHash uses a dedicated peppered HMAC', () => {
  const participationHash = voteAccess.createParticipationHash('poll-1', 'access-1');
  const legacyHash = crypto.createHash('sha256').update('poll-1:access-1').digest('hex');

  assert.match(participationHash, /^[a-f0-9]{64}$/);
  assert.notEqual(participationHash, legacyHash);
  assert.equal(participationHash, voteAccess.createParticipationHash('poll-1', 'access-1'));
});

test('createAnonymousBallotId returns an unlinkable 128-bit random id', () => {
  const firstId = voteAccess.createAnonymousBallotId();
  const secondId = voteAccess.createAnonymousBallotId();

  assert.match(firstId, /^[a-f0-9]{32}$/);
  assert.match(secondId, /^[a-f0-9]{32}$/);
  assert.notEqual(firstId, secondId);
  assert.equal(firstId.includes('poll-1'), false);
  assert.equal(firstId.includes('access-1'), false);
});

test('signAccessToken and verifyAccessToken roundtrip anonymous participation payload', () => {
  const participationHash = voteAccess.createParticipationHash('poll-1', 'access-1');
  const token = voteAccess.signAccessToken({
    communeId: 'commune-1',
    participations: { 'poll-1': participationHash },
  });
  const payload = voteAccess.verifyAccessToken(token);

  assert.equal(payload.communeId, 'commune-1');
  assert.equal(payload.participations['poll-1'], participationHash);
  assert.equal(payload.accessCodeId, undefined);
  assert.ok(payload.exp > Date.now());
});

test('verifyAccessToken rejects tampered token', () => {
  const token = voteAccess.signAccessToken({ accessCodeId: 'AB12CD34', communeId: 'commune-1' });
  const tampered = `${token}broken`;
  assert.equal(voteAccess.verifyAccessToken(tampered), null);
});

test('optionBelongsToPoll validates option ownership', () => {
  const poll = { options: [{ id: 'opt-1' }, { id: 'opt-2' }] };
  assert.equal(voteAccess.optionBelongsToPoll(poll, 'opt-2'), true);
  assert.equal(voteAccess.optionBelongsToPoll(poll, 'opt-3'), false);
});

test('anonymous vote records separate participation from ballot', () => {
  const participation = voteAccess.buildParticipationRecord({
    pollId: 'poll-1',
    participationHash: 'a'.repeat(64),
    communeId: 'commune-1',
  });
  const ballot = voteAccess.buildAnonymousBallotRecord({
    pollId: 'poll-1',
    optionId: 'opt-1',
    communeId: 'commune-1',
    source: 'web',
  });

  assert.equal(participation.pollId, 'poll-1');
  assert.equal(participation.participationHash, 'a'.repeat(64));
  assert.equal(participation.optionId, undefined);
  assert.equal(participation.accessCodeId, undefined);
  assert.equal(participation.citizenFingerprintHash, undefined);

  assert.equal(ballot.pollId, 'poll-1');
  assert.equal(ballot.optionId, 'opt-1');
  assert.equal(ballot.participationHash, undefined);
  assert.equal(ballot.accessCodeId, undefined);
  assert.equal(ballot.citizenFingerprintHash, undefined);
});

test('isPollOpen respects active/open status and dates', () => {
  const now = new Date();
  const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString();
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString();

  assert.equal(voteAccess.isPollOpen({ status: 'active', opensAt: yesterday, closesAt: tomorrow }), true);
  assert.equal(voteAccess.isPollOpen({ status: 'closed', opensAt: yesterday, closesAt: tomorrow }), false);
  assert.equal(voteAccess.isPollOpen({ status: 'active', opensAt: tomorrow, closesAt: tomorrow }), false);
});

test('isPollOpen accepts scheduled polls only after publication date', () => {
  const now = new Date();
  const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString();
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString();

  assert.equal(
    voteAccess.isPollOpen({
      status: 'scheduled',
      scheduledPublishDate: yesterday,
      opensAt: yesterday,
      closesAt: tomorrow,
    }),
    true,
  );
  assert.equal(
    voteAccess.isPollOpen({
      status: 'scheduled',
      scheduledPublishDate: tomorrow,
      opensAt: yesterday,
      closesAt: tomorrow,
    }),
    false,
  );
});