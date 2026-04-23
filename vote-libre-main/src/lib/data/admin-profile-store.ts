import { doc, getDoc, serverTimestamp, setDoc } from 'firebase/firestore';
import { getFirestoreDb } from '@/lib/firebase';
import {
  clearAdminCommune,
  loadAdminCommune,
  saveAdminCommune,
  type CommuneConfig,
} from '@/lib/registration-data';
import { FIRESTORE_COLLECTIONS } from '@/lib/data/firestore-collections';

const ADMIN_PROFILE_DOC_ID = 'default';

interface AdminProfileDocument {
  commune: CommuneConfig | null;
}

const isValidCommuneConfig = (value: unknown): value is CommuneConfig => {
  if (!value || typeof value !== 'object') {
    return false;
  }

  const candidate = value as Partial<CommuneConfig>;
  return (
    typeof candidate.name === 'string' &&
    typeof candidate.population === 'number' &&
    typeof candidate.maxCodes === 'number'
  );
};

export const loadAdminProfileCommune = async (): Promise<CommuneConfig | null> => {
  const db = getFirestoreDb();

  if (!db) {
    return loadAdminCommune();
  }

  try {
    const snapshot = await getDoc(doc(db, FIRESTORE_COLLECTIONS.adminProfiles, ADMIN_PROFILE_DOC_ID));

    if (!snapshot.exists()) {
      return loadAdminCommune();
    }

    const data = snapshot.data() as Partial<AdminProfileDocument>;

    if (!isValidCommuneConfig(data.commune)) {
      return null;
    }

    saveAdminCommune(data.commune);
    return data.commune;
  } catch {
    return loadAdminCommune();
  }
};

export const saveAdminProfileCommune = async (commune: CommuneConfig): Promise<CommuneConfig> => {
  saveAdminCommune(commune);

  const db = getFirestoreDb();
  if (!db) {
    return commune;
  }

  await setDoc(
    doc(db, FIRESTORE_COLLECTIONS.adminProfiles, ADMIN_PROFILE_DOC_ID),
    {
      commune,
      updatedAt: serverTimestamp(),
    },
    { merge: true },
  );

  return commune;
};

export const clearAdminProfileCommune = async () => {
  clearAdminCommune();

  const db = getFirestoreDb();
  if (!db) {
    return;
  }

  await setDoc(
    doc(db, FIRESTORE_COLLECTIONS.adminProfiles, ADMIN_PROFILE_DOC_ID),
    {
      commune: null,
      updatedAt: serverTimestamp(),
    },
    { merge: true },
  );
};