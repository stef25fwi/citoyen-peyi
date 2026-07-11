# Audit production — Citoyen Peyi

Date : audit rapide post-build après harmonisation des écrans publics/citoyens.

## Verdict

L'application compile en release web et le parcours citoyen principal est utilisable, mais elle ne doit pas encore être considérée comme prête production à 100 % tant que les points P1 ci-dessous ne sont pas clôturés.

## Points validés

- Build web release réussi côté Codespaces.
- `flutter analyze` ne remonte qu'un warning non bloquant sur `home_page.dart`.
- Les pages publiques principales ont été rapprochées de la charte Citoyen Peyi : fond clair, cartes blanches, bleu profond, jaune d'action.
- La page de résultats publics utilise maintenant `CitizenDesignTokens`, `CitizenBottomNav`, un header bleu et des cartes harmonisées.
- Le bouton de diagnostic public est masqué en production, sauf build volontaire avec `--dart-define=SHOW_DEBUG_LOG=true`.

## P0 — Bloquant avant production

Aucun P0 détecté dans le périmètre audité. Le build web est généré.

## P1 — À corriger avant production 100 %

1. **Doublons UI citoyen**
   - `citizen_consultations_page.dart` et `citizen_poll_question_page.dart` conservent encore des copies locales de header, mobile frame, couleurs et bottom nav.
   - Risque : divergence visuelle au fil des corrections, menus légèrement différents selon profil/page.
   - Correction recommandée : créer des widgets communs `CitizenPageFrame`, `CitizenPageHeader`, `CitizenStatusCard`, puis remplacer les classes privées locales.

2. **Warning Flutter Analyze**
   - `home_page.dart` : paramètre optionnel `height` de `_GlassCard` déclaré mais plus utilisé dans les appels.
   - Risque faible, mais à supprimer pour un analyze 100 % propre.

3. **Navigation citoyen**
   - Vérifier que tous les onglets `Accueil / Actualités / Donner mon avis / Résultats` utilisent les mêmes routes selon session connectée ou non.
   - Risque : empilement de pages ou perte de session si certaines pages utilisent `push`, d'autres `pushReplacement`.

4. **Données de démonstration**
   - Les consultations fallback historiques existent encore quand aucune session/poll n'est présent.
   - Risque : voir des dates anciennes ou des fausses données en production si l'état de session est mal détecté.

## P2 — Performance / UX

1. Mutualiser les couleurs : supprimer les classes privées `_CitizenColors` restantes et n'utiliser que `CitizenDesignTokens`.
2. Réduire les effets lourds sur web mobile si nécessaire : ombres fortes, blur, grandes images SVG multiples.
3. Garder le chargement des polices sans runtime fetching pour éviter les écrans sans texte sur réseau instable.
4. Ajouter des tests widget pour les pages : accueil public, accès citoyen, consultations, vote, résultats, profil.

## Checklist de validation avant release

```bash
cd /workspaces/citoyen-peyi

git pull
cd flutter_app
flutter analyze
flutter test
flutter build web --release
cd ..
firebase deploy --only hosting
```

## Commande Firebase correcte

Le déploiement doit être lancé depuis la racine du repo, pas depuis `flutter_app`, car `firebase.json` pointe vers `flutter_app/build/web`.
