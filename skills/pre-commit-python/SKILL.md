---
name: pre-commit-python
description: The standard .pre-commit-config.yaml used across this user's Python projects — ruff (lint + format), pre-commit-hooks sanity checks, bandit security scanning, and pyupgrade for py312. Use when creating or editing .pre-commit-config.yaml in a Python project, or reviewing one for consistency with this user's other projects.
---

# Pre-commit Config (Python)

## What This Skill Does

Provides the standard `.pre-commit-config.yaml` this user runs on Python projects — the same four hook repos appear near-identically across projects (`guthenberg`, `iquest_ai`, `secret_mgmt`, and others).

## The Standard Config

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.11.13
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
        name: ruff-lint
      - id: ruff-format
        name: ruff-format

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-toml
      - id: check-merge-conflict
      - id: check-added-large-files
      - id: debug-statements
      - id: check-case-conflict
      - id: check-docstring-first

  - repo: https://github.com/PyCQA/bandit
    rev: 1.8.3
    hooks:
      - id: bandit
        args: [-c, pyproject.toml]

  - repo: https://github.com/asottile/pyupgrade
    rev: v3.20.0
    hooks:
      - id: pyupgrade
        args: [--py312-plus]
```

## Rules

### 1. Use this config verbatim for new Python projects

Copy it as-is rather than assembling hooks from scratch — pin versions match what's already deployed elsewhere so behavior stays consistent across projects.

### 2. `ruff` covers both lint and format — don't add black/isort/flake8

This config replaces the black+isort+flake8 combo entirely. Don't add those alongside it.

### 3. Point bandit's `-c` at whatever config file the project actually uses

The arg after `-c` varies by project (`bandit.yaml`, `pyproject.toml`, `bandit.toml` have all been seen) — match whichever the project already has, or default to `pyproject.toml` for a new project (add a `[tool.bandit]` section there).

### 4. `pyupgrade --py312-plus` tracks the project's minimum Python version

If a project targets an older/newer minimum, change the flag to match (`--py311-plus`, etc.) rather than leaving it mismatched.

### 5. mypy is commonly drafted but left commented out

Several projects have a commented-out mypy block staged for later. Don't silently enable it — ask before turning on a new hook that will start failing CI.

## Quick Checklist

When creating or reviewing `.pre-commit-config.yaml` in a Python project:

- [ ] ruff (lint + format) — no black/isort/flake8 alongside it
- [ ] pre-commit-hooks sanity checks (trailing-whitespace, end-of-file-fixer, check-toml, check-merge-conflict, check-added-large-files, debug-statements, check-case-conflict, check-docstring-first)
- [ ] bandit, `-c` pointed at the project's actual config file
- [ ] pyupgrade, `--pyXXX-plus` matching the project's minimum Python version
- [ ] mypy left commented out unless explicitly requested
