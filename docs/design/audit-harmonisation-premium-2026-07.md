# Audit et harmonisation premium — Citoyen Peyi

## Intention de marque

Citoyen Peyi doit rester une application **institutionnelle, rassurante, accessible et locale**. Le bleu porte la confiance publique, le blanc la clarté et le jaune solaire l’action citoyenne. Le logo conserve le contraste entre « Citoyen », institutionnel, et « Peyi », plus humain.

## Diagnostic initial

L’application disposait de bonnes bases, mais trois systèmes visuels coexistaient :

- `AppTheme` : bleu `#0D73F2`, accent turquoise et typographie Plus Jakarta Sans ;
- `CitizenDesignTokens` : bleu `#0077C8`, bleu profond `#005A9C`, jaune `#FFE060` ;
- `citoyen_theme.dart` : autres nuances de bleu (`#0756B8`, `#1A8FE8`) et de jaune.

Cette coexistence créait des différences visibles entre les pages publiques, citoyennes, administratives et Super Admin : fonds gris ou bleus différents, rayons entre 14 et 28 px, ombres plus ou moins marquées, champs de formulaires reconstruits localement et boutons utilisant plusieurs couleurs d’action.

## Système premium retenu

### Palette principale

- Bleu principal : `#0077C8`
- Bleu profond : `#005A9C`
- Bleu nuit / texte : `#0B2F4A`
- Bleu clair : `#DFF5FF`
- Fond général : `#F4F9FD`
- Surface : `#FFFFFF`
- Jaune d’action : `#FFE060`
- Jaune fort : `#FFD21F`

### Couleurs fonctionnelles

- Succès : `#16845A`
- Avertissement : `#B7791F`
- Erreur : `#C43D4B`
- Super Admin : `#5A58C9`, uniquement comme accent de rôle

### Typographie

**Inter** devient la typographie unique de l’interface. Elle correspond au positionnement institutionnel souhaité et assure une meilleure cohérence entre les écrans publics et les espaces professionnels. Les titres utilisent des graisses 800–900 et les textes courants 400–600.

### Formes et élévation

- Cartes : rayon 22 px
- Boutons : rayon 18 px
- Champs : rayon 16 px
- Modales et grands conteneurs : rayon 28 px
- Ombres : bleutées, très diffuses et peu opaques
- Bordures : fines, bleu-gris clair

### Règles d’usage

- Le bleu est l’action institutionnelle principale.
- Le jaune est réservé à la participation citoyenne et aux appels à l’action prioritaires.
- Le violet distingue le périmètre Super Admin sans créer une seconde identité visuelle.
- Le rouge n’est utilisé que pour les erreurs, suppressions et alertes critiques.
- Une page ne doit pas introduire une nouvelle nuance sans rôle sémantique.

## Recommandations et harmonisation par parcours

### Pages publiques

#### Accueil public
- Hero plus respirant avec une hiérarchie titre / explication / action nette.
- Une seule action dominante jaune : « Je participe ».
- Cartes d’accès rapide sur surface blanche avec icônes bleues homogènes.
- Suppression des ombres lourdes et des fonds gris isolés.

#### Accès citoyen
- Conserver le fond lumineux et le logo centré.
- Utiliser les champs, boutons, erreurs et espacements du thème global.
- Réserver le message rouge aux véritables erreurs de validation.

#### Actualités
- Carte d’introduction commune aux autres pages publiques.
- Même format de cartes, date, catégorie et état vide que les consultations.
- Images avec rayon 18–22 px et ratio stable.

#### Donner mon avis
- Jaune uniquement sur le bouton de participation.
- États « en cours », « à venir » et « terminé » avec couleurs sémantiques, pas décoratives.
- Même hauteur de cartes et même grille d’espacement que les actualités.

#### Résultats
- Filtres sous forme de chips cohérentes.
- Barres de résultats bleu principal, fond bleu très clair.
- Pourcentages et données clés en graisse forte, textes d’explication plus discrets.

#### Mentions légales
- Largeur de lecture limitée, titres structurés et sections sur cartes blanches.
- Aucun effet décoratif qui nuise à la lecture administrative.

### Parcours citoyen connecté

#### Bienvenue et accueil
- Header bleu premium commun.
- Cartes et actions alignées sur la même grille.
- Jaune réservé à « Je participe ».
- Cloche, profil et états de notification utilisent les mêmes boutons d’icône.

#### Consultations
- Cartes interactives avec effet tactile réel, bordure fine et ombre douce.
- Statuts représentés de la même manière sur toutes les pages.
- Cohérence stricte entre liste, questionnaire et confirmation.

#### Questionnaire
- Progression bleue, options blanches et sélection bleu clair.
- Bouton principal jaune, désactivé en surface gris-bleu.
- Espacement vertical constant entre question, options et action.

#### Confirmation
- Succès vert réservé à la confirmation.
- Retour à l’accueil en bleu ou jaune selon l’importance de l’action.

#### Profil
- Sections regroupées dans des cartes cohérentes.
- Informations secondaires en texte atténué.
- Déconnexion et suppression en rouge uniquement.

### Administrateur communal

#### Connexion
- Même structure premium que les autres authentifications.
- Icône, champ et bouton bleu principal.
- Texte simplifié et accents corrigés.

#### Tableau de bord
- Fond général uniforme.
- Cartes statistiques avec même rayon, bordure et hiérarchie typographique.
- Accent turquoise historique remplacé par les couleurs sémantiques du système.

#### Consultations et édition
- Formulaires structurés par sections.
- Champs et boutons issus du thème global.
- Actions destructives exclusivement rouges.

#### Résultats et statistiques
- Graphiques et indicateurs limités à la palette de marque et aux couleurs fonctionnelles.
- Même présentation des filtres et périodes que dans les autres écrans de données.

#### Agents, paramètres et assistance
- Listes et cartes alignées avec le tableau de bord.
- Badges de statut identiques dans toutes les pages.
- Modales et bottom sheets utilisent les rayons 28 px du design system.

### Agent de mobilisation citoyenne

#### Connexion
- Même surface, même carte et même typographie que l’espace administrateur.
- Code centré et lisible, sans palette indépendante.

#### Tableau de bord
- Carte de profil en tête, statistiques sur la grille commune.
- Accès « Mon activité » présenté comme action secondaire claire.

#### Accès citoyen et historique
- Codes, statuts et dates utilisent les mêmes composants de badge.
- Historique présenté sous forme de chronologie ou de liste structurée.
- États vides cohérents avec le reste de l’application.

### Super Administrateur

#### Connexion
- Structure identique aux autres connexions.
- Violet limité à l’icône, au focus et au bouton principal de ce rôle.
- Outils Debug masqués en production.

#### Tableau de bord et gestion
- Surfaces, textes et espacements communs au reste de l’application.
- Accent violet utilisé uniquement pour l’identification du rôle.
- Données critiques, sauvegardes et suppressions utilisent les couleurs sémantiques.

#### Communes, administrateurs, agents, sauvegardes et historique supprimé
- Même grille de cartes, filtres, boîtes de dialogue et états vides.
- Pagination et actions groupées présentées de manière uniforme.

#### Assistance
- Priorité et statut des tickets utilisent les mêmes badges fonctionnels dans les espaces Admin et Super Admin.

## Modifications appliquées dans cette harmonisation

- Une seule palette source dans `CitizenDesignTokens`.
- Les anciens alias publics pointent désormais vers cette palette.
- Thème Material 3 complet : typographie, cartes, champs, boutons, modales, navigation, onglets, listes, snackbars, menus, indicateurs et contrôles.
- Cadre responsive global aligné sur les nouvelles surfaces et ombres.
- Suppression du double cadre sur les pages publiques.
- Headers et navigations publiques/citoyennes harmonisés.
- Outils Debug masqués hors mode développement.
- Connexions Admin, Agent et Super Admin reconstruites avec la même structure visuelle.
- Cartes citoyennes interactives et bouton de participation améliorés.

## Critères de validation visuelle

- Aucun écran ne doit introduire une quatrième nuance de bleu principale.
- Les mêmes composants doivent avoir le même rayon et le même état de survol.
- Une seule action dominante par écran.
- Contraste texte/fond conforme aux usages accessibles.
- Aucun bouton Debug visible dans une version de production.
- Aucun double cadre ou double ombre sur tablette et desktop.
- Les écrans 320, 360, 390, 430, 768, 1024 et 1440 px doivent rester sans débordement.
