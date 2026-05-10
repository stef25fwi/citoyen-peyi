import test from 'node:test';
import assert from 'node:assert/strict';

process.env.SUPER_ADMIN_KEY = process.env.SUPER_ADMIN_KEY || 'test-super-admin-key';
process.env.VOTE_ACCESS_TOKEN_SECRET = process.env.VOTE_ACCESS_TOKEN_SECRET || 'test-vote-secret';
process.env.FIREBASE_ADMIN_PROJECT_ID = process.env.FIREBASE_ADMIN_PROJECT_ID || 'test-project';
process.env.FIREBASE_ADMIN_CLIENT_EMAIL = process.env.FIREBASE_ADMIN_CLIENT_EMAIL || 'test@example.com';
process.env.FIREBASE_ADMIN_PRIVATE_KEY = process.env.FIREBASE_ADMIN_PRIVATE_KEY || '-----BEGIN PRIVATE KEY-----\\nTEST\\n-----END PRIVATE KEY-----\\n';

const migrationModule = await import('../src/scripts/migrateRegistrationCodesToCitizenAccessCodes.js');

test('buildAccessPayload maps legacy document to official schema', () => {
  const payload = migrationModule.buildAccessPayload('legacy-1', {
    communeId: 'commune-1',
    communeName: 'Fort-de-France',
    verifiedByControleurCode: 'controller-1',
    verifiedByControleurLabel: 'Controleur 1',
    documentType: 'CNI',
    qrPayload: '{"code":"AB12CD34"}',
    expiresAt: '2026-12-31',
    status: 'validated',
  }, 'AB12CD34');

  assert.equal(payload.accessCode, 'AB12CD34');
  assert.equal(payload.codeHash, migrationModule.hashCode('AB12CD34'));
  assert.equal(payload.displayCodeMasked, 'AB••••34');
  assert.equal(payload.status, 'active');
  assert.equal(payload.metadata.legacyRegistrationCodeId, 'legacy-1');
  assert.equal(payload.metadata.legacyQrPayloadPresent, true);
});

test('migrateRegistrationCodesToCitizenAccessCodes reports ignored, skipped and migrated records', async () => {
  const legacyDocs = [
    {
      id: 'legacy-valid',
      data: () => ({ code: 'AB12CD34', status: 'validated', communeId: 'commune-1', communeName: 'Fort-de-France' }),
      ref: { id: 'legacy-valid' },
    },
    {
      id: 'legacy-ignored',
      data: () => ({ code: 'ZZ99YY88', status: 'draft' }),
      ref: { id: 'legacy-ignored' },
    },
  ];

  const writes = [];
  let batchWrites = [];
  const accessCollection = new Map();
  const accessCollectionApi = {
    doc(id) {
      return {
        id,
        get: async () => ({ exists: accessCollection.has(id) }),
      };
    },
  };

  const db = {
    batch() {
      batchWrites = [];
      return {
        set(ref, data) {
          batchWrites.push({ ref, data });
        },
        async commit() {
          writes.push(...batchWrites);
          for (const write of batchWrites) {
            if (write.ref?.id) {
              accessCollection.set(write.ref.id, write.data);
            }
          }
        },
      };
    },
    collection(name) {
      if (name === 'registrationCodes') {
        return {
          orderBy() {
            return {
              limit() {
                return {
                  async get() {
                    if (legacyDocs.length === 0) {
                      return { empty: true, docs: [] };
                    }
                    const docs = [...legacyDocs];
                    legacyDocs.length = 0;
                    return { empty: false, docs };
                  },
                  startAfter() {
                    return this;
                  },
                };
              },
            };
          },
        };
      }
      if (name === 'citizen_access_codes') {
        return accessCollectionApi;
      }
      return {
        doc(id) {
          return { id };
        },
      };
    },
  };

  const result = await migrationModule.migrateRegistrationCodesToCitizenAccessCodes({ db, dryRun: false });

  assert.equal(result.scanned, 2);
  assert.equal(result.migrated, 1);
  assert.equal(result.ignored, 1);
  assert.equal(result.skipped, 0);
  assert.ok(writes.length >= 2);
});