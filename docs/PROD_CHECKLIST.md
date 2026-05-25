# Production go-live checklist

## Secrets et configuration
- [ ] `SUPER_ADMIN_KEY` genere avec `openssl rand -base64 48`, stocke dans Secret Manager.
- [ ] `ADMIN_ACCESS_KEY` genere et utilise uniquement pour le bootstrap initial.
- [ ] `VOTE_ACCESS_TOKEN_SECRET` genere avec `openssl rand -base64 64`.
- [ ] Service account Firebase Admin avec scope minimal (Firestore User).
- [ ] `CORS_ORIGIN` configure avec uniquement le domaine prod du frontend (HTTPS).
- [ ] Variables GitHub Actions definies: `GCP_PROJECT_ID`, `GCP_REGION`, `API_BASE_URL`, `CORS_ORIGIN`, `FIREBASE_PROJECT_ID`.
- [ ] Secrets GitHub Actions definis: `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_DEPLOY_SERVICE_ACCOUNT`, `GCP_RUNTIME_SERVICE_ACCOUNT`, `VITE_FIREBASE_*` (x6).

## Code et tests
- [ ] CI vert sur la branche cible (backend tests, Flutter analyze + test, Firestore rules emulator).
- [ ] `npm audit --omit=dev` revu, vulnerabilites tracables a `firebase-admin` documentees.
- [ ] Aucun grep ne retourne `ADMIN2026`, `change-me`, `fallback` actif dans `flutter_app/lib`.

## Infrastructure
- [ ] Cloud Run service `citoyen-peyi-api` cree en `eu-west1` (ou region la plus proche).
- [ ] Artifact Registry repo `citoyen-peyi/backend` cree.
- [ ] Domain mapping `api.citoyen-peyi.<tld>` -> Cloud Run.
- [ ] GitHub Pages domain mapping (optionnel) `app.citoyen-peyi.<tld>`.
- [ ] Backup Firestore quotidien programme.
- [ ] Alertes Cloud Monitoring: p95 > 1s, error rate > 1%, instance count saturee.

## Donnees
- [ ] Toutes les collections de demonstration supprimees (`polls/poll-1`, controleurs `ADMIN2026`).
- [ ] `registrationCodes` migrees vers `citizen_access_codes` via `npm run migrate:registration-codes`.
- [ ] Premiers profils `communeAdmins` et `controleurCodes` crees via les nouveaux endpoints backend.

## QA fonctionnelle (depuis `docs/CITOYEN_PEYI_FLOW_QA.md`)
- [ ] Flow super-admin OK
- [ ] Flow admin communal OK
- [ ] Flow controleur OK
- [ ] Flow citoyen + tentative de double vote bloque cote backend
- [ ] Health endpoints (`/api/health/live`, `/api/health/ready`) verifies depuis l'exterieur

## Securite
- [ ] Headers helmet verifies (`curl -I https://$API/api/health/live`).
- [ ] Rate-limit observe (10 reqs/min sur `/api/auth/*` provoquent un 429).
- [ ] Logs ne contiennent jamais `accessKey`, `Authorization`, `x-super-admin-key` (redacted par pino).
- [ ] Scan ZAP baseline lance contre l'API et le frontend.
