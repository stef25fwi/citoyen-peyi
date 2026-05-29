#!/usr/bin/env bash
# Verifie le flow de connexion super admin -> admin communal -> agent -> citoyen.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
API_BASE_URL="${API_BASE_URL:-https://citoyen-peyi-backend-up6de3cljq-ew.a.run.app}"
OUT_FILE="${OUT_FILE:-$REPO_DIR/.auth-flow-smoke.local.json}"

command -v jq >/dev/null || { echo "jq requis" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl requis" >&2; exit 1; }

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

load_local_defaults() {
  local env_file
  for env_file in "$REPO_DIR/.env" "$REPO_DIR/app/backend/.env" "$REPO_DIR/.backend-secrets.generated.txt"; do
    if [[ -z "${ADMIN_ACCESS_KEY:-}" ]]; then
      ADMIN_ACCESS_KEY="$(read_env_value "$env_file" ADMIN_ACCESS_KEY)"
    fi
    if [[ -z "${SUPER_ADMIN_KEY:-}" ]]; then
      SUPER_ADMIN_KEY="$(read_env_value "$env_file" SUPER_ADMIN_KEY)"
    fi
    if [[ -z "${FIREBASE_API_KEY:-}" ]]; then
      FIREBASE_API_KEY="$(read_env_value "$env_file" FIREBASE_API_KEY)"
    fi
  done

  if [[ -z "${ADMIN_ACCESS_KEY:-}" && -f "$REPO_DIR/.auth-flow-smoke.local.json" ]]; then
    ADMIN_ACCESS_KEY="$(jq -r '.admin.accessKey // empty' "$REPO_DIR/.auth-flow-smoke.local.json" 2>/dev/null || true)"
  fi

  if [[ -z "${ADMIN_ACCESS_KEY:-}" && -f "$REPO_DIR/.admin_access_key.local" ]]; then
    local local_admin_key
    local_admin_key="$(grep -vE '^[[:space:]]*(#|$)' "$REPO_DIR/.admin_access_key.local" | head -n 1 || true)"
    if [[ "$local_admin_key" == *ADMIN_ACCESS_KEY=* ]]; then
      local_admin_key="${local_admin_key#*ADMIN_ACCESS_KEY=}"
    fi
    ADMIN_ACCESS_KEY="$(strip_optional_quotes "$local_admin_key")"
  fi

  if [[ -z "${FIREBASE_API_KEY:-}" && -f "$REPO_DIR/flutter_app/lib/firebase_options.dart" ]]; then
    FIREBASE_API_KEY="$(sed -n "s/.*apiKey: '\([^']*\)'.*/\1/p" "$REPO_DIR/flutter_app/lib/firebase_options.dart" | head -n 1)"
  fi
}

mask_secret() {
  local secret_value="$1"
  local visible_chars="${2:-4}"
  local secret_length="${#secret_value}"
  if [[ "$secret_length" -le $((visible_chars * 2)) ]]; then
    printf '[masque]'
    return
  fi
  printf '%s...%s' "${secret_value:0:visible_chars}" "${secret_value: -visible_chars}"
}

fail_with_payload() {
  local step_name="$1"
  local payload="$2"
  echo "ECHEC_${step_name}" >&2
  if jq -e . >/dev/null 2>&1 <<<"$payload"; then
    jq 'del(.customToken, .idToken, .refreshToken, .accessKey, .controller.code, .accessCode.accessCode)' <<<"$payload" >&2
  else
    printf '%s\n' "$payload" >&2
  fi
  exit 1
}

exchange_custom_token_for_id_token() {
  local custom_token="$1"
  local step_name="$2"
  local id_token_resp
  id_token_resp="$(curl -sS -X POST \
    "https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${FIREBASE_API_KEY}" \
    -H 'Content-Type: application/json' \
    -d "$(jq -nc --arg token "$custom_token" '{token:$token,returnSecureToken:true}')")"
  local id_token
  id_token="$(jq -r '.idToken // empty' <<<"$id_token_resp")"
  if [[ -z "$id_token" ]]; then
    fail_with_payload "$step_name" "$id_token_resp"
  fi
  printf '%s' "$id_token"
}

ensure_super_id_token() {
  if [[ -n "${super_id_token:-}" ]]; then
    return
  fi
  if [[ -z "${SUPER_ADMIN_KEY:-}" ]]; then
    fail_with_payload "SUPER_EXCHANGE" '{"message":"SUPER_ADMIN_KEY requis pour verifier la liste superadmin des agents."}'
  fi

  local super_exchange_resp
  local super_custom_token
  super_exchange_resp="$(curl -sS -X POST "$API_BASE_URL/api/auth/super/exchange" \
    -H 'Content-Type: application/json' \
    -H "x-super-admin-key: $SUPER_ADMIN_KEY" \
    -d '{}')"
  super_custom_token="$(jq -r '.customToken // empty' <<<"$super_exchange_resp")"
  if [[ -z "$super_custom_token" ]]; then
    fail_with_payload "SUPER_EXCHANGE" "$super_exchange_resp"
  fi
  super_id_token="$(exchange_custom_token_for_id_token "$super_custom_token" SUPER_FIREBASE_TOKEN)"
}

try_admin_exchange() {
  local candidate_key="$1"
  ADMIN_EXCHANGE_RESP="$(curl -sS -X POST "$API_BASE_URL/api/auth/admin/exchange" \
    -H 'Content-Type: application/json' \
    -d "$(jq -nc --arg access_key "$candidate_key" '{accessKey:$access_key}')")"
  ADMIN_CUSTOM_TOKEN="$(jq -r '.customToken // empty' <<<"$ADMIN_EXCHANGE_RESP")"
  ADMIN_COMMUNE_ID="$(jq -r '.profile.communeId // ""' <<<"$ADMIN_EXCHANGE_RESP")"
  ADMIN_COMMUNE_NAME="$(jq -r '.profile.communeName // ""' <<<"$ADMIN_EXCHANGE_RESP")"
  [[ -n "$ADMIN_CUSTOM_TOKEN" && -n "$ADMIN_COMMUNE_ID" ]]
}

load_local_defaults

if [[ -z "${FIREBASE_API_KEY:-}" ]]; then
  echo "FIREBASE_API_KEY requis ou firebase_options.dart introuvable." >&2
  exit 1
fi

timestamp="$(date -u +%Y%m%d%H%M%S)"
commune_code="${COMMUNE_ID:-qa-${timestamp}}"
commune_name="${COMMUNE_NAME:-Commune QA Citoyen Peyi}"
admin_label="Admin communal QA ${timestamp}"
admin_source="local_admin_key"
admin_access_key="${ADMIN_ACCESS_KEY:-}"

echo "==> 1/9 Connexion admin communal"
if [[ -z "$admin_access_key" ]] || ! try_admin_exchange "$admin_access_key"; then
  echo "    cle admin locale indisponible ou invalide, tentative super admin"
  if [[ -z "${SUPER_ADMIN_KEY:-}" ]]; then
    fail_with_payload "ADMIN_EXCHANGE" "${ADMIN_EXCHANGE_RESP:-{"message":"SUPER_ADMIN_KEY requis pour creer un admin communal."}}"
  fi

  echo "==> 2/9 Connexion super admin et creation admin communal"
  super_exchange_resp="$(curl -sS -X POST "$API_BASE_URL/api/auth/super/exchange" \
    -H 'Content-Type: application/json' \
    -H "x-super-admin-key: $SUPER_ADMIN_KEY" \
    -d '{}')"
  super_custom_token="$(jq -r '.customToken // empty' <<<"$super_exchange_resp")"
  if [[ -z "$super_custom_token" ]]; then
    fail_with_payload "SUPER_EXCHANGE" "$super_exchange_resp"
  fi
  super_id_token="$(exchange_custom_token_for_id_token "$super_custom_token" SUPER_FIREBASE_TOKEN)"

  create_admin_resp="$(curl -sS -X POST "$API_BASE_URL/api/admins" \
    -H "Authorization: Bearer $super_id_token" \
    -H "x-super-admin-key: $SUPER_ADMIN_KEY" \
    -H 'Content-Type: application/json' \
    -d "$(jq -nc \
      --arg label "$admin_label" \
      --arg commune_name "$commune_name" \
      --arg commune_code "$commune_code" \
      '{label:$label,communeName:$commune_name,communeCode:$commune_code,codePostal:"QA"}')")"
  admin_access_key="$(jq -r '.accessKey // empty' <<<"$create_admin_resp")"
  if [[ -z "$admin_access_key" ]]; then
    fail_with_payload "CREATE_ADMIN" "$create_admin_resp"
  fi
  admin_source="created_from_super_admin"
  try_admin_exchange "$admin_access_key" || fail_with_payload "ADMIN_EXCHANGE_CREATED" "$ADMIN_EXCHANGE_RESP"
else
  echo "==> 2/9 Connexion super admin ignoree (admin communal local valide)"
fi

admin_id_token="$(exchange_custom_token_for_id_token "$ADMIN_CUSTOM_TOKEN" ADMIN_FIREBASE_TOKEN)"
commune_code="$ADMIN_COMMUNE_ID"
commune_name="${ADMIN_COMMUNE_NAME:-$commune_name}"
echo "    admin communal OK: $commune_name ($commune_code)"

echo "==> 3/9 Creation consultation type"
today="$(date -u +%Y-%m-%d)"
plus14="$(date -u -d '+14 days' +%Y-%m-%d)"
project_title="${PROJECT_TITLE:-Consultation type Citoyen Peyi ${today}}"
question="${QUESTION:-Quelle priorite communale souhaitez-vous voir avancer en premier ?}"
create_poll_resp="$(curl -sS -X POST "$API_BASE_URL/api/polls" \
  -H "Authorization: Bearer $admin_id_token" \
  -H 'Content-Type: application/json' \
  -d "$(jq -nc \
    --arg project_title "$project_title" \
    --arg question "$question" \
    --arg open_date "$today" \
    --arg close_date "$plus14" \
    --arg commune_id "$commune_code" \
    --arg commune_name "$commune_name" \
    '{projectTitle:$project_title,description:"Consultation type creee automatiquement pour verifier le flow de connexion.",question:$question,options:[{label:"Voirie et espaces publics"},{label:"Actions jeunesse"},{label:"Cadre de vie et proprete"}],targetPopulation:"Habitants de la commune",openDate:$open_date,closeDate:$close_date,communeId:$commune_id,communeName:$commune_name,totalVoters:1000}')")"
poll_id="$(jq -r '.poll.id // empty' <<<"$create_poll_resp")"
if [[ -z "$poll_id" ]]; then
  fail_with_payload "CREATE_POLL" "$create_poll_resp"
fi

echo "==> 4/9 Publication consultation"
publish_resp="$(curl -sS -X POST "$API_BASE_URL/api/polls/$poll_id/publish" \
  -H "Authorization: Bearer $admin_id_token")"
poll_status="$(jq -r '.poll.status // .status // empty' <<<"$publish_resp")"
if [[ "$poll_status" != "active" ]]; then
  fail_with_payload "PUBLISH_POLL" "$publish_resp"
fi
echo "    consultation OK: $poll_id ($poll_status)"

echo "==> 5/9 Verification consultations super admin"
ensure_super_id_token
super_polls_resp="$(curl -sS -X GET "$API_BASE_URL/api/polls" \
  -H "Authorization: Bearer $super_id_token")"
listed_poll_id="$(jq -r --arg poll_id "$poll_id" '.polls[]? | select(.id == $poll_id) | .id' <<<"$super_polls_resp" | head -n 1)"
if [[ "$listed_poll_id" != "$poll_id" ]]; then
  fail_with_payload "SUPER_ADMIN_ACTIVE_POLLS_LIST" "$super_polls_resp"
fi
corrected_project_title="${project_title} - texte verifie"
patch_poll_resp="$(curl -sS -X PATCH "$API_BASE_URL/api/polls/$poll_id" \
  -H "Authorization: Bearer $super_id_token" \
  -H 'Content-Type: application/json' \
  -d "$(jq -nc \
    --arg project_title "$corrected_project_title" \
    --arg description "Consultation type creee automatiquement puis corrigee par verification superadmin." \
    --arg question "$question" \
    '{projectTitle:$project_title,description:$description,question:$question}')")"
patch_ok="$(jq -r '.ok // false' <<<"$patch_poll_resp")"
if [[ "$patch_ok" != "true" ]]; then
  fail_with_payload "SUPER_ADMIN_PATCH_POLL_TEXT" "$patch_poll_resp"
fi
project_title="$corrected_project_title"
echo "    consultations superadmin OK: liste + correction texte"

echo "==> 6/9 Creation et connexion agent"
controller_label="Agent mobilisation QA ${timestamp}"
create_controller_resp="$(curl -sS -X POST "$API_BASE_URL/api/controllers" \
  -H "Authorization: Bearer $admin_id_token" \
  -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg label "$controller_label" --arg commune_name "$commune_name" '{label:$label,communeName:$commune_name}')")"
controller_code="$(jq -r '.controller.code // empty' <<<"$create_controller_resp")"
if [[ -z "$controller_code" ]]; then
  fail_with_payload "CREATE_CONTROLLER" "$create_controller_resp"
fi
controller_exchange_resp="$(curl -sS -X POST "$API_BASE_URL/api/auth/controller/exchange" \
  -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg code "$controller_code" '{code:$code}')")"
controller_custom_token="$(jq -r '.customToken // empty' <<<"$controller_exchange_resp")"
if [[ -z "$controller_custom_token" ]]; then
  fail_with_payload "CONTROLLER_EXCHANGE" "$controller_exchange_resp"
fi
controller_id_token="$(exchange_custom_token_for_id_token "$controller_custom_token" CONTROLLER_FIREBASE_TOKEN)"
echo "    agent OK: $(mask_secret "$controller_code")"

echo "==> 7/9 Verification liste agents super admin"
ensure_super_id_token
controllers_list_resp="$(curl -sS -X GET "$API_BASE_URL/api/controllers" \
  -H "Authorization: Bearer $super_id_token")"
listed_controller_id="$(jq -r --arg controller_code "$controller_code" '.controllers[]? | select(.id == $controller_code) | .id' <<<"$controllers_list_resp" | head -n 1)"
if [[ "$listed_controller_id" != "$controller_code" ]]; then
  fail_with_payload "SUPER_ADMIN_CONTROLLERS_LIST" "$controllers_list_resp"
fi
echo "    liste superadmin OK: agent present"

echo "==> 8/9 Generation code citoyen"
citizen_code_resp='{}'
citizen_access_code=''
for attempt in 1 2 3 4 5; do
  birth_year="$(printf '%04d' $((1920 + RANDOM % 80)))"
  phone_suffix="$(printf '%02d' $((RANDOM % 100)))"
  citizen_code_resp="$(curl -sS -X POST "$API_BASE_URL/api/citizen-access/codes" \
    -H "Authorization: Bearer $controller_id_token" \
    -H 'Content-Type: application/json' \
    -d "$(jq -nc \
      --arg birth_year "$birth_year" \
      --arg phone_suffix "$phone_suffix" \
      '{firstName:"Q",lastName:"A",birthYear:$birth_year,phoneSuffix:$phone_suffix,duplicateReason:"new_citizen_code_creation",verification:{hasIdentityDocument:true,hasResidenceProof:true,communeEligibilityChecked:true}}')")"
  citizen_access_code="$(jq -r '.accessCode.accessCode // empty' <<<"$citizen_code_resp")"
  [[ -n "$citizen_access_code" ]] && break
done
if [[ -z "$citizen_access_code" ]]; then
  fail_with_payload "CREATE_CITIZEN_CODE" "$citizen_code_resp"
fi
echo "    code citoyen genere: $(mask_secret "$citizen_access_code")"

echo "==> 9/9 Validation code citoyen sur la consultation"
validate_resp="$(curl -sS -X POST "$API_BASE_URL/api/vote-access/validate" \
  -H 'Content-Type: application/json' \
  -d "$(jq -nc --arg code "$citizen_access_code" --arg poll_id "$poll_id" '{code:$code,pollId:$poll_id}')")"
validate_ok="$(jq -r '.ok // false' <<<"$validate_resp")"
validated_poll_id="$(jq -r --arg poll_id "$poll_id" '.eligiblePolls[]? | select(.pollId == $poll_id) | .pollId' <<<"$validate_resp" | head -n 1)"
if [[ "$validate_ok" != "true" || "$validated_poll_id" != "$poll_id" ]]; then
  fail_with_payload "VALIDATE_CITIZEN_CODE" "$validate_resp"
fi
echo "    code citoyen OK pour: $validated_poll_id"

umask 077
jq -n \
  --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg api_base_url "$API_BASE_URL" \
  --arg admin_source "$admin_source" \
  --arg admin_access_key "$admin_access_key" \
  --arg commune_id "$commune_code" \
  --arg commune_name "$commune_name" \
  --arg poll_id "$poll_id" \
  --arg poll_status "$poll_status" \
  --arg project_title "$project_title" \
  --arg controller_code "$controller_code" \
  --arg citizen_access_code "$citizen_access_code" \
  '{createdAt:$created_at,apiBaseUrl:$api_base_url,admin:{source:$admin_source,accessKey:$admin_access_key},commune:{id:$commune_id,name:$commune_name},poll:{id:$poll_id,status:$poll_status,projectTitle:$project_title},controller:{code:$controller_code,visibleToSuperAdmin:true},citizen:{accessCode:$citizen_access_code}}' \
  > "$OUT_FILE"

echo
echo "OK. Flow complet verifie. Valeurs completes: $OUT_FILE"