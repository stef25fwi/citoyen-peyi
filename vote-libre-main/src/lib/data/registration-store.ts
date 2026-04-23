import { collection, doc, getDocs, setDoc, serverTimestamp, writeBatch } from 'firebase/firestore';
import { FIRESTORE_COLLECTIONS } from '@/lib/data/firestore-collections';
import { getFirestoreDb } from '@/lib/firebase';
import {
  loadRegistrationCodes,
  saveRegistrationCodes,
  type RegistrationCode,
} from '@/lib/registration-data';

const normalizeRegistrationCode = (item: Partial<RegistrationCode>): RegistrationCode => ({
  id: item.id || `reg-${Math.random().toString(36).slice(2, 8)}`,
  code: item.code || '',
  pollId: item.pollId || 'poll-1',
  createdAt: item.createdAt || new Date().toISOString().split('T')[0],
  usedBy: item.usedBy || null,
  status: item.status || 'available',
  documentType: item.documentType || null,
  validatedAt: item.validatedAt || null,
  expiresAt: item.expiresAt || null,
  communeName: item.communeName || null,
  qrPayload: item.qrPayload || null,
  activatedAt: item.activatedAt || null,
  votedAt: item.votedAt || null,
  verifiedByControleurCode: item.verifiedByControleurCode || null,
  verifiedByControleurLabel: item.verifiedByControleurLabel || null,
});

export const loadRegistrationCodesData = async (): Promise<RegistrationCode[]> => {
  const db = getFirestoreDb();
  if (!db) {
    return loadRegistrationCodes();
  }

  try {
    const snapshot = await getDocs(collection(db, FIRESTORE_COLLECTIONS.registrationCodes));
    const codes = snapshot.docs
      .map((item) => normalizeRegistrationCode(item.data() as Partial<RegistrationCode>))
      .filter((item) => item.code)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    saveRegistrationCodes(codes);
    return codes;
  } catch {
    return loadRegistrationCodes();
  }
};

export const saveRegistrationCodesData = async (codes: RegistrationCode[]) => {
  saveRegistrationCodes(codes);

  const db = getFirestoreDb();
  if (!db) {
    return codes;
  }

  const batch = writeBatch(db);
  codes.forEach((codeRecord) => {
    batch.set(doc(db, FIRESTORE_COLLECTIONS.registrationCodes, codeRecord.id), {
      ...codeRecord,
      updatedAt: serverTimestamp(),
    });
  });
  await batch.commit();
  return codes;
};

export const saveRegistrationCodeData = async (codeRecord: RegistrationCode) => {
  const existing = loadRegistrationCodes();
  const nextCodes = existing.some((item) => item.id === codeRecord.id)
    ? existing.map((item) => (item.id === codeRecord.id ? codeRecord : item))
    : [codeRecord, ...existing];

  saveRegistrationCodes(nextCodes);

  const db = getFirestoreDb();
  if (!db) {
    return codeRecord;
  }

  await setDoc(doc(db, FIRESTORE_COLLECTIONS.registrationCodes, codeRecord.id), {
    ...codeRecord,
    updatedAt: serverTimestamp(),
  }, { merge: true });

  return codeRecord;
};

export const saveRegistrationCodesBatchData = async (codes: RegistrationCode[]) => {
  if (codes.length === 0) {
    return codes;
  }

  const existing = loadRegistrationCodes();
  const nextMap = new Map(existing.map((item) => [item.id, item]));
  codes.forEach((codeRecord) => {
    nextMap.set(codeRecord.id, codeRecord);
  });
  saveRegistrationCodes(Array.from(nextMap.values()));

  const db = getFirestoreDb();
  if (!db) {
    return codes;
  }

  const batch = writeBatch(db);
  codes.forEach((codeRecord) => {
    batch.set(doc(db, FIRESTORE_COLLECTIONS.registrationCodes, codeRecord.id), {
      ...codeRecord,
      updatedAt: serverTimestamp(),
    }, { merge: true });
  });
  await batch.commit();

  return codes;
};