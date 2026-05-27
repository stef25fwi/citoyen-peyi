import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { env, getFirebaseAdminPrivateKey } from '../config/env.js';

const cloudRunProjectId = () =>
  process.env.GOOGLE_CLOUD_PROJECT ||
  process.env.GCLOUD_PROJECT ||
  process.env.FIREBASE_PROJECT_ID ||
  env.firebaseAdminProjectId;

const hasCloudRunAdc = () =>
  Boolean(process.env.K_SERVICE && cloudRunProjectId());

const hasExplicitCredentials = () =>
  Boolean(
    env.firebaseAdminProjectId &&
    env.firebaseAdminClientEmail &&
    env.firebaseAdminPrivateKey,
  );

export const isFirebaseAdminConfigured = () =>
  Boolean(hasCloudRunAdc() || env.googleApplicationCredentials || hasExplicitCredentials());

const initializeFirebaseAdmin = () => {
  const existing = getApps()[0];
  if (existing) return existing;

  if (hasExplicitCredentials()) {
    return initializeApp({
      credential: cert({
        projectId: env.firebaseAdminProjectId,
        clientEmail: env.firebaseAdminClientEmail,
        privateKey: getFirebaseAdminPrivateKey(),
      }),
      projectId: env.firebaseAdminProjectId,
    });
  }

  return initializeApp({
    credential: applicationDefault(),
    projectId: cloudRunProjectId(),
  });
};

export const getFirebaseAdminAuth = () => getAuth(initializeFirebaseAdmin());

export const getFirebaseAdminDb = () => getFirestore(initializeFirebaseAdmin());
