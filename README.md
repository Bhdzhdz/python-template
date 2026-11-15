# Python project template (Copier)

Includes: uv (`uv_build` backend, `uv audit` dependency CVE check, PEP 735 `lint`/`test`/`dev` dependency groups), ruff (strict lint + format + McCabe complexity/size/annotations/security/print/commented-code/naming/logging gates), ty (strict type checking with `error-on-warning`), complexipy (Rust cognitive complexity gate), deptry (dependency hygiene), vulture (dead code), import-linter (acyclic module boundaries), pylint (`duplicate-code` & `max-module-lines`), codeaudit (SAST security scan), pytest 9 + coverage (native `[tool.pytest]` TOML with `strict = true`, `-q --tb=short --doctest-modules --no-cov-on-fail`), `justfile` (`rust-just` task runner), `./scripts/map.sh` (1-call AST signature/line-range/field map), `./scripts/check.sh` (single-file, `--changed`, & full-repo quiet gate runner for AI & CI), `.ignore` (token-lean `rg`/`fd` search defaults), `.gitattributes`, `.editorconfig`, `CLAUDE.md` + `AGENTS.md`, `prek` (Rust drop-in pre-commit hook runner: hygiene/ruff on commit; `./scripts/check.sh` on push), GitHub Actions + Dependabot & GitLab CI (`ci_provider`), multi-stage Dockerfile (uv), `.gitignore`, `.dockerignore`, src/ layout with `py.typed`, [Spec Kit](https://github.com/github/spec-kit) (`.specify/` with pre-configured `constitution.md` + `speckit-*` skills in `.agents/skills`, codex integration, v1.2.0).

## Use

```bash
uvx copier copy --trust /path/to/this/repo ~/Projects/my-new-project
# or from git: uvx copier copy --trust gh:<you>/<repo> ./my-project
```

`--trust` is needed because the template runs tasks (`git init`, `uv sync`, `prek install`).

## Update an existing project when the template changes

```bash
uvx copier update --trust
```

## Maintaining this template

```bash
./scripts/smoke-test.sh                # render template + run all gates, copier update & ci_provider checks
./scripts/update-template.sh           # update pre-commit configs (prek) + sync uv/uv_build versions + run smoke test
./scripts/update-template.sh --speckit # also refresh vendored Spec Kit (.specify/ & speckit-* skills)
```

## Commits

Conventional Commits are enforced via [commitizen](https://commitizen-tools.github.io/commitizen/) (`commit-msg` hook; use `cz commit` for a guided prompt, `cz bump` to release) in this repo and in generated projects. In this repo run `uvx prek install` once.
