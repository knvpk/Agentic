---
name: backend-scaffold
description: Bootstrap files every new backend project needs — flake.nix dev shell, Taskfile environment loading, pre-commit linters, ruff config for Python, and OpenAPI spec init. Use when starting a new backend service or repo from scratch, or when any of these foundational files are missing.
compatibility: Requires Nix with flakes enabled, go-task >= 3, pre-commit >= 3. Python projects require ruff >= 0.4.
metadata:
  author: knvpk
  version: "1.0"
---

## Overview

Every new backend repo starts with the same five scaffolding concerns: a reproducible dev shell, a task runner with environment layering, pre-commit quality gates, a formatter/linter config (Python), and an OpenAPI spec stub. This skill covers all five with concrete file contents and the rationale behind each decision.

---

## 1. `flake.nix` — Reproducible dev shell

Add a `flake.nix` at the repo root so every developer and CI runner gets identical tooling regardless of host OS or distro.

**Minimum tool set:** `git`, `jq`, `go-task`. Extend with language-specific tools (e.g. `python312`, `ruff`, `terraform`) inside `packages` as needed.

```nix
{
  description = "Dev shell for <project-name>";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            git
            jq
            go-task
            # add language runtimes and tools below
          ];

          shellHook = ''
            echo "dev shell ready"
          '';
        };
      });
}
```

Enter the shell with `nix develop`. Pin `nixpkgs` to a specific rev for fully reproducible builds:

```
nixpkgs.url = "github:NixOS/nixpkgs/a1b2c3d4...";
```

---

## 2. `Taskfile.yaml` — Task runner with environment layering

Use [go-task](https://taskfile.dev) as the task runner. The core pattern is a two-layer env loading: `.env` holds common defaults, `.env.{{.APP_ENV}}` holds environment-specific overrides that are merged on top.

```yaml
# Taskfile.yaml
version: "3"

dotenv:
  - .env
  - ".env.{{.APP_ENV}}"   # overrides .env; silently ignored if file missing

vars:
  APP_ENV:
    sh: echo "${APP_ENV:-dev}"

tasks:
  default:
    desc: List available tasks
    cmds:
      - task --list

  run:
    desc: Start the application (APP_ENV={{.APP_ENV}})
    cmds:
      - <your start command here>

  test:
    desc: Run tests
    cmds:
      - <your test command here>

  lint:
    desc: Run pre-commit on all files
    cmds:
      - pre-commit run --all-files

  install:
    desc: Install pre-commit hooks
    cmds:
      - pre-commit install
```

**Env file convention:**

```
.env               # shared defaults — commit a .env.example instead
.env.dev           # development overrides
.env.staging       # staging overrides
.env.prod          # production overrides — never commit
```

`APP_ENV` selects the overlay. Running `APP_ENV=staging task run` merges `.env.staging` on top of `.env`.

Always commit `.env.example` with every variable listed but no real values. Never commit `.env` or any overlay that contains credentials.

---

## 3. `.pre-commit-config.yaml` — Quality gates

Every repo requires a `.pre-commit-config.yaml`. The hook set varies by stack.

### Python projects

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-toml
      - id: check-merge-conflict
      - id: detect-private-key

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.11.0   # pin to latest stable
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

### Terraform projects

```yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-merge-conflict
      - id: detect-private-key

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.99.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
        args:
          - --args=--config=__GIT_WORKING_DIR__/.tflint.hcl
      - id: terraform_checkov
        args:
          - --args=--quiet
```

### Mixed Python + Terraform

Merge both hook lists into a single file. Put `pre-commit-hooks` first, then `ruff-pre-commit`, then `pre-commit-terraform`.

Install after cloning: `task install` (or `pre-commit install` directly).

---

## 4. `ruff.toml` — Python linter/formatter config

For Python projects, keep ruff config in a standalone `ruff.toml` at the repo root rather than embedding it in `pyproject.toml`. This keeps the file scannable and allows ruff to be used in repos that do not have a `pyproject.toml` (e.g. scripts-only repos).

```toml
# ruff.toml
target-version = "py312"
line-length = 100

[lint]
select = [
  "E",    # pycodestyle errors
  "W",    # pycodestyle warnings
  "F",    # pyflakes
  "I",    # isort
  "B",    # flake8-bugbear
  "UP",   # pyupgrade
  "N",    # pep8-naming
  "SIM",  # flake8-simplify
]
ignore = [
  "E501",  # line too long — handled by formatter
]

[lint.isort]
known-first-party = ["<your_package_name>"]

[format]
quote-style = "double"
indent-style = "space"
```

Adjust `target-version` and `known-first-party` per project. Do not duplicate these settings in `pyproject.toml`; let `ruff.toml` be the single source of truth.

---

## 5. OpenAPI spec init

Add an `openapi.yaml` stub at the repo root (or under `docs/` for larger projects). This gives the team a machine-readable API contract from day one, even before any endpoints are implemented.

```yaml
# openapi.yaml
openapi: "3.1.0"

info:
  title: <Project Name> API
  version: "0.1.0"
  description: |
    API specification for <Project Name>.

servers:
  - url: http://localhost:8000
    description: Local development
  - url: https://api.dev.<your-domain>
    description: Development

tags: []

paths: {}

components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

security:
  - bearerAuth: []
```

Grow this file alongside the implementation. Paths and schemas added here become the contract that consumers program against — do not let implementation drift ahead of the spec.

---

## Checklist

When scaffolding a new backend repo, verify all five files are present:

- [ ] `flake.nix` with `git`, `jq`, `go-task` in `packages`
- [ ] `Taskfile.yaml` with `dotenv` two-layer loading and a `lint` task
- [ ] `.env.example` committed; `.env` in `.gitignore`
- [ ] `.pre-commit-config.yaml` matching the project stack (Python / Terraform / both)
- [ ] `ruff.toml` (Python projects only)
- [ ] `openapi.yaml` stub at repo root
