export interface CommuneConfig {
  name: string;
  population: number;
  maxCodes: number;
}

export interface RegistrationCode {
  id: string;
  code: string;
  createdAt: string;
  usedBy: string | null;
  status: 'available' | 'assigned' | 'validated';
  documentType: string | null;
  validatedAt: string | null;
  expiresAt: string | null;
}

export const ID_DOCUMENT_TYPES = [
  "Carte nationale d'identité",
  "Passeport",
  "Titre de séjour",
  "Permis de conduire",
  "Livret de famille",
] as const;

export const PROOF_OF_ADDRESS_TYPES = [
  "Facture d'électricité / gaz",
  "Facture d'eau",
  "Facture internet / téléphone",
  "Quittance de loyer",
  "Avis d'imposition",
  "Attestation d'hébergement",
] as const;

export const DOCUMENT_TYPES = [...ID_DOCUMENT_TYPES, ...PROOF_OF_ADDRESS_TYPES] as const;

export type DocumentType = typeof DOCUMENT_TYPES[number];
export type IdDocumentType = typeof ID_DOCUMENT_TYPES[number];
export type ProofOfAddressType = typeof PROOF_OF_ADDRESS_TYPES[number];

// Helper to generate a random code
export const generateCode = (): string => {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = 'INS-';
  for (let i = 0; i < 6; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
};

// Calculate expiry date (2 years from now)
export const getExpiryDate = (): string => {
  const d = new Date();
  d.setFullYear(d.getFullYear() + 2);
  return d.toISOString().split('T')[0];
};
