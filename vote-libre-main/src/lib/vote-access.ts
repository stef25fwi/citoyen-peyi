import { demoTokens } from '@/lib/demo-data';
import { loadRegistrationCodes, saveRegistrationCodes, type RegistrationCode } from '@/lib/registration-data';

const DEMO_OVERRIDES_KEY = 'demo_vote_access_v1';

interface DemoVoteOverride {
  code: string;
  activated: boolean;
  hasVoted: boolean;
}

export interface VoteAccessRecord {
  id: string;
  code: string;
  pollId: string;
  activated: boolean;
  hasVoted: boolean;
  activatedAt: string | null;
  votedAt: string | null;
  expiresAt: string | null;
  communeName: string | null;
  qrPayload: string | null;
  source: 'registration' | 'demo';
}

const loadDemoOverrides = (): DemoVoteOverride[] => {
  try {
    const raw = localStorage.getItem(DEMO_OVERRIDES_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed as DemoVoteOverride[] : [];
  } catch {
    return [];
  }
};

const saveDemoOverrides = (overrides: DemoVoteOverride[]) => {
  localStorage.setItem(DEMO_OVERRIDES_KEY, JSON.stringify(overrides));
};

const toRegistrationAccessRecord = (code: RegistrationCode): VoteAccessRecord => ({
  id: code.id,
  code: code.code,
  pollId: code.pollId,
  activated: Boolean(code.activatedAt),
  hasVoted: Boolean(code.votedAt),
  activatedAt: code.activatedAt || null,
  votedAt: code.votedAt || null,
  expiresAt: code.expiresAt || null,
  communeName: code.communeName || null,
  qrPayload: code.qrPayload || null,
  source: 'registration',
});

const toDemoAccessRecord = (code: string): VoteAccessRecord | null => {
  const demoToken = demoTokens.find(token => token.token === code);
  if (!demoToken) return null;
  const override = loadDemoOverrides().find(item => item.code === code);

  return {
    id: demoToken.id,
    code: demoToken.token,
    pollId: demoToken.pollId,
    activated: override?.activated ?? demoToken.activated,
    hasVoted: override?.hasVoted ?? demoToken.hasVoted,
    activatedAt: override?.activated ? new Date().toISOString() : demoToken.activated ? new Date().toISOString() : null,
    votedAt: override?.hasVoted ? new Date().toISOString() : demoToken.hasVoted ? new Date().toISOString() : null,
    expiresAt: null,
    communeName: null,
    qrPayload: `${window.location.origin}/vote/${demoToken.token}`,
    source: 'demo',
  };
};

export const resolveVoteAccessCode = (rawValue: string): string | null => {
  const trimmed = rawValue.trim();
  if (!trimmed) return null;

  if (trimmed.startsWith('{')) {
    try {
      const parsed = JSON.parse(trimmed) as { code?: string };
      if (typeof parsed.code === 'string' && parsed.code.trim()) {
        return parsed.code.trim().toUpperCase();
      }
    } catch {
      return null;
    }
  }

  if (/^https?:\/\//i.test(trimmed)) {
    try {
      const url = new URL(trimmed);
      const match = url.pathname.match(/\/vote\/([^/]+)$/i);
      if (match?.[1]) {
        return decodeURIComponent(match[1]).toUpperCase();
      }
    } catch {
      return null;
    }
  }

  return trimmed.toUpperCase();
};

export const findVoteAccessRecord = (code: string): VoteAccessRecord | null => {
  const normalizedCode = code.trim().toUpperCase();
  const registrationCode = loadRegistrationCodes().find(item => item.code.toUpperCase() === normalizedCode);
  if (registrationCode) {
    const isExpired = registrationCode.expiresAt ? new Date(registrationCode.expiresAt).getTime() < Date.now() : false;
    if (registrationCode.status !== 'validated' || isExpired) {
      return null;
    }
    return toRegistrationAccessRecord(registrationCode);
  }
  return toDemoAccessRecord(normalizedCode);
};

export const markVoteAccessActivated = (code: string) => {
  const normalizedCode = code.trim().toUpperCase();
  const registrationCodes = loadRegistrationCodes();
  const registrationIndex = registrationCodes.findIndex(item => item.code.toUpperCase() === normalizedCode);

  if (registrationIndex >= 0) {
    if (!registrationCodes[registrationIndex].activatedAt) {
      registrationCodes[registrationIndex] = {
        ...registrationCodes[registrationIndex],
        activatedAt: new Date().toISOString(),
      };
      saveRegistrationCodes(registrationCodes);
    }
    return;
  }

  const existing = loadDemoOverrides();
  const index = existing.findIndex(item => item.code === normalizedCode);
  if (index >= 0) {
    existing[index] = { ...existing[index], activated: true };
  } else {
    existing.push({ code: normalizedCode, activated: true, hasVoted: false });
  }
  saveDemoOverrides(existing);
};

export const markVoteAccessVoted = (code: string) => {
  const normalizedCode = code.trim().toUpperCase();
  const registrationCodes = loadRegistrationCodes();
  const registrationIndex = registrationCodes.findIndex(item => item.code.toUpperCase() === normalizedCode);

  if (registrationIndex >= 0) {
    registrationCodes[registrationIndex] = {
      ...registrationCodes[registrationIndex],
      activatedAt: registrationCodes[registrationIndex].activatedAt || new Date().toISOString(),
      votedAt: new Date().toISOString(),
    };
    saveRegistrationCodes(registrationCodes);
    return;
  }

  const existing = loadDemoOverrides();
  const index = existing.findIndex(item => item.code === normalizedCode);
  if (index >= 0) {
    existing[index] = { ...existing[index], activated: true, hasVoted: true };
  } else {
    existing.push({ code: normalizedCode, activated: true, hasVoted: true });
  }
  saveDemoOverrides(existing);
};

export const loadPollVoteAccessRecords = (pollId: string): VoteAccessRecord[] => {
  const registrationRecords = loadRegistrationCodes()
    .filter(item => item.status === 'validated' && item.pollId === pollId)
    .map(toRegistrationAccessRecord);

  const demoRecords = demoTokens
    .filter(item => item.pollId === pollId)
    .map(item => toDemoAccessRecord(item.token))
    .filter((item): item is VoteAccessRecord => Boolean(item));

  return [...registrationRecords, ...demoRecords];
};
