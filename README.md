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
