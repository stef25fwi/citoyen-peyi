import { signInWithCustomToken } from 'firebase/auth';
import { getFirebaseAuth, initializeFirebaseServices } from '@/lib/firebase';
import { persistControleurSessionData, validateControleurAccessCode } from '@/lib/data/controleur-store';
import type { CommuneConfig } from '@/lib/registration-data';

interface ControleurExchangeProfile {
  id: string;
  code: string;
  label: string;
  commune: CommuneConfig | null;
}

interface ControleurExchangeResponse {
  customToken: string;
  profile: ControleurExchangeProfile;
}

const resolveApiBaseUrl = () => {
  const configuredBaseUrl = import.meta.env.VITE_API_BASE_URL?.trim();
  return (configuredBaseUrl || 'http://localhost:4000').replace(/\/$/, '');
};

const readErrorMessage = async (response: Response) => {
  try {
    const payload = await response.json() as { message?: string };
    return payload.message || 'Connexion controleur impossible.';
  } catch {
    return 'Connexion controleur impossible.';
  }
};

export const signInControleurWithCode = async (code: string) => {
  const services = initializeFirebaseServices();
  const auth = getFirebaseAuth();

  if (!services.configured || !auth) {
    const fallbackProfile = await validateControleurAccessCode(code);
    if (!fallbackProfile) {
      throw new Error('Code invalide. Demandez un code a un administrateur.');
    }

    return {
      profile: fallbackProfile,
      session: persistControleurSessionData({
        id: fallbackProfile.id,
        code: fallbackProfile.code,
        label: fallbackProfile.label,
        commune: fallbackProfile.commune,
        connectedAt: new Date().toISOString(),
      }),
      mode: 'fallback' as const,
    };
  }

  const response = await fetch(`${resolveApiBaseUrl()}/api/auth/controller/exchange`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ code }),
  });

  if (!response.ok) {
    throw new Error(await readErrorMessage(response));
  }

  const payload = await response.json() as ControleurExchangeResponse;
  await signInWithCustomToken(auth, payload.customToken);

  const session = persistControleurSessionData({
    id: payload.profile.id,
    code: payload.profile.code,
    label: payload.profile.label,
    commune: payload.profile.commune,
    connectedAt: new Date().toISOString(),
  });

  return {
    profile: payload.profile,
    session,
    mode: 'secure' as const,
  };
};