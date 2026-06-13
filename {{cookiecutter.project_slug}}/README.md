# {{cookiecutter.project_name}}

{{cookiecutter.project_description}}

**Generated from azure-project-starter ({{cookiecutter.project_type}} archetype)** using cookiecutter/cruft.

## Stack

{% if cookiecutter.project_type == 'dotnet-api' %}
- .NET 10 / ASP.NET Core API / C# 14
- Azure App Service (Linux, managed identity)
{% elif cookiecutter.project_type == 'dotnet-web' %}
- .NET 10 / ASP.NET Core Razor Pages / C# 14
- Azure App Service (Linux, managed identity)
{% elif cookiecutter.project_type == 'python-function' %}
- Python 3.12 / Azure Functions (serverless, Linux)
- HTTP trigger with managed identity auth
{% elif cookiecutter.project_type == 'go-web' %}
- Go 1.23 / Chi router
- Embedded SPA (static assets served from the Go binary)
- Azure App Service (Linux, Go runtime, managed identity)
{% elif cookiecutter.project_type == 'go-desktop' %}
- Go 1.23 — compiled CLI / desktop binary
- Cross-compiled: linux/amd64, darwin/arm64, windows/amd64
- Distributed via GitHub Releases (no Azure infra needed)
{% elif cookiecutter.project_type == 'node-agent' %}
- Node.js 22 / TypeScript / SvelteKit
- Azure App Service (Linux, managed identity)
- Azure AI Foundry (Agents API + Responses API + vector search)
{% endif %}

{% if cookiecutter.include_sql %}
- Azure SQL (`{{cookiecutter.database_name}}`)
{% endif %}
{% if cookiecutter.include_foundry %}
- Azure AI Foundry (Hub + Project + AI Search for RAG)
{% endif %}
- Bicep (infrastructure as code, consuming azure-platform-iac modules)
- Azure DevOps (CI/CD — consumes platform pipeline templates)

## Quickstart

{% if cookiecutter.project_type == 'dotnet-api' or cookiecutter.project_type == 'dotnet-web' %}
```bash
dotnet restore {{cookiecutter.project_slug}}.slnx
dotnet build {{cookiecutter.project_slug}}.slnx
dotnet run --project src/{{cookiecutter.project_slug}}.{{ 'Api' if cookiecutter.project_type == 'dotnet-api' else 'Web' }}
curl http://localhost:{{cookiecutter.app_port}}/health
```
{% elif cookiecutter.project_type == 'python-function' %}
```bash
cd src
pip install -r requirements.txt
func start
curl http://localhost:7071/api/health
```
{% elif cookiecutter.project_type == 'go-web' %}
```bash
go run ./cmd/app
# Opens on http://localhost:{{cookiecutter.app_port}}
curl http://localhost:{{cookiecutter.app_port}}/health
```
{% elif cookiecutter.project_type == 'go-desktop' %}
```bash
go run ./cmd/app
# Binary output: {{cookiecutter.project_name}} (darwin/arm64)
```
{% elif cookiecutter.project_type == 'node-agent' %}
```bash
npm install
npm run dev
curl http://localhost:{{cookiecutter.app_port}}/health
```
{% endif %}

## Development workflow

```bash
# Branch strategy (branch-per-environment)
# main = prod | stage = staging | qa = QA | dev = dev

# Start a feature
git checkout stage && git pull
git checkout -b feature/my-feature

# PR into dev → auto-deploy to dev
# PR into qa  → QA lead approves
# stage → main → VP-approved prod release
```

## Project structure

{% if cookiecutter.project_type == 'dotnet-api' %}
```
├── {{cookiecutter.project_slug}}.slnx
├── src/
│   └── {{cookiecutter.project_slug}}.Api/
│       ├── {{cookiecutter.project_slug}}.Api.csproj
│       ├── Program.cs
│       ├── Controllers/
│       │   └── HomeController.cs
│       └── Services/
│           └── DatabaseService.cs
```
{% elif cookiecutter.project_type == 'dotnet-web' %}
```
├── {{cookiecutter.project_slug}}.slnx
├── src/
│   └── {{cookiecutter.project_slug}}.Web/
│       ├── {{cookiecutter.project_slug}}.Web.csproj
│       ├── Program.cs
│       ├── Pages/
│       │   └── Index.cshtml
│       └── Services/
│           └── DatabaseService.cs
```
{% elif cookiecutter.project_type == 'python-function' %}
```
├── src/
│   ├── requirements.txt
│   ├── host.json
│   └── functions/
│       ├── function.json
│       └── health.py
```
{% elif cookiecutter.project_type == 'go-web' %}
```
├── go.mod
├── cmd/app/
│   └── main.go
├── internal/handler/
│   └── handler.go
└── static/
    └── index.html          # SPA root
```
{% elif cookiecutter.project_type == 'go-desktop' %}
```
├── go.mod
├── cmd/app/
│   ├── main.go
│   └── version.go
```
{% elif cookiecutter.project_type == 'node-agent' %}
```
├── package.json
├── svelte.config.js
├── vite.config.ts
├── tsconfig.json
├── server.js
├── src/
│   ├── routes/api/         # API endpoints
│   └── lib/server/         # Foundry client, agents
├── kb/                     # Knowledge base documents
└── scripts/
    └── setup-agents.ts     # Create Foundry agents + vector stores
```
{% endif %}
{% if cookiecutter.project_type != 'go-desktop' %}
├── infra/
│   ├── main.bicep
│   └── params/
│       └── dev.bicepparam
{% endif %}
├── pipelines/
│   ├── azure-pipelines.yml
{% if cookiecutter.project_type != 'go-desktop' %}
│   └── infra-pipeline.yml
{% endif %}
├── Directory.Build.props
├── .editorconfig
├── .gitignore
└── README.md

{% if cookiecutter.project_type != 'go-desktop' %}
## Infrastructure

```bash
# Manual deploy (dev environment)
az deployment sub create \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters infra/params/dev.bicepparam
```
{% endif %}

## Pipelines

{% if cookiecutter.project_type == 'go-desktop' %}
| Pipeline | Trigger | What it does |
|---|---|---|
| `azure-pipelines.yml` | Push to any branch | Build → cross-compile → GitHub Release |
{% else %}
| Pipeline | Trigger | What it does |
|---|---|---|
| `azure-pipelines.yml` | Push to any branch | Build → Scan → Deploy (per-branch) |
| `infra-pipeline.yml` | Push to infra/* paths | Validate Bicep → Deploy infra per environment |
{% endif %}

### Required ADO setup

After pushing this repo, configure in Azure DevOps:
1. **Variable Groups** — Create vg-{{cookiecutter.project_name}}-{shared,dev,qa,staging,prod} per environment
2. **Service Connections** — sc-{{cookiecutter.project_name}}-{dev,qa,staging,prod}
3. **Environments** — {{cookiecutter.project_name}}-{dev,qa,staging,prod} with approval gates
4. **Branch Policies** — PR validation build, squash merge on dev, 2 reviewers on main

{% if cookiecutter.project_type == 'go-desktop' %}
### GitHub Release

The pipeline cross-compiles Go binaries for linux/amd64, darwin/arm64, and windows/amd64, then creates a GitHub Release with all three binaries attached. The release tag is the build number.

Requires a `GITHUB_TOKEN` secret in the ADO variable group with `repo` scope.
{% endif %}

## Post-deployment setup

{% if cookiecutter.include_foundry %}
### Foundry AI (agents)

1. Grant the App Service managed identity the **Azure AI Developer** role on the Foundry AI Services account
2. Run agent setup scripts (if using agents):
   ```bash
   npm run setup-agents     # Creates text agents + KB vector store
   ```
3. Agent IDs are written to `.env` / App Configuration — the app reads them at startup
{% endif %}

{% if cookiecutter.include_sql %}
### SQL Database

1. The SQL Server + Database are provisioned by the Bicep deployment
2. Firewall rules: add your IP for local dev, or use the App Service's outbound IPs
3. Run schema migrations (DDL scripts, EF Core, or whatever your team uses)
{% endif %}

### Key Vault

- The Key Vault is created with the App Service's managed identity granted `get/list` on secrets
- Add secrets via `az keyvault secret set` or the Azure Portal
- The app accesses secrets via `DefaultAzureCredential` (no keys in config files)

## Code quality

- `.editorconfig` — consistent formatting across the team
{% if cookiecutter.project_type == 'dotnet-api' or cookiecutter.project_type == 'dotnet-web' %}
- `Directory.Build.props` — .NET analyzers enabled, warnings-as-errors
{% endif %}
- All scanning happens in the platform pipeline templates (gitleaks, trivy, semgrep, NuGet vuln) — no repo-level config needed
- **Add a scanner to the platform repo → this project gets it on next build**

## Syncing with the template

This project was generated from `azure-project-starter`. To pull in template updates:

```bash
pip install cruft
cruft check    # See what's changed
cruft update   # Merge template changes
```

## Team

{{cookiecutter.team_name}} — [ADO Project](https://dev.azure.com/{{cookiecutter.ado_org}}/{{cookiecutter.ado_project}})
