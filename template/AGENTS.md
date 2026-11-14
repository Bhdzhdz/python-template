# Agent guidelines

Keep token usage (cost) low. **For isolated tasks, all rules and commands are in this file—do NOT spend tool calls reading `.agents/skills/` unless invoking a Spec Kit workflow (`speckit-*`).**

## Isolated-Call Workflow (Minimum Tokens)
1. **Map before reading**: Run `./scripts/map.sh` (or `./scripts/map.sh src/pkg`) to get all files, line counts, `Lstart-Lend` ranges, and full typed signatures in 1 call, or locate symbols with `rg -n "symbol" src tests` (`.ignore` automatically skips `.specify/`, `.agents/`, and `uv.lock`).
2. **Read narrow line ranges**: Use the `Lstart-Lend` ranges from `./scripts/map.sh` or `rg` to read only the needed function/class. Never read whole large files, lockfiles, or `.venv`.
3. **Edit in place**: Use targeted diffs. Do not rewrite or paste back whole files.
4. **Iterate on touched files**: Run `./scripts/check.sh --fix path/to/file.py` (or `./scripts/check.sh --fix --changed`) to auto-fix, lint, type-check, verify complexity/SAST, and run matching unit tests in 1 quiet call.
5. **Verify once at the end**: Run `./scripts/check.sh --fix` to execute all 12 repo-wide gates + coverage (outputs `ok: all checks passed`, or only failing checks).
6. **Be concise**: Answer first; state what changed in 1–3 lines; reference `path:line` instead of quoting code; ask 1 clarifying question early if requirements are ambiguous.

## Code & Architecture Gates (write compliant code on first pass)
- **Typing & imports**: Explicit type annotations on all functions/methods (`ANN`); put typing-only imports under `if TYPE_CHECKING:` (`TC`); use absolute imports only (`TID`).
- **Size & complexity**: Function CC <= 10 (`C901`/`xenon` <= B, module/avg A), Maintainability Index A (`radon mi`), <= 300 lines per module (`pylint C0302`), <= 5 args, <= 10 branches, <= 5 returns, <= 40 statements (`PLR`).
- **Hygiene & security**: No dead/unused code (`vulture`), no duplicate blocks >= 6 lines (`pylint`), no commented-out code (`ERA`), no `print()` in `src/` (`T20`), no unused args (`ARG`), no blind `except Exception` (`BLE`), timezone-aware datetimes (`DTZ`), `pathlib.Path` over `os.path` (`PTH`), no shadowed builtins (`A`), PEP 8 naming (`N`), structured/lazy logging (`LOG`/`G`), clean raises (`RSE`), no blocking calls in async (`ASYNC`), no SAST security weaknesses in `src/` (`ruff S` + `codeaudit cimode`), no known dependency CVEs (`pip-audit`).
- **No gate gaming**: Never add `# noqa`, `# type: ignore`, `# nosec`, or `# pragma: no cover` to silence a gate without explicit user approval (`PGH` bans bare suppressions). Fix the underlying code.
- **Architecture & deps**: No circular sibling imports (`lint-imports`), no unused/missing/misplaced dependencies (`deptry`), >= 80% branch coverage with strict warnings/xfails (`pytest --cov`).

## Project commands
- **Codebase AST map (1 call)**: `./scripts/map.sh [path ...]` (or `uv run just map`)
- **Single-file / changed-files gate (fast iteration)**: `./scripts/check.sh --fix path/to/file.py [...]` or `./scripts/check.sh --fix --changed` (`uv run just changed`)
- **All repo gates (final check)**: `./scripts/check.sh --fix` (`uv run just fix`)
- Install: `uv sync -q`
- One test (no cov table; `-q --tb=short` is default): `uv run pytest path::test_name`
- Full tests + coverage: `uv run pytest -x --cov`
- Individual tools: `uv run ruff check --fix .`, `uv run ty check --output-format concise`, `uv run deptry .`, `uv run vulture`, `uv run lint-imports`, `uv run pylint`, `uv run codeaudit cimode src`, `uv run xenon -b B -m A -a A src tests`

## Skills (load ONLY when needed)
- `speckit-*`: Spec Kit spec-driven workflow (`constitution` → `specify` → `clarify` → `plan` → `tasks` → `implement`); state in `.specify/`, specs in `specs/`.
- `efficient-exploration`, `concise-output`, `quiet-commands`, `context-hygiene`: Reference skills (already summarized above; do not load on simple isolated calls).

## Commits
- Use Conventional Commits (`type(scope): subject`; types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert). Enforced by a commitizen `commit-msg` hook; `uv run cz commit` gives a guided prompt and `uv run cz bump` cuts a release.
