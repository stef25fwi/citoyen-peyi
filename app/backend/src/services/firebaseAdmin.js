import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

const resolvePrivateKey = () => process.env.FIREBASE_ADMIN_PRIVATE_KEY?.replace(/\\n/g, '\n');

const hasExplicitCredentials = () => Boolean(
  process.env.FIREBASE_ADMIN_PROJECT_ID
  && process.env.FIREBASE_ADMIN_CLIENT_EMAIL
  && process.env.FIREBASE_ADMIN_PRIVATE_KEY,
);

const initializeFirebaseAdmin = () => {
  const existing = getApps()[0];
  if (existing) {
    return existing;
  }

  if (hasExplicitCredentials()) {
    return initializeApp({
      credential: cert({
        projectId: process.env.FIREBASE_ADMIN_PROJECT_ID,
        clientEmail: process.env.FIREBASE_ADMIN_CLIENT_EMAIL,
        privateKey: resolvePrivateKey(),
      }),
    });
  }

  return initializeApp({
    credential: applicationDefault(),
    projectId: process.env.FIREBASE_ADMIN_PROJECT_ID || undefined,
  });
};

export const isFirebaseAdminConfigured = () => Boolean(
  hasExplicitCredentials() || process.env.GOOGLE_APPLICATION_CREDENTIALS,
);

export const getFirebaseAdminAuth = () => getAuth(initializeFirebaseAdmin());

export const getFirebaseAdminDb = () => getFirestore(initializeFirebaseAdmin());