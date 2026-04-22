import { useEffect, useMemo } from 'react';

export interface PollPalette {
  name: string;
  primary: string;
  accent: string;
  surface: string;
  primaryHsl: string;
  accentHsl: string;
  surfaceHsl: string;
}

const palettes: PollPalette[] = [
  { name: 'Indigo Nuit', primary: '#6366F1', accent: '#A78BFA', surface: '#1E1B4B', primaryHsl: '239 84% 67%', accentHsl: '263 83% 76%', surfaceHsl: '244 47% 20%' },
  { name: 'Émeraude', primary: '#10B981', accent: '#34D399', surface: '#064E3B', primaryHsl: '160 84% 39%', accentHsl: '160 67% 52%', surfaceHsl: '163 88% 16%' },
  { name: 'Corail Solaire', primary: '#F97316', accent: '#FB923C', surface: '#7C2D12', primaryHsl: '25 95% 53%', accentHsl: '27 96% 61%', surfaceHsl: '15 75% 28%' },
  { name: 'Rose Vif', primary: '#EC4899', accent: '#F472B6', surface: '#831843', primaryHsl: '330 81% 60%', accentHsl: '330 86% 70%', surfaceHsl: '336 74% 30%' },
  { name: 'Cyan Océan', primary: '#06B6D4', accent: '#22D3EE', surface: '#164E63', primaryHsl: '189 94% 43%', accentHsl: '188 86% 53%', surfaceHsl: '199 59% 24%' },
];

function hashCode(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = ((hash << 5) - hash) + str.charCodeAt(i);
    hash |= 0;
  }
  return Math.abs(hash);
}

export function getPalette(pollId: string): PollPalette {
  return palettes[hashCode(pollId) % palettes.length];
}

export function usePollTheme(pollId: string | undefined) {
  const palette = useMemo(() => pollId ? getPalette(pollId) : palettes[0], [pollId]);

  useEffect(() => {
    if (!pollId) return;
    const root = document.documentElement;
    root.style.setProperty('--poll-primary', palette.primaryHsl);
    root.style.setProperty('--poll-accent', palette.accentHsl);
    root.style.setProperty('--poll-surface', palette.surfaceHsl);

    return () => {
      root.style.removeProperty('--poll-primary');
      root.style.removeProperty('--poll-accent');
      root.style.removeProperty('--poll-surface');
    };
  }, [pollId, palette]);

  return palette;
}
