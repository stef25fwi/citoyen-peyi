# Citoyen Peyi

Application de vote anonyme avec une architecture complete:

- frontend React (Vite)
- backend Node.js + Express
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

## Installation

1. Installer les dependances:

	npm install

2. Dupliquer les variables d'environnement:

	cp .env.example .env
	cp app/frontend/.env.example app/frontend/.env

3. Lancer frontend et backend:

	npm run dev

Frontend: http://localhost:5173
Backend: http://localhost:4000

## Build

npm run build

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
- Le workflow [deploy-pages.yml](.github/workflows/deploy-pages.yml) publie automatiquement le contenu de [vote-libre-main](vote-libre-main) apres chaque push sur main.

Commandes utiles pour ce projet extrait:

- Installer les dependances: npm run install:vote-libre
- Lancer en dev: npm run dev:vote-libre
- Build: npm run build:vote-libre
- Tests: npm run test:vote-libre

## Clarification structure

- [app](app): structure app creee dans ce depot (frontend/backend minimal)
- [vote-libre-main](vote-libre-main): application complete recuperee depuis l'archive ZIP
