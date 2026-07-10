import test from 'node:test';
import assert from 'node:assert/strict';

const { resolveCanonicalCommune } = await import('../src/services/communeDirectory.js');

// Mock minimal du Firestore Admin : collection('communeAdmins').where('communeCode','==',x).limit(1).get()
const makeDb = (existingAdmins) => ({
  collection(name) {
    assert.equal(name, 'communeAdmins');
    return {
      where(field, op, value) {
        assert.equal(field, 'communeCode');
        assert.equal(op, '==');
        const matches = existingAdmins.filter((admin) => admin.communeCode === value);
        return {
          limit() {
            return {
              async get() {
                return {
                  empty: matches.length === 0,
                  docs: matches.slice(0, 1).map((admin) => ({ id: admin.id, data: () => admin })),
                };
              },
            };
          },
        };
      },
    };
  },
});

test('resolveCanonicalCommune reuses the existing commune identity for the same INSEE code', async () => {
  const db = makeDb([
    { id: 'adm-1', communeCode: '77288', communeName: 'Goyave', codePostal: '97128' },
  ]);

  const result = await resolveCanonicalCommune(db, {
    communeCode: '77288',
    communeName: 'goyave (variante)',
    codePostal: '00000',
  });

  assert.equal(result.matched, true);
  assert.equal(result.matchedAdminId, 'adm-1');
  assert.equal(result.communeCode, '77288');
  assert.equal(result.communeName, 'Goyave');
  assert.equal(result.codePostal, '97128');
});

test('resolveCanonicalCommune keeps the provided values when the commune is new', async () => {
  const db = makeDb([]);

  const result = await resolveCanonicalCommune(db, {
    communeCode: '97101',
    communeName: 'Basse-Terre',
    codePostal: '97100',
  });

  assert.equal(result.matched, false);
  assert.equal(result.matchedAdminId, null);
  assert.equal(result.communeName, 'Basse-Terre');
  assert.equal(result.codePostal, '97100');
});

test('resolveCanonicalCommune falls back to provided fields missing on the stored commune', async () => {
  const db = makeDb([
    { id: 'adm-2', communeCode: '97209', communeName: 'Fort-de-France', codePostal: '' },
  ]);

  const result = await resolveCanonicalCommune(db, {
    communeCode: '97209',
    communeName: 'autre',
    codePostal: '97200',
  });

  assert.equal(result.matched, true);
  assert.equal(result.communeName, 'Fort-de-France');
  // Code postal absent en base -> on garde la saisie.
  assert.equal(result.codePostal, '97200');
});

test('resolveCanonicalCommune does not query Firestore when no INSEE code is provided', async () => {
  let queried = false;
  const db = {
    collection() {
      queried = true;
      return { where() { throw new Error('should not query'); } };
    },
  };

  const result = await resolveCanonicalCommune(db, { communeName: 'Sans code' });

  assert.equal(queried, false);
  assert.equal(result.matched, false);
  assert.equal(result.communeName, 'Sans code');
});
