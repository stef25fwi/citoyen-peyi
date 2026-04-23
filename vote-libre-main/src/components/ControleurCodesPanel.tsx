import { useEffect, useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Copy, KeyRound, Plus, Trash2, ClipboardCheck, CheckCircle2 } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  type ControleurCode,
} from '@/lib/controleur-codes';
import {
  createControleurCodeRecord,
  deleteControleurCodeData,
  loadControleurCodesData,
} from '@/lib/data/controleur-store';
import type { CommuneConfig } from '@/lib/registration-data';
import { toast } from 'sonner';

interface ControleurCodesPanelProps {
  commune: CommuneConfig | null;
  onRequestCommuneSetup: () => void;
}

const ControleurCodesPanel = ({ commune, onRequestCommuneSetup }: ControleurCodesPanelProps) => {
  const [codes, setCodes] = useState<ControleurCode[]>([]);
  const [label, setLabel] = useState('');

  useEffect(() => {
    let isMounted = true;

    const syncCodes = async () => {
      const nextCodes = await loadControleurCodesData();
      if (!isMounted) {
        return;
      }

      setCodes(nextCodes);
    };

    void syncCodes();

    return () => {
      isMounted = false;
    };
  }, []);

  const handleGenerate = async () => {
    if (!commune) {
      toast.error('Sélectionnez d\'abord la commune de rattachement du compte administrateur.');
      onRequestCommuneSetup();
      return;
    }

    const sanitizedLabel = label.trim().slice(0, 50).replace(/<[^>]*>/g, '');
    const nextCode = await createControleurCodeRecord(sanitizedLabel, commune);
    setCodes((previous) => [nextCode, ...previous]);
    setLabel('');
    toast.success(`Code contrôleur généré pour ${commune.name}`);
  };

  const handleCopy = async (code: string) => {
    try {
      await navigator.clipboard.writeText(code);
      toast.success('Code copié');
    } catch {
      toast.error('Impossible de copier');
    }
  };

  const handleRevoke = async (id: string) => {
    setCodes(codes.filter(c => c.id !== id));
    await deleteControleurCodeData(id);
    toast.success('Code révoqué');
  };

  return (
    <Card className="border border-border shadow-card">
      <CardHeader>
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-accent/10 text-accent">
            <ClipboardCheck className="h-5 w-5" />
          </div>
          <div>
            <CardTitle className="text-base">Codes d'accès contrôleur</CardTitle>
            <CardDescription className="text-xs">
              {commune
                ? `Chaque code est automatiquement rattaché à ${commune.name}.`
                : 'Sélectionnez d\'abord une commune administrateur pour rattacher les contrôleurs à une collectivité.'}
            </CardDescription>
          </div>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex flex-col gap-2 sm:flex-row">
          <Input
            value={label}
            onChange={e => setLabel(e.target.value)}
            placeholder="Nom du contrôleur (optionnel)"
            className="flex-1"
          />
          <Button onClick={handleGenerate} className="gradient-primary border-0 text-primary-foreground">
            <Plus className="mr-2 h-4 w-4" />
            Générer un code
          </Button>
        </div>

        {codes.length === 0 ? (
          <div className="rounded-lg border border-dashed border-border p-6 text-center">
            <KeyRound className="mx-auto mb-2 h-6 w-6 text-muted-foreground" />
            <p className="text-sm text-muted-foreground">Aucun code généré pour le moment.</p>
          </div>
        ) : (
          <ul className="space-y-2">
            <AnimatePresence initial={false}>
              {codes.map(c => (
                <motion.li
                  key={c.id}
                  initial={{ opacity: 0, y: -5 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, x: -10 }}
                  className="flex items-center justify-between gap-3 rounded-xl border border-border bg-card p-3"
                >
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-sm font-semibold text-foreground">{c.code}</span>
                      {c.usedAt ? (
                        <Badge variant="secondary" className="gap-1 text-[10px]">
                          <CheckCircle2 className="h-3 w-3" /> Utilisé
                        </Badge>
                      ) : (
                        <Badge className="text-[10px]">Actif</Badge>
                      )}
                    </div>
                    <p className="truncate text-xs text-muted-foreground">
                      {c.label} · créé le {new Date(c.createdAt).toLocaleDateString('fr-FR')}
                      {c.usedAt && ` · utilisé le ${new Date(c.usedAt).toLocaleDateString('fr-FR')}`}
                    </p>
                    {c.commune && (
                      <p className="truncate text-xs text-muted-foreground">Rattaché à {c.commune.name}</p>
                    )}
                  </div>
                  <div className="flex items-center gap-1">
                    <Button size="icon" variant="ghost" onClick={() => handleCopy(c.code)} title="Copier">
                      <Copy className="h-4 w-4" />
                    </Button>
                    <Button size="icon" variant="ghost" onClick={() => handleRevoke(c.id)} title="Révoquer">
                      <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                  </div>
                </motion.li>
              ))}
            </AnimatePresence>
          </ul>
        )}
      </CardContent>
    </Card>
  );
};

export default ControleurCodesPanel;
