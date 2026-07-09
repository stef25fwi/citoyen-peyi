#!/usr/bin/env node

/*
 * Audit non destructif des profils administrateurs communaux Citoyen Peyi.
 *
 * Ce script vérifie :
 * - santé backend ;
 * - échange super admin ;
 * - obtention ID token Firebase ;
 * - lecture des profils communeAdmins ;
 * - champs minimaux des profils existants ;
 * - création d'un profil admin temporaire ;
 * - connexion admin communal avec sa clé ;
 * - régénération de la clé ;
 * - ancienne clé invalidée ;
 * - nouvelle clé acceptée ;
 * - suppression du profil temporaire ;
 * - clé supprimée refusée.
 *
 * Il NE régénère PAS les clés des vrais profils existants.
 */

const SERVICE_URL = (process.env.SERVICE_URL || 'https://citoyen-peyi-backend-1087566305566.europe-west1.run.app').replace(/\/$/, '');
const SUPER_ADMIN_KEY = (process.env.SUPER_ADMIN_KEY || '').trim();
const FIREBASE_API_KEY = (process.env.FIREBASE_API_KEY || 'AIzaSyCPbwCjZivExVMV6iJQvQLcnjAfr1m3CMA').trim();

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

const mask = (value) => {
  const text = String(value || '');
  if (text.length <= 10) return '***';
  return `${text.slice(0, 6)}…${text.slice(-4)}`;
};

const requestJson = async (url, options = {}) => {
  const response = await fetch(url, {
    ...options,
    headers: {
      ...(options.body ? { 'Content-Type': 'application/json' } : {}),
      ...(options.headers || {}),
    },
  });
  const text = await response.text();
  let payload = null;
  try {
    payload = text ? JSON.parse(text) : null;
  } catch (_) {
    payload = { raw: text };
  }
  return { response, payload, text };
};

const postJson = (path, body, headers = {}) => requestJson(`${SERVICE_URL}${path}`, {
  method: 'POST',
  headers,
  body: JSON.stringify(body || {}),
});

const getJson = (path, headers = {}) => requestJson(`${SERVICE_URL}${path}`, {
  method: 'GET',
  headers,
});

const deleteJson = (path, headers = {}) => requestJson(`${SERVICE_URL}${path}`, {
  method: 'DELETE',
  headers,
});

const signInWithCustomToken = async (customToken) => {
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${encodeURIComponent(FIREBASE_API_KEY)}`;
  const { response, payload } = await requestJson(url, {
    method: 'POST',
    body: JSON.stringify({ token: customToken, returnSecureToken: true }),
  });
  assert(response.ok, `Identity Toolkit refuse le customToken (${response.status}) : ${JSON.stringify(payload)}`);
  assert(payload?.idToken, 'Identity Toolkit n\'a pas retourné idToken.');
  return payload.idToken;
};

const auditProfilesShape = (admins) => {
  const issues = [];
  const seenIds = new Set();
  const communeCodes = new Map();

  for (const admin of admins) {
    const id = String(admin.id || '').trim();
    const label = String(admin.label || '').trim();
    const communeName = String(admin.communeName || '').trim();
    const communeCode = String(admin.communeCode || '').trim();
    const codePostal = String(admin.codePostal || '').trim();

    if (!id) issues.push('Profil sans id.');
    if (id && seenIds.has(id)) issues.push(`ID dupliqué : ${id}`);
    if (id) seenIds.add(id);
    if (!label) issues.push(`${id || '(sans id)'} : label manquant.`);
    if (!communeName) issues.push(`${id || '(sans id)'} : communeName manquant.`);
    if (!communeCode) issues.push(`${id || '(sans id)'} : communeCode manquant.`);
    if (!codePostal) issues.push(`${id || '(sans id)'} : codePostal manquant.`);

    if (communeCode) {
      const key = communeCode.toUpperCase();
      const previous = communeCodes.get(key) || [];
      previous.push(id || '(sans id)');
      communeCodes.set(key, previous);
    }
  }

  for (const [communeCode, ids] of communeCodes.entries()) {
    if (ids.length > 1) {
      issues.push(`Plusieurs profils pour communeCode ${communeCode} : ${ids.join(', ')}`);
    }
  }
  return issues;
};

const main = async () => {
  assert(SUPER_ADMIN_KEY, 'SUPER_ADMIN_KEY manquant. Exemple : export SUPER_ADMIN_KEY="CP-SUPER-..."');

  console.log('=== Audit admin Citoyen Peyi ===');
  console.log(`Backend : ${SERVICE_URL}`);

  const health = await getJson('/api/health/ready');
  console.log(`Health ready : HTTP ${health.response.status}`);
  assert(health.response.ok, `Backend pas prêt : ${health.text}`);

  const superExchange = await postJson('/api/auth/super/exchange', {}, {
    'x-super-admin-key': SUPER_ADMIN_KEY,
  });
  console.log(`Super admin exchange : HTTP ${superExchange.response.status}`);
  assert(superExchange.response.ok, `Connexion super admin KO : ${superExchange.text}`);
  assert(superExchange.payload?.customToken, 'customToken super admin manquant.');

  const superIdToken = await signInWithCustomToken(superExchange.payload.customToken);
  console.log(`ID token super admin : OK ${mask(superIdToken)}`);

  const authHeaders = { Authorization: `Bearer ${superIdToken}` };
  const list = await getJson('/api/admins', authHeaders);
  console.log(`Liste profils admin : HTTP ${list.response.status}`);
  assert(list.response.ok, `Liste profils admin KO : ${list.text}`);
  const admins = Array.isArray(list.payload?.admins) ? list.payload.admins : [];
  console.log(`Nombre profils existants : ${admins.length}`);

  const shapeIssues = auditProfilesShape(admins);
  if (shapeIssues.length) {
    console.log('\n⚠️ Champs/profils à vérifier :');
    for (const issue of shapeIssues) console.log(`- ${issue}`);
  } else {
    console.log('Audit champs minimaux profils existants : OK');
  }

  const suffix = new Date().toISOString().replace(/[-:.TZ]/g, '').slice(0, 14);
  const testPayload = {
    label: `Audit Admin Temp ${suffix}`,
    communeName: `Commune Audit Temp ${suffix}`,
    communeCode: `AUD${suffix.slice(-5)}`,
    codePostal: '97100',
    referenceEmail: `audit-${suffix}@example.invalid`,
  };

  let created = null;
  try {
    const create = await postJson('/api/admins', testPayload, authHeaders);
    console.log(`Création profil temporaire : HTTP ${create.response.status}`);
    assert(create.response.status === 201, `Création profil temporaire KO : ${create.text}`);
    created = create.payload;
    assert(created?.id, 'id profil temporaire manquant.');
    assert(created?.accessKey, 'accessKey profil temporaire manquant.');
    console.log(`Profil temporaire : ${created.id}`);
    console.log(`Clé temporaire créée : OK ${mask(created.accessKey)}`);

    const adminLoginBefore = await postJson('/api/auth/admin/exchange', { accessKey: created.accessKey });
    console.log(`Connexion admin avec clé initiale : HTTP ${adminLoginBefore.response.status}`);
    assert(adminLoginBefore.response.ok, `Connexion admin initiale KO : ${adminLoginBefore.text}`);
    assert(adminLoginBefore.payload?.claims?.role === 'commune_admin', 'Claim role commune_admin manquant.');

    const regen = await postJson(`/api/admins/${created.id}/regenerate`, {}, authHeaders);
    console.log(`Régénération clé admin : HTTP ${regen.response.status}`);
    assert(regen.response.ok, `Régénération clé admin KO : ${regen.text}`);
    const newKey = regen.payload?.accessKey;
    assert(newKey, 'Nouvelle clé accessKey manquante après régénération.');
    assert(newKey !== created.accessKey, 'La clé régénérée est identique à l\'ancienne.');
    console.log(`Nouvelle clé temporaire : OK ${mask(newKey)}`);

    const adminLoginOld = await postJson('/api/auth/admin/exchange', { accessKey: created.accessKey });
    console.log(`Ancienne clé après régénération : HTTP ${adminLoginOld.response.status}`);
    assert(adminLoginOld.response.status === 401, `Ancienne clé encore acceptée : ${adminLoginOld.text}`);

    const adminLoginNew = await postJson('/api/auth/admin/exchange', { accessKey: newKey });
    console.log(`Nouvelle clé après régénération : HTTP ${adminLoginNew.response.status}`);
    assert(adminLoginNew.response.ok, `Nouvelle clé refusée : ${adminLoginNew.text}`);
    assert(adminLoginNew.payload?.claims?.role === 'commune_admin', 'Claim role commune_admin manquant après régénération.');

    const deleted = await deleteJson(`/api/admins/${created.id}`, authHeaders);
    console.log(`Suppression profil temporaire : HTTP ${deleted.response.status}`);
    assert(deleted.response.ok, `Suppression profil temporaire KO : ${deleted.text}`);

    const adminLoginAfterDelete = await postJson('/api/auth/admin/exchange', { accessKey: newKey });
    console.log(`Clé temporaire après suppression : HTTP ${adminLoginAfterDelete.response.status}`);
    assert(adminLoginAfterDelete.response.status === 401, `Clé supprimée encore acceptée : ${adminLoginAfterDelete.text}`);
  } catch (error) {
    if (created?.id) {
      console.log(`Nettoyage profil temporaire ${created.id}…`);
      try { await deleteJson(`/api/admins/${created.id}`, authHeaders); } catch (_) {}
    }
    throw error;
  }

  console.log('\n✅ Audit terminé : connexion super admin OK, création profil OK, connexion admin OK, régénération OK, ancienne clé invalidée OK.');
};

main().catch((error) => {
  console.error(`\n❌ Audit échoué : ${error.message}`);
  process.exit(1);
});
