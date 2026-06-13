.PHONY: setup-hooks build test clean

# Install pre-commit hooks (runs after `make setup` or manually)
setup-hooks:
	@command -v pre-commit >/dev/null 2>&1 || { echo "pre-commit not installed — run: pip install pre-commit"; exit 0; }
	pre-commit install --install-hooks

# Full setup: install hooks + tidy deps
setup: setup-hooks
	go mod tidy

# Build
build:
	go build -ldflags="-s -w" -o bin/{{cookiecutter.project_name | lower}} ./cmd/app

# Run tests
test:
	go test ./...

# Clean build artifacts
clean:
	rm -rf bin/
