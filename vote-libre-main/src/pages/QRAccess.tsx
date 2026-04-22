import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { ArrowLeft, QrCode, ArrowRight } from 'lucide-react';
import AnonymityBadge from '@/components/AnonymityBadge';
import StepIndicator from '@/components/StepIndicator';
import { demoTokens } from '@/lib/demo-data';
import { toast } from 'sonner';

const STEPS = ['Accès', 'Vote', 'Confirmation'];

const QRAccess = () => {
  const navigate = useNavigate();
  const [code, setCode] = useState('');

  const handleAccess = (e: React.FormEvent) => {
    e.preventDefault();
    const token = demoTokens.find(t => t.token.toUpperCase() === code.toUpperCase());
    if (token) {
      navigate(`/vote/${token.token}`);
    } else {
      toast.error('Code invalide. Vérifiez votre QR code et réessayez.');
    }
  };

  return (
    <div className="flex min-h-screen flex-col bg-background">
      <header className="border-b border-border bg-card">
        <div className="container mx-auto flex items-center gap-3 px-4 py-4">
          <Button variant="ghost" size="icon" onClick={() => navigate('/')}>
            <ArrowLeft className="h-4 w-4" />
          </Button>
          <h1 className="text-lg font-bold text-foreground">Accès au vote</h1>
        </div>
      </header>

      <StepIndicator steps={STEPS} current={0} />

      <main className="flex flex-1 items-center justify-center px-3 py-4 sm:px-4 sm:py-6 md:py-8">
        <div className="w-full max-w-md space-y-4 sm:space-y-5 md:space-y-6">
          {/* Animated QR icon with pulsing rings */}
          <div className="relative mx-auto flex h-24 w-24 items-center justify-center sm:h-32 sm:w-32">
            <div className="absolute inset-0 rounded-full border-2 border-primary/30 animate-pulse-ring" />
            <div className="absolute inset-2 rounded-full border-2 border-primary/20 animate-pulse-ring-delayed" />
            <div className="absolute inset-4 rounded-full border-2 border-primary/10 animate-pulse-ring-delayed-2" />
            <div className="relative z-10 flex h-20 w-20 items-center justify-center rounded-2xl bg-primary/10">
              <QrCode className="h-10 w-10 text-primary" />
            </div>
          </div>

          <div className="text-center">
            <h2 className="text-base font-bold text-foreground sm:text-xl md:text-2xl">Accédez à votre vote</h2>
            <p className="mt-1.5 text-xs leading-relaxed text-muted-foreground sm:mt-2 sm:text-sm">
              Scannez votre QR code ou entrez le code manuellement ci-dessous.
            </p>
          </div>

          <Card className="border border-border bg-card p-4 shadow-card sm:p-6">
            <form onSubmit={handleAccess} className="space-y-4">
              <div>
                <Input
                  value={code}
                  onChange={e => setCode(e.target.value.toUpperCase())}
                  placeholder="Ex : VOTE-A1B2C3"
                  className="h-12 text-center font-mono text-base tracking-wide transition-all duration-300 focus:border-primary focus:ring-2 focus:ring-primary/20 sm:text-lg sm:tracking-wider"
                  maxLength={20}
                />
              </div>
              <Button type="submit" className="gradient-primary h-12 w-full border-0 text-primary-foreground" size="lg">
                Accéder au vote
                <ArrowRight className="ml-2 h-4 w-4" />
              </Button>
            </form>
          </Card>

          <AnonymityBadge />

          {import.meta.env.DEV && (
            <p className="text-center text-xs text-muted-foreground">
              Code de démo : <span className="font-mono font-medium text-foreground">VOTE-D4E5F6</span>
            </p>
          )}
        </div>
      </main>
    </div>
  );
};

export default QRAccess;
