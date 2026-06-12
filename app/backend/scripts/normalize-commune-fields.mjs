#!/usr/bin/env node
/**
 * Normalise les champs commune (nom / code postal / INSEE) des enregistrements
 * deja en base, pour les profils crees avant l'autocompletion normalisee.
 *
 * Detecte les documents dont le "nom de commune" n'est pas un vrai nom
 * (vide, ou uniquement des chiffres comme un code postal/INSEE) puis re-derive
 * le nom officiel et le code postal depuis le code INSEE via geo.api.gouv.fr.
 *
 * IMPORTANT : ne modifie JAMAIS le code INSEE / communeId (cle de rattachement
 * aux consultations). Ne corrige que le nom affiche et le code postal.
 *
 * Usage (depuis app/backend, ADC configure -> gcloud auth application-default login) :
 *   node scripts/normalize-commune-fields.mjs                 # dry-run (lecture seule)
 *   node scripts/normalize-commune-fields.mjs --apply         # ecrit les corrections
 *   GOOGLE_CLOUD_PROJECT=mon-projet node scripts/normalize-commune-fields.mjs
 */
import admin from 'firebase-admin';

const APPLY = process.argv.includes('--apply');
const PROJECT_ID = process.env.GOOGLE_CLOUD_PROJECT
  || process.env.GCLOUD_PROJECT
  || process.env.FIREBASE_PROJECT_ID;

const INSEE_RE = /^(\d{5}|2[AB]\d{3})$/i;

// Un vrai nom de commune contient au moins une lettre. Vide ou "97122" => invalide.
const isInvalidName = (name) => {
  const v = String(name || '').trim();
  return v === '' || !/[A-Za-zÀ-ÿ]/.test(v);
};

const normalizeName = (v) => String(v || '').trim().replace(/\s+/g, ' ');
const normalizePostal = (v) => {
  const d = String(v || '').replace(/\D/g, '');
  return d.length > 5 ? d.slice(0, 5) : d;
};
const normalizeInsee = (v) => String(v || '').trim().toUpperCase().replace(/\s+/g, '');

const communeCache = new Map();
async function lookupInsee(code) {
  const insee = normalizeInsee(code);
  if (!INSEE_RE.test(insee)) return null;
  if (communeCache.has(insee)) return communeCache.get(insee);
  let result = null;
  try {
    const res = await fetch(
      `https://geo.api.gouv.fr/communes/${insee}?fields=nom,code,codesPostaux`,
    );
    if (res.ok) {
      const data = await res.json();
      if (data && data.nom && data.code) {
        result = {
          nom: normalizeName(data.nom),
          code: normalizeInsee(data.code),
          codesPostaux: Array.isArray(data.codesPostaux) ? data.codesPostaux.map(normalizePostal) : [],
        };
      }
    }
  } catch (error) {
    console.warn(`  ! geo.api injoignable pour INSEE ${insee}: ${error.message}`);
  }
  communeCache.set(insee, result);
  return result;
}

const stats = { scanned: 0, ok: 0, fixed: 0, manual: 0 };

async function processCollection({ db, name, read, write }) {
  const snap = await db.collection(name).limit(2000).get();
  console.log(`\n=== ${name} (${snap.size} docs) ===`);
  for (const doc of snap.docs) {
    const data = doc.data() || {};
    const { currentName, inseeSource, currentPostal } = read(data);
    stats.scanned += 1;
    if (!isInvalidName(currentName)) {
      stats.ok += 1;
      continue;
    }
    const ref = await lookupInsee(inseeSource);
    if (!ref) {
      stats.manual += 1;
      console.log(`  [MANUEL] ${doc.id}: nom="${currentName}" INSEE source="${inseeSource}" non resoluble -> revue manuelle`);
      continue;
    }
    const proposedPostal = normalizePostal(currentPostal) || ref.codesPostaux[0] || '';
    stats.fixed += 1;
    console.log(`  [FIX]    ${doc.id}: nom "${currentName}" -> "${ref.nom}" | CP "${currentPostal || ''}" -> "${proposedPostal}" | INSEE ${ref.code} (inchange)`);
    if (APPLY) {
      await doc.ref.set(write({ nom: ref.nom, codePostal: proposedPostal, insee: ref.code }), { merge: true });
    }
  }
}

async function main() {
  if (!PROJECT_ID) {
    console.error('GOOGLE_CLOUD_PROJECT manquant. Exporte-le ou passe par gcloud.');
    process.exit(1);
  }
  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: PROJECT_ID });
  const db = admin.firestore();

  console.log(`Projet: ${PROJECT_ID} | Mode: ${APPLY ? 'APPLY (ecriture)' : 'DRY-RUN (lecture seule)'}`);

  await processCollection({
    db,
    name: 'communeAdmins',
    read: (d) => ({ currentName: d.communeName, inseeSource: d.communeCode, currentPostal: d.codePostal }),
    write: ({ nom, codePostal }) => ({ communeName: nom, codePostal }),
  });

  await processCollection({
    db,
    name: 'controleurCodes',
    read: (d) => ({ currentName: d.commune?.name, inseeSource: d.commune?.code, currentPostal: d.commune?.codePostal }),
    write: ({ nom, codePostal, insee }) => ({ commune: { name: nom, code: insee, codePostal } }),
  });

  await processCollection({
    db,
    name: 'citizen_access_codes',
    read: (d) => ({ currentName: d.communeName, inseeSource: d.communeId, currentPostal: d.codePostal }),
    write: ({ nom }) => ({ communeName: nom }),
  });

  console.log(`\nResume: ${stats.scanned} scannes | ${stats.ok} deja OK | ${stats.fixed} ${APPLY ? 'corriges' : 'a corriger'} | ${stats.manual} a revoir manuellement`);
  if (!APPLY && stats.fixed > 0) {
    console.log('Relance avec --apply pour ecrire les corrections.');
  }
  process.exit(0);
}

main().catch((error) => {
  console.error('Echec migration:', error);
  process.exit(1);
});
