

# Refonte visuelle mobile avec couleurs dynamiques

## Concept

Transformer l'app en une expérience mobile-first avec des **couleurs dynamiques** — chaque sondage génère automatiquement une palette de couleurs unique basée sur son titre/thème. L'interface s'adapte visuellement selon le contexte (vote, admin, résultats).

## Palettes dynamiques proposées

Chaque sondage se voit attribuer une palette parmi un ensemble prédéfini, sélectionnée par hash du titre :

| Palette | Primary | Accent | Surface | Ambiance |
|---------|---------|--------|---------|----------|
| **Indigo Nuit** | `#6366F1` | `#A78BFA` | `#1E1B4B` | Confiance, sérieux |
| **Émeraude** | `#10B981` | `#34D399` | `#064E3B` | Nature, renouveau |
| **Corail Solaire** | `#F97316` | `#FB923C` | `#7C2D12` | Énergie, dynamisme |
| **Rose Vif** | `#EC4899` | `#F472B6` | `#831843` | Créativité, audace |
| **Cyan Océan** | `#06B6D4` | `#22D3EE` | `#164E63` | Calme, technologie |

## Changements visuels clés

### 1. Système de thème dynamique (`usePollTheme` hook)
- Nouveau hook qui génère une palette CSS à partir de l'ID ou du titre du sondage
- Injecte des variables CSS `--poll-primary`, `--poll-accent`, `--poll-surface` sur la page de vote
- Les couleurs changent avec une transition douce (`transition: background 0.4s`)

### 2. Page de vote — refonte mobile
- **Header gradient** utilisant la couleur dynamique du sondage
- **Cards d'options** avec bordure gauche colorée, effet de sélection avec glow animé
- **Bouton de confirmation** avec dégradé adapté à la palette du sondage
- **Barre de progression** en haut indiquant l'étape (accès → vote → confirmation)
- Bottom sheet style sur mobile avec coins arrondis en haut

### 3. Page d'accès QR — refonte mobile
- **Illustration animée** : cercles concentriques pulsants autour de l'icône QR
- **Input stylisé** avec bordure qui s'anime en couleur primary au focus
- **Fond avec gradient radial** subtil

### 4. Dashboard admin — refonte mobile
- **Stat cards** avec icônes colorées et micro-graphiques (sparklines)
- **Poll cards** avec bande de couleur dynamique correspondant à chaque sondage
- **FAB (Floating Action Button)** pour créer un sondage sur mobile
- **Bottom navigation** mobile avec 3 onglets (Sondages, Créer, Paramètres)

### 5. Page de confirmation post-vote
- **Animation de succès** : cercle qui se dessine + confettis légers
- **Couleur du sondage** utilisée dans l'animation de confirmation
- Message de remerciement avec la palette du sondage

### 6. Écran d'accueil (Index)
- **Gradient animé** en fond du hero qui cycle subtilement entre les palettes
- **Cards de features** avec hover coloré individuel
- **CTA buttons** plus grands, adaptés au pouce sur mobile

## Fichiers à créer/modifier

| Fichier | Action |
|---------|--------|
| `src/hooks/usePollTheme.ts` | Créer — hook de palette dynamique |
| `src/components/MobileNav.tsx` | Créer — navigation bottom mobile |
| `src/components/StepIndicator.tsx` | Créer — barre de progression vote |
| `src/components/SuccessAnimation.tsx` | Créer — animation post-vote |
| `src/pages/VotePage.tsx` | Modifier — refonte mobile + couleurs dynamiques |
| `src/pages/QRAccess.tsx` | Modifier — refonte mobile |
| `src/pages/AdminDashboard.tsx` | Modifier — FAB + stat cards colorés |
| `src/pages/Index.tsx` | Modifier — gradient animé, mobile-first |
| `src/components/PollCard.tsx` | Modifier — bande couleur dynamique |
| `src/index.css` | Modifier — variables CSS dynamiques, animations |
| `src/lib/demo-data.ts` | Modifier — ajouter `themeIndex` aux sondages |

## Détails techniques

- Les palettes sont un tableau constant dans `usePollTheme.ts`, sélectionnées via `hashCode(pollId) % palettes.length`
- Les variables CSS sont injectées via `document.documentElement.style.setProperty()` dans un `useEffect`
- Les animations utilisent `framer-motion` (déjà installé)
- Le responsive utilise les breakpoints Tailwind existants, avec des ajustements `sm:` / `md:`
- Le FAB est visible uniquement sous `md` breakpoint

