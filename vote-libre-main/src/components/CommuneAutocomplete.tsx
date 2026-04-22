import { useEffect, useRef, useState } from 'react';
import { Input } from '@/components/ui/input';
import { Loader2, MapPin, Search } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface CommuneSuggestion {
  nom: string;
  code: string;
  codesPostaux: string[];
  population: number;
}

interface Props {
  onSelect: (commune: CommuneSuggestion, codePostal: string) => void;
  placeholder?: string;
}

const CommuneAutocomplete = ({ onSelect, placeholder = 'Tapez le nom ou code postal de la commune…' }: Props) => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<CommuneSuggestion[]>([]);
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  const [highlight, setHighlight] = useState(0);
  const wrapperRef = useRef<HTMLDivElement>(null);

  // Close on outside click
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (wrapperRef.current && !wrapperRef.current.contains(e.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  // Debounced search
  useEffect(() => {
    const q = query.trim();
    if (q.length < 2) {
      setResults([]);
      return;
    }
    const isPostal = /^\d{2,5}$/.test(q);
    const url = isPostal
      ? `https://geo.api.gouv.fr/communes?codePostal=${q}&fields=nom,code,codesPostaux,population&limit=10`
      : `https://geo.api.gouv.fr/communes?nom=${encodeURIComponent(q)}&fields=nom,code,codesPostaux,population&boost=population&limit=10`;

    setLoading(true);
    const ctrl = new AbortController();
    const timeout = setTimeout(() => {
      fetch(url, { signal: ctrl.signal })
        .then(r => r.json())
        .then((data: CommuneSuggestion[]) => {
          setResults(Array.isArray(data) ? data : []);
          setOpen(true);
          setHighlight(0);
        })
        .catch((error: unknown) => {
          if (error instanceof Error && error.name !== 'AbortError') {
            console.error('Erreur lors de la recherche de communes:', error);
          }
        })
        .finally(() => setLoading(false));
    }, 250);

    return () => {
      ctrl.abort();
      clearTimeout(timeout);
    };
  }, [query]);

  // Flatten: one entry per (commune, codePostal)
  const flat = results.flatMap(c =>
    (c.codesPostaux.length ? c.codesPostaux : ['—']).map(cp => ({ commune: c, codePostal: cp }))
  );

  const handlePick = (commune: CommuneSuggestion, cp: string) => {
    setQuery(`${commune.nom} (${cp})`);
    setOpen(false);
    onSelect(commune, cp);
  };

  const handleKey = (e: React.KeyboardEvent) => {
    if (!open || flat.length === 0) return;
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setHighlight(h => Math.min(h + 1, flat.length - 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setHighlight(h => Math.max(h - 1, 0));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      const sel = flat[highlight];
      if (sel) handlePick(sel.commune, sel.codePostal);
    } else if (e.key === 'Escape') {
      setOpen(false);
    }
  };

  return (
    <div ref={wrapperRef} className="relative">
      <div className="relative">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          value={query}
          onChange={e => setQuery(e.target.value)}
          onFocus={() => results.length > 0 && setOpen(true)}
          onKeyDown={handleKey}
          placeholder={placeholder}
          className="pl-9 pr-9"
        />
        {loading && (
          <Loader2 className="absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 animate-spin text-muted-foreground" />
        )}
      </div>

      {open && flat.length > 0 && (
        <div className="absolute z-50 mt-1 w-full overflow-hidden rounded-lg border border-border bg-popover shadow-elevated">
          <ul className="max-h-72 overflow-y-auto py-1">
            {flat.map((item, i) => (
              <li key={`${item.commune.code}-${item.codePostal}`}>
                <button
                  type="button"
                  onMouseEnter={() => setHighlight(i)}
                  onClick={() => handlePick(item.commune, item.codePostal)}
                  className={cn(
                    'flex w-full items-center gap-3 px-3 py-2 text-left text-sm transition-colors',
                    highlight === i ? 'bg-accent text-accent-foreground' : 'text-foreground hover:bg-accent/50'
                  )}
                >
                  <MapPin className="h-4 w-4 shrink-0 text-primary" />
                  <span className="flex-1 truncate">
                    <span className="font-medium">{item.commune.nom}</span>
                    <span className="ml-2 text-xs text-muted-foreground">
                      {item.codePostal} · {item.commune.population.toLocaleString('fr-FR')} hab.
                    </span>
                  </span>
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}

      {open && !loading && query.trim().length >= 2 && flat.length === 0 && (
        <div className="absolute z-50 mt-1 w-full rounded-lg border border-border bg-popover px-3 py-2 text-sm text-muted-foreground shadow-elevated">
          Aucune commune trouvée
        </div>
      )}
    </div>
  );
};

export default CommuneAutocomplete;
