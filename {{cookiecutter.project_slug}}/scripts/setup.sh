#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# setup.sh — one-command dev environment setup
#
# Run this once after cloning. Installs pre-commit hooks, tooling, and
{% if cookiecutter.project_type == 'node-agent' %}
# npm dependencies.
{% elif cookiecutter.project_type == 'python-function' %}
# Python dependencies including dev tooling.
{% elif cookiecutter.project_type == 'go-web' or cookiecutter.project_type == 'go-desktop' %}
# Go dependencies and pre-commit.
{% else %}
# any archetype-specific tooling.
{% endif %}
#
# Usage: bash scripts/setup.sh
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

echo "→ Setting up {{cookiecutter.project_name}} ({{cookiecutter.project_type}})..."

# ── 1. pre-commit hooks ─────────────────────────────────────────────────────
if command -v pre-commit &>/dev/null; then
    echo "  installing pre-commit hooks..."
    pre-commit install --install-hooks
    echo "  ✓ hooks installed (gitleaks + formatting will run on every commit)"
else
    echo "  ⚠ pre-commit not found — install it for automatic commit checks:"
    echo "    pip install pre-commit"
    echo "    pre-commit install --install-hooks"
fi

# ── 2. Language-specific setup ───────────────────────────────────────────────
{% if cookiecutter.project_type == 'dotnet-api' or cookiecutter.project_type == 'dotnet-web' %}
echo "  restoring .NET dependencies..."
dotnet restore {{cookiecutter.project_slug}}.slnx
echo "  ✓ .NET SDK ready"

{% elif cookiecutter.project_type == 'python-function' %}
echo "  creating venv + installing deps..."
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
echo "  ✓ Python venv ready (activate: source .venv/bin/activate)"

{% elif cookiecutter.project_type == 'go-web' or cookiecutter.project_type == 'go-desktop' %}
echo "  downloading Go dependencies..."
go mod tidy
echo "  ✓ Go modules ready"

{% elif cookiecutter.project_type == 'node-agent' %}
echo "  installing npm dependencies..."
npm install
echo "  ✓ npm packages ready (pre-commit hooks auto-installed via postinstall)"

{% endif %}

echo ""
echo "✓ Setup complete. Run:"
{% if cookiecutter.project_type == 'dotnet-api' or cookiecutter.project_type == 'dotnet-web' %}
echo "  dotnet run --project src/{{cookiecutter.project_slug}}.{{ 'Api' if cookiecutter.project_type == 'dotnet-api' else 'Web' }}"
{% elif cookiecutter.project_type == 'python-function' %}
echo "  source .venv/bin/activate && cd src && func start"
{% elif cookiecutter.project_type == 'go-web' or cookiecutter.project_type == 'go-desktop' %}
echo "  go run ./cmd/app"
{% elif cookiecutter.project_type == 'node-agent' %}
echo "  npm run dev"
{% endif %}
