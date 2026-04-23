import { useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { AlertTriangle, ArrowLeft, Home } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Card } from '@/components/ui/card';

const NotFound = () => {
  const location = useLocation();
  const navigate = useNavigate();

  useEffect(() => {
    if (import.meta.env.DEV) {
      console.error('404 Error: User attempted to access non-existent route:', location.pathname);
    }
  }, [location.pathname]);

  return (
    <div className="flex min-h-screen items-center justify-center bg-muted/40 px-3 py-6 sm:px-4 sm:py-8">
      <motion.div
        initial={{ opacity: 0, y: 16 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-lg"
      >
        <Card className="border border-border bg-card p-5 text-center shadow-card sm:p-8">
          <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-warning/10 text-warning sm:h-16 sm:w-16">
            <AlertTriangle className="h-7 w-7 sm:h-8 sm:w-8" />
          </div>
          <p className="mt-5 text-sm font-semibold uppercase tracking-[0.2em] text-muted-foreground">Erreur 404</p>
          <h1 className="mt-2 text-3xl font-bold text-foreground sm:text-4xl">Page introuvable</h1>
          <div className="mx-auto mt-3 max-w-md space-y-3 text-sm leading-relaxed text-muted-foreground sm:text-base">
            <p>
              L'adresse demandee ne correspond a aucune page disponible dans cette version de l'application.
            </p>
            <p className="rounded-lg bg-muted px-3 py-2 font-mono text-xs text-foreground break-all sm:text-sm">
              {location.pathname}
            </p>
          </div>
          <div className="mt-6 flex flex-col gap-3 sm:flex-row sm:justify-center">
            <Button variant="outline" onClick={() => navigate(-1)} className="h-11 w-full sm:w-auto">
              <ArrowLeft className="mr-2 h-4 w-4" />
              Revenir
            </Button>
            <Button onClick={() => navigate('/')} className="h-11 w-full sm:w-auto">
              <Home className="mr-2 h-4 w-4" />
              Retour a l'accueil
            </Button>
          </div>
        </Card>
      </motion.div>
    </div>
  );
};

export default NotFound;
