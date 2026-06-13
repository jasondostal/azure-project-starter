{% if cookiecutter.project_type != 'go-desktop' %}
using 'main.bicep'

// ── Core ──
param environment = 'dev'
param location = 'eastus'
param tenantId = '{{cookiecutter.azure_tenant_id}}'

{% if cookiecutter.include_sql %}
// ── SQL ──
param sqlAdminLogin = 'sqladmin'
param sqlAdminPassword = ''     // Secure — inject from Key Vault or variable group
{% endif %}

{% if cookiecutter.include_apim %}
// ── APIM auth ──
// Fill from .azure-guids.env after running scripts/setup-app-registrations.sh.
// Leave empty to deploy APIM without validate-jwt (open API) for first bring-up.
param internalApiClientId = ''
param m2mClientId = ''
{% endif %}
{% endif %}
