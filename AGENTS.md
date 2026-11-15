# Agent Guidelines — `python-template` (Copier Template Repository)

Keep token usage low and responses concise (answer first, state changes in 1–3 lines, cite `path:line`, ask 1 clarifying question before making architectural or tooling trade-offs).

## 1. Repository Architecture & Boundaries
- **Two-layer layout**:
  - **Root (`/`)**: Copier template definition (`copier.yml`), template maintenance/verification scripts (`scripts/smoke-test.sh`, `scripts/update-template.sh`), root CI (`.github/workflows/ci.yml`, `.gitlab-ci.yml`), release config (`.cz.toml`, `CHANGELOG.md`), and root git hooks (`.pre-commit-config.yaml`).
  - **Template (`template/`)**: Jinja/static skeleton rendered into downstream projects (`_subdirectory: template`).
- **Context hygiene**:
  - **Do NOT read or edit vendored Spec Kit files** (`template/.specify/` and `template/.agents/skills/speckit-*`) unless specifically working on Spec Kit integration. They are refreshed via `./scripts/update-template.sh --speckit`.
  - **Exception**: `template/.specify/memory/constitution.md.jinja` is custom-maintained and automatically preserved by `./scripts/update-template.sh --speckit`.
  - **Never leave scratch directories in the workspace**: Always test template rendering in `mktemp -d` with `trap 'rm -rf "$tmp"' EXIT` (or run `./scripts/smoke-test.sh`).
- **Downstream `copier update` safety**:
  - Preserve `template/{{ _copier_conf.answers_file }}.jinja` so `copier update` works in generated projects.
  - Keep downstream-owned starter files in `copier.yml` `_skip_if_exists` (`src/**/__init__.py`, `tests/test_smoke.py`).
  - Jinja files that are invalid YAML/Python before rendering must use `.jinja` suffixes (or be excluded in root `.pre-commit-config.yaml`) so root hooks pass cleanly.

## 2. Core Design & Tooling Principles
Every tool and configuration in `template/` must follow these principles:
1. **Single responsibility, zero overlap**:
   - **Package/Build/Audit**: `uv` (`uv_build` backend, `uv audit --preview-features audit-command --locked` for CVE scanning, PEP 735 `lint`/`test`/`dev` dependency groups).
   - **Lint, Format, Fast AST & McCabe Complexity**: `ruff` (strict rules: `ANN`, `TC`, `S`, `ERA`, `T20`, `ARG`, `BLE`, `DTZ`, `PTH`, `A`, `N`, `LOG`, `G`, `RSE`, `ASYNC`, `PGH`, `PLR`, `C901` <= 10).
   - **Cognitive Complexity**: `complexipy` (`max-complexity-allowed = 10`, Rust-native; complements `ruff C901` without `radon`/`xenon` overlap).
   - **Static Types**: `ty` (`[tool.ty.terminal]` `output-format = "concise"`, `error-on-warning = true`).
   - **Code Duplication & Module Size**: `pylint` (`disable = ["all"]`, enabled **only** for `duplicate-code` >= 6 lines and `too-many-lines` <= 300 lines).
   - **SAST Security**: `codeaudit` (`codeaudit cimode src`) alongside `ruff S`.
   - **Dead Code, Dependencies & Architecture**: `vulture` (unused code), `deptry` (unused/missing/misplaced deps), `import-linter` (`acyclic_siblings`).
   - **Tests & Coverage**: `pytest 9+` + `pytest-cov` (native `[tool.pytest]` TOML with `strict = true`, `filterwarnings = ["error"]`, `--doctest-modules`, `>= 80%` branch coverage).
   - **Git Hooks & Tasks**: `prek` (Rust drop-in for `.pre-commit-config.yaml`) and `rust-just` (`justfile`).
2. **Prefer Rust-native / built-in tools**: Before adding a Python tool, check if `uv`, `ruff`, `ty`, `complexipy`, or `prek` already covers the responsibility with fewer dependencies and sub-second runtime.
3. **Consolidated config, separated dependency groups**: Keep tool settings consolidated in `template/pyproject.toml.jinja` (avoid extra root config dotfiles) while separating `[dependency-groups]` into `lint`, `test`, and `dev`.
4. **Token-lean output for AI agents**: All scripts (`template/scripts/check.sh`, `template/scripts/map.sh`) must stay quiet on success (`ok: all checks passed`) and print capped diagnostics only on failure.
5. **No gate gaming**: Never weaken rules or add bare suppressions (`# noqa`, `# type: ignore`, `# pragma: no cover`) without explicit user approval.

## 3. Synchronization Checklist for Template Changes
When adding, removing, or modifying a quality gate, tool, CLI flag, or `copier.yml` prompt, update all affected touchpoints together:
- [ ] `template/pyproject.toml.jinja` (`[dependency-groups]` + `[tool.<name>]` section)
- [ ] `template/scripts/check.sh` (both single-file/`--changed` mode and full-repo mode)
- [ ] `template/justfile.jinja` (recipes and gate-count comments)
- [ ] `template/.pre-commit-config.yaml` (hook entry/description)
- [ ] `template/AGENTS.md` & `template/.agents/skills/quiet-commands/SKILL.md` (gate rules, count, and CLI reference)
- [ ] `template/.specify/memory/constitution.md.jinja` (Core Principles & Governance)
- [ ] `template/README.md.jinja` & root `README.md` (feature summary and commands)
- [ ] `scripts/smoke-test.sh` & `scripts/update-template.sh` (assertions and version-pin syncing)

## 4. Verification, Commits & Release Workflow
- **Verify every change**:
  ```bash
  ./scripts/smoke-test.sh        # renders template (--vcs-ref=HEAD) + runs map.sh, check.sh, just, pytest, uv build, re-copy & ci_provider checks
  uvx prek run --all-files       # runs root and template hygiene/spellcheck hooks
  ```
- **Routine version maintenance**:
  ```bash
  ./scripts/update-template.sh           # updates pre-commit hooks via prek + syncs uv tag (Dockerfile) & uv_build bound (pyproject.toml) + smoke test
  ./scripts/update-template.sh --speckit # also refreshes vendored Spec Kit files while preserving constitution.md.jinja
  ```
- **Commits & Releases**:
  - Use Conventional Commits (`feat:`, `fix:`, `chore:`, `ci:`, `docs:`, `refactor:`), enforced by Commitizen.
  - Because `copier update` in downstream projects reads the **latest Git tag**, cut a release after template changes with:
    ```bash
    uvx --from commitizen cz bump --yes
    ```
