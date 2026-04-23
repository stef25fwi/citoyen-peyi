import { signInWithCustomToken } from 'firebase/auth';
import { getFirebaseAuth, initializeFirebaseServices } from '@/lib/firebase';

interface AdminExchangeResponse {
  customToken: string;
}

const resolveApiBaseUrl = () => {
  const configuredBaseUrl = import.meta.env.VITE_API_BASE_URL?.trim();
  return (configuredBaseUrl || 'http://localhost:4000').replace(/\/$/, '');
};

const readErrorMessage = async (response: Response) => {
  try {
    const payload = await response.json() as { message?: string };
    return payload.message || 'Connexion administrateur impossible.';
  } catch {
    return 'Connexion administrateur impossible.';
  }
};

export const signInAdminWithAccessKey = async (accessKey: string) => {
  const services = initializeFirebaseServices();
  const auth = getFirebaseAuth();

  if (!services.configured || !auth) {
    return {
      mode: 'fallback' as const,
    };
  }

  const response = await fetch(`${resolveApiBaseUrl()}/api/auth/admin/exchange`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ accessKey }),
  });

  if (!response.ok) {
    throw new Error(await readErrorMessage(response));
  }

  const payload = await response.json() as AdminExchangeResponse;
  await signInWithCustomToken(auth, payload.customToken);

  return {
    mode: 'secure' as const,
  };
};