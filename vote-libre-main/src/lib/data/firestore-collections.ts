export const FIRESTORE_COLLECTIONS = {
  adminProfiles: 'adminProfiles',
  polls: 'polls',
  registrationCodes: 'registrationCodes',
  controleurCodes: 'controleurCodes',
  controleurActivities: 'controleurActivities',
} as const;

export type FirestoreCollectionName = typeof FIRESTORE_COLLECTIONS[keyof typeof FIRESTORE_COLLECTIONS];