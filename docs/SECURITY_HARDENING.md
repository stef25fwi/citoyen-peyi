# Durcissement securite Citoyen Peyi

Derniere mise a jour: 2026-05-26

## Principes appliques

- Les codes citoyens sont generes par le backend avec `crypto.randomBytes`.
- Les codes citoyens ne sont pas stockes en clair dans Firestore.
- La recherche de code citoyen se fait par HMAC `accessCodeHash` avec `ACCESS_CODE_PEPPER`.
- Les empreintes citoyennes sont separees des codes et hachees par HMAC avec `CITIZEN_FINGERPRINT_PEPPER`.
- Le droit de vote consomme est separe du bulletin via `PARTICIPATION_PEPPER`.
- Les demandes de doublon exposent des identifiants de dossier, pas les fragments d'identite.
- Les jetons Firebase custom et cles d'acces ne sont pas persistés dans le stockage Flutter.
- Les collections sensibles Firestore sont reservees aux operations backend/admin.

## Variables obligatoires

Backend production:

- `NODE_ENV=production`
- `SUPER_ADMIN_KEY`: secret long et aleatoire.
- `ENABLE_BOOTSTRAP_ADMIN=false` sauf operation de bootstrap explicitement controlee.
- `ACCESS_CODE_PEPPER`: secret long, aleatoire, distinct des autres secrets.
- `CITIZEN_FINGERPRINT_PEPPER`: secret long, aleatoire, distinct des autres secrets.
- `PARTICIPATION_PEPPER`: secret long, aleatoire, distinct des autres secrets, utilise pour empecher le lien durable entre code citoyen et bulletin.
- `VOTE_ACCESS_TOKEN_SECRET`: secret long et aleatoire pour les jetons courts de vote.
- Identifiants Firebase Admin: `GOOGLE_APPLICATION_CREDENTIALS` ou variables projet/client/private key selon l'environnement.

Frontend Flutter Web:

- `API_BASE_URL`: URL HTTPS du backend.
- `FIREBASE_API_KEY`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_PROJECT_ID`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_APP_ID`.

## Flux code citoyen

1. Le controleur verifie physiquement l'eligibilite.
2. Le frontend envoie les donnees minimales au backend authentifie.
3. Le backend calcule l'empreinte citoyenne HMAC et detecte un doublon.
4. Si aucun doublon n'existe, le backend cree un code aleatoire, stocke uniquement son HMAC et retourne le code une seule fois a l'ecran controleur.
5. Si un doublon existe, le backend cree une demande de validation sans exposer de code existant en clair.
6. Le vote public valide le code via le backend et recoit un jeton court dedie au vote, contenant uniquement des hashes de participation par consultation.
7. La soumission cree une participation consommee sans option choisie et un bulletin anonyme sans code citoyen ni hash de participation.

## Firestore

Les collections suivantes doivent rester inaccessibles directement aux clients publics:

- `citizen_access_codes`
- `citizen_fingerprints`
- `duplicate_code_requests`

Les journaux `controller_activity_logs` sont lisibles uniquement selon le role et le rattachement commune/controleur.

## Verification avant production

- Lancer les tests backend.
- Lancer `flutter analyze`, `flutter test` et `flutter build web`.
- Verifier que les scans ne trouvent pas de stockage clair de `customToken`, `accessKey`, code citoyen ou fragments personnels.
- Confirmer que `ENABLE_BOOTSTRAP_ADMIN=false` en production.
- Faire une rotation des peppers si un environnement non fiable a vu des donnees sensibles.
