import { useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card } from '@/components/ui/card';
import { ArrowLeft, QrCode, ArrowRight } from 'lucide-react';
import AnonymityBadge from '@/components/AnonymityBadge';
import StepIndicator from '@/components/StepIndicator';
import { findVoteAccessRecord, markVoteAccessActivated, resolveVoteAccessCode } from '@/lib/vote-access';
import { toast } from 'sonner';

const STEPS = ['Accès', 'Vote', 'Confirmation'];

const QRAccess = () => {
  const navigate = useNavigate();
  const [code, setCode] = useState('');
  const fileInputRef = useRef<HTMLInputElement | null>(null);

  const openVoteAccess = async (rawValue: string) => {
    const resolvedCode = resolveVoteAccessCode(rawValue);
    if (!resolvedCode) {
      toast.error('QR code ou code invalide. Vérifiez et réessayez.');
      return;
    }

    const record = await findVoteAccessRecord(resolvedCode);
    if (!record) {
      toast.error('Code invalide. Vérifiez votre QR code et réessayez.');
      return;
    }

    await markVoteAccessActivated(record.code);
    navigate(`/vote/${record.code}`);
  };

  const handleAccess = async (e: React.FormEvent) => {
    e.preventDefault();
    await openVoteAccess(code);
  };

  const handleScanClick = () => {
    fileInputRef.current?.click();
  };

  const handleScanFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    e.target.value = '';

    if (!file) return;

    const BarcodeDetectorApi = (window as Window & {
      BarcodeDetector?: new (options?: { formats?: string[] }) => {
        detect: (source: ImageBitmapSource) => Promise<Array<{ rawValue?: string }>>;
      };
    }).BarcodeDetector;

    if (!BarcodeDetectorApi) {
      toast.error('Le scan automatique n\'est pas disponible sur cet appareil. Saisissez le code manuellement.');
      return;
    }

    try {
      const bitmap = await createImageBitmap(file);
      const detector = new BarcodeDetectorApi({ formats: ['qr_code'] });
      const result = await detector.detect(bitmap);
      bitmap.close();
      const rawValue = result[0]?.rawValue;

      if (!rawValue) {
        toast.error('Aucun QR code détecté sur cette image.');
        return;
      }

      await openVoteAccess(rawValue);
    } catch {
      toast.error('Impossible de lire ce QR code. Essayez avec une image plus nette ou saisissez le code.');
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
            <button
              type="button"
              onClick={handleScanClick}
              className="relative z-10 flex h-20 w-20 items-center justify-center rounded-2xl bg-primary/10 transition-transform hover:scale-[1.02] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
              aria-label="Scanner un QR code"
            >
              <QrCode className="h-10 w-10 text-primary" />
            </button>
          </div>
          <input
            ref={fileInputRef}
            type="file"
            accept="image/*"
            capture="environment"
            className="hidden"
            onChange={handleScanFile}
          />

          <div className="text-center">
            <h2 className="text-base font-bold text-foreground sm:text-xl md:text-2xl">Accédez à votre vote</h2>
            <p className="mt-1.5 text-xs leading-relaxed text-muted-foreground sm:mt-2 sm:text-sm">
              Scannez votre QR code ou entrez le code manuellement ci-dessous.
            </p>
            <p className="mt-1 text-xs text-primary">Touchez le logo QR pour ouvrir l'appareil photo et scanner.</p>
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
        </div>
      </main>
    </div>
  );
};

export default QRAccess;
