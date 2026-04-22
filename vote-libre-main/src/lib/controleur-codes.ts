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

export interface ControleurSession {
  id: string;
  code: string;
  label: string;
  connectedAt: string;
}

export interface ControleurActivity {
  id: string;
  controleurCode: string;
  controleurLabel: string;
  registrationCode: string;
  verifiedAt: string;
}

const CODES_KEY = 'controleur_codes_v1';
const SESSION_KEY = 'controleur_session_v1';
const ACTIVITY_KEY = 'controleur_activity_v1';

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
  const session: ControleurSession = {
    id: match.id,
    code: match.code,
    label: match.label,
    connectedAt: new Date().toISOString(),
  };
  sessionStorage.setItem(SESSION_KEY, JSON.stringify(session));
  return match;
};

export const getActiveControleurSession = (): ControleurSession | null => {
  const raw = sessionStorage.getItem(SESSION_KEY);
  if (!raw) return null;

  // Backward compatibility with older storage format (string code only).
  try {
    const parsed = JSON.parse(raw) as Partial<ControleurSession>;
    if (parsed && typeof parsed.code === 'string') {
      return {
        id: parsed.id || parsed.code,
        code: parsed.code,
        label: parsed.label || 'Controleur',
        connectedAt: parsed.connectedAt || new Date().toISOString(),
      };
    }
  } catch {
    const fallbackCode = raw;
    const matched = loadCodes().find(c => c.code === fallbackCode);
    if (!matched) return null;
    return {
      id: matched.id,
      code: matched.code,
      label: matched.label,
      connectedAt: new Date().toISOString(),
    };
  }

  return null;
};

export const loadControleurActivities = (controleurCode: string): ControleurActivity[] => {
  try {
    const raw = localStorage.getItem(ACTIVITY_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return (parsed as ControleurActivity[])
      .filter(item => item.controleurCode === controleurCode)
      .sort((a, b) => new Date(b.verifiedAt).getTime() - new Date(a.verifiedAt).getTime());
  } catch {
    return [];
  }
};

export const recordControleurVerification = (
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

  let existing: ControleurActivity[] = [];
  try {
    const raw = localStorage.getItem(ACTIVITY_KEY);
    if (raw) {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) {
        existing = parsed as ControleurActivity[];
      }
    }
  } catch {
    existing = [];
  }

  localStorage.setItem(ACTIVITY_KEY, JSON.stringify([entry, ...existing]));
};

export const hasControleurSession = (): boolean => {
  return !!sessionStorage.getItem(SESSION_KEY);
};

export const clearControleurSession = () => {
  sessionStorage.removeItem(SESSION_KEY);
};
