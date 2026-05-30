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
6. Le vote public valide le code via le backend et recoit un jeton court dedie a une consultation precise, contenant uniquement `pollId`, `communeId`, `participationHash` et `exp`.
7. La soumission cree une participation consommee sans option choisie et un bulletin anonyme sans code citoyen ni hash de participation.
8. Le bulletin anonyme ne conserve que `pollId`, `optionId`, `communeId` et `castAt`.

## Logs applicatifs

Les logs backend redigent systematiquement `accessCode`, `accessCodeId`,
`accessCodeHash`, `citizenFingerprintHash`, `participationHash`, `accessToken`,
`Authorization`, `x-super-admin-key` et `optionId`. `optionId` est masque pour
eviter tout log combinant une option choisie avec un identifiant de droit de
vote ou de code citoyen.

## Retrait de `poll_votes` legacy

La collection `poll_votes` est conservee temporairement en lecture/ecriture
client interdites. Elle represente l'ancien modele pseudonymise, car un document
pouvait contenir ou deriver le couple `accessCodeId` + `optionId`. Elle ne doit
pas etre presentee comme une preuve d'anonymat complet.

Le backend n'ecrit plus dans `poll_votes`; les nouveaux votes utilisent
`poll_participations` et `poll_ballots`. Avant suppression de l'historique,
faire une sauvegarde Firestore controlee, puis executer:

```bash
npm run retire:poll-votes -- --archive-summary --confirm-backup
npm run retire:poll-votes -- --archive-summary --delete --confirm-backup
```

Le script n'archive que des metadonnees agregees et ne recopie jamais le couple
`accessCodeId` + `optionId` dans une nouvelle collection.

## Evolution cryptographique: jetons aveugles

Le modele actuel separe durablement droit de vote consomme et bulletin anonyme,
mais le serveur voit encore l'emission du jeton et la soumission du bulletin.
Pour un niveau institutionnel superieur, etudier un protocole de jeton aveugle
ou de signature aveugle:

1. Le citoyen prouve son droit de vote avec son code.
2. Le client genere un jeton aleatoire et l'aveugle cryptographiquement.
3. Le serveur signe le jeton aveugle apres verification d'eligibilite, sans voir
	le jeton final.
4. Le client desaveugle la signature et soumet le bulletin avec ce jeton signe.
5. Le serveur verifie que le jeton signe est valide et non consomme, sans pouvoir
	relier l'emission initiale au bulletin final.

Cette evolution doit faire l'objet d'un design separe, d'une revue crypto et de
tests de non-correlation avant implementation production.

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
