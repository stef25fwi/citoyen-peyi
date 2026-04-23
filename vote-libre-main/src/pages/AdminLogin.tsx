import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ArrowLeft, ArrowRight, LockKeyhole, Settings } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { signInAdminWithAccessKey } from '@/lib/admin-auth';
import { toast } from 'sonner';

const AdminLogin = () => {
  const navigate = useNavigate();
  const [accessKey, setAccessKey] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    setIsSubmitting(true);

    try {
      const result = await signInAdminWithAccessKey(accessKey);
      if (result.mode === 'fallback') {
        toast.success('Mode local actif. Acces administrateur ouvert sans echange backend.');
      } else {
        toast.success('Connexion administrateur securisee etablie.');
      }

      navigate('/admin');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Connexion administrateur impossible.';
      toast.error(message);
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="flex min-h-screen flex-col bg-background">
      <header className="border-b border-border bg-card">
        <div className="container mx-auto flex items-center gap-3 px-4 py-4">
          <Button variant="ghost" size="icon" onClick={() => navigate('/')} className="h-12 w-12">
            <ArrowLeft className="h-5 w-5" />
          </Button>
          <div className="flex items-center gap-2">
            <Settings className="h-5 w-5 text-primary" />
            <h1 className="text-lg font-bold text-foreground">Espace administrateur</h1>
          </div>
        </div>
      </header>

      <main className="flex flex-1 items-center justify-center px-3 py-4 sm:px-4 sm:py-6 md:py-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="w-full max-w-md"
        >
          <Card className="border border-border shadow-card">
            <CardHeader className="space-y-3 text-center">
              <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10 sm:h-16 sm:w-16">
                <LockKeyhole className="h-6 w-6 text-primary sm:h-8 sm:w-8" />
              </div>
              <CardTitle className="text-lg sm:text-xl">Connexion administrateur</CardTitle>
              <CardDescription>
                Entrez votre cle d'acces administrateur pour recevoir un jeton de confiance emis par le backend.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                <Input
                  value={accessKey}
                  onChange={event => setAccessKey(event.target.value)}
                  type="password"
                  placeholder="Cle administrateur"
                  className="h-12 text-center font-mono text-base tracking-wide sm:text-lg"
                  autoFocus
                  disabled={isSubmitting}
                />
                <Button
                  type="submit"
                  className="gradient-primary h-12 w-full border-0 text-primary-foreground"
                  size="lg"
                  disabled={isSubmitting || !accessKey.trim()}
                >
                  {isSubmitting ? 'Connexion en cours...' : 'Acceder au tableau de bord'}
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Button>
              </form>
              <p className="mt-4 text-center text-xs text-muted-foreground">
                En mode configure, cette cle est verifiee par le backend avant emission des claims admin.
              </p>
            </CardContent>
          </Card>
        </motion.div>
      </main>
    </div>
  );
};

export default AdminLogin;