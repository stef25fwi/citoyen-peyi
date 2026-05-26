# Runbook production - Citoyen Peyi

## Architecture deployee

```
GitHub Pages (statique)         Cloud Run                 Firestore
  flutter_app/build/web   --->  citoyen-peyi-api  <--->   collections
       (HTTPS)                   (HTTPS, region eu)        + Admin SDK
                                       |
                                       v
                                Secret Manager
                                (SUPER_ADMIN_KEY,
                                 ADMIN_ACCESS_KEY,
                                 VOTE_ACCESS_TOKEN_SECRET,
                                 firebase service account)
```

## Variables et secrets requis

| Cible | Nom | Type | Source |
|---|---|---|---|
| Cloud Run env | `NODE_ENV=production` | env | workflow |
| Cloud Run env | `CORS_ORIGIN` | env | `vars.CORS_ORIGIN` |
| Cloud Run env | `API_BASE_URL` | env | `vars.API_BASE_URL` |
| Cloud Run env | `LOG_LEVEL=info` | env | workflow |
| Cloud Run secret | `SUPER_ADMIN_KEY` | Secret Manager | `SUPER_ADMIN_KEY:latest` |
| Cloud Run secret | `ADMIN_ACCESS_KEY` | Secret Manager | `ADMIN_ACCESS_KEY:latest` |
| Cloud Run secret | `VOTE_ACCESS_TOKEN_SECRET` | Secret Manager | idem |
| Cloud Run identity | service account avec Firestore User | IAM | `GCP_RUNTIME_SERVICE_ACCOUNT` |
| GitHub Actions | `GCP_PROJECT_ID`, `GCP_REGION`, `FIREBASE_PROJECT_ID`, `CORS_ORIGIN`, `API_BASE_URL` | repo `vars` |  |
| GitHub Actions | `GCP_WORKLOAD_IDENTITY_PROVIDER`, `GCP_DEPLOY_SERVICE_ACCOUNT`, `GCP_RUNTIME_SERVICE_ACCOUNT` | repo `secrets` |  |
| GitHub Pages | `FIREBASE_*` (6 secrets) | repo `secrets` |  |

## Rotation de cle (operation courante)

### `SUPER_ADMIN_KEY`

1. Generer une nouvelle valeur: `openssl rand -base64 48 | tr -d '\n='`
2. `gcloud secrets versions add SUPER_ADMIN_KEY --data-file=- <<< "$NEW_KEY"`
3. `gcloud run services update citoyen-peyi-api --region=eu-west1 --update-secrets=SUPER_ADMIN_KEY=SUPER_ADMIN_KEY:latest`
4. Informer les super-admins de re-saisir la cle a la prochaine connexion.

### `VOTE_ACCESS_TOKEN_SECRET`

Attention: tous les tokens citoyens en cours sont invalides (TTL 30 min de toute facon).

1. Generer: `openssl rand -base64 64 | tr -d '\n='`
2. Pousser dans Secret Manager comme ci-dessus.
3. Redeployer le service Cloud Run pour prendre la nouvelle version.

### Service account Firebase

1. Generer une nouvelle cle dans la console Firebase.
2. Importer dans Secret Manager.
3. Mettre a jour le mount du secret dans Cloud Run.
4. Revoquer l'ancienne cle dans la console.

## Revoquer un code citoyen compromis

```bash
curl -X POST "$API/api/citizen-access/codes/AB12CD34/revoke" \
  -H "Authorization: Bearer $SUPER_ID_TOKEN" \
  -H "x-super-admin-key: $SUPER_ADMIN_KEY" \
  -H "Content-Type: application/json" \
  -d '{"reason":"Demande citoyen, code partage"}'
```

## Healthcheck

- Liveness: `GET /api/health/live` (toujours 200 si le process tourne)
- Readiness: `GET /api/health/ready` (200 si Firestore reachable + config OK,
  503 sinon). Utilise par Cloud Run.

## Sauvegarde Firestore

Cron quotidien GCS:

```bash
gcloud firestore export gs://citoyen-peyi-backups/$(date +%Y%m%d) \
  --project=$GCP_PROJECT_ID
```

Restauration: `gcloud firestore import gs://citoyen-peyi-backups/<date>`.

## Bascule deploiement

1. Push sur `main` declenche en parallele:
   - `Deploy backend (Cloud Run)` (si `app/backend/**` modifie)
   - `Deploy Firestore rules` (si `firestore.rules` modifie)
   - `Deploy to GitHub Pages` (Flutter)
2. Verifier `gcloud run services describe citoyen-peyi-api` (revision active).
3. Smoke test:
   - `curl https://$API/api/health/ready` -> `{"ok":true}`
   - Connexion super-admin reelle, creation poll de test, vote.

## Incident: backend KO

1. `gcloud logging read 'resource.type="cloud_run_revision" severity>=ERROR' --limit=50`
2. Si exception: lire le trace dans les logs structures pino.
3. Rollback: `gcloud run services update-traffic citoyen-peyi-api --to-revisions=<previous>=100`

## Incident: votes bloques

1. Verifier que `/api/vote-access/validate` repond.
2. Verifier les regles Firestore via `firebase emulators:exec` en local.
3. Verifier que les `VOTE_ACCESS_TOKEN_SECRET` n'ont pas tourne sans
   redemarrage du service (tokens anciens deviennent invalides).

## Pre-bascule (checklist)

- [ ] Tous les secrets en place sur Secret Manager
- [ ] Firestore rules deployees (`firebase deploy --only firestore:rules`)
- [ ] Backup Firestore active
- [ ] DNS pointe sur Cloud Run via domain mapping
- [ ] `CORS_ORIGIN` couvre uniquement le domaine prod du frontend
- [ ] `API_BASE_URL` GitHub var pointe sur le domaine API prod HTTPS
- [ ] Tous les codes contoleur `ADMIN2026` purgees de Firestore
- [ ] Sentry / Cloud Monitoring brancher (alertes p95 > 1s, 5xx > 1%)
- [ ] QA flow citoyen + controleur + admin + super-admin OK
