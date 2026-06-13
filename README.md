# azure-project-starter

Cookiecutter template for new services — 6 archetypes, one command.
Uses **cruft** to generate and keep projects in sync with the template.

**One command → full repo** with pipeline, IaC, code quality tooling, and onboarding docs.

## Quickstart

```bash
pip install cruft
cruft create gh:jasondostal/azure-project-starter
```

Answer the prompts (project name, type, team, features). Gets you:

- ✅ **6 archetypes**: dotnet-api, dotnet-web, python-function, go-web, go-desktop, node-agent
- ✅ Bicep IaC (consuming azure-platform-iac modules) — App Service, Function App, or no infra (desktop)
- ✅ Azure DevOps pipeline consuming platform pipeline templates (build + security gates + deploy)
- ✅ Infra pipeline — validate + deploy Bicep per environment (not for desktop)
- ✅ `.editorconfig` + language-specific tooling (.NET analyzers, Go modules, npm scripts)
- ✅ `.gitignore`, `.cruft.json` (for `cruft update`), `.azure-guids.env`
- ✅ `README.md` rendered per-archetype with quickstart, workflow, pipeline setup checklist

## Archetypes

| Archetype | Runtime | Deployment | Use case |
|-----------|---------|------------|----------|
| `dotnet-api` | .NET 10 / ASP.NET Core API | App Service (Linux) | REST APIs, microservices |
| `dotnet-web` | .NET 10 / Razor Pages | App Service (Linux) | Server-rendered web apps |
| `python-function` | Python 3.12 / Azure Functions | Function App (serverless) | Event-driven, cron jobs, webhooks |
| `go-web` | Go 1.23 / Chi + embedded SPA | App Service (Linux, Go) | Low-footprint APIs + SPA in one binary |
| `go-desktop` | Go 1.23 / CLI | GitHub Releases (no Azure) | Cross-compiled CLI tools, desktop utils |
| `node-agent` | Node 22 / TS / SvelteKit | App Service (Linux) | Foundry AI agents, voice, RAG front-ends |

Each archetype gets its own pipeline template reference from the platform repo, the right Bicep module (App Service vs Function App vs none), and an archetype-specific directory structure.

## What you get (example: dotnet-api)

```
<your-project>/
├── <Project>.slnx
├── Directory.Build.props
├── .editorconfig, .gitignore
├── .cruft.json, .azure-guids.env
├── README.md
├── src/<Project>.Api/              # Source code (archetype-specific)
├── infra/                          # Bicep IaC (skipped for go-desktop)
│   ├── main.bicep
│   └── params/dev.bicepparam
└── pipelines/
    ├── azure-pipelines.yml         # Consumes platform pipeline templates
    └── infra-pipeline.yml          # Bicep CI/CD (skipped for go-desktop)
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
