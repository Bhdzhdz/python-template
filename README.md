# Python project template (Copier)

Includes: uv, ruff (strict lint + format + complexity/size/annotations/security/print/commented-code gates), ty, deptry (dependency hygiene), vulture (dead code), import-linter (acyclic module boundaries), pylint (`duplicate-code`), codeaudit (SAST security scan), radon + xenon (cyclomatic complexity & maintainability index), pytest + coverage (`-q --tb=short` by default), `./scripts/map.sh` (1-call AST signature/line-range map), `./scripts/check.sh` (single-file & full-repo quiet gate runner for AI & CI), `.ignore` (token-lean `rg`/`fd` search defaults), pre-commit (hygiene/ruff on commit; `./scripts/check.sh` on push), Dockerfile (uv), `.gitignore`, `.dockerignore`, src/ layout, [Spec Kit](https://github.com/github/spec-kit) (`.specify/` with pre-configured `constitution.md` + `speckit-*` skills in `.agents/skills`, codex integration, v1.2.0).

## Use

```bash
uvx copier copy --trust /path/to/this/repo ~/Projects/my-new-project
# or from git: uvx copier copy --trust gh:<you>/<repo> ./my-project
```

`--trust` is needed because the template runs tasks (`git init`, `uv sync`, `pre-commit install`).

## Update an existing project when the template changes

```bash
uvx copier update --trust
```

## Commits

Conventional Commits are enforced via [commitizen](https://commitizen-tools.github.io/commitizen/) (pre-commit `commit-msg` hook; use `cz commit` for a guided prompt, `cz bump` to release) in this repo and in generated projects. In this repo run `uvx pre-commit install` once.
