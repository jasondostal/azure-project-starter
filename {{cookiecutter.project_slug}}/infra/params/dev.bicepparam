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
{% endif %}
