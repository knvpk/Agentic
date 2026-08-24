---
name: nix-best-practises
description: Nix conventions and rules for projects using flake.nix — attribute set nesting style, required buildInputs, derivation file layout, flake description conventions, and the paired .envrc for direnv activation. Use when creating or editing a flake.nix or .envrc, adding packages/dependencies to a Nix flake, writing custom Nix derivations, or reviewing Nix code for style.
---

# Nix Best Practises

## What This Skill Does

Provides conventions to follow when a project has (or needs) a `flake.nix` defining its OS-level tool dependencies.

## Rules

### 1. Prefer nested attribute sets over dotted paths

Don't chain config with `.` — keep nested `{}` instead.

```nix
# Good
nixpkgs = {
  url = "github:nixos/nixpkgs?ref=26.05";
};

# Avoid
nixpkgs.url = "something";
```

### 2. Required buildInputs

Every flake must include these in `buildInputs`:

- `nixd`
- `nixfmt-rfc-style`

### 3. Custom derivations go in `nix/derivations`

Keep derivations of custom packages under `nix/derivations` and link them from `flake.nix` — don't inline custom derivations directly in `flake.nix`.

### 4. Keep the flake description minimal

`description` should be as small as possible — just the project name and its purpose (api, cli, ui, etc.), not a full explanation.

### 5. Pair every `flake.nix` with an `.envrc`

Every project with a `flake.nix` gets a matching `.envrc` for direnv, so the devShell activates automatically on `cd`:

```sh

dotenv .env
use flake
```

- `dotenv .env` comes first if the project has a `.env` file — omit it if there's none.
- `use flake` is the default; add `--impure` (`use flake . --impure`) only if the flake actually needs it (e.g. it reads env vars or impure paths at eval time).

## Quick Checklist

When creating or reviewing a `flake.nix`:

- [ ] Attribute sets use nested `{}`, not dotted chains
- [ ] `buildInputs` includes `nixd` and `nixfmt-rfc-style`
- [ ] Custom derivations live in `nix/derivations` and are linked in, not inlined
- [ ] `description` is short: name + purpose only
- [ ] A matching `.envrc` exists with `use flake` (plus `dotenv .env` if applicable)
