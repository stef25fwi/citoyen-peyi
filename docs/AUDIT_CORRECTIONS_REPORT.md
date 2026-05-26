# Rapport de corrections audit UI/UX et securite

Date: 2026-05-26

## Synthese

Les corrections se concentrent sur le durcissement du flux de codes citoyens, la reduction des donnees sensibles cote Flutter, la fermeture des acces Firestore directs et le nettoyage des traces de configuration historiques.

## Backend

- Generation des codes citoyens aleatoire et non deterministe.
- Stockage backend par `accessCodeHash` HMAC avec `ACCESS_CODE_PEPPER`.
- Empreinte citoyenne separee par HMAC avec `CITIZEN_FINGERPRINT_PEPPER`.
- Documents `citizen_access_codes` crees avec identifiants aleatoires.
- Demandes de doublon rattachees a des identifiants techniques, sans code existant en clair dans les reponses standard.
- Validation vote publique forcee via backend et jeton court signe.
- Bootstrap admin bloque par defaut via `ENABLE_BOOTSTRAP_ADMIN=false`.
- Profils controleur desactivables et controles avant usage.
- Redaction logger elargie pour cles, jetons, codes et fragments personnels.

## Flutter Web

- `AuthSessionStore` ne persiste plus `customToken`, code controleur ou cle d'acces.
- Nettoyage des cles locales sensibles legacy via `clearSensitiveSessionData()`.
- Modeles de doublon Flutter nettoyes: affichage par identifiant de dossier, commune, controleur, statut et motif uniquement.
- Ecrans de doublon super administrateur sans affichage de code existant ni fragments personnels.
- Accueil responsive reconstruit avec parcours citoyen, controleur et admin distincts.
- Manifeste web et assets alignes sur Citoyen Peyi.

## Firestore

- Acces client direct refuse aux collections sensibles de codes citoyens et empreintes.
- Lecture des journaux controleur limitee par role, commune et controleur rattache.
- Ecritures sensibles reservees au backend Admin SDK.

## Documentation

- Ajout de `docs/SECURITY_HARDENING.md`.
- Ajout du present rapport de corrections.
- Variables d'environnement critiques documentees pour production.

## Validations

- Backend tests: OK, 19/19 via `npm test` dans `app/backend`.
- Flutter tests: OK, 8/8 via `flutter test` dans `flutter_app`.
- Flutter build web release: OK via `flutter build web --release --base-href /citoyen-peyi/`.
- Firestore rules: diagnostics editeur OK.
- Flutter analyze: non execute dans cette session, car le terminal direct et la creation de tache temporaire retournent `ENOPRO` dans VS Code. Les diagnostics editeur cibles sur les fichiers modifies sont OK.
- Scans sensibles: les occurrences restantes attendues concernent les champs transitoires envoyes au backend, la redaction des logs ou les identifiants techniques `accessCodeId`.

## Risques residuels

- Les migrations legacy doivent etre lancees et verifiees avant de supprimer les anciens champs en base.
- Les peppers doivent etre geres comme secrets de production et ne jamais etre commites.
- Le code citoyen clair reste volontairement visible uniquement au controleur au moment de creation pour remise physique au citoyen.
