export interface CommuneConfig {
  name: string;
  code?: string;
  codePostal?: string;
  population: number;
  maxCodes: number;
}

const ADMIN_COMMUNE_KEY = 'admin_commune_v1';
const REGISTRATION_CODES_KEY = 'registration_codes_v1';

export interface RegistrationCode {
  id: string;
  code: string;
  pollId: string;
  createdAt: string;
  usedBy: string | null;
  status: 'available' | 'assigned' | 'validated';
  documentType: string | null;
  validatedAt: string | null;
  expiresAt: string | null;
  communeName?: string | null;
  qrPayload?: string | null;
  activatedAt?: string | null;
  votedAt?: string | null;
  verifiedByControleurCode?: string | null;
  verifiedByControleurLabel?: string | null;
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

export const loadAdminCommune = (): CommuneConfig | null => {
  try {
    const raw = localStorage.getItem(ADMIN_COMMUNE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as Partial<CommuneConfig>;
    if (!parsed || typeof parsed.name !== 'string' || typeof parsed.population !== 'number' || typeof parsed.maxCodes !== 'number') {
      return null;
    }

    return {
      name: parsed.name,
      code: parsed.code,
      codePostal: parsed.codePostal,
      population: parsed.population,
      maxCodes: parsed.maxCodes,
    };
  } catch {
    return null;
  }
};

export const saveAdminCommune = (commune: CommuneConfig) => {
  localStorage.setItem(ADMIN_COMMUNE_KEY, JSON.stringify(commune));
};

export const clearAdminCommune = () => {
  localStorage.removeItem(ADMIN_COMMUNE_KEY);
};

export const loadRegistrationCodes = (): RegistrationCode[] => {
  try {
    const raw = localStorage.getItem(REGISTRATION_CODES_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];

    return parsed.map((item: Partial<RegistrationCode>) => ({
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
    })).filter(item => item.code);
  } catch {
    return [];
  }
};

export const saveRegistrationCodes = (codes: RegistrationCode[]) => {
  localStorage.setItem(REGISTRATION_CODES_KEY, JSON.stringify(codes));
};
