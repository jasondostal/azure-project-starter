#!/usr/bin/env python3
"""Cookiecutter post-generation hook — runs after template variables are resolved.

Does things that cookiecutter/Jinja2 can't do in static templates:
  1. Generates stable GUIDs for Azure resources (app registrations, role IDs)
  2. Removes unused archetype directories
  3. Initializes a fresh git repo
"""
import os
import sys
import shutil
import subprocess
from pathlib import Path


PROJECT_DIR = Path.cwd()
PROJECT_TYPE = "{{ cookiecutter.project_type }}"


def remove_dir(path: str) -> None:
    """Remove a directory tree if it exists."""
    p = PROJECT_DIR / path
    if p.exists():
        shutil.rmtree(p)
        print(f"  removed {path}")


def remove_file(path: str) -> None:
    """Remove a file if it exists."""
    p = PROJECT_DIR / path
    if p.exists():
        p.unlink()
        print(f"  removed {path}")


def run(cmd: list[str], cwd: Path | None = None) -> None:
    """Run a command, fail if it fails."""
    result = subprocess.run(cmd, cwd=cwd or PROJECT_DIR, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"  WARNING: {' '.join(cmd)} failed: {result.stderr.strip()}", file=sys.stderr)


# ── 1. Remove unused archetype files ────────────────────────────────────────
#    CookieCutter can't delete files based on conditionals, so we clean up
#    everything that doesn't belong to the selected project_type.

is_dotnet = PROJECT_TYPE in ("dotnet-api", "dotnet-web")
is_go = PROJECT_TYPE in ("go-web", "go-desktop")
is_python = PROJECT_TYPE == "python-function"
is_node = PROJECT_TYPE == "node-agent"
is_go_desktop = PROJECT_TYPE == "go-desktop"
is_go_web = PROJECT_TYPE == "go-web"

if not is_dotnet:
    remove_file("Directory.Build.props")
    remove_file("Directory.Build.targets")
    remove_file("{{cookiecutter.project_slug}}.slnx")

# Always remove the dotnet sub-archetype dirs that don't match the selected type.
# This must run unconditionally (not nested under `if not is_dotnet`) so that
# dotnet-api cleans up the Web project and dotnet-web cleans up the Api project.
if PROJECT_TYPE != "dotnet-api":
    remove_dir("src/{{cookiecutter.project_slug}}.Api")
if PROJECT_TYPE != "dotnet-web":
    remove_dir("src/{{cookiecutter.project_slug}}.Web")

if not is_go:
    remove_dir("cmd")
    remove_dir("internal")
    remove_dir("static")
    remove_file("go.mod")
    remove_file("Makefile")
else:
    # Go-specific cleanup
    if not is_go_web:
        remove_dir("static")
    if not is_go_desktop:
        remove_file("cmd/app/version.go")

if not is_python:
    remove_dir("src/functions")
    remove_file("src/requirements.txt")
    remove_file("src/host.json")
    remove_file("src/pyproject.toml")

if not is_node:
    remove_file("package.json")
    remove_file("server.js")
    remove_file("svelte.config.js")
    remove_file("vite.config.ts")
    remove_file("tsconfig.json")
    remove_dir("kb")
    remove_file("src/app.html")
    remove_dir("src/routes")
    remove_dir("src/lib")  # SvelteKit convention dir — only needed for node-agent

if is_go_desktop:
    remove_dir("infra")
    remove_file("pipelines/infra-pipeline.yml")

# Remove src/ if it ended up empty (go archetypes have no src content).
if is_go:
    src_dir = PROJECT_DIR / "src"
    if src_dir.exists() and not any(src_dir.iterdir()):
        src_dir.rmdir()
        print("  removed src (empty)")

# ── 2. App registration bootstrap (APIM only) ───────────────────────────────
#    Entra app registrations CANNOT be created by Bicep, and the client ID
#    (appId) is assigned BY Azure at creation time — there is nothing real to
#    pre-generate here. Pre-minting a "client ID" would be fiction: it would
#    never match the appId that `az ad app create` actually returns.
#
#    Instead, projects that expose an API via APIM ship a bootstrap script that
#    creates the app reg(s) and writes the REAL client IDs to .azure-guids.env
#    (gitignored — never committed). appRole GUIDs ARE caller-owned, so the
#    script derives them deterministically from the project name at runtime,
#    keeping reruns idempotent. Projects without APIM need no app reg, so the
#    script is removed.

project_name = "{{ cookiecutter.project_name }}"
include_apim = "{{ cookiecutter.include_apim }}".lower() == "true"

if not include_apim or is_go_desktop:
    remove_file("scripts/setup-app-registrations.sh")

# ── 3. Write .cruft.json (for cruft update) ─────────────────────────────────

import json as _json
cruft_data = {
    "template": "https://github.com/jasondostal/azure-project-starter",
    "commit": "initial",
    "checkout": None,
    "context": {
        "cookiecutter": {
            "project_name": "{{cookiecutter.project_name}}",
            "project_slug": "{{cookiecutter.project_slug}}",
            "project_description": "{{cookiecutter.project_description}}",
            "project_type": "{{cookiecutter.project_type}}",
            "azure_tenant_id": "{{cookiecutter.azure_tenant_id}}",
            "team_name": "{{cookiecutter.team_name}}",
            "ado_org": "{{cookiecutter.ado_org}}",
            "ado_project": "{{cookiecutter.ado_project}}",
            "database_name": "{{cookiecutter.database_name}}",
            "app_port": "{{cookiecutter.app_port}}",
            "go_module_path": "{{cookiecutter.go_module_path}}",
            "include_foundry": "{{cookiecutter.include_foundry}}",
            "include_apim": "{{cookiecutter.include_apim}}",
            "include_sql": "{{cookiecutter.include_sql}}"
        }
    },
    "directory": "{{cookiecutter.project_slug}}"
}
cruft_path = PROJECT_DIR / ".cruft.json"
with open(cruft_path, "w") as f:
    _json.dump(cruft_data, f, indent=2)
print(f"  wrote {cruft_path}")

# ── 4. Generate package-lock.json for node-agent projects ───────────────────
#    CI runs `npm ci` which requires package-lock.json to be present.

if is_node:
    print("  running npm install to generate package-lock.json …")
    run(["npm", "install", "--no-audit", "--no-fund"])

# ── 5. Initialize git repo ──────────────────────────────────────────────────

run(["git", "init", "-b", "main"])
run(["git", "add", "-A"])
run(["git", "commit", "-m", f"Initial scaffold from azure-project-starter ({PROJECT_TYPE} archetype)"])

print(f"""
✓ Project '{project_name}' ({PROJECT_TYPE}) is ready at {PROJECT_DIR}

Next steps:
  cd {PROJECT_DIR}
  # 1. Onboard each subscription/environment (idempotent — one run per env).
  #    This wires the deploy identity (WIF, no secret), the ADO service
  #    connection, variable groups, and the ADO environment:
  #    azure-platform-iac/bootstrap/onboard-subscription.sh \\
  #      --env dev --subscription <sub-id> \\
  #      --ado-org https://dev.azure.com/{{cookiecutter.ado_org}} \\
  #      --ado-project {{cookiecutter.ado_project}} --project {project_name}
  #
  # 2. Create Entra app registrations (APIM projects only):
  #    bash scripts/setup-app-registrations.sh
  #    → creates the app reg(s), writes REAL client IDs to .azure-guids.env
  #
  # 3. Add approval checks on the ADO environments (qa/stage/prod) in the UI.
  #
  # 4. Push to Azure DevOps (single branch — main):
  #    git remote add origin https://dev.azure.com/{{cookiecutter.ado_org}}/{{cookiecutter.ado_project}}/_git/{project_name}
  #    git push -u origin main
  #
  # 5. Create pipeline from existing YAML:
  #    pipelines/azure-pipelines.yml  (build once → promote dev→qa→stage→prod)
""")
