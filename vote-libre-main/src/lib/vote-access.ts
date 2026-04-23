import { type RegistrationCode } from '@/lib/registration-data';
import { loadRegistrationCodesData, saveRegistrationCodeData } from '@/lib/data/registration-store';

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
}

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
});

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

export const findVoteAccessRecord = async (code: string): Promise<VoteAccessRecord | null> => {
  const normalizedCode = code.trim().toUpperCase();
  const registrationCodes = await loadRegistrationCodesData();
  const registrationCode = registrationCodes.find(item => item.code.toUpperCase() === normalizedCode);
  if (registrationCode) {
    const isExpired = registrationCode.expiresAt ? new Date(registrationCode.expiresAt).getTime() < Date.now() : false;
    if (registrationCode.status !== 'validated' || isExpired) {
      return null;
    }
    return toRegistrationAccessRecord(registrationCode);
  }

  return null;
};

export const markVoteAccessActivated = async (code: string) => {
  const normalizedCode = code.trim().toUpperCase();
  const registrationCodes = await loadRegistrationCodesData();
  const registrationIndex = registrationCodes.findIndex(item => item.code.toUpperCase() === normalizedCode);

  if (registrationIndex >= 0) {
    if (!registrationCodes[registrationIndex].activatedAt) {
      const nextRecord = {
        ...registrationCodes[registrationIndex],
        activatedAt: new Date().toISOString(),
      };
      await saveRegistrationCodeData(nextRecord);
    }
    return;
  }
};

export const markVoteAccessVoted = async (code: string) => {
  const normalizedCode = code.trim().toUpperCase();
  const registrationCodes = await loadRegistrationCodesData();
  const registrationIndex = registrationCodes.findIndex(item => item.code.toUpperCase() === normalizedCode);

  if (registrationIndex >= 0) {
    const nextRecord = {
      ...registrationCodes[registrationIndex],
      activatedAt: registrationCodes[registrationIndex].activatedAt || new Date().toISOString(),
      votedAt: new Date().toISOString(),
    };
    await saveRegistrationCodeData(nextRecord);
    return;
  }
};

export const loadPollVoteAccessRecords = async (pollId: string): Promise<VoteAccessRecord[]> => {
  const registrationCodes = await loadRegistrationCodesData();
  const registrationRecords = registrationCodes
    .filter(item => item.status === 'validated' && item.pollId === pollId)
    .map(toRegistrationAccessRecord);

  return registrationRecords;
};
