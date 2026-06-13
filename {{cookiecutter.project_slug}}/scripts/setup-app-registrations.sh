#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# setup-app-registrations.sh — create the Entra app registration(s) for
# {{cookiecutter.project_name}} and capture the REAL client IDs.
#
# WHY THIS EXISTS (and isn't Bicep):
#   Bicep has no Microsoft.Graph provider — it cannot create app registrations.
#   And the client ID (appId) is assigned BY Entra at creation time, so it can't
#   be pre-generated either. This script is the source of truth for that step:
#   it runs `az ad app create`, then writes the resulting REAL client IDs into
#   .azure-guids.env, which the Bicep params / APIM validate-jwt config consume.
#
#   .azure-guids.env is gitignored — client IDs are environment facts, not
#   source. Re-run this script per tenant; it is idempotent.
#
#   appRole GUIDs ARE caller-owned and must stay stable across reruns (so role
#   assignments survive), so they're derived deterministically from the project
#   name below — not random, not committed-as-fiction.
#
# Usage:
#   az login --tenant <your-tenant>
#   bash scripts/setup-app-registrations.sh [dev|qa|stage|prod]   # default: dev
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

ENVIRONMENT="${1:-dev}"
PROJECT="{{cookiecutter.project_name}}"
GUIDS_FILE="$(dirname "$0")/../.azure-guids.env"

command -v az >/dev/null  || { echo "✗ Azure CLI (az) not found"; exit 1; }
command -v python3 >/dev/null || { echo "✗ python3 not found (needed for stable role GUIDs)"; exit 1; }

# Deterministic, caller-owned appRole GUIDs (uuid5 over project+role → stable).
stable_guid() { python3 -c "import uuid,sys; print(uuid.uuid5(uuid.NAMESPACE_DNS, sys.argv[1]))" "$1"; }
ROLE_READER="$(stable_guid "${PROJECT}.Members.Reader")"
ROLE_WRITER="$(stable_guid "${PROJECT}.Members.Writer")"
ROLE_CALLER="$(stable_guid "${PROJECT}.API.Caller")"

APP_ROLES_JSON=$(cat <<JSON
[
  {"id":"${ROLE_READER}","allowedMemberTypes":["User"],"description":"Can read member data","displayName":"Member Reader","value":"Members.Reader","isEnabled":true},
  {"id":"${ROLE_WRITER}","allowedMemberTypes":["User"],"description":"Can read and write member data","displayName":"Member Writer","value":"Members.Writer","isEnabled":true},
  {"id":"${ROLE_CALLER}","allowedMemberTypes":["Application"],"description":"Machine-to-machine access","displayName":"API Caller","value":"API.Caller","isEnabled":true}
]
JSON
)

# upsert_app <display-name> → echoes the appId (creates if absent, idempotent).
upsert_app() {
  local display="$1"
  local existing
  existing=$(az ad app list --display-name "$display" --query "[0].appId" -o tsv 2>/dev/null || true)
  if [[ -n "$existing" ]]; then
    echo "  ↺ exists: $display ($existing)" >&2
    echo "$existing"
    return
  fi
  local app_id
  app_id=$(az ad app create \
    --display-name "$display" \
    --sign-in-audience AzureADMyOrg \
    --app-roles "$APP_ROLES_JSON" \
    --query appId -o tsv)
  echo "  ✓ created: $display ($app_id)" >&2
  echo "$app_id"
}

echo "→ Provisioning app registrations for ${PROJECT} (${ENVIRONMENT})..."
INTERNAL_API_CLIENT_ID=$(upsert_app "${PROJECT}-api-internal-${ENVIRONMENT}")
M2M_CLIENT_ID=$(upsert_app "${PROJECT}-api-m2m-${ENVIRONMENT}")

# Set the identifier URI on the internal API app (api://<appId>).
az ad app update --id "$INTERNAL_API_CLIENT_ID" \
  --identifier-uris "api://${INTERNAL_API_CLIENT_ID}" >/dev/null

# Write REAL client IDs to the gitignored env file (consumed by bicepparam).
{
  echo "# REAL Entra client IDs — written by setup-app-registrations.sh."
  echo "# Environment facts, NOT source. Gitignored. Re-run per tenant."
  echo "# tenant=$(az account show --query tenantId -o tsv 2>/dev/null) env=${ENVIRONMENT}"
  echo "INTERNAL_API_CLIENT_ID=${INTERNAL_API_CLIENT_ID}"
  echo "M2M_CLIENT_ID=${M2M_CLIENT_ID}"
} > "$GUIDS_FILE"

echo "✓ Wrote real client IDs to .azure-guids.env"
echo "  These feed the APIM validate-jwt / App Service EasyAuth config:"
echo "    INTERNAL_API_CLIENT_ID  → audience for the protected API"
echo "    M2M_CLIENT_ID           → machine-to-machine caller"
echo "  Wire them into your APIM auth params when you add the APIM module to infra/."
