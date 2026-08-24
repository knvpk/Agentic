---
name: backend-scaffold
description: Bootstrap files every new backend project needs — Nix dev shell, task runner, pre-commit/ruff for Python, and OpenAPI spec init. States this user's default tool for each concern and points to the dedicated convention skill for full rules. Use when starting a new backend service or repo from scratch, or when any of these foundational files are missing.
compatibility: Requires Nix with flakes enabled, go-task >= 3 (or Just), pre-commit >= 3. Python projects require ruff >= 0.4.
metadata:
  author: knvpk
  version: "2.0"
---

## Overview

Every new backend repo starts with the same four scaffolding concerns: a reproducible dev shell, a task runner, pre-commit/linting for Python, and an OpenAPI spec stub. This skill names the default tool for each and gives the minimal starting file — for the full rule set behind each default, follow the linked skill.

---

## 1. Dev shell — Nix (`flake.nix`)

Default. Gives every developer and CI runner identical tooling regardless of host OS. Full conventions — required `buildInputs`, attribute-set style, derivation layout, the paired `.envrc` — are in [[nix-best-practises]]; this is just the minimal starting point.

```nix
{
  description = "<project-name> — <purpose>";

  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs?ref=26.05";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [ git jq go-task nixd nixfmt-rfc-style ];
    };
  };
}
```

```sh
# .envrc

dotenv .env
use flake
```

---

## 2. Task runner — Taskfile (recommended), justfile as alternative

Default `Taskfile.yaml` (go-task) for new projects — full naming/structure rules (colon-namespaced tasks, `desc` on every task, dotenv layering, `prompt:` on destructive tasks) are in [[taskfile-conventions]]. Use `justfile` instead only if the user asks for Just, or the project already has one — see [[justfile-conventions]].

```yaml
# Taskfile.yaml
version: "3"
dotenv: ['.env']

tasks:
  run:
    desc: Start the application
    cmds:
      - <start command>

  test:
    desc: Run tests
    cmds:
      - <test command>

  lint:
    desc: Run pre-commit on all files
    cmds:
      - pre-commit run --all-files
```

Commit `.env.example` with every variable listed but no real values; never commit `.env`.

---

## 3. Linting & formatting

**Python — ruff.** Default and only linter/formatter; never add `black`/`isort`/`flake8` alongside it. Wire it into `.pre-commit-config.yaml` using the standard hook set (also includes `bandit` and `pyupgrade`) — see [[pre-commit-python]] for the full config and rationale.

```toml
# ruff.toml
target-version = "py312"
line-length = 100

[lint]
select = ["E", "F", "I", "B", "UP"]

[format]
quote-style = "double"
```

**Terraform** — no dedicated convention skill yet, so the hook list lives here:

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

Mixed Python + Terraform: merge into one file, Python hooks first (per [[pre-commit-python]] ordering), Terraform hooks appended last.

Install after cloning: `task install` (or `pre-commit install` directly).

---

## 4. OpenAPI spec init

Add an `openapi.yaml` stub at the repo root (or under `docs/` for larger projects) — a machine-readable API contract from day one, even before any endpoints exist.

```yaml
# openapi.yaml
openapi: "3.1.0"

info:
  title: <Project Name> API
  version: "0.1.0"

servers:
  - url: http://localhost:8000
    description: Local development

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

Grow this file alongside the implementation — don't let endpoints drift ahead of the spec.

---

## Checklist

When scaffolding a new backend repo, verify:

- [ ] `flake.nix` (`buildInputs` per [[nix-best-practises]]) + matching `.envrc`
- [ ] `Taskfile.yaml` (or `justfile`) per [[taskfile-conventions]] / [[justfile-conventions]]
- [ ] `.env.example` committed; `.env` in `.gitignore`
- [ ] If the project needs managed secrets, `secretspec.toml` — see [[secretspec-conventions]]
- [ ] `.pre-commit-config.yaml` matching the stack — Python config per [[pre-commit-python]]
- [ ] `ruff.toml` (Python projects only)
- [ ] `openapi.yaml` stub at repo root
