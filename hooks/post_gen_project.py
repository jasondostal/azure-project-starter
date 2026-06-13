#!/usr/bin/env python3
"""Cookiecutter post-generation hook — runs after template variables are resolved.

Does things that cookiecutter/Jinja2 can't do in static templates:
  1. Generates stable GUIDs for Azure resources (app registrations, role IDs)
  2. Removes unused archetype directories
  3. Initializes a fresh git repo
"""
import os
import sys
import uuid
import shutil
import subprocess
from pathlib import Path


PROJECT_DIR = Path.cwd()
PROJECT_TYPE = "{{ cookiecutter.project_type }}"


def generate_stable_guid(seed: str) -> str:
    """Generate a deterministic GUID from a seed string (stable across runs)."""
    return str(uuid.uuid5(uuid.NAMESPACE_DNS, seed))


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

if not is_node:
    remove_file("package.json")
    remove_file("server.js")
    remove_file("svelte.config.js")
    remove_file("vite.config.ts")
    remove_file("tsconfig.json")
    remove_dir("kb")

if is_go_desktop:
    remove_dir("infra")
    remove_file("pipelines/infra-pipeline.yml")

# ── 2. Generate stable GUIDs ────────────────────────────────────────────────

project_name = "{{ cookiecutter.project_name }}"

guids = {
    "INTERNAL_API_CLIENT_ID": generate_stable_guid(f"{project_name}.internal-api"),
    "M2M_CLIENT_ID": generate_stable_guid(f"{project_name}.m2m-client"),
}

guids_path = PROJECT_DIR / ".azure-guids.env"
with open(guids_path, "w") as f:
    f.write("# Auto-generated stable GUIDs for Azure app registrations.\n")
    f.write("# Re-running cookiecutter with the same project_name produces the same IDs.\n")
    f.write("# These are DETERMINISTIC — suitable for IAC app registrations, not for secrets.\n")
    for key, val in guids.items():
        f.write(f"{key}={val}\n")
print(f"  wrote {guids_path}")

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

# ── 4. Initialize git repo ──────────────────────────────────────────────────

run(["git", "init", "-b", "main"])
run(["git", "add", "-A"])
run(["git", "commit", "-m", f"Initial scaffold from azure-project-starter ({PROJECT_TYPE} archetype)"])

print(f"""
✓ Project '{project_name}' ({PROJECT_TYPE}) is ready at {PROJECT_DIR}

Next steps:
  cd {PROJECT_DIR}
  # 1. Create Entra app registrations (if using APIM auth):
  #    az ad app create --display-name "{project_name}-api-internal-dev"
  #
  # 2. Create the Azure DevOps project variables + service connections
  #
  # 3. Push to Azure DevOps:
  #    git remote add origin https://dev.azure.com/{{cookiecutter.ado_org}}/{{cookiecutter.ado_project}}/_git/{project_name}
  #    git push -u origin --all
  #
  # 4. Create pipeline from existing YAML:
  #    pipelines/azure-pipelines.yml
""")
