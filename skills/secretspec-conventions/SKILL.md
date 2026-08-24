---
name: secretspec-conventions
description: Conventions for secretspec.toml (declarative secrets manifest) used across this user's projects — schema shape, provider configuration, the newer-than-nixpkgs Nix override, and the Taskfile export task. Use when creating or editing secretspec.toml, wiring secretspec into a flake.nix or Taskfile.yaml, or reviewing secrets handling for a project.
---

# secretspec Conventions

## What This Skill Does

Provides conventions for [secretspec](https://github.com/cachix/secretspec) manifests, seen in `kora/secretspec.toml`, `kora/nix/derivations/secretspec.nix`, and `jnana_sena`'s per-app/per-package `secretspec.toml` files.

## The Manifest Shape

```toml
[project]
name = "kora"
revision = "1.0"

[providers]
openbao = "openbao://kora%2Flocal@openbao.tail7bd60b.ts.net/kv"

[profiles.default]
DB_USER = { description = "Postgres control-plane user", default = "user1", providers = ["openbao"] }
DB_PASSWORD = { description = "Postgres control-plane password", required = true, providers = ["openbao"], generate = true, type = "password" }
GRAPH_DB_ENCRYPTION_KEY = { description = "FalkorDB browser encryption key", required = true, providers = ["openbao"], generate = true, type = "hex" }
```

## Rules

### 1. Every secret gets a `description`

No bare keys — every entry states what it's for, even short ones. This is the primary documentation for what secrets a service needs.

### 2. Mark generated secrets with `generate` + `type`

If the value is a credential the system should mint rather than something a human supplies (passwords, API keys, encryption keys), set `required = true, generate = true, type = "password" | "base64" | "hex"`. For a specific byte length instead of the type default, use `generate = { bytes = N }` (seen for a 32-byte Pulumi passphrase).

### 3. Non-generated values that have a sane default use `default`, not `required`

```toml
DB_USER = { description = "Postgres control-plane user", default = "user1", providers = ["openbao"] }
```

Reserve `required = true` for values with no safe default (passwords, keys, external API credentials).

### 4. Choose provider wiring based on whether the project is single-developer or shared

- **Single project, one deployment target** (e.g. `kora`, backed by a shared OpenBao instance): declare a `[providers]` alias table in the manifest so `secretspec export --provider openbao ...` works directly.
- **Per-app/per-package manifests in a monorepo with individual developer setups** (e.g. `jnana_sena`'s `apps/student`, `apps/info`, `packages/infra`): skip the `[providers]` table — it isn't resolved without each developer's own `~/.config/secretspec/config.toml`. Instead, leave a comment documenting the explicit provider invocation:

  ```toml
  # Run secretspec commands here with SECRETSPEC_PROVIDER=dotenv://.env (or `-p dotenv://.env`) —
  # a project-level [providers] alias table is not resolved without each developer's own
  # ~/.config/secretspec/config.toml, so the provider is passed explicitly instead.
  ```

### 5. nixpkgs' `secretspec` trails upstream — override it, don't wait

If the project needs a `secretspec` feature newer than what's packaged (e.g. `--reason` / `require_reason` support), override the derivation rather than pinning an older workflow. Following the `nix/derivations` layout from [[nix-best-practises]]:

```nix
# nix/derivations/secretspec.nix
# nixpkgs' `secretspec` package trails upstream releases; override to 0.19.1
# (not packaged in any nixpkgs revision yet) for its require_reason support.
{ pkgs }:

pkgs.secretspec.overrideAttrs (finalAttrs: old: {
  version = "0.19.1";
  src = pkgs.fetchCrate {
    pname = "secretspec";
    version = "0.19.1";
    hash = "sha256-...";
  };
  cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src pname version;
    hash = "sha256-...";
  };
  doCheck = false;
})
```

Wire it into `flake.nix`: `secretspec = import ./nix/derivations/secretspec.nix { inherit pkgs; };`, then reference that binding (not `pkgs.secretspec`) in `buildInputs`. Comment why the override exists and which upstream version/feature it's for. If the project doesn't need a newer feature, `pkgsUnstable.secretspec` (nixpkgs-unstable channel) is a lighter alternative — used as-is in `jnana_sena`.

### 6. Export to `.env` via a Taskfile task, with a `--reason`

```yaml
secrets:export:
  desc: Export secrets from OpenBao into .env for docker compose to consume.
  cmds:
    - secretspec export --provider openbao --format dotenv --reason "Exporting <project> secrets to .env for docker compose" > .env
```

The `--reason` string should say what the export is for and where the result is consumed — it's an audit trail on the provider side, not a free-form comment. See [[taskfile-conventions]] for the surrounding Taskfile shape.

## Quick Checklist

When creating or reviewing a `secretspec.toml` (or its surrounding wiring):

- [ ] Every secret has a `description`
- [ ] Generated credentials use `generate = true` (or `generate = { bytes = N }`) with an explicit `type`
- [ ] Non-generated values with a safe default use `default:`, not `required: true`
- [ ] `[providers]` table present only for single-target projects; per-developer/monorepo manifests instead carry a comment documenting the explicit `-p`/`SECRETSPEC_PROVIDER` invocation
- [ ] If a newer `secretspec` feature is needed than nixpkgs carries, it's overridden in `nix/derivations/secretspec.nix` with a comment explaining why
- [ ] `.env` export goes through a Taskfile task with a meaningful `--reason`
