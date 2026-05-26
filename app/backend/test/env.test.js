import test from 'node:test';
import assert from 'node:assert/strict';

const baseEnv = () => ({
  ...process.env,
});

const resetEnv = (snapshot) => {
  for (const key of Object.keys(process.env)) {
    if (!(key in snapshot)) delete process.env[key];
  }
  Object.assign(process.env, snapshot);
};

const importFresh = async () => {
  const path = `../src/config/env.js?t=${Date.now()}`;
  return import(path);
};

test('validateEnv accepts a complete development configuration', async () => {
  const snapshot = baseEnv();
  process.env.NODE_ENV = 'development';
  process.env.SUPER_ADMIN_KEY = 'dev-key';
  process.env.VOTE_ACCESS_TOKEN_SECRET = 'dev-secret';
  process.env.ACCESS_CODE_PEPPER = 'dev-access-pepper';
  process.env.CITIZEN_FINGERPRINT_PEPPER = 'dev-fingerprint-pepper';
  process.env.FIREBASE_ADMIN_PROJECT_ID = 'demo';
  process.env.FIREBASE_ADMIN_CLIENT_EMAIL = 'demo@example.com';
  process.env.FIREBASE_ADMIN_PRIVATE_KEY = 'PRIVATE';

  const { validateEnv } = await importFresh();
  assert.doesNotThrow(() => validateEnv());

  resetEnv(snapshot);
});

test('validateEnv refuses production boot without CORS_ORIGIN', async () => {
  const snapshot = baseEnv();
  process.env.NODE_ENV = 'production';
  delete process.env.CORS_ORIGIN;
  process.env.SUPER_ADMIN_KEY = 'x'.repeat(48);
  process.env.VOTE_ACCESS_TOKEN_SECRET = 'y'.repeat(48);
  process.env.ACCESS_CODE_PEPPER = 'a'.repeat(48);
  process.env.CITIZEN_FINGERPRINT_PEPPER = 'b'.repeat(48);
  process.env.FIREBASE_ADMIN_PROJECT_ID = 'demo';
  process.env.FIREBASE_ADMIN_CLIENT_EMAIL = 'demo@example.com';
  process.env.FIREBASE_ADMIN_PRIVATE_KEY = 'PRIVATE';

  const { validateEnv } = await importFresh();
  assert.throws(() => validateEnv(), /CORS_ORIGIN/);

  resetEnv(snapshot);
});

test('validateEnv refuses production boot with localhost CORS_ORIGIN', async () => {
  const snapshot = baseEnv();
  process.env.NODE_ENV = 'production';
  process.env.CORS_ORIGIN = 'http://localhost:3000,https://app.example.com';
  process.env.SUPER_ADMIN_KEY = 'x'.repeat(48);
  process.env.VOTE_ACCESS_TOKEN_SECRET = 'y'.repeat(48);
  process.env.ACCESS_CODE_PEPPER = 'a'.repeat(48);
  process.env.CITIZEN_FINGERPRINT_PEPPER = 'b'.repeat(48);
  process.env.FIREBASE_ADMIN_PROJECT_ID = 'demo';
  process.env.FIREBASE_ADMIN_CLIENT_EMAIL = 'demo@example.com';
  process.env.FIREBASE_ADMIN_PRIVATE_KEY = 'PRIVATE';

  const { validateEnv } = await importFresh();
  assert.throws(() => validateEnv(), /CORS_ORIGIN contient des origines de developpement/);

  resetEnv(snapshot);
});

test('validateEnv refuses production boot with short secrets', async () => {
  const snapshot = baseEnv();
  process.env.NODE_ENV = 'production';
  process.env.CORS_ORIGIN = 'https://app.example.com';
  process.env.SUPER_ADMIN_KEY = 'short';
  process.env.VOTE_ACCESS_TOKEN_SECRET = 'short';
  process.env.ACCESS_CODE_PEPPER = 'short';
  process.env.CITIZEN_FINGERPRINT_PEPPER = 'short';
  process.env.FIREBASE_ADMIN_PROJECT_ID = 'demo';
  process.env.FIREBASE_ADMIN_CLIENT_EMAIL = 'demo@example.com';
  process.env.FIREBASE_ADMIN_PRIVATE_KEY = 'PRIVATE';

  const { validateEnv } = await importFresh();
  assert.throws(() => validateEnv(), /au moins 32 caracteres/);

  resetEnv(snapshot);
});

test('validateEnv refuses production boot without access peppers', async () => {
  const snapshot = baseEnv();
  process.env.NODE_ENV = 'production';
  process.env.CORS_ORIGIN = 'https://app.example.com';
  process.env.SUPER_ADMIN_KEY = 'x'.repeat(48);
  process.env.VOTE_ACCESS_TOKEN_SECRET = 'y'.repeat(48);
  delete process.env.ACCESS_CODE_PEPPER;
  delete process.env.CITIZEN_FINGERPRINT_PEPPER;
  process.env.FIREBASE_ADMIN_PROJECT_ID = 'demo';
  process.env.FIREBASE_ADMIN_CLIENT_EMAIL = 'demo@example.com';
  process.env.FIREBASE_ADMIN_PRIVATE_KEY = 'PRIVATE';

  const { validateEnv } = await importFresh();
  assert.throws(() => validateEnv(), /ACCESS_CODE_PEPPER|CITIZEN_FINGERPRINT_PEPPER/);

  resetEnv(snapshot);
});

test('bootstrap admin is disabled unless explicitly enabled', async () => {
  const snapshot = baseEnv();
  delete process.env.ENABLE_BOOTSTRAP_ADMIN;
  let module = await importFresh();
  assert.equal(module.isBootstrapAdminEnabled(), false);

  process.env.ENABLE_BOOTSTRAP_ADMIN = 'false';
  module = await importFresh();
  assert.equal(module.isBootstrapAdminEnabled(), false);

  process.env.ENABLE_BOOTSTRAP_ADMIN = 'true';
  module = await importFresh();
  assert.equal(module.isBootstrapAdminEnabled(), true);

  resetEnv(snapshot);
});
