import test from 'node:test';
import assert from 'node:assert/strict';

process.env.SUPER_ADMIN_KEY = process.env.SUPER_ADMIN_KEY || 'test-super-admin-key';
process.env.VOTE_ACCESS_TOKEN_SECRET = process.env.VOTE_ACCESS_TOKEN_SECRET || 'test-vote-secret';
process.env.ACCESS_CODE_PEPPER = process.env.ACCESS_CODE_PEPPER || 'test-access-code-pepper';
process.env.CITIZEN_FINGERPRINT_PEPPER = process.env.CITIZEN_FINGERPRINT_PEPPER || 'test-citizen-fingerprint-pepper';
process.env.ADMIN_ACCESS_PEPPER = process.env.ADMIN_ACCESS_PEPPER || 'test-admin-access-pepper';
process.env.CONTROLLER_CODE_PEPPER = process.env.CONTROLLER_CODE_PEPPER || 'test-controller-code-pepper';
process.env.FIREBASE_ADMIN_PROJECT_ID = process.env.FIREBASE_ADMIN_PROJECT_ID || 'test-project';
process.env.FIREBASE_ADMIN_CLIENT_EMAIL = process.env.FIREBASE_ADMIN_CLIENT_EMAIL || 'test@example.com';
process.env.FIREBASE_ADMIN_PRIVATE_KEY = process.env.FIREBASE_ADMIN_PRIVATE_KEY || '-----BEGIN PRIVATE KEY-----\\nTEST\\n-----END PRIVATE KEY-----\\n';

const security = await import('../src/routes/citizenAccess.js');
const loggerModule = await import('../src/services/logger.js');
const keyHashing = await import('../src/services/keyHashing.js');

test('generateSecureAccessCode returns non deterministic readable codes', () => {
  const first = security.generateSecureAccessCode();
  const second = security.generateSecureAccessCode();

  assert.match(first, /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{10}$/);
  assert.match(second, /^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{10}$/);
  assert.notEqual(first, second);
});

test('hashAccessCode is normalized and peppered', () => {
  const hash = security.hashAccessCode(' AB12CD34 ');
  assert.equal(hash, security.hashAccessCode('ab12cd34'));
  assert.match(hash, /^[a-f0-9]{64}$/);
  assert.notEqual(hash, 'AB12CD34');
});

test('createCitizenFingerprint is separate from access code hashing', () => {
  const source = 'AB198099';
  assert.match(security.createCitizenFingerprint(source), /^[a-f0-9]{64}$/);
  assert.notEqual(security.createCitizenFingerprint(source), security.hashAccessCode(source));
});

test('admin/controller hashes use peppered HMAC and keep legacy compatibility check', () => {
  const adminKey = 'ADM-ABCD-1234';
  const controllerCode = 'CTRL-AB12CD34';
  const adminHash = keyHashing.hashAdminAccessKey(adminKey);
  const controllerHash = keyHashing.hashControllerCode(controllerCode);

  assert.match(adminHash, /^[a-f0-9]{64}$/);
  assert.match(controllerHash, /^[a-f0-9]{64}$/);
  assert.notEqual(adminHash, keyHashing.hashLegacySha256(adminKey));
  assert.equal(keyHashing.matchesStoredHash(adminKey, adminHash, adminHash), true);
  assert.equal(
    keyHashing.matchesStoredHash(adminKey, keyHashing.hashLegacySha256(adminKey), adminHash),
    true,
  );
});

test('sanitizeRequestUrl redacts access codes from logged URLs', () => {
  assert.equal(
    loggerModule.sanitizeRequestUrl('/api/citizen-access/codes/AB12CD34/revoke'),
    '/api/citizen-access/codes/[REDACTED]/revoke',
  );
  assert.equal(
    loggerModule.sanitizeRequestUrl('/api/vote-access/validate?code=AB12CD34&pollId=poll-1'),
    '/api/vote-access/validate?code=[REDACTED]&pollId=poll-1',
  );
});