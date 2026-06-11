# Operations & Runbook — Citoyen Peyi (backend Cloud Run)

Ce document décrit la configuration de production, les opérations courantes, et le
chemin pas-à-pas pour atteindre un niveau **10/10** de robustesse.

- **Projet GCP** : `citoyen-peyi`
- **Région** : `europe-west1`
- **Service Cloud Run** : `citoyen-peyi-backend`
- **URL backend** : `https://citoyen-peyi-backend-up6de3cljq-ew.a.run.app`
- **Frontend** : `https://stef25fwi.github.io` (Flutter web, GitHub Pages)
- **Comptes de service** :
  - Déploiement (CI, via Workload Identity) : `github-deploy@citoyen-peyi.iam.gserviceaccount.com`
  - Runtime (identité du conteneur Cloud Run) : `1087566305566-compute@developer.gserviceaccount.com`

---

## 1. Pré-requis IAM (à faire une fois)

Le SA de déploiement doit pouvoir **agir en tant que** le SA runtime, et le SA runtime
doit pouvoir **lire les secrets**. Sans ça, `gcloud run deploy` échoue.

```bash
PROJECT=citoyen-peyi
DEPLOY_SA=github-deploy@citoyen-peyi.iam.gserviceaccount.com
RUNTIME_SA=1087566305566-compute@developer.gserviceaccount.com

# (a) Le SA de deploiement peut "actAs" le SA runtime
gcloud iam service-accounts add-iam-policy-binding "$RUNTIME_SA" \
  --member="serviceAccount:$DEPLOY_SA" \
  --role="roles/iam.serviceAccountUser" --project="$PROJECT"

# (b) Le SA runtime peut lire tous les secrets de l'app (niveau projet)
gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="serviceAccount:$RUNTIME_SA" \
  --role="roles/secretmanager.secretAccessor"

# (c) Le SA runtime peut signer les custom tokens Firebase (createCustomToken)
gcloud iam service-accounts add-iam-policy-binding "$RUNTIME_SA" \
  --member="serviceAccount:$RUNTIME_SA" \
  --role="roles/iam.serviceAccountTokenCreator" --project="$PROJECT"
```

---

## 2. Configuration requise (GitHub)

### Secrets GitHub (Settings → Secrets and variables → Actions → Secrets)
| Nom | Rôle |
|---|---|
| `GCP_WORKLOAD_IDENTITY_PROVIDER` | Fournisseur WIF pour l'auth CI |
| `GCP_DEPLOY_SERVICE_ACCOUNT` | `github-deploy@…` (sans espace/retour parasite !) |
| `GCP_RUNTIME_SERVICE_ACCOUNT` | `1087566305566-compute@…` (sans espace/retour parasite !) |

### Variables GitHub (Settings → Secrets and variables → Actions → Variables)
| Nom | Valeur |
|---|---|
| `GCP_PROJECT_ID` | `citoyen-peyi` |
| `GCP_REGION` | `europe-west1` |
| `CORS_ORIGIN` | `https://citoyen-peyi.web.app,https://citoyen-peyi.firebaseapp.com,https://stef25fwi.github.io` |
| `API_BASE_URL` | URL du backend Cloud Run |
| `RATE_LIMIT_REDIS_URL` | *(optionnel — voir §6)* |

### Secrets Secret Manager (montés dans le conteneur)
Requis : `SUPER_ADMIN_KEY`, `VOTE_ACCESS_TOKEN_SECRET`, `ACCESS_CODE_PEPPER`,
`CITIZEN_FINGERPRINT_PEPPER`, `PARTICIPATION_PEPPER`.
Optionnels : `ADMIN_ACCESS_KEY`, `ADMIN_ACCESS_PEPPER`, `CONTROLLER_CODE_PEPPER`.

> ⚠️ En production, `validateEnv()` exige : chaque clé/pepper ≥ 32 caractères, les
> **5 peppers tous distincts**, et `CORS_ORIGIN` uniquement en HTTPS. Le conteneur
> refuse de démarrer sinon (fail-safe).

Créer un secret manquant (valeur forte et distincte) :
```bash
printf '%s' "$(openssl rand -hex 32)" | \
  gcloud secrets create PARTICIPATION_PEPPER --data-file=- --project=citoyen-peyi
```

---

## 3. Déployer le backend

Le workflow `.github/workflows/deploy-backend.yml` se déclenche sur push `main`
touchant `app/backend/**` ou le workflow lui-même, ou via **Actions → Deploy backend
→ Run workflow**. Il : (1) lance les **tests backend (gate bloquant)**, (2) build +
push l'image, (3) déploie sur Cloud Run.

Les secrets sont montés en `:latest` → **une rotation n'est prise en compte qu'au
prochain déploiement**.

---

## 4. Rotation d'une clé / secret

```bash
# 1. Ajouter une nouvelle version
printf '%s' "$(openssl rand -hex 32)" | \
  gcloud secrets versions add SUPER_ADMIN_KEY --data-file=- --project=citoyen-peyi

# 2. Récupérer la nouvelle valeur (NE PAS la coller dans un chat/issue)
gcloud secrets versions access latest --secret=SUPER_ADMIN_KEY --project=citoyen-peyi

# 3. Redéployer pour activer :latest (Run workflow ou push backend)

# 4. Désactiver l'ancienne version (réversible)
gcloud secrets versions disable 1 --secret=SUPER_ADMIN_KEY --project=citoyen-peyi
```

---

## 5. Vérifier la santé / tester l'auth super admin

```bash
URL=https://citoyen-peyi-backend-up6de3cljq-ew.a.run.app

# Santé : doit renvoyer "ok":true partout
curl -sS "$URL/api/health/ready"

# CORS preflight depuis GitHub Pages : 204 + un seul access-control-allow-origin
curl -i -sS -X OPTIONS "$URL/api/auth/super/exchange" \
  -H "Origin: https://stef25fwi.github.io" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type,x-super-admin-key" \
  | grep -iE "HTTP/|access-control-"

# Mauvaise clé -> 401 (prouve que l'auth est atteinte) ; vraie clé -> 200 + customToken
curl -i -sS -X POST "$URL/api/auth/super/exchange" \
  -H "Origin: https://stef25fwi.github.io" \
  -H "x-super-admin-key: <CLE>" | head -n 5
```

---

## 6. ✅ Chemin vers 10/10

État actuel ≈ **9/10**. Les trois étapes ci-dessous ferment les derniers écarts.

### 6.1 Rate-limiting partagé via Redis (le point principal)
Aujourd'hui sans `RATE_LIMIT_REDIS_URL`, le rate-limiter est **en mémoire** (par
instance, remis à zéro au cold start). Le code (`src/middlewares/rateLimit.js`) bascule
automatiquement sur Redis si la variable est présente.

```bash
# Option A — Memorystore (Redis géré GCP, même région)
gcloud redis instances create citoyen-peyi-ratelimit \
  --size=1 --region=europe-west1 --redis-version=redis_7_0 \
  --project=citoyen-peyi
# Récupérer l'IP/host puis composer redis://HOST:6379
# (Memorystore exige un connecteur VPC : --vpc-connector au deploy, voir doc Cloud Run)

# Option B — Upstash (Redis serverless, plus simple, URL TLS rediss://)
#   Créer une base sur upstash.com, récupérer l'URL rediss://...
```
Puis : définir la **variable de dépôt** GitHub `RATE_LIMIT_REDIS_URL`, et redéployer.
Vérifier l'absence du warning `rate_limit_memory_store_fallback` dans les logs.

> Memorystore nécessite un connecteur VPC Serverless (`gcloud compute networks
> vpc-access connectors create …` + `--vpc-connector` au `gcloud run deploy`).
> Upstash (TLS public) évite le VPC et est plus rapide à mettre en place.

### 6.2 Startup probe Cloud Run sur `/api/health/ready`
Le `HEALTHCHECK` du Dockerfile est **ignoré** par Cloud Run (qui fait un probe TCP par
défaut). Configurer un probe HTTP de démarrage rend les déploiements plus sûrs :

```bash
gcloud run deploy citoyen-peyi-backend --region=europe-west1 --project=citoyen-peyi \
  --image=<IMAGE_ACTUELLE> \
  --startup-probe=httpGet.path=/api/health/ready,httpGet.port=8080,initialDelaySeconds=5,periodSeconds=5,failureThreshold=6
```
*(ou via l'onglet « Health checks » de la révision dans la console Cloud Run).*

### 6.3 Seuil de couverture des tests
Mesurer et fixer un plancher sur les routes d'auth :
```bash
node --test --experimental-test-coverage app/backend/test
```
Ajouter une étape de couverture au job `test` de `deploy-backend.yml` et/ou à `ci.yml`,
avec un seuil (ex. lignes ≥ 70 % sur `src/routes` et `src/middlewares`).

---

## 7. Dépannage rapide (erreurs déjà rencontrées)

| Symptôme (log) | Cause | Correctif |
|---|---|---|
| `PERMISSION_DENIED iam.serviceaccounts.actAs` | binding §1(a) manquant | appliquer §1(a) |
| `Unsupported service account` | espace/retour dans le secret SA | nettoyer la valeur (le workflow trim déjà) |
| `Permission denied on secret …` | accessor §1(b) manquant | appliquer §1(b) |
| `container failed to start on PORT 8080` | crash boot (voir logs révision) | lire `gcloud logging read … revision_name="…"` |
| `Configuration backend invalide: PARTICIPATION_PEPPER …` | secret non monté / manquant | créer + monter le secret |
| `Configuration backend invalide: Firebase Admin …` | `GOOGLE_CLOUD_PROJECT` absent | injecté par le workflow (`--set-env-vars`) |
| `Cle super administrateur invalide.` (401) | clé erronée (auth OK) | utiliser la bonne clé |

Lire les logs d'une révision qui crashe :
```bash
gcloud logging read \
  'resource.type="cloud_run_revision" AND resource.labels.revision_name="<REVISION>"' \
  --project=citoyen-peyi --limit=50 --freshness=2h \
  --format='table(timestamp, severity, textPayload)'
```
