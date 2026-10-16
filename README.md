# Python project template (Copier)

Includes: uv, ruff (lint + format), ty, pytest + coverage, pre-commit (hygiene/ruff on commit; ty + pytest on push), Dockerfile (uv), `.gitignore`, `.dockerignore`, src/ layout, [Spec Kit](https://github.com/github/spec-kit) (`.specify/` + `speckit-*` skills in `.agents/skills`, codex integration, v1.2.0).

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
