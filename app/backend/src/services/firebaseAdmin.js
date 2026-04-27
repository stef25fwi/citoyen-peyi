import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { env, getFirebaseAdminPrivateKey, isFirebaseAdminConfigured } from '../config/env.js';

const hasExplicitCredentials = () => Boolean(
  env.firebaseAdminProjectId
  && env.firebaseAdminClientEmail
  && env.firebaseAdminPrivateKey,
);

const initializeFirebaseAdmin = () => {
  const existing = getApps()[0];
  if (existing) {
    return existing;
  }

  if (hasExplicitCredentials()) {
    return initializeApp({
      credential: cert({
        projectId: env.firebaseAdminProjectId,
        clientEmail: env.firebaseAdminClientEmail,
        privateKey: getFirebaseAdminPrivateKey(),
      }),
    });
  }

  return initializeApp({
    credential: applicationDefault(),
    projectId: env.firebaseAdminProjectId || undefined,
  });
};

export { isFirebaseAdminConfigured };

export const getFirebaseAdminAuth = () => getAuth(initializeFirebaseAdmin());

export const getFirebaseAdminDb = () => getFirestore(initializeFirebaseAdmin());