import { useEffect, useState, type ReactNode } from 'react';
import { Navigate } from 'react-router-dom';
import { loadFirebaseRoleState, type FirebaseAppRole, isFirebaseRoleGuardEnabled } from '@/lib/firebase-authz';

interface ProtectedRouteProps {
  allowedRoles: FirebaseAppRole[];
  fallbackPath: string;
  children: ReactNode;
}

const ProtectedRoute = ({ allowedRoles, fallbackPath, children }: ProtectedRouteProps) => {
  const [isLoading, setIsLoading] = useState(isFirebaseRoleGuardEnabled());
  const [isAllowed, setIsAllowed] = useState(!isFirebaseRoleGuardEnabled());

  useEffect(() => {
    if (!isFirebaseRoleGuardEnabled()) {
      return;
    }

    let isMounted = true;

    const checkAccess = async () => {
      const roleState = await loadFirebaseRoleState();
      if (!isMounted) {
        return;
      }

      const nextAllowed = roleState.roles.some((role) => allowedRoles.includes(role));
      setIsAllowed(nextAllowed);
      setIsLoading(false);
    };

    void checkAccess();

    return () => {
      isMounted = false;
    };
  }, [allowedRoles]);

  if (!isFirebaseRoleGuardEnabled()) {
    return <>{children}</>;
  }

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-background px-4">
        <div className="max-w-sm text-center">
          <p className="text-sm font-semibold text-foreground">Verification des autorisations</p>
          <p className="mt-2 text-sm text-muted-foreground">
            Controle des claims Firebase en cours.
          </p>
        </div>
      </div>
    );
  }

  if (!isAllowed) {
    return <Navigate to={fallbackPath} replace />;
  }

  return <>{children}</>;
};

export default ProtectedRoute;