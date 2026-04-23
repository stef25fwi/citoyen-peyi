import { initializeApp, type FirebaseApp, getApps } from 'firebase/app';
import { getAuth, signInAnonymously, type Auth, type UserCredential } from 'firebase/auth';
import { getFirestore, type Firestore } from 'firebase/firestore';

const FIREBASE_CONFIG_KEYS = [
  'apiKey',
  'authDomain',
  'projectId',
  'storageBucket',
  'messagingSenderId',
  'appId',
] as const;

type FirebaseConfigShape = Record<(typeof FIREBASE_CONFIG_KEYS)[number], string>;

const resolveFirebaseConfig = (): FirebaseConfigShape => ({
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY?.trim() || '',
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN?.trim() || '',
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID?.trim() || '',
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET?.trim() || '',
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID?.trim() || '',
  appId: import.meta.env.VITE_FIREBASE_APP_ID?.trim() || '',
});

const hasCompleteFirebaseConfig = (config: FirebaseConfigShape) =>
  FIREBASE_CONFIG_KEYS.every((key) => Boolean(config[key]));

let firebaseAppInstance: FirebaseApp | null | undefined;
let firebaseAuthInstance: Auth | null | undefined;
let firestoreInstance: Firestore | null | undefined;
let missingConfigWarningShown = false;
let firebaseSessionPromise: Promise<UserCredential | null> | null = null;

export const getFirebaseConfig = () => resolveFirebaseConfig();

export const isFirebaseConfigured = () => hasCompleteFirebaseConfig(resolveFirebaseConfig());

export const initializeFirebaseServices = () => {
  if (firebaseAppInstance !== undefined && firebaseAuthInstance !== undefined && firestoreInstance !== undefined) {
    return {
      app: firebaseAppInstance,
      auth: firebaseAuthInstance,
      db: firestoreInstance,
      configured: Boolean(firebaseAppInstance && firestoreInstance),
    };
  }

  const config = resolveFirebaseConfig();

  if (!hasCompleteFirebaseConfig(config)) {
    firebaseAppInstance = null;
    firebaseAuthInstance = null;
    firestoreInstance = null;

    if (import.meta.env.DEV && !missingConfigWarningShown) {
      missingConfigWarningShown = true;
      console.warn('Firebase non configure: definir les variables VITE_FIREBASE_* pour activer Firestore.');
    }

    return {
      app: firebaseAppInstance,
      auth: firebaseAuthInstance,
      db: firestoreInstance,
      configured: false,
    };
  }

  const existingApp = getApps()[0] ?? initializeApp(config);
  firebaseAppInstance = existingApp;
  firebaseAuthInstance = getAuth(existingApp);
  firestoreInstance = getFirestore(existingApp);

  return {
    app: firebaseAppInstance,
    auth: firebaseAuthInstance,
    db: firestoreInstance,
    configured: true,
  };
};

export const getFirebaseApp = () => initializeFirebaseServices().app;

export const getFirebaseAuth = () => initializeFirebaseServices().auth;

export const getFirestoreDb = () => initializeFirebaseServices().db;

export const ensureFirebaseSession = async () => {
  const { auth, configured } = initializeFirebaseServices();

  if (!configured || !auth) {
    return null;
  }

  if (auth.currentUser) {
    return auth.currentUser;
  }

  if (!firebaseSessionPromise) {
    firebaseSessionPromise = signInAnonymously(auth).catch((error) => {
      if (import.meta.env.DEV) {
        console.warn('Connexion Firebase anonyme impossible.', error);
      }
      return null;
    }).finally(() => {
      firebaseSessionPromise = null;
    });
  }

  const credential = await firebaseSessionPromise;
  return credential?.user || auth.currentUser || null;
};