# Citoyen Peyi — écrans 2, 3 et 4 en grand pixel-perfect

Objectif : reproduire fidèlement les écrans **2, 3 et 4** du mockup Citoyen Peyi fourni, sans toucher au backend, aux règles Firestore, aux routes ni à l’authentification.

Ce fichier sert de brief d’intégration pour Flutter Web/mobile. Les assets ajoutés dans `flutter_app/assets/citoyen_peyi/` sont des assets de référence visuelle pour construire les cartes, les illustrations et la charte.

## 1. Assets créés

| Asset | Usage |
|---|---|
| `assets/citoyen_peyi/cp_logo_flower.svg` | Logo fleur du header et du splash. |
| `assets/citoyen_peyi/cp_illustration_opinion_secure.svg` | Bloc “Votre opinion compte !” de l’accueil. |
| `assets/citoyen_peyi/cp_illustration_public_spaces.svg` | Carte consultation “Aménagement des espaces publics”. |
| `assets/citoyen_peyi/cp_illustration_mobility_bus.svg` | Carte consultation “Mobilité et transports de demain”. |
| `assets/citoyen_peyi/cp_illustration_ecology_transition.svg` | Carte consultation “Transition écologique et environnement”. |
| `assets/citoyen_peyi/cp_design_tokens.json` | Tokens couleurs, espacements, rayons et dimensions. |

> Important Flutter : ces fichiers sont en SVG. Pour les afficher directement dans Flutter, utiliser `flutter_svg` ou les exporter ensuite en PNG/WebP. La déclaration `assets/citoyen_peyi/` existe déjà dans `flutter_app/pubspec.yaml`.

## 2. Largeur et comportement responsive

Base mobile à respecter :

```dart
const double cpScreenBaseWidth = 390;
const double cpScreenMinWidth = 360;
const double cpScreenMaxWidth = 430;
```

Règle indispensable pour obtenir le rendu “grand pixel” sans étirer les cards sur desktop :

```dart
Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 430),
    child: child,
  ),
)
```

Sur tablette/desktop, la page reste centrée comme une app mobile premium. Ne pas transformer les cards en grille desktop pour les écrans 2, 3 et 4.

## 3. Charte visuelle

Couleurs principales :

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

Typographie : rester sur la police actuelle du projet si elle est déjà chargée. Le style attendu est arrondi, lisible, premium, proche Plus Jakarta Sans.

Rayons :

```dart
const cpRadiusCard = 18.0;
const cpRadiusHeader = 26.0;
const cpRadiusButton = 14.0;
const cpRadiusPill = 999.0;
```

Ombre cards :

```dart
BoxShadow(
  color: cpBlue.withOpacity(0.10),
  blurRadius: 18,
  offset: Offset(0, 8),
)
```

## 4. Écran 2 — Accueil connecté

### Structure verticale

Largeur : `390 px` logique, max `430`.

1. Status/top safe area.
2. Header bleu en dégradé, hauteur visuelle `236`.
3. Logo fleur centré en haut, texte `Citoyen Peyi` blanc/jaune.
4. Titre `Bienvenue !`.
5. Sous-titre : `Exprimez-vous, contribuez, participez à la vie de votre collectivité.`
6. Grande zone blanche avec coins arrondis supérieurs.
7. Grille 2 × 2 de cards.
8. Card information bleutée `Votre opinion compte !`.
9. Bottom navigation fixe.

### Header

```dart
Container(
  height: 236,
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0075C9), Color(0xFF13A7E8)],
    ),
  ),
)
```

La zone blanche démarre autour de `y = 214` et recouvre légèrement le header :

```dart
Container(
  decoration: const BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
  ),
)
```

### Cards accueil

Dimensions recommandées :

```dart
childAspectRatio: 1.04
crossAxisSpacing: 12
mainAxisSpacing: 12
```

Card :

```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: cpBorder),
    boxShadow: [cpCardShadow],
  ),
)
```

Cards attendues :

- `Actualités` : icône mégaphone bleue.
- `Donner mon avis` : icône bulle de dialogue bleue.
- `Résultats` : icône graphique bleue.
- `À propos` : icône information bleue.

Chaque card :
- icône circulaire ou pictogramme plein bleu, taille 44 à 52 ;
- titre 15/16 px, `FontWeight.w800` ;
- description 12 px, couleur `cpText`, alignée centre.

### Bloc “Votre opinion compte !”

Hauteur : environ `112`.

```dart
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: cpSoftSky,
    borderRadius: BorderRadius.circular(18),
  ),
)
```

Contenu :
- illustration à gauche `cp_illustration_opinion_secure.svg`, affichée en 96 × 72 environ ;
- texte à droite :
  - titre 15 px, gras ;
  - description 12/13 px.

## 5. Écran 3 — Donner mon avis / liste des consultations

### AppBar

Hauteur visuelle : `86`.

- Fond bleu `cpBlue`.
- Flèche retour à gauche.
- Titre centré : `Donner mon avis`.
- Texte blanc, 17/18 px, `FontWeight.w700`.

### Onglets

Sous l’appbar, padding horizontal 16, top 14.

Hauteur : `40`.

```dart
SegmentedButton / custom Row
```

États :
- `En cours` actif : fond bleu, texte blanc.
- `À venir` et `Terminés` inactifs : fond `#EEF7FC`, texte `cpText`.

Chaque segment doit avoir un rayon `999`.

### Carte consultation

Dimensions :
- marge horizontale : 16 ;
- padding : 14 ;
- radius : 18 ;
- image : 96 × 84 à droite ;
- bouton jaune pleine largeur en bas.

Contenu carte :

1. Petit badge `NOUVEAU` pour la première card.
2. Titre sur 2 lignes max.
3. Ligne date avec icône calendrier.
4. Ligne participations avec icône groupe.
5. Illustration à droite.
6. Bouton `Je donne mon avis`.

Bouton :

```dart
Container(
  height: 44,
  decoration: BoxDecoration(
    color: cpYellow,
    borderRadius: BorderRadius.circular(10),
  ),
)
```

Le chevron doit être à droite, centré verticalement.

### Données visibles du mockup

Créer au moins ces trois cards de référence :

```dart
[
  {
    "badge": "NOUVEAU",
    "title": "Aménagement des espaces publics",
    "deadline": "Jusqu'au 15 juin 2024",
    "participations": "1 248 participations",
    "asset": "assets/citoyen_peyi/cp_illustration_public_spaces.svg"
  },
  {
    "title": "Mobilité et transports de demain",
    "deadline": "Jusqu'au 30 juin 2024",
    "participations": "892 participations",
    "asset": "assets/citoyen_peyi/cp_illustration_mobility_bus.svg"
  },
  {
    "title": "Transition écologique et environnement",
    "deadline": "Jusqu'au 20 juillet 2024",
    "participations": "654 participations",
    "asset": "assets/citoyen_peyi/cp_illustration_ecology_transition.svg"
  }
]
```

## 6. Écran 4 — Questionnaire consultation

### AppBar

Même hauteur et fond que l’écran 3.

Titre centré sur deux lignes autorisées :

```text
Aménagement des
espaces publics
```

Icône partage à droite.

### Progression

Bloc sous appbar :

```text
Étape 1 sur 6
```

Progress bar :
- hauteur `8`;
- fond `#E3F2FA`;
- progression bleue `cpBlueLight`;
- radius `999`;
- largeur remplie environ `1 / 6`.

### Card question

Marge 16, top 22, radius 18, padding 18.

Titre :

```text
1. Quels sont les aménagements que vous jugez prioritaires dans votre commune ?
```

Style :
- 17 px ;
- `FontWeight.w800` ;
- couleur `cpText` ;
- line-height 1.18.

Sous-titre :

```text
Vous pouvez choisir plusieurs réponses
```

Style 12/13 px, `cpMutedText`.

### Options

Hauteur item : `58` à `64`.

Fond item : `#F3FAFE`.

Radius : 12.

Options :

1. `Espaces verts et parcs` — sélectionné.
2. `Éclairage public` — sélectionné.
3. `Aires de jeux` — non sélectionné.
4. `Accessibilité PMR` — sélectionné.
5. `Autre` — non sélectionné.

Checkbox :
- sélectionné : carré bleu avec check blanc ;
- non sélectionné : contour `#B8CBDD`, fond blanc.

### Bouton suivant

Bouton jaune pleine largeur, hauteur `52`, radius `12`.

Texte centré :

```text
Suivant
```

Chevron à droite.

## 7. Bottom navigation commune

Hauteur : `72`.

Fond blanc, bordure haute `#E3EEF6`, rayon supérieur léger si la barre est dans une card.

Items :

1. Accueil
2. Actualités
3. Donner mon avis
4. Résultats

État actif :
- icône bleue ;
- fond pastille très clair `#EAF8FF` derrière l’icône possible ;
- label bleu, 11/12 px, gras.

État inactif :
- icône `#526C86` ;
- label `#526C86`.

## 8. Prompt d’intégration Copilot / Claude Code

```text
Travaille uniquement dans flutter_app.
Objectif : reproduire les écrans Citoyen Peyi 2, 3 et 4 du fichier docs/design/citoyen-peyi-large-pixel-2-3-4.md.

Contraintes strictes :
- zéro régression
- ne modifie pas le backend
- ne modifie pas Firestore
- ne modifie pas les routes existantes sauf si une route cible existe déjà
- ne supprime aucune logique d’authentification
- conserve la largeur mobile premium avec maxWidth 430 sur desktop
- ne fais aucun commit ni push

Utilise les assets :
- assets/citoyen_peyi/cp_logo_flower.svg
- assets/citoyen_peyi/cp_illustration_opinion_secure.svg
- assets/citoyen_peyi/cp_illustration_public_spaces.svg
- assets/citoyen_peyi/cp_illustration_mobility_bus.svg
- assets/citoyen_peyi/cp_illustration_ecology_transition.svg
- assets/citoyen_peyi/cp_design_tokens.json

Si Flutter ne peut pas afficher les SVG, ajoute flutter_svg proprement dans pubspec.yaml puis flutter pub get.
Ne transforme pas les pages en layout desktop.
Le rendu final doit rester centré, arrondi, bleu/jaune, très lisible, proche du mockup fourni.
```

## 9. Checklist de validation visuelle

- La largeur utile ne dépasse jamais 430 px sur desktop.
- Le header bleu est arrondi par la zone blanche sur l’accueil.
- Les cards ont un fond blanc, radius 18 et une ombre douce.
- Les boutons principaux sont jaunes, lisibles et arrondis.
- Les onglets de l’écran 3 sont en pilules.
- La progress bar de l’écran 4 indique bien l’étape 1/6.
- La bottom bar est présente et cohérente sur les écrans 2, 3 et 4.
- Le texte reste lisible en mobile 360 px.
