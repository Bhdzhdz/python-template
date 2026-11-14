#!/usr/bin/env bash
# Update pinned versions across the template repository:
# 1. Pre-commit hook revisions in root and template/.pre-commit-config.yaml
# 2. Pinned uv image tag in template/Dockerfile.jinja
# 3. Vendored Spec Kit files in template/.specify/ and template/.agents/skills/speckit-* (when --speckit is passed)
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo"

sync_speckit=0
for arg in "$@"; do
    case "$arg" in
        --speckit) sync_speckit=1 ;;
        *)
            echo "Usage: $0 [--speckit]" >&2
            exit 2
            ;;
    esac
done

echo "==> Updating pre-commit hooks (root & template)..."
uvx pre-commit autoupdate -c .pre-commit-config.yaml
uvx pre-commit autoupdate -c template/.pre-commit-config.yaml

echo "==> Syncing uv version in template/Dockerfile.jinja..."
uv_ver="$(uv --version | awk '{print $2}')"
if [[ -n "$uv_ver" ]]; then
    sed -i -E "s|(ghcr\.io/astral-sh/uv:)[0-9]+\.[0-9]+\.[0-9]+|\1${uv_ver}|g" template/Dockerfile.jinja
fi

if [[ "$sync_speckit" -eq 1 ]]; then
    echo "==> Updating vendored Spec Kit files..."
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cp template/.specify/memory/constitution.md.jinja "$tmp/constitution.md.jinja"
    (
        cd template
        uvx --from git+https://github.com/github/spec-kit.git specify init --here --ai codex --ai-skills --script sh --no-git --force
    )
    mv "$tmp/constitution.md.jinja" template/.specify/memory/constitution.md.jinja
    rm -f template/.specify/memory/constitution.md
fi

echo "==> Running template smoke test..."
./scripts/smoke-test.sh
