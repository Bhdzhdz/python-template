#!/usr/bin/env bash
# Render the template into a temp dir and run the generated project's checks.
# --vcs-ref=HEAD: use the current tree (incl. uncommitted changes) instead of the latest tag.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

out="$tmp/smoke-project"
uvx copier copy --trust --defaults --vcs-ref=HEAD \
    --data project_name="Smoke Test" \
    --data ci_provider="both" \
    "$repo" "$out" >/dev/null 2>&1
cd "$out"
test -f .copier-answers.yml
test -f .specify/memory/constitution.md
test -f .ignore
test -f .gitattributes
test -f .editorconfig
test -f justfile
test -f CLAUDE.md
test -f .github/workflows/ci.yml
test -f .github/dependabot.yml
test -f .gitlab-ci.yml
test -f src/smoke_test/py.typed
./scripts/map.sh
(cd src && ../scripts/map.sh smoke_test)
./scripts/check.sh --fix src/smoke_test/__init__.py tests/test_smoke.py
(cd src && ../scripts/check.sh --fix smoke_test/__init__.py)
./scripts/check.sh --fix --changed
./scripts/check.sh --fix
uv run just check
uv run pytest tests/test_smoke.py::test_version

# Verify _skip_if_exists preserves downstream-owned files on re-copy/update
echo '# custom' >> src/smoke_test/__init__.py
uvx copier copy --trust --defaults --vcs-ref=HEAD \
    --data project_name="Smoke Test" \
    --data ci_provider="both" \
    "$repo" "$out" >/dev/null 2>&1
grep -q '# custom' src/smoke_test/__init__.py

# Verify ci_provider=none excludes CI configs
out_no_ci="$tmp/smoke-no-ci"
uvx copier copy --trust --defaults --vcs-ref=HEAD \
    --data project_name="No CI" \
    --data ci_provider="none" \
    "$repo" "$out_no_ci" >/dev/null 2>&1
test ! -e "$out_no_ci/.github"
test ! -e "$out_no_ci/.gitlab-ci.yml"
