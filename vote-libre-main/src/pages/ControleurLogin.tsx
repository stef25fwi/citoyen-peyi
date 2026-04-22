import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ArrowLeft, ClipboardCheck, KeyRound, ArrowRight } from 'lucide-react';
import { motion } from 'framer-motion';
import { validateControleurCode } from '@/lib/controleur-codes';
import { toast } from 'sonner';

const ControleurLogin = () => {
  const navigate = useNavigate();
  const [code, setCode] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const match = validateControleurCode(code);
    if (match) {
      toast.success(`Bienvenue, ${match.label}`);
      navigate('/admin/inscriptions');
    } else {
      toast.error('Code invalide. Demandez un code à un administrateur.');
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
            <ClipboardCheck className="h-5 w-5 text-primary" />
            <h1 className="text-lg font-bold text-foreground">Espace contrôleur</h1>
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
                <KeyRound className="h-6 w-6 text-primary sm:h-8 sm:w-8" />
              </div>
              <CardTitle className="text-lg sm:text-xl">Connexion contrôleur</CardTitle>
              <CardDescription>
                Entrez le code fourni par un administrateur pour accéder à l'interface de contrôle des pièces.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <form onSubmit={handleSubmit} className="space-y-4">
                <Input
                  value={code}
                  onChange={e => setCode(e.target.value.toUpperCase())}
                  placeholder="Ex : CTRL-A1B2C3D4"
                  className="h-12 text-center font-mono text-base tracking-wide sm:text-lg sm:tracking-wider"
                  maxLength={20}
                  autoFocus
                />
                <Button type="submit" className="gradient-primary h-12 w-full border-0 text-primary-foreground" size="lg">
                  Accéder à mon profil
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Button>
              </form>
              <p className="mt-4 text-center text-xs text-muted-foreground">
                Vous n'avez pas de code ? Contactez l'administrateur de votre commune.
              </p>
            </CardContent>
          </Card>
        </motion.div>
      </main>
    </div>
  );
};

export default ControleurLogin;
