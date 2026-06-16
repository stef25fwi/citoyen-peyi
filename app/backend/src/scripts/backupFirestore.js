// CLI de sauvegarde Firestore (Niveau 2, applicatif).
//
// Exemples :
//   node src/scripts/backupFirestore.js --gcs
//   node src/scripts/backupFirestore.js --out=/tmp/snap.json
//   node src/scripts/backupFirestore.js --communeId=97211 --collections=polls,citizen_access_codes --gcs
//
// Destine aux operations (cron Cloud Scheduler ou execution manuelle). Necessite
// Firebase Admin configure ; --gcs necessite en plus le bucket de backup.

import fs from 'fs';
import { isFirebaseAdminConfigured, getFirebaseAdminDb } from '../services/firebaseAdmin.js';
import { COLLECTION_SPECS, collectSnapshot } from '../services/backupService.js';
import { newSnapshotId, saveSnapshot } from '../services/backupStorage.js';

export const parseArgs = (argv = []) => {
  const get = (name) => argv.find((arg) => arg.startsWith(`--${name}=`))?.split('=').slice(1).join('=') || '';
  const collections = get('collections').split(',').map((value) => value.trim()).filter(Boolean);
  const pollIds = get('pollIds').split(',').map((value) => value.trim()).filter(Boolean);
  const communeId = get('communeId').trim();
  return {
    collections,
    scope: {
      ...(communeId ? { communeId } : {}),
      ...(pollIds.length > 0 ? { pollIds } : {}),
    },
    out: get('out').trim(),
    gcs: argv.includes('--gcs'),
  };
};

export const run = async (argv = process.argv.slice(2)) => {
  if (!isFirebaseAdminConfigured()) {
    throw new Error('Firebase Admin doit etre configure pour sauvegarder Firestore.');
  }
  const options = parseArgs(argv);
  const specs = options.collections.length > 0
    ? COLLECTION_SPECS.filter((spec) => options.collections.includes(spec.key))
    : COLLECTION_SPECS;

  const now = new Date();
  const snapshot = await collectSnapshot({ db: getFirebaseAdminDb(), specs, scope: options.scope, now });
  const id = newSnapshotId(now);

  let storage = null;
  if (options.gcs) {
    storage = await saveSnapshot(id, snapshot);
  }
  if (options.out) {
    fs.writeFileSync(options.out, JSON.stringify(snapshot));
  }

  return {
    ok: true,
    id,
    createdAt: snapshot.createdAt,
    totalDocuments: snapshot.totalDocuments,
    counts: snapshot.counts,
    out: options.out || null,
    storage,
  };
};

if (import.meta.url === `file://${process.argv[1]}`) {
  run().then((result) => {
    console.log(JSON.stringify(result, null, 2));
  }).catch((error) => {
    console.error(error.message || error);
    process.exit(1);
  });
}
