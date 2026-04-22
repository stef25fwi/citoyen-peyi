import { ShieldCheck } from 'lucide-react';

const AnonymityBadge = ({ compact = false }: { compact?: boolean }) => {
  if (compact) {
    return (
      <div className="inline-flex items-center gap-1.5 rounded-full bg-success/10 px-3 py-1 text-xs font-medium text-success">
        <ShieldCheck className="h-3.5 w-3.5" />
        Vote anonyme garanti
      </div>
    );
  }

  return (
    <div className="rounded-xl border border-success/20 bg-success/5 p-4">
      <div className="flex items-start gap-3">
        <div className="mt-0.5 rounded-lg bg-success/10 p-2">
          <ShieldCheck className="h-5 w-5 text-success" />
        </div>
        <div>
          <h4 className="text-sm font-semibold text-foreground">Anonymat total garanti</h4>
          <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
            Votre vote est complètement anonyme. Aucune donnée personnelle n'est associée à votre bulletin. 
            Ni l'administrateur, ni le système ne peuvent relier votre identité à votre choix. 
            Seuls les résultats agrégés sont visibles.
          </p>
        </div>
      </div>
    </div>
  );
};

export default AnonymityBadge;
