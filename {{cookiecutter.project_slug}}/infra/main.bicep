{% if cookiecutter.project_type != 'go-desktop' %}
targetScope = 'subscription'

// ═══════════════════════════════════════════════════════════════════════════
// {{cookiecutter.project_name}} — main.bicep
//
// Orchestrator that wires platform modules for this app, per environment.
// Consumes modules from azure-platform-iac (checked out alongside).
//
// Generated from azure-project-starter ({{cookiecutter.project_type}} archetype).
// ═══════════════════════════════════════════════════════════════════════════

@description('Environment name: dev, qa, stage, prod')
@allowed(['dev', 'qa', 'stage', 'prod'])
param environment string

@description('Azure region')
param location string = 'eastus'

@description('Base name for all resources')
param appName string = '{{cookiecutter.project_name}}'

@description('Tenant ID (Entra ID directory)')
param tenantId string = '{{cookiecutter.azure_tenant_id}}'

{% if cookiecutter.include_apim %}
@description('Internal API Entra app registration client ID. Run scripts/setup-app-registrations.sh, then set per env from .azure-guids.env. Empty = no Entra auth on the API.')
param internalApiClientId string = ''

@description('M2M client-credential app registration client ID (optional). Empty = no client-credential auth.')
param m2mClientId string = ''

@description('Azure AD B2C app registration client ID (external/partner users). Empty = no B2C auth. B2C lives in its OWN tenant — create the app there, not via setup-app-registrations.sh.')
param b2cClientId string = ''

@description('B2C tenant name — the <name> in <name>.b2clogin.com (e.g. contosob2c)')
param b2cTenantName string = ''

@description('B2C sign-in user-flow / policy name')
param b2cSignInPolicy string = 'B2C_1_signin'
{% endif %}

// ── Resource Group ──────────────────────────────────────────────────────────

var resourceGroupName = 'rg-${appName}-${environment}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: {
    environment: environment
    app: appName
    managedBy: 'azure-platform-iac'
    team: '{{cookiecutter.team_name}}'
  }
}

{% if cookiecutter.include_cosmos %}
// Cosmos DB account name (globally unique, deterministic) + endpoint. The endpoint
// is computed from the name so the app can be configured without depending on the
// Cosmos resource — avoids a circular dependency with the data-plane role assignment.
var cosmosAccountName = take('${toLower(replace(appName, '-', ''))}cosmos${uniqueString(resourceGroup.id)}', 44)
var cosmosEndpoint = 'https://${cosmosAccountName}.documents.azure.com:443/'
{% endif %}

{% if cookiecutter.project_type == 'python-function' %}
// ═══════════════════════════════════════════════════════════════════════════
// Function App (Python serverless)
// ═══════════════════════════════════════════════════════════════════════════
module appServicePlan '../../azure-platform-iac/modules/compute/app-service-plan.bicep' = {
  name: '${appName}-asp-${environment}'
  scope: resourceGroup
  params: {
    name: '${appName}-asp-${environment}'
    location: location
    skuName: (environment == 'prod' ? 'S1' : 'B1')
    skuTier: (environment == 'prod' ? 'Standard' : 'Basic')
    environment: environment
    osKind: 'linux'
  }
}

// Storage account required by the Functions runtime (AzureWebJobsStorage).
// Name: lowercase-alphanumeric, ≤24 chars, globally unique.
var funcStorageName = take('${toLower(replace(replace(appName, '-', ''), '_', ''))}${uniqueString(resourceGroup.id)}', 24)

module functionStorage '../../azure-platform-iac/modules/data/storage.bicep' = {
  name: '${appName}-stg-${environment}'
  scope: resourceGroup
  params: {
    name: funcStorageName
    location: location
    environment: environment
  }
}

module functionApp '../../azure-platform-iac/modules/compute/function-app.bicep' = {
  name: '${appName}-func-${environment}'
  scope: resourceGroup
  params: {
    name: '${appName}-func-${environment}'
    location: location
    appServicePlanId: appServicePlan.outputs.id
    storageAccountName: functionStorage.outputs.name
    runtimeStack: 'python'
    runtimeVersion: '3.12'
    environment: environment
{% if cookiecutter.include_cosmos %}
    appSettings: {
      Cosmos__Endpoint: cosmosEndpoint
    }
{% endif %}
  }
}

{% else %}
// ═══════════════════════════════════════════════════════════════════════════
// App Service (Linux)
{% if cookiecutter.project_type == 'go-web' %}
// Go binary + embedded SPA served from App Service
{% elif cookiecutter.project_type == 'node-agent' %}
// Node.js / TypeScript agent app
{% endif %}
// ═══════════════════════════════════════════════════════════════════════════
module appServicePlan '../../azure-platform-iac/modules/compute/app-service-plan.bicep' = {
  name: '${appName}-asp-${environment}'
  scope: resourceGroup
  params: {
    name: '${appName}-asp-${environment}'
    location: location
    skuName: (environment == 'prod' || environment == 'stage' ? 'S1' : 'B1')
    skuTier: (environment == 'prod' || environment == 'stage' ? 'Standard' : 'Basic')
    environment: environment
    osKind: 'linux'
  }
}

module appService '../../azure-platform-iac/modules/compute/app-service.bicep' = {
  name: '${appName}-app-${environment}'
  scope: resourceGroup
  params: {
    name: '${appName}-app-${environment}'
    location: location
    appServicePlanId: appServicePlan.outputs.id
{% if cookiecutter.project_type == 'go-web' %}
    runtimeStack: 'GO|1.23'
{% elif cookiecutter.project_type == 'node-agent' %}
    runtimeStack: 'NODE|22-lts'
{% else %}
    runtimeStack: 'DOTNETCORE|10.0'
{% endif %}
    alwaysOn: (environment == 'prod')
    environment: environment
    enableManagedIdentity: true
{% if cookiecutter.include_cosmos %}
    appSettings: {
      Cosmos__Endpoint: cosmosEndpoint
    }
{% endif %}
  }
}
{% endif %}

// ═══════════════════════════════════════════════════════════════════════════
// Key Vault (always deployed — managed identity secrets + config)
// ═══════════════════════════════════════════════════════════════════════════
module keyVault '../../azure-platform-iac/modules/security/key-vault.bicep' = {
  name: '${appName}-kv-${environment}'
  scope: resourceGroup
  params: {
    name: '${appName}-kv-${environment}'
    location: location
    tenantId: tenantId
    enablePurgeProtection: (environment == 'prod')
    environment: environment
  }
}

{% if cookiecutter.include_sql %}
// ═══════════════════════════════════════════════════════════════════════════
// SQL Server + Database
// ═══════════════════════════════════════════════════════════════════════════
@secure()
param sqlAdminLogin string

@secure()
param sqlAdminPassword string

module sqlServer '../../azure-platform-iac/modules/data/sql-server.bicep' = {
  name: '${appName}-sql-${environment}'
  scope: resourceGroup
  params: {
    name: '${appName}-sql-${environment}'
    location: location
    adminLogin: sqlAdminLogin
    adminPassword: sqlAdminPassword
    environment: environment
  }
}

module sqlDatabase '../../azure-platform-iac/modules/data/sql-database.bicep' = {
  name: '${appName}-sqldb-${environment}'
  scope: resourceGroup
  params: {
    name: '{{cookiecutter.database_name | lower}}-${environment}'
    location: location
    sqlServerName: sqlServer.outputs.name
    skuName: (environment == 'prod' || environment == 'stage' ? 'S0' : 'Basic')
    skuTier: (environment == 'prod' || environment == 'stage' ? 'Standard' : 'Basic')
    environment: environment
  }
}
{% endif %}

{% if cookiecutter.include_cosmos %}
// ═══════════════════════════════════════════════════════════════════════════
// Cosmos DB — passwordless. App managed identity gets the built-in Data
// Contributor role (data plane), so it reads/writes documents with no key.
// Control-plane RBAC: no Directory Readers, no contained users. Consume with
//   new CosmosClient(endpoint, new DefaultAzureCredential())
// ═══════════════════════════════════════════════════════════════════════════
module cosmos '../../azure-platform-iac/modules/data/cosmos-db.bicep' = {
  name: '${appName}-cosmos-${environment}'
  scope: resourceGroup
  params: {
    name: cosmosAccountName
    location: location
    environment: environment
    databaseName: 'appdb'
    containerName: '{{cookiecutter.database_name | lower}}'
    dataContributorPrincipalIds: [
{% if cookiecutter.project_type == 'python-function' %}
      functionApp.outputs.managedIdentityPrincipalId
{% else %}
      appService.outputs.managedIdentityPrincipalId
{% endif %}
    ]
  }
}
{% endif %}

{% if cookiecutter.include_foundry %}
// ═══════════════════════════════════════════════════════════════════════════
// Foundry AI — Hub, Models, Project, AI Search
// ═══════════════════════════════════════════════════════════════════════════
var foundryModels = [
  { name: 'gpt-5-mini', modelFormat: 'OpenAI', modelName: 'gpt-5-mini', modelVersion: '2024-10-21', skuName: 'GlobalStandard', skuCapacity: 10 }
  { name: 'text-embedding-3-small', modelFormat: 'OpenAI', modelName: 'text-embedding-3-small', modelVersion: '1', skuName: 'GlobalStandard', skuCapacity: 10 }
]

module aiSearch '../../azure-platform-iac/modules/ai/ai-search.bicep' = {
  name: '${appName}-search-${environment}'
  scope: resourceGroup
  params: {
    name: replace('${appName}-search-${environment}', '_', '-')
    location: location
    sku: (environment == 'prod' ? 'standard' : 'basic')
    replicaCount: (environment == 'prod' ? 3 : 1)
    environment: environment
  }
}

module foundryHub '../../azure-platform-iac/modules/ai/foundry-hub.bicep' = {
  name: '${appName}-foundry-${environment}'
  scope: resourceGroup
  params: {
    name: '${appName}-foundry-${environment}'
    location: location
    modelDeployments: foundryModels
    environment: environment
  }
}

module foundryProject '../../azure-platform-iac/modules/ai/foundry-project.bicep' = {
  name: '${appName}-proj-${environment}'
  scope: resourceGroup
  params: {
    name: '${appName}-proj-${environment}'
    location: location
    hubId: foundryHub.outputs.hubId
    aiServicesId: foundryHub.outputs.aiServicesId
    aiSearchServiceId: aiSearch.outputs.searchServiceId
    environment: environment
  }
}
{% endif %}

{% if cookiecutter.include_apim %}
// ═══════════════════════════════════════════════════════════════════════════
// API Management — gateway + protected API with Entra/M2M auth
//
// App registrations can't be created by Bicep — run
// scripts/setup-app-registrations.sh, then set internalApiClientId /
// m2mClientId per env. validate-jwt activates automatically when an ID is set.
// ═══════════════════════════════════════════════════════════════════════════
module apim '../../azure-platform-iac/modules/integration/api-management.bicep' = {
  name: '${appName}-apim-${environment}'
  scope: resourceGroup
  params: {
    name: '${appName}-apim-${environment}'
    location: location
    sku: (environment == 'prod' ? 'Standard' : 'Developer')
    publisherEmail: 'platform@{{cookiecutter.team_name | lower}}.example'
    publisherName: '{{cookiecutter.project_name}}'
    environment: environment
  }
}

module api '../../azure-platform-iac/modules/integration/apim-api.bicep' = {
  name: '${appName}-api-${environment}'
  scope: resourceGroup
  params: {
    apimServiceName: apim.outputs.name
    apiName: '${appName}-api'
    displayName: '{{cookiecutter.project_name}} API'
    path: '{{cookiecutter.project_name | lower}}'
{% if cookiecutter.project_type == 'python-function' %}
    serviceUrl: 'https://${functionApp.outputs.defaultHostName}'
{% else %}
    serviceUrl: 'https://${appService.outputs.defaultHostName}'
{% endif %}
    environment: environment
    enableEntraAuth: !empty(internalApiClientId)
    entraTenantId: tenantId
    entraAudience: internalApiClientId
    enableClientCredentialAuth: !empty(m2mClientId)
    clientCredentialTenantId: tenantId
    clientCredentialAudience: m2mClientId
    enableB2CAuth: !empty(b2cClientId)
    b2cTenantName: b2cTenantName
    b2cSignInPolicy: b2cSignInPolicy
    b2cAudience: b2cClientId
  }
}
{% endif %}

// --- Outputs ---

output resourceGroupName string = resourceGroup.name
{% if cookiecutter.project_type == 'python-function' %}
output functionAppName string = functionApp.outputs.name
{% else %}
output appServiceName string = appService.outputs.name
output appServiceUrl string = appService.outputs.defaultHostName
{% endif %}
output keyVaultUri string = keyVault.outputs.uri

{% if cookiecutter.include_sql %}
output sqlServerName string = sqlServer.outputs.name
output sqlDatabaseName string = sqlDatabase.outputs.name
{% endif %}

{% if cookiecutter.include_foundry %}
output foundryEndpoint string = foundryHub.outputs.aiServicesEndpoint
output foundryProjectEndpoint string = foundryProject.outputs.projectEndpoint
output aiSearchEndpoint string = aiSearch.outputs.searchEndpoint
{% endif %}

{% if cookiecutter.include_apim %}
output apimGatewayUrl string = apim.outputs.gatewayUrl
{% endif %}
{% endif %}
