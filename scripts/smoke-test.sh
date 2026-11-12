#!/usr/bin/env bash
# Render the template into a temp dir and run the generated project's checks.
# --vcs-ref=HEAD: use the current tree (incl. uncommitted changes) instead of the latest tag.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

out="$tmp/smoke-project"
uvx copier copy --trust --defaults --vcs-ref=HEAD --data project_name="Smoke Test" "$repo" "$out" >/dev/null 2>&1
cd "$out"
test -f .copier-answers.yml
test -f .specify/memory/constitution.md
test -f .ignore
./scripts/map.sh
./scripts/check.sh --fix src/smoke_test/__init__.py
./scripts/check.sh --fix
uv run pytest tests/test_smoke.py::test_version
