# Citoyen Peyi

Application de vote anonyme avec une architecture complete:

- backend Node.js + Express
- application Flutter Web publiee sur GitHub Pages
- source React historique conservee pour reference dans [vote-libre-main](vote-libre-main)
- workflow CI GitHub Actions
- script pour generer un ZIP complet du projet

## Structure

- `app/backend/`: API Node/Express (production)
- `app/scripts/`: utilitaires (zip, extraction archive)
- `flutter_app/`: application Flutter Web (production)
- `vote-libre-main/`: legacy React conserve pour reference / Firestore rules
- `tests/firestore-rules/`: tests unitaires des regles Firestore (emulateur)
- `.github/workflows/`: CI + deploiement Cloud Run / Firestore / Pages

## Prerequis

- Node.js 20+
- npm 10+
- Flutter SDK pour la version web publiee

## Installation

1. Installer les dependances:

	npm install

2. Dupliquer les variables d'environnement:

	cp .env.example .env

3. Lancer le backend Node:

	npm run dev

Backend: http://localhost:4000

4. Pour l'application Flutter Web:

	cd flutter_app
	flutter pub get
	flutter run -d web-server --web-hostname 0.0.0.0 --web-port=8081

## Configuration d'environnement production

### Variables backend obligatoires

Le backend lit ses secrets depuis l'environnement serveur uniquement. Ne jamais passer ces valeurs a Flutter.

- `SUPER_ADMIN_KEY`: cle longue et aleatoire exigee dans le header `x-super-admin-key` pour les routes super administrateur.
- `VOTE_ACCESS_TOKEN_SECRET`: secret dedie a la signature HMAC des `accessToken` citoyens temporaires. Obligatoire.
- Firebase Admin, avec une des deux options suivantes:
	- `GOOGLE_APPLICATION_CREDENTIALS`: chemin vers un fichier service account present sur le serveur.
	- ou `FIREBASE_ADMIN_PROJECT_ID`, `FIREBASE_ADMIN_CLIENT_EMAIL`, `FIREBASE_ADMIN_PRIVATE_KEY`.
- `ADMIN_ACCESS_KEY`: cle d'acces admin si l'endpoint admin backend est utilise.
- `PORT`: port HTTP backend, par defaut `4000`.
- `CORS_ORIGIN`: origines autorisees separees par des virgules.
- `API_BASE_URL`: URL publique du backend si necessaire cote backend ou documentation d'exploitation.

Le backend refuse de demarrer si `SUPER_ADMIN_KEY` ou Firebase Admin ne sont pas correctement configures. Les valeurs de secrets ne sont jamais retournees par `/api/health` et ne doivent jamais etre loggees.

### Exemple `.env` backend sans vraies cles

Copier [app/backend/.env.example](app/backend/.env.example) vers un fichier `.env` local non commite, puis remplacer les placeholders.

```env
NODE_ENV=production
PORT=4000
CORS_ORIGIN=https://votre-domaine-frontend.example
API_BASE_URL=https://votre-backend-prod.example

# Long random strings. NEVER commit, NEVER reuse across environments.
SUPER_ADMIN_KEY=<48+ char random>
ADMIN_ACCESS_KEY=<48+ char random>
VOTE_ACCESS_TOKEN_SECRET=<64+ char random>

# Option 1
GOOGLE_APPLICATION_CREDENTIALS=/var/secrets/firebase-admin.json

# Option 2
FIREBASE_ADMIN_PROJECT_ID=votre-project-id
FIREBASE_ADMIN_CLIENT_EMAIL=firebase-adminsdk-xxx@votre-project-id.iam.gserviceaccount.com
FIREBASE_ADMIN_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

En production, `NODE_ENV=production` est obligatoire. Le backend refuse de
demarrer si `CORS_ORIGIN` n'est pas defini explicitement (le defaut localhost
n'est utilise qu'en developpement).

Les fichiers `.env`, `.env.*`, `secrets/`, `firebase-admin.json` et `service-account*.json` sont exclus de Git.

### Healthcheck backend

```bash
curl https://URL_BACKEND_PROD/api/health
```

Reponse attendue, sans secret:

```json
{
	"ok": true,
	"service": "citoyen-peyi-backend",
	"firebaseAdminConfigured": true,
	"superAdminConfigured": true,
	"time": "2026-04-27T00:00:00.000Z"
}
```

### Flutter: uniquement `API_BASE_URL`

Flutter ne doit recevoir que l'URL du backend via `--dart-define=API_BASE_URL=...`. Ne jamais passer `SUPER_ADMIN_KEY`, `FIREBASE_ADMIN_PRIVATE_KEY` ou un service account a Flutter.

Execution locale Flutter Web:

```bash
cd flutter_app
flutter run -d web-server \
	--web-hostname 0.0.0.0 \
	--web-port=8081 \
	--dart-define=API_BASE_URL=http://localhost:4000
```

Build Flutter Web production:

```bash
cd flutter_app
flutter build web --release \
	--base-href /citoyen-peyi/ \
	--dart-define=API_BASE_URL=https://URL_BACKEND_PROD
```

## Build

npm run build

Pour la version Flutter GitHub Pages:

	cd flutter_app
	flutter build web --release --base-href /citoyen-peyi/

## Creer le ZIP complet de l'app

npm run zip

Le fichier genere est:

app-release.zip

## Recuperer les donnees depuis vote-libre-main 2.zip

Si l'archive est a la racine du projet, lance:

npm run extract:vote-libre

## Projet extrait: vote-libre-main

Le contenu recupere depuis l'archive est disponible dans [vote-libre-main](vote-libre-main).

Consultation en ligne via GitHub Pages:

- URL attendue: https://stef25fwi.github.io/citoyen-peyi/
- Le workflow [deploy-pages.yml](.github/workflows/deploy-pages.yml) publie automatiquement le contenu de [flutter_app](flutter_app) apres chaque push sur main.

Configuration GitHub Pages requise:

- Variables de repository:
	- `API_BASE_URL`
	- `RECAPTCHA_SITE_KEY` (optionnel: surcharge la cle publique embarquee dans `AppConfig`)
- Secrets de repository:
	- `VITE_FIREBASE_API_KEY`
	- `VITE_FIREBASE_AUTH_DOMAIN`
	- `VITE_FIREBASE_PROJECT_ID`
	- `VITE_FIREBASE_STORAGE_BUCKET`
	- `VITE_FIREBASE_MESSAGING_SENDER_ID`
	- `VITE_FIREBASE_APP_ID`

### Firebase App Check (reCAPTCHA v3)

La cle site reCAPTCHA est publique (elle ne fonctionne que sur les domaines
declares dans la console reCAPTCHA). Domaines a enregistrer:

- `stef25fwi.github.io` (GitHub Pages, environnement actuel)
- `localhost` et `127.0.0.1` (dev local)
- Domaine personnalise eventuel (ex `app.citoyen-peyi.mq`) une fois mappe

Cote Firebase Console > App Check, lier la cle, garder `Unenforced` tant que
les tests prod ne sont pas verts, puis passer en `Enforced` sur Firestore
et Authentication.

Le workflow [deploy-pages.yml](.github/workflows/deploy-pages.yml) echoue desormais explicitement si `API_BASE_URL` n'est pas defini, afin d'eviter un build de production pointant vers `localhost`.

## Firestore rules

Le repo expose maintenant une configuration CLI minimale pour deployer les regles Firestore sans modification manuelle dans la console:

```bash
npm run deploy:firestore:rules -- --project VOTRE_PROJECT_ID
```

Le fichier racine [firebase.json](firebase.json) pointe vers [vote-libre-main/firestore.rules](vote-libre-main/firestore.rules).

## Migration `registrationCodes` vers `citizen_access_codes`

Une commande backend dediee est disponible pour migrer les anciens codes valides vers la collection officielle:

```bash
npm run migrate:registration-codes -- --dry-run
npm run migrate:registration-codes
```

La migration:

- cree les documents `citizen_access_codes/{ACCESS_CODE}` absents
- calcule `codeHash`
- renseigne `displayCodeMasked`, `createdByControllerId`, `createdByControllerName`, `lastUsedAt`
- marque les documents legacy avec `migratedAt`, `migratedAccessCodeId`, `migratedToCollection`

## Collection publique `public_news`

La page `/news` lit la collection `public_news`. Schema minimal recommande par document:

```json
{
	"title": "Consultation sur le front de mer",
	"body": "Presentation du projet et calendrier de participation.",
	"communeName": "Fort-de-France",
	"publishedAt": "2026-05-10T10:00:00.000Z"
}
```

Commandes utiles pour le projet React historique:

- Installer les dependances: npm run install:vote-libre
- Lancer en dev: npm run dev:vote-libre
- Build: npm run build:vote-libre
- Tests: npm run test:vote-libre

## Clarification structure

- [app](app): backend et structure minimale initiale
- [flutter_app](flutter_app): application Flutter Web courante, cible de GitHub Pages
- [vote-libre-main](vote-libre-main): application React conservee comme reference de migration
