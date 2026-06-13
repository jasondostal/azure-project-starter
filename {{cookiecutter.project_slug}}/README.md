# {{cookiecutter.project_name}}

{{cookiecutter.project_description}}

**Generated from [azure-project-starter](https://dev.azure.com/{{cookiecutter.ado_org}}/{{cookiecutter.ado_project}}/_git/azure-project-starter)** using cookiecutter/cruft.

## Stack

- .NET 10 / ASP.NET Core / C# 14
- Azure App Service (Linux, managed identity)
- Azure SQL (`{{cookiecutter.database_name}}`)
{% if cookiecutter.include_foundry == 'true' %}
- Azure AI Foundry (Hub + Project + AI Search for RAG)
{% endif %}
- Bicep (infrastructure as code, consuming azure-platform-iac modules)
- Azure DevOps (CI/CD)

## Quickstart

```bash
# 1. Restore + build
dotnet restore {{cookiecutter.project_slug}}.slnx
dotnet build {{cookiecutter.project_slug}}.slnx

# 2. Run locally
dotnet run --project src/{{cookiecutter.project_slug}}.Api

# 3. Hit the health endpoint
curl http://localhost:{{cookiecutter.app_port}}/health
```

## Development workflow

```bash
# Branch strategy (branch-per-environment)
# main = prod | stage = staging | qa = QA | dev = dev

# Start a feature
git checkout stage && git pull
git checkout -b feature/my-feature

# PR into dev → auto-deploy to dev
# PR into qa  → QA lead approves
# PR into release/X → sprint-end bundle
# stage → main → VP-approved prod release
```

## Infrastructure

```
infra/
├── main.bicep          # Orchestrator — wires platform modules
├── params/             # Per-environment parameters
│   ├── dev.bicepparam
│   ├── qa.bicepparam
│   ├── staging.bicepparam
│   └── prod.bicepparam
└── modules/            # App-specific modules (if any)
```

### Deploy infrastructure

```bash
# Manual deploy (dev environment)
az deployment sub create \
  --location eastus \
  --template-file infra/main.bicep \
  --parameters infra/params/dev.bicepparam

# Or push to dev branch → infra-pipeline.yml auto-deploys
```

## Pipelines

| Pipeline | Trigger | What it does |
|---|---|---|
| `azure-pipelines.yml` | Push to any branch | Build → Lint → Scan → Deploy (per-branch) |
| `infra-pipeline.yml` | Push to infra/* paths | Validate Bicep → Deploy infra per environment |

### Required ADO setup

After pushing this repo, configure in Azure DevOps:
1. **Variable Groups** — Create vg-{{cookiecutter.project_name}}-{shared,dev,qa,staging,prod} per environment
2. **Service Connections** — sc-{{cookiecutter.project_name}}-{dev,qa,staging,prod}
3. **Environments** — {{cookiecutter.project_name}}-{dev,qa,staging,prod} with approval gates
4. **Branch Policies** — PR validation build, squash merge on dev, 2 reviewers on main

## Post-deployment setup

{% if cookiecutter.include_foundry == 'true' %}
### Foundry AI (agents)

1. Grant App Service managed identity the **Azure AI Developer** role on the Foundry AI Services account
2. Run agent setup scripts (if using agents):
   ```bash
   # These scripts create Foundry agents + vector stores from the infra-provisioned Hub/Project
   npm run setup-agents
   python scripts/provision_voice_agent.py
   ```
3. Agent IDs are written to `.env` / App Configuration — the app reads them at startup
{% endif %}

{% if cookiecutter.include_sql == 'true' %}
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
- `Directory.Build.props` — .NET analyzers enabled, warnings-as-errors
- `dotnet format` — enforced in CI (warning gate during initial setup)
- `gitleaks` — secret detection, HARD gate in CI
- `NuGet vulnerability scan`, `Semgrep SAST`, `Trivy FS scan` — all running in CI

## Syncing with the template

This project was generated from `azure-project-starter`. To pull in template updates:

```bash
# Install cruft if you haven't
pip install cruft

# Check for updates
cruft check

# Apply updates (merges template changes into your project)
cruft update
```

## Team

{{cookiecutter.team_name}} — [ADO Project](https://dev.azure.com/{{cookiecutter.ado_org}}/{{cookiecutter.ado_project}})
