import { collection, deleteDoc, doc, getDoc, getDocs, setDoc, serverTimestamp, writeBatch } from 'firebase/firestore';
import { FIRESTORE_COLLECTIONS } from '@/lib/data/firestore-collections';
import { getFirestoreDb } from '@/lib/firebase';
import {
  generateControleurCode,
  getActiveControleurSession,
  loadCodes,
  loadControleurActivities,
  saveCodes,
  type ControleurActivity,
  type ControleurCode,
  type ControleurSession,
} from '@/lib/controleur-codes';
import type { CommuneConfig } from '@/lib/registration-data';

const SESSION_KEY = 'controleur_session_v1';

const normalizeControleurCode = (item: Partial<ControleurCode>): ControleurCode => ({
  id: item.id || `ctrl-${Math.random().toString(36).slice(2, 8)}`,
  code: item.code || '',
  label: item.label?.trim() || 'Contrôleur',
  commune: item.commune ?? null,
  createdAt: item.createdAt || new Date().toISOString(),
  usedAt: item.usedAt || null,
});

const normalizeControleurActivity = (item: Partial<ControleurActivity>): ControleurActivity => ({
  id: item.id || `ctrl-log-${Math.random().toString(36).slice(2, 8)}`,
  controleurCode: item.controleurCode || '',
  controleurLabel: item.controleurLabel || 'Contrôleur',
  registrationCode: item.registrationCode || '',
  verifiedAt: item.verifiedAt || new Date().toISOString(),
});

const persistControleurSession = (session: ControleurSession) => {
  sessionStorage.setItem(SESSION_KEY, JSON.stringify(session));
};

export const persistControleurSessionData = (session: ControleurSession) => {
  persistControleurSession(session);
  return session;
};

export const loadControleurCodesData = async (): Promise<ControleurCode[]> => {
  const db = getFirestoreDb();
  if (!db) {
    return loadCodes();
  }

  try {
    const snapshot = await getDocs(collection(db, FIRESTORE_COLLECTIONS.controleurCodes));
    const codes = snapshot.docs
      .map((item) => normalizeControleurCode(item.data() as Partial<ControleurCode>))
      .filter((item) => item.code)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    saveCodes(codes);
    return codes;
  } catch {
    return loadCodes();
  }
};

export const saveControleurCodesData = async (codes: ControleurCode[]) => {
  saveCodes(codes);

  const db = getFirestoreDb();
  if (!db) {
    return codes;
  }

  const batch = writeBatch(db);
  codes.forEach((codeRecord) => {
    batch.set(doc(db, FIRESTORE_COLLECTIONS.controleurCodes, codeRecord.id), {
      ...codeRecord,
      updatedAt: serverTimestamp(),
    });
  });
  await batch.commit();
  return codes;
};

export const saveControleurCodeData = async (codeRecord: ControleurCode) => {
  const existing = loadCodes();
  const nextCodes = existing.some((item) => item.id === codeRecord.id)
    ? existing.map((item) => (item.id === codeRecord.id ? codeRecord : item))
    : [codeRecord, ...existing];

  saveCodes(nextCodes);

  const db = getFirestoreDb();
  if (!db) {
    return codeRecord;
  }

  await setDoc(doc(db, FIRESTORE_COLLECTIONS.controleurCodes, codeRecord.id), {
    ...codeRecord,
    updatedAt: serverTimestamp(),
  }, { merge: true });

  return codeRecord;
};

export const deleteControleurCodeData = async (codeId: string) => {
  const nextCodes = loadCodes().filter((item) => item.id !== codeId);
  saveCodes(nextCodes);

  const db = getFirestoreDb();
  if (!db) {
    return;
  }

  await deleteDoc(doc(db, FIRESTORE_COLLECTIONS.controleurCodes, codeId));
};

export const createControleurCodeRecord = async (label: string, commune: CommuneConfig) => {
  const nextCode = generateControleurCode(label, commune);
  await saveControleurCodeData(nextCode);
  return nextCode;
};

export const validateControleurAccessCode = async (input: string): Promise<ControleurCode | null> => {
  const normalizedInput = input.trim().toUpperCase();
  if (!normalizedInput) {
    return null;
  }

  const codes = await loadControleurCodesData();
  const match = codes.find((item) => item.code.toUpperCase() === normalizedInput);
  if (!match) {
    return null;
  }

  const nextMatch: ControleurCode = match.usedAt
    ? match
    : {
        ...match,
        usedAt: new Date().toISOString(),
      };

  if (!match.usedAt) {
    await saveControleurCodeData(nextMatch);
  }

  const session: ControleurSession = {
    id: nextMatch.id,
    code: nextMatch.code,
    label: nextMatch.label,
    commune: nextMatch.commune ?? null,
    connectedAt: new Date().toISOString(),
  };

  persistControleurSession(session);
  return nextMatch;
};

export const loadControleurActivitiesData = async (controleurCode: string): Promise<ControleurActivity[]> => {
  const db = getFirestoreDb();
  if (!db) {
    return loadControleurActivities(controleurCode);
  }

  try {
    const snapshot = await getDocs(collection(db, FIRESTORE_COLLECTIONS.controleurActivities));
    return snapshot.docs
      .map((item) => normalizeControleurActivity(item.data() as Partial<ControleurActivity>))
      .filter((item) => item.controleurCode === controleurCode)
      .sort((a, b) => new Date(b.verifiedAt).getTime() - new Date(a.verifiedAt).getTime());
  } catch {
    return loadControleurActivities(controleurCode);
  }
};

export const recordControleurVerificationData = async (
  controleur: Pick<ControleurSession, 'code' | 'label'>,
  registrationCode: string,
) => {
  const entry: ControleurActivity = {
    id: `ctrl-log-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
    controleurCode: controleur.code,
    controleurLabel: controleur.label,
    registrationCode,
    verifiedAt: new Date().toISOString(),
  };

  const db = getFirestoreDb();
  if (!db) {
    const existing = loadControleurActivities(controleur.code);
    localStorage.setItem('controleur_activity_v1', JSON.stringify([entry, ...existing]));
    return entry;
  }

  await setDoc(doc(db, FIRESTORE_COLLECTIONS.controleurActivities, entry.id), {
    ...entry,
    createdAt: serverTimestamp(),
  });

  return entry;
};

export const loadControleurCodeBySession = async (sessionCode: string) => {
  const codes = await loadControleurCodesData();
  return codes.find((item) => item.code === sessionCode) || null;
};