import { getFirebaseAuth, initializeFirebaseServices, isFirebaseConfigured } from '@/lib/firebase';

export type FirebaseAppRole = 'admin' | 'controller';

export interface FirebaseRoleState {
  configured: boolean;
  authenticated: boolean;
  anonymous: boolean;
  roles: FirebaseAppRole[];
}

const hasRoleClaim = (claims: Record<string, unknown>, role: FirebaseAppRole) => {
  if (claims.role === role) {
    return true;
  }

  return claims[role] === true;
};

export const isFirebaseRoleGuardEnabled = () => import.meta.env.VITE_FIREBASE_ENFORCE_ROLE_GUARDS === 'true';

export const loadFirebaseRoleState = async (): Promise<FirebaseRoleState> => {
  const services = initializeFirebaseServices();
  const auth = getFirebaseAuth();

  if (!services.configured || !auth?.currentUser) {
    return {
      configured: isFirebaseConfigured(),
      authenticated: false,
      anonymous: false,
      roles: [],
    };
  }

  const tokenResult = await auth.currentUser.getIdTokenResult();
  const claims = tokenResult.claims as Record<string, unknown>;

  return {
    configured: true,
    authenticated: true,
    anonymous: tokenResult.signInProvider === 'anonymous',
    roles: (['admin', 'controller'] as FirebaseAppRole[]).filter((role) => hasRoleClaim(claims, role)),
  };
};