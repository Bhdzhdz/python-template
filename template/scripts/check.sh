#!/usr/bin/env bash
# Unified quality gate runner. Prints output ONLY on failure to minimize token usage.
# Usage:
#   ./scripts/check.sh [--fix]                         # Run all 11 repo-wide gates + coverage
#   ./scripts/check.sh [--fix] --changed               # Fast check on git-changed Python files
#   ./scripts/check.sh [--fix] path/to/file.py [...]   # Fast check on specific file(s) + matching unit tests
set -uo pipefail

fix=0
changed=0
targets=()
for arg in "$@"; do
    case "$arg" in
        --fix) fix=1 ;;
        --changed) changed=1 ;;
        *) targets+=("$arg") ;;
    esac
done

if [[ "$changed" -eq 1 ]]; then
    while IFS= read -r f; do
        [[ -n "$f" && -f "$f" ]] && targets+=("$f")
    done < <(
        {
            git diff --name-only --diff-filter=ACMRTUXB -- '*.py' 2>/dev/null || true
            git diff --cached --name-only --diff-filter=ACMRTUXB -- '*.py' 2>/dev/null || true
            git ls-files --others --exclude-standard -- '*.py' 2>/dev/null || true
        } | sort -u
    )
    if [[ ${#targets[@]} -eq 0 ]]; then
        echo "ok: no changed python files"
        exit 0
    fi
fi

failed=0

run_gate() {
    local name="$1"
    shift
    local out
    if ! out="$("$@" 2>&1)"; then
        echo "FAIL [$name]:"
        printf '%s\n' "$out" | head -n 60 || true
        failed=1
    fi
}

run_mi_gate() {
    local out status=0
    out="$(uv run radon mi -n B -s "$@" 2>&1)" || status=$?
    if [[ "$status" -ne 0 || -n "$out" ]]; then
        echo "FAIL [radon-mi] (files below Maintainability Index rank A):"
        printf '%s\n' "$out" | head -n 60 || true
        failed=1
    fi
}

if [[ ${#targets[@]} -gt 0 ]]; then
    if [[ "$fix" -eq 1 ]]; then
        uv run ruff check --fix -q "${targets[@]}" || true
        uv run ruff format -q "${targets[@]}"
    fi
    run_gate "ruff-lint" uv run ruff check "${targets[@]}"
    run_gate "ruff-format" uv run ruff format --check -q "${targets[@]}"
    run_gate "ty" uv run ty check --output-format concise "${targets[@]}"
    run_gate "xenon-complexity" uv run xenon --max-absolute B --max-modules A --max-average A "${targets[@]}"
    run_mi_gate "${targets[@]}"

    test_files=()
    for target in "${targets[@]}"; do
        if [[ "$target" == src/* && -f "$target" ]]; then
            run_gate "codeaudit ($target)" uv run codeaudit cimode "$target"
            base="$(basename "$target" .py)"
            while IFS= read -r tf; do
                [[ -n "$tf" ]] && test_files+=("$tf")
            done < <(find tests -type f -name "test_${base}.py" 2>/dev/null || true)
        elif [[ "$target" == tests/* && -f "$target" ]]; then
            test_files+=("$target")
        fi
    done

    if [[ ${#test_files[@]} -gt 0 ]]; then
        mapfile -t unique_tests < <(printf '%s\n' "${test_files[@]}" | sort -u)
        run_gate "pytest" uv run pytest "${unique_tests[@]}" -x -o addopts="-q --tb=short --strict-markers --strict-config"
    fi
else
    if [[ "$fix" -eq 1 ]]; then
        uv run ruff check --fix -q . || true
        uv run ruff format -q .
    fi
    run_gate "ruff-lint" uv run ruff check .
    run_gate "ruff-format" uv run ruff format --check -q .
    run_gate "ty" uv run ty check --output-format concise
    run_gate "deptry" uv run deptry .
    run_gate "vulture" uv run vulture
    run_gate "import-linter" uv run lint-imports
    run_gate "pylint" uv run pylint
    run_gate "codeaudit" uv run codeaudit cimode src
    run_gate "xenon-complexity" uv run xenon --max-absolute B --max-modules A --max-average A src tests
    run_mi_gate src tests
    run_gate "pytest" uv run pytest -x --cov --no-cov-on-fail
fi

if [[ "$failed" -eq 0 ]]; then
    echo "ok: all checks passed"
fi
exit "$failed"
