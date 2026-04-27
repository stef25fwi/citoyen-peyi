# Citoyen Peyi

Application de vote anonyme avec une architecture complete:

- backend Node.js + Express
- application Flutter Web publiee sur GitHub Pages
- source React historique conservee pour reference dans [vote-libre-main](vote-libre-main)
- workflow CI GitHub Actions
- script pour generer un ZIP complet du projet

## Structure

app/
- frontend/
- backend/
- shared/
- scripts/

.github/
- workflows/

## Prerequis

- Node.js 20+
- npm 10+
- Flutter SDK pour la version web publiee

## Installation

1. Installer les dependances:

	npm install

2. Dupliquer les variables d'environnement:

	cp .env.example .env
	cp app/frontend/.env.example app/frontend/.env

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
PORT=4000
CORS_ORIGIN=http://localhost:5173,http://localhost:8081,https://votre-domaine-frontend.example
API_BASE_URL=https://votre-backend-prod.example
SUPER_ADMIN_KEY=change-me-long-random-secret
ADMIN_ACCESS_KEY=ADMIN2026

# Option 1
GOOGLE_APPLICATION_CREDENTIALS=./secrets/firebase-admin.json

# Option 2
FIREBASE_ADMIN_PROJECT_ID=votre-project-id
FIREBASE_ADMIN_CLIENT_EMAIL=firebase-adminsdk-xxx@votre-project-id.iam.gserviceaccount.com
FIREBASE_ADMIN_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

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

- Variable de repository: `API_BASE_URL`
- Secrets de repository:
	- `VITE_FIREBASE_API_KEY`
	- `VITE_FIREBASE_AUTH_DOMAIN`
	- `VITE_FIREBASE_PROJECT_ID`
	- `VITE_FIREBASE_STORAGE_BUCKET`
	- `VITE_FIREBASE_MESSAGING_SENDER_ID`
	- `VITE_FIREBASE_APP_ID`

Commandes utiles pour le projet React historique:

- Installer les dependances: npm run install:vote-libre
- Lancer en dev: npm run dev:vote-libre
- Build: npm run build:vote-libre
- Tests: npm run test:vote-libre

## Clarification structure

- [app](app): backend et structure minimale initiale
- [flutter_app](flutter_app): application Flutter Web courante, cible de GitHub Pages
- [vote-libre-main](vote-libre-main): application React conservee comme reference de migration
