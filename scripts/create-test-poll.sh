#!/usr/bin/env bash
# Cree une consultation de test via l'API backend.
#
# Variables requises :
#   ADMIN_ACCESS_KEY  Cle administrateur communal (ou bootstrap).
#   FIREBASE_API_KEY  Cle web Firebase (echange customToken -> idToken).
#
# Variables optionnelles :
#   API_BASE_URL      Defaut: https://citoyen-peyi-backend-up6de3cljq-ew.a.run.app
#   COMMUNE_ID        Defaut: lu depuis la reponse admin/exchange.
#   COMMUNE_NAME      Defaut: lu depuis la reponse admin/exchange.
#   PROJECT_TITLE     Defaut: "Test pipeline <date>"
#   QUESTION          Defaut: "Approuvez-vous le deploiement test ?"
#   OPEN_DATE         Defaut: aujourd'hui (YYYY-MM-DD)
#   CLOSE_DATE        Defaut: aujourd'hui + 7 jours
#   PUBLISH           Si "1", publie la consultation apres creation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

strip_optional_quotes() {
  local raw_value="$1"
  raw_value="${raw_value#"${raw_value%%[![:space:]]*}"}"
  raw_value="${raw_value%"${raw_value##*[![:space:]]}"}"
  local first_char="${raw_value:0:1}"
  local last_char="${raw_value: -1}"
  if [[ ${#raw_value} -ge 2 && "$first_char" == "$last_char" && ( "$first_char" == '"' || "$first_char" == "'" ) ]]; then
    raw_value="${raw_value:1:${#raw_value}-2}"
  fi
  printf '%s' "$raw_value"
}

read_env_value() {
  local env_file="$1"
  local key_name="$2"
  [[ -f "$env_file" ]] || return 0
  local env_line
  env_line="$(grep -E "^[[:space:]]*(export[[:space:]]+)?${key_name}=" "$env_file" | tail -n 1 || true)"
  [[ -n "$env_line" ]] || return 0
  strip_optional_quotes "${env_line#*${key_name}=}"
}

for env_file in "$REPO_DIR/.env" "$REPO_DIR/app/backend/.env" "$REPO_DIR/.backend-secrets.generated.txt"; do
  if [[ -z "${ADMIN_ACCESS_KEY:-}" ]]; then
    ADMIN_ACCESS_KEY="$(read_env_value "$env_file" ADMIN_ACCESS_KEY)"
  fi
  if [[ -z "${FIREBASE_API_KEY:-}" ]]; then
    FIREBASE_API_KEY="$(read_env_value "$env_file" FIREBASE_API_KEY)"
  fi
done

if [[ -z "${ADMIN_ACCESS_KEY:-}" && -f "$REPO_DIR/.auth-flow-smoke.local.json" ]] && command -v jq >/dev/null 2>&1; then
  ADMIN_ACCESS_KEY="$(jq -r '.admin.accessKey // empty' "$REPO_DIR/.auth-flow-smoke.local.json" 2>/dev/null || true)"
fi

if [[ -z "${ADMIN_ACCESS_KEY:-}" && -f "$REPO_DIR/.admin_access_key.local" ]]; then
  local_admin_key="$(grep -vE '^[[:space:]]*(#|$)' "$REPO_DIR/.admin_access_key.local" | head -n 1 || true)"
  if [[ "$local_admin_key" == *ADMIN_ACCESS_KEY=* ]]; then
    local_admin_key="${local_admin_key#*ADMIN_ACCESS_KEY=}"
  fi
  ADMIN_ACCESS_KEY="$(strip_optional_quotes "$local_admin_key")"
fi

if [[ -z "${FIREBASE_API_KEY:-}" && -f "$REPO_DIR/flutter_app/lib/firebase_options.dart" ]]; then
  FIREBASE_API_KEY="$(sed -n "s/.*apiKey: '\([^']*\)'.*/\1/p" "$REPO_DIR/flutter_app/lib/firebase_options.dart" | head -n 1)"
fi

: "${ADMIN_ACCESS_KEY:?ADMIN_ACCESS_KEY requis}"
: "${FIREBASE_API_KEY:?FIREBASE_API_KEY requis}"
API_BASE_URL="${API_BASE_URL:-https://citoyen-peyi-backend-up6de3cljq-ew.a.run.app}"

command -v jq >/dev/null || { echo "jq requis (sudo apt-get install -y jq)" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl requis" >&2; exit 1; }

fail_with_payload() {
  local step="$1"
  local payload="$2"
  echo "ECHEC_${step}" >&2
  if jq -e . >/dev/null 2>&1 <<<"$payload"; then
    jq . <<<"$payload" >&2
  else
    printf '%s\n' "$payload" >&2
  fi
  exit 1
}

today="$(date -u +%Y-%m-%d)"
plus7="$(date -u -d '+7 days' +%Y-%m-%d)"

PROJECT_TITLE="${PROJECT_TITLE:-Test pipeline ${today}}"
QUESTION="${QUESTION:-Approuvez-vous le deploiement test ?}"
OPEN_DATE="${OPEN_DATE:-$today}"
CLOSE_DATE="${CLOSE_DATE:-$plus7}"

echo "==> 1/4 Echange cle admin -> customToken"
exchange_payload="$(jq -nc --arg k "$ADMIN_ACCESS_KEY" '{accessKey:$k}')"
exchange_resp="$(curl -sS -X POST "$API_BASE_URL/api/auth/admin/exchange" \
  -H 'Content-Type: application/json' \
  -d "$exchange_payload")"

custom_token="$(jq -r '.customToken // empty' <<<"$exchange_resp")"
if [[ -z "$custom_token" ]]; then
  fail_with_payload "ADMIN_EXCHANGE" "$exchange_resp"
fi
COMMUNE_ID="${COMMUNE_ID:-$(jq -r '.profile.communeId // ""' <<<"$exchange_resp")}"
COMMUNE_NAME="${COMMUNE_NAME:-$(jq -r '.profile.communeName // ""' <<<"$exchange_resp")}"

if [[ -z "$COMMUNE_ID" ]]; then
  echo "COMMUNE_ID introuvable (profil bootstrap ?). Renseignez COMMUNE_ID=... avant de relancer." >&2
  exit 2
fi

echo "    commune: ${COMMUNE_NAME:-?} (${COMMUNE_ID})"

echo "==> 2/4 Echange customToken -> idToken (Firebase Auth REST)"
id_token_resp="$(curl -sS -X POST \
  "https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${FIREBASE_API_KEY}" \
  -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg t "$custom_token" '{token:$t,returnSecureToken:true}')")"

id_token="$(jq -r '.idToken // empty' <<<"$id_token_resp")"
if [[ -z "$id_token" ]]; then
  fail_with_payload "FIREBASE_CUSTOM_TOKEN" "$id_token_resp"
fi

echo "==> 3/4 Creation consultation"
poll_payload="$(jq -nc \
  --arg pt "$PROJECT_TITLE" \
  --arg q "$QUESTION" \
  --arg od "$OPEN_DATE" \
  --arg cd "$CLOSE_DATE" \
  --arg ci "$COMMUNE_ID" \
  --arg cn "$COMMUNE_NAME" \
  '{
     projectTitle:$pt,
     description:"Consultation de validation pipeline (creation auto).",
     question:$q,
     options:[{label:"Oui"},{label:"Non"}],
     targetPopulation:"Habitants test",
     openDate:$od,
     closeDate:$cd,
     communeId:$ci,
     communeName:$cn,
     totalVoters:1000
   }')"

create_resp="$(curl -sS -X POST "$API_BASE_URL/api/polls" \
  -H "Authorization: Bearer $id_token" \
  -H 'Content-Type: application/json' \
  -d "$poll_payload")"

poll_id="$(jq -r '.poll.id // empty' <<<"$create_resp")"
if [[ -z "$poll_id" ]]; then
  fail_with_payload "CREATE_POLL" "$create_resp"
fi
echo "    consultation creee: $poll_id"
final_status="$(jq -r '.poll.status // "draft"' <<<"$create_resp")"

if [[ "${PUBLISH:-0}" == "1" ]]; then
  echo "==> 4/4 Publication"
  publish_resp="$(curl -sS -X POST "$API_BASE_URL/api/polls/$poll_id/publish" \
    -H "Authorization: Bearer $id_token")"
  publish_status="$(jq -r '.poll.status // .status // empty' <<<"$publish_resp")"
  if [[ -z "$publish_status" ]]; then
    fail_with_payload "PUBLISH_POLL" "$publish_resp"
  fi
  final_status="$publish_status"
  echo "    statut: $publish_status"
else
  echo "==> 4/4 Publication ignoree (PUBLISH=1 pour activer)"
fi

echo
echo "OK. Consultation:"
jq --arg status "$final_status" '{id:.poll.id,projectTitle:.poll.projectTitle,status:$status,openDate:.poll.openDate,closeDate:.poll.closeDate,options:.poll.options}' <<<"$create_resp"
