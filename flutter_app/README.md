# Citoyen Peyi Flutter

Port Flutter Web de l'application Citoyen Peyi.

## Prerequis

- Flutter SDK disponible dans le PATH
- Navigateur compatible Flutter Web
- Optionnel: backend Node accessible pour l'auth admin/controleur
- Optionnel: configuration Firebase pour l'auth custom-token et Firestore

## Lancer en local

1. Installer les dependances:

	flutter pub get

2. Lancer l'apercu web:

	flutter run -d web-server --web-hostname 0.0.0.0 --web-port=8081

3. Ou construire la version Pages:

	flutter build web --release --base-href /citoyen-peyi/

## Variables compile-time

Les variables suivantes sont lues via `--dart-define` dans [lib/config/app_config.dart](lib/config/app_config.dart):

- `API_BASE_URL`
- `FIREBASE_API_KEY`
- `FIREBASE_AUTH_DOMAIN`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_APP_ID`

Si les variables Firebase sont absentes, l'application reste utilisable avec son fallback local, mais l'auth Firebase et Firestore ne seront pas actives.

## GitHub Pages

Le workflow [deploy-pages.yml](../.github/workflows/deploy-pages.yml) construit et publie [flutter_app](.) sur GitHub Pages.

Configuration attendue dans GitHub:

- Variable de repository: `API_BASE_URL`
- Secrets de repository:
  - `VITE_FIREBASE_API_KEY`
  - `VITE_FIREBASE_AUTH_DOMAIN`
  - `VITE_FIREBASE_PROJECT_ID`
  - `VITE_FIREBASE_STORAGE_BUCKET`
  - `VITE_FIREBASE_MESSAGING_SENDER_ID`
  - `VITE_FIREBASE_APP_ID`

URL de publication attendue:

- https://stef25fwi.github.io/citoyen-peyi/
