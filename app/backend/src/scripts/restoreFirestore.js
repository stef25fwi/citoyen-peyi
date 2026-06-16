// CLI de restauration Firestore (Niveau 2, applicatif).
//
// Exemples (dry-run par defaut, n'ecrit RIEN sans --apply) :
//   node src/scripts/restoreFirestore.js --id=snapshot-...            # depuis GCS, dry-run
//   node src/scripts/restoreFirestore.js --in=/tmp/snap.json --apply  # depuis fichier local, applique (merge)
//   node src/scripts/restoreFirestore.js --id=snapshot-... --mode=mirror --apply --force
//
// Securite : merge (defaut) n'efface jamais ; mirror supprime les documents
// absents du snapshot et exige --force.

import fs from 'fs';
import { Timestamp } from 'firebase-admin/firestore';
import { isFirebaseAdminConfigured, getFirebaseAdminDb } from '../services/firebaseAdmin.js';
import { restoreSnapshot } from '../services/backupService.js';
import { loadSnapshot } from '../services/backupStorage.js';

export const parseArgs = (argv = []) => {
  const get = (name) => argv.find((arg) => arg.startsWith(`--${name}=`))?.split('=').slice(1).join('=') || '';
  const collections = get('collections').split(',').map((value) => value.trim()).filter(Boolean);
  return {
    id: get('id').trim(),
    in: get('in').trim(),
    mode: get('mode').trim() === 'mirror' ? 'mirror' : 'merge',
    apply: argv.includes('--apply'),
    force: argv.includes('--force'),
    collections: collections.length > 0 ? collections : null,
  };
};

export const run = async (argv = process.argv.slice(2)) => {
  if (!isFirebaseAdminConfigured()) {
    throw new Error('Firebase Admin doit etre configure pour restaurer Firestore.');
  }
  const options = parseArgs(argv);

  let snapshot = null;
  if (options.in) {
    snapshot = JSON.parse(fs.readFileSync(options.in, 'utf8'));
  } else if (options.id) {
    snapshot = await loadSnapshot(options.id);
  } else {
    throw new Error('Indiquez --id=<snapshot GCS> ou --in=<fichier local>.');
  }
  if (!snapshot) {
    throw new Error('Snapshot introuvable.');
  }

  if (options.mode === 'mirror' && options.apply && !options.force) {
    throw new Error('Le mode mirror supprime des documents : ajoutez --force pour confirmer.');
  }

  const report = await restoreSnapshot({
    db: getFirebaseAdminDb(),
    snapshot,
    Timestamp,
    options: {
      mode: options.mode,
      force: options.force,
      dryRun: !options.apply,
      collections: options.collections,
    },
  });

  return { ok: true, source: options.in || options.id, report };
};

if (import.meta.url === `file://${process.argv[1]}`) {
  run().then((result) => {
    console.log(JSON.stringify(result, null, 2));
  }).catch((error) => {
    console.error(error.message || error);
    process.exit(1);
  });
}
