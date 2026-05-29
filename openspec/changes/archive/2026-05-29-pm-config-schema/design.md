## Context

`.project/config.yaml` is written by `init` mode and read by every other mode. Its shape varies by provider (`github`, `gitlab`, `jira`, `plane`), GitLab edition (`ce` vs `ee-premium`), and project type. This conditional structure is currently documented only as prose in SKILL.md and scattered YAML examples — no machine-readable contract exists.

The schema lives at `skills/project-management/references/config.schema.json` alongside the existing `providers.json`. It uses JSON Schema draft 2020-12 so that `unevaluatedProperties: false` works correctly across `if/then` branches (draft 2019-09 and earlier have known issues with `additionalProperties` in conditional schemas).

## Goals / Non-Goals

**Goals:**
- Single authoritative schema for all `.project/config.yaml` fields
- `unevaluatedProperties: false` — unknown keys are rejected
- Editor autocomplete and inline validation via `# yaml-language-server: $schema=` header
- Pre-write validation in `init` (Step 4.5)
- Pre-probe validation in `init --probe` (Step 1b) with drift reporting
- SKILL.md Step 5 references schema rather than duplicating field list

**Non-Goals:**
- Runtime schema loading by compiled code — validation is performed by Claude reading the schema against the config object
- Migrating existing hand-created configs automatically
- Validating `providers.json` (separate file, separate contract)

## Decisions

### D1: JSON Schema draft 2020-12 with `unevaluatedProperties: false`

`additionalProperties: false` fails to account for properties introduced by `if/then` branches — validators incorrectly reject valid provider-conditional fields. `unevaluatedProperties: false` (draft 2020-12) evaluates after all applicators (including `if/then`) resolve, making it the correct mechanism for this config shape.

Alternatives considered:
- `additionalProperties: false` (draft-07) — rejected: breaks conditional fields
- CUE language — cleaner conditional syntax but no YAML editor integration, learning curve for contributors
- No strict unknown-key rejection — rejected: defeats the schema's purpose as a typo catcher

### D2: Schema as source of truth; SKILL.md defers to it

SKILL.md Step 5 replaces the inline YAML example block with a reference to the schema file. Field enumeration lives in one place only.

Alternatives considered:
- Schema as parallel artifact mirroring SKILL.md — rejected: guaranteed drift over time

### D3: Schema location at `skills/project-management/references/config.schema.json`

Co-located with `providers.json`. Generated configs reference it with a relative path from the project root.

The `# yaml-language-server:` comment written into `.project/config.yaml` at init time:
```yaml
# yaml-language-server: $schema=../skills/project-management/references/config.schema.json
```

Alternatives considered:
- Copy schema into `.project/` per project — rejected: duplicates the file; updates require re-init
- Absolute path — rejected: not portable across machines

### D4: `active_sprint` as `oneOf` discriminated by `sprint_proxy`

The CE shape (`label_name`, `meta_issue_url`, `start`, `end`) and the standard shape (`id`, `name`) are mutually exclusive. The discriminator is `sprint_proxy` in the parent object.

```json
"active_sprint": {
  "oneOf": [
    { "$ref": "#/$defs/active_sprint_ce" },
    { "$ref": "#/$defs/active_sprint_standard" }
  ]
}
```

The parent-level `if/then` for `sprint_proxy == "label"` also requires `active_sprint` to match the CE `$ref`. This double-enforcement (oneOf + parent if/then) ensures the constraint is caught at both the field and parent levels.

### D5: Validation is declarative, performed by Claude reading schema

There is no runtime JSON Schema validator called in the skill. Validation means: after assembling the config object in Step 4.5, Claude checks each field against the schema definition and surfaces any violations before writing. This is consistent with how the skill operates (prompt-driven, not code-driven).

## Risks / Trade-offs

- **Schema drift from SKILL.md** — mitigated by making schema authoritative; any new field added to the skill must go to the schema first
- **`unevaluatedProperties` validator support** — most modern validators (VS Code YAML ext ≥1.14, ajv ≥8) support draft 2020-12. Older editors fall back silently to no-schema behavior (no breakage, just no validation)
- **Relative `$schema` path breaks if skill directory moves** — low risk; `skills/` is a stable root convention in this project

## Migration Plan

1. Write `config.schema.json`
2. Update SKILL.md: add Step 4.5 (validation before write), Step 1b (validation before probe), update Step 5 to reference schema
3. No migration of existing `.project/config.yaml` files — they gain the `$schema` comment on next `init --probe`

### D6: `branching` block is config-driven with auto-detection fallback

A `branching` object is added to the config with two strategies: `single` (all feature branches cut from `main`, configurable branch name) and `multi` (feature branches cut from `develop`, optional `staging` intermediate, merging up to `main`/production). The `main` field is always required when `branching` is present; `develop` is required only when `strategy == "multi"`; `staging` is optional for `multi`.

When `branching` is absent from config, `start` Step 5a falls back to the existing git topology auto-detection — preserving backward compatibility for projects that have not run `init` with branching config.

The `branching` subschema uses `unevaluatedProperties: false` internally, consistent with the root schema.

Alternatives considered:
- Enum of named presets (gitflow, trunk) — rejected: too opaque, branch names still need to be configurable
- Always requiring `branching` — rejected: breaks existing projects; fallback is cheap and safe

`start` Step 5a priority order:
1. Read `branching` from config → use it, skip git detection
2. `branching` absent → run existing git topology detection (unchanged)

## Open Questions

- None — all key decisions resolved in explore and discussion sessions.
