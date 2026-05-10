import test from 'node:test';
import assert from 'node:assert/strict';

process.env.SUPER_ADMIN_KEY = process.env.SUPER_ADMIN_KEY || 'test-super-admin-key';
process.env.VOTE_ACCESS_TOKEN_SECRET = process.env.VOTE_ACCESS_TOKEN_SECRET || 'test-vote-secret';
process.env.FIREBASE_ADMIN_PROJECT_ID = process.env.FIREBASE_ADMIN_PROJECT_ID || 'test-project';
process.env.FIREBASE_ADMIN_CLIENT_EMAIL = process.env.FIREBASE_ADMIN_CLIENT_EMAIL || 'test@example.com';
process.env.FIREBASE_ADMIN_PRIVATE_KEY = process.env.FIREBASE_ADMIN_PRIVATE_KEY || '-----BEGIN PRIVATE KEY-----\\nTEST\\n-----END PRIVATE KEY-----\\n';

const voteAccess = await import('../src/routes/voteAccess.js');

test('normalizeCode trims and uppercases values', () => {
  assert.equal(voteAccess.normalizeCode(' ab12cd34 '), 'AB12CD34');
});

test('signAccessToken and verifyAccessToken roundtrip payload', () => {
  const token = voteAccess.signAccessToken({ accessCodeId: 'AB12CD34', communeId: 'commune-1' });
  const payload = voteAccess.verifyAccessToken(token);

  assert.equal(payload.accessCodeId, 'AB12CD34');
  assert.equal(payload.communeId, 'commune-1');
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

test('isPollOpen respects active/open status and dates', () => {
  const now = new Date();
  const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000).toISOString();
  const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000).toISOString();

  assert.equal(voteAccess.isPollOpen({ status: 'active', opensAt: yesterday, closesAt: tomorrow }), true);
  assert.equal(voteAccess.isPollOpen({ status: 'closed', opensAt: yesterday, closesAt: tomorrow }), false);
  assert.equal(voteAccess.isPollOpen({ status: 'active', opensAt: tomorrow, closesAt: tomorrow }), false);
});