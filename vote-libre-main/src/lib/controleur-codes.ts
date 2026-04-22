// Lightweight client-side store for "contrôleur" access codes.
// NOTE: This is a demo-only mechanism (localStorage). For production,
// use Lovable Cloud auth + a server-validated invite/role system.

export interface ControleurCode {
  id: string;
  code: string;
  label: string;
  createdAt: string;
  usedAt: string | null;
}

const CODES_KEY = 'controleur_codes_v1';
const SESSION_KEY = 'controleur_session_v1';

export const loadCodes = (): ControleurCode[] => {
  try {
    const raw = localStorage.getItem(CODES_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed as ControleurCode[];
  } catch {
    return [];
  }
};

export const saveCodes = (codes: ControleurCode[]) => {
  localStorage.setItem(CODES_KEY, JSON.stringify(codes));
};

export const generateControleurCode = (label: string): ControleurCode => {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let body = '';
  for (let i = 0; i < 8; i++) body += chars.charAt(Math.floor(Math.random() * chars.length));
  return {
    id: `ctrl-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
    code: `CTRL-${body}`,
    label: label.trim() || 'Contrôleur',
    createdAt: new Date().toISOString(),
    usedAt: null,
  };
};

export const validateControleurCode = (input: string): ControleurCode | null => {
  const codes = loadCodes();
  const match = codes.find(c => c.code.toUpperCase() === input.trim().toUpperCase());
  if (!match) return null;
  // mark used (first time)
  if (!match.usedAt) {
    match.usedAt = new Date().toISOString();
    saveCodes(codes);
  }
  // open session
  sessionStorage.setItem(SESSION_KEY, match.code);
  return match;
};

export const hasControleurSession = (): boolean => {
  return !!sessionStorage.getItem(SESSION_KEY);
};

export const clearControleurSession = () => {
  sessionStorage.removeItem(SESSION_KEY);
};
