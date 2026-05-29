## Why

`.project/config.yaml` has complex conditional structure (provider-specific fields, edition-dependent sprint shapes, project-type-dependent stack field) but no machine-readable contract — the structure only exists as prose and examples in SKILL.md. This means `init` can write invalid configs silently, hand-edited configs can drift undetected, and there is no editor autocomplete or inline validation.

## What Changes

- Add `skills/project-management/references/config.schema.json` — a JSON Schema (draft 2020-12) defining the full shape of `.project/config.yaml`, using `unevaluatedProperties: false` to correctly handle conditional fields via `if/then`
- SKILL.md Step 5 (write config) becomes authoritative via schema reference — the inline YAML example block is replaced by a pointer to the schema
- `init` Step 4.5 added: assemble config in memory → validate against schema → only write if valid; surface field-level errors if not
- `init --probe` Step 1b added: validate existing config against schema before re-probing; report drift to user
- `init` writes `# yaml-language-server: $schema=` comment at top of every generated `.project/config.yaml` for editor autocomplete

## Capabilities

### New Capabilities

- `config-schema`: JSON Schema definition for `.project/config.yaml` — field types, enums, required fields, conditional blocks per provider, `unevaluatedProperties: false`
- `config-validation`: Validation step wired into `init` (pre-write) and `init --probe` (pre-probe); error reporting format for schema violations

### Modified Capabilities

- `provider-adapter`: `init` Step 5 references schema as authoritative field list instead of duplicating inline YAML example

## Impact

- `skills/project-management/references/config.schema.json` — new file
- `skills/project-management/SKILL.md` — Steps 5, 1b (--probe), and new Step 4.5
- All generated `.project/config.yaml` files gain a `# yaml-language-server:` header comment
