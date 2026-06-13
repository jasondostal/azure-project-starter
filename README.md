# azure-project-starter

Cookiecutter template for new .NET services.

**One command → full repo** with pipeline, IaC, code quality tooling, and onboarding docs.

## Quickstart

```bash
# Option 1: Cookiecutter (one-time)
pip install cookiecutter
cookiecutter gh:your-org/azure-project-starter

# Option 2: Cruft (recommended — supports cruft update)
pip install cruft
cruft create gh:your-org/azure-project-starter
```

Answer the prompts (project name, team, features to include). Gets you:

- ✅ .NET 10 ASP.NET Core project with managed identity auth
- ✅ Bicep IaC (consuming azure-platform-iac modules) — App Service, Key Vault, optional SQL/Foundry/APIM
- ✅ Azure DevOps pipeline — Build → Lint → Scan → Deploy×4 (per-branch environment gates)
- ✅ Infra pipeline — validate + deploy Bicep per environment
- ✅ `.editorconfig` + `Directory.Build.props` with analyzers cranked
- ✅ `.gitignore`, `.cruft.json` (for `cruft update`), `.azure-guids.env`
- ✅ `README.md` with quickstart, workflow, pipeline setup checklist

## What you get

```
<your-project>/
├── <Project>.slnx                    # Solution file (.NET 10 slnx format)
├── Directory.Build.props             # Analyzers enabled, warnings-as-errors
├── .editorconfig                     # Team-wide formatting
├── .gitignore
├── .cruft.json                       # cruft update metadata
├── README.md                         # Project-specific onboarding
├── src/
│   └── <Project>.Api/
│       ├── <Project>.Api.csproj
│       ├── Program.cs                # Managed identity, health endpoint, DI
│       ├── Controllers/
│       │   └── HomeController.cs     # Placeholder — replace with your endpoints
│       └── Services/
│           └── DatabaseService.cs    # Placeholder — replace with your data layer
├── infra/
│   ├── main.bicep                    # Orchestrator — wires platform modules
│   └── params/
│       └── dev.bicepparam
└── pipelines/
    ├── azure-pipelines.yml           # Build → Lint → Scan → Deploy×4
    └── infra-pipeline.yml            # Bicep validate + deploy
```

## Features included (conditional)

| Feature | Toggle | Adds |
|---|---|---|
| SQL Server + Database | `include_sql` | Azure SQL, connection string in App Service |
| Foundry AI | `include_foundry` | Foundry Hub + Project + AI Search + GPT-5-mini |
| API Management | `include_apim` | APIM instance + auth policies (Entra ID, B2C, client credentials) |

## Syncing projects with template updates

Projects generated with `cruft create` can pull in template changes later:

```bash
cd my-project
cruft check       # See what's changed
cruft update      # Merge template changes
```

## Before you push

1. Create Entra app registrations (if using APIM): `az ad app create --display-name "your-project-api-internal-dev"`
2. Configure ADO variable groups + service connections + environments
3. Update `infra/params/*.bicepparam` with real values
4. Push → pipeline auto-triggers on branch match

## Dependencies

The generated project consumes:
- **azure-platform-iac** — platform Bicep modules (must be checked out alongside)
- **azure-iac-reference** — exhaustive reference app showing all modules wired together
- **azure-iac-patterns** — standalone patterns catalog (identity, foundry, networking, etc.)
- **Azure DevOps** — pipeline YAML references ADO variable groups and environments
- **Azure subscriptions** — one per environment (dev/qa/staging/prod or dev/prod)

## The full platform

```
azure-platform-iac        ← 17 generic Bicep modules (the foundation)
azure-iac-reference       ← exhaustive demo: everything wired together
azure-iac-patterns        ← standalone patterns: identity, foundry, networking, etc.
azure-project-starter     ← this repo: cookiecutter template for new projects
```

## Maintainers

Platform Engineering
