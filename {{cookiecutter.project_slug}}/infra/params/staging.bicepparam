{% if cookiecutter.project_type != 'go-desktop' %}
using '../main.bicep'

// ── Core ──
param environment = 'stage'
param location = 'eastus'
param tenantId = '{{cookiecutter.azure_tenant_id}}'

{% if cookiecutter.include_sql %}
// ── SQL ──
param sqlAdminLogin = 'sqladmin'
param sqlAdminPassword = ''     // Secure — inject from Key Vault or variable group
{% endif %}

{% if cookiecutter.include_apim %}
// ── APIM auth ──
// Fill internalApiClientId / m2mClientId from .azure-guids.env after running
// scripts/setup-app-registrations.sh. Leave empty to deploy APIM without
// validate-jwt (open API) for first bring-up. Each validate-jwt block activates
// only when its client ID is set.
param internalApiClientId = ''
param m2mClientId = ''

// B2C lives in its own tenant — create the app reg there, then set these.
param b2cClientId = ''
param b2cTenantName = ''
param b2cSignInPolicy = 'B2C_1_signin'
{% endif %}
{% endif %}
