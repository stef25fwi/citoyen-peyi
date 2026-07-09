# Citoyen Peyi — écrans 2, 3 et 4 en grand pixel-perfect

Objectif : reproduire fidèlement les écrans **2, 3 et 4** du mockup Citoyen Peyi, sans toucher au backend, aux règles Firestore, aux routes ni à l’authentification.

## Assets créés

| Asset | Usage |
|---|---|
| `assets/citoyen_peyi/cp_logo_flower.svg` | Logo fleur du header et du splash. |
| `assets/citoyen_peyi/cp_illustration_opinion_secure.svg` | Bloc “Votre opinion compte !” de l’accueil. |
| `assets/citoyen_peyi/cp_illustration_public_spaces.svg` | Carte consultation “Aménagement des espaces publics”. |
| `assets/citoyen_peyi/cp_illustration_mobility_bus.svg` | Carte consultation “Mobilité et transports de demain”. |
| `assets/citoyen_peyi/cp_illustration_ecology_transition.svg` | Carte consultation “Transition écologique et environnement”. |
| `assets/citoyen_peyi/cp_design_tokens.json` | Tokens couleurs, espacements, rayons et dimensions. |

## Largeur réelle attendue

```dart
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 430),
    child: child,
  ),
)
```

Sur tablette/desktop, la page reste centrée comme une app mobile premium. Ne pas transformer les cards en grille desktop pour les écrans citoyen.

## Couleurs principales

```dart
const cpBlue = Color(0xFF0075C9);
const cpBlueDark = Color(0xFF005CA8);
const cpBlueLight = Color(0xFF13A7E8);
const cpYellow = Color(0xFFFFDA29);
const cpText = Color(0xFF143B5A);
const cpMutedText = Color(0xFF607A94);
const cpBorder = Color(0xFFE3EEF6);
const cpSoftSky = Color(0xFFEAF8FF);
const cpPageBg = Color(0xFFF6FCFF);
```

## Écrans couverts

### Accueil citoyen connecté

- Header bleu dégradé.
- Logo fleur SVG.
- Texte `Bienvenue !`.
- Grille 2 × 2 : Actualités, Donner mon avis, Résultats, À propos.
- Bloc `Votre opinion compte !` avec illustration SVG sécurisée.
- Bottom navigation centrée et limitée à 430 px.

### Donner mon avis

- AppBar bleue.
- Onglets `En cours`, `À venir`, `Terminés`.
- Cards de consultation avec illustrations SVG.
- Boutons jaunes `Je donne mon avis`.
- Bottom navigation limitée à 430 px.

### Questionnaire

- AppBar bleue.
- `Étape 1 sur 6` et progress bar.
- Question + options multiples.
- Bouton jaune `Suivant`.
- Bottom navigation limitée à 430 px.

## Checklist validation

- [ ] `flutter_svg` est dans `pubspec.yaml`.
- [ ] Les SVG sont déclarés par `assets/citoyen_peyi/`.
- [ ] Les widgets utilisent `SvgPicture.asset` pour les illustrations.
- [ ] Les pages citoyen restent en `maxWidth: 430` sur desktop.
- [ ] Les libellés visibles ont leurs accents français.
