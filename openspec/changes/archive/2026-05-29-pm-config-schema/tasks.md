## 1. Schema File

- [x] 1.1 Create `skills/project-management/references/config.schema.json` with `$schema: https://json-schema.org/draft/2020-12/schema`, `$id`, `title`, and `unevaluatedProperties: false` at root
- [x] 1.2 Add `$defs`: `provider_name_enum`, `project_type_enum`, `stack_enum`, `sprint_convention_enum`, `capabilities`, `provider_block`, `active_sprint_standard`, `active_sprint_ce`, `branching_single`, `branching_multi`
- [x] 1.3 Define root `properties`: `provider`, `project_type`, `stack`, `active_sprint`, `context_repos`, `branching`, and all GitLab-specific fields
- [x] 1.4 Add `if/then` block: when `provider.name == "gitlab"`, require `gitlab_group`, `gitlab_edition`, `sprint_proxy`, `sprint_label_scope`, `sprint_convention`, `sprint_length_days`, `pm_meta_project`
- [x] 1.5 Add `if/then` block: when `project_type != "generic"`, require `stack`
- [x] 1.6 Add `if/then` block: when `sprint_proxy == "label"`, require `active_sprint` to match `$defs.active_sprint_ce` shape
- [x] 1.7 Define `active_sprint` as `oneOf: [$defs.active_sprint_ce, $defs.active_sprint_standard]`
- [x] 1.8 Define `branching` property using `oneOf: [$defs.branching_single, $defs.branching_multi]`; `branching_single` requires `strategy: "single"` and `main`, with `unevaluatedProperties: false`; `branching_multi` requires `strategy: "multi"`, `main`, and `develop`, with optional `staging`, and `unevaluatedProperties: false`
- [x] 1.9 Add `if/then` block: when `branching.strategy == "multi"`, require `branching.develop`

## 2. SKILL.md — Init Step 4.5 (pre-write validation)

- [x] 2.1 Insert Step 4.5 between Step 4 (API probe) and Step 5 (write): "Assemble config object, validate against `references/config.schema.json`"
- [x] 2.2 Specify validation failure behaviour: list all field-level violations in a single error block, do NOT write the file
- [x] 2.3 Specify validation success behaviour: proceed to Step 5

## 3. SKILL.md — Init --probe Step 1b (pre-probe validation)

- [x] 3.1 Insert Step 1b after Step 1 (read config), gated on `--probe` flag only
- [x] 3.2 Specify drift reporting format: `⚠ <field> <reason> — will re-probe` per violation
- [x] 3.3 Specify that drift does NOT halt the probe — continue to Step 2 regardless
- [x] 3.4 Specify unknown-key drift message format: `⚠ <key> is not a recognised config field — will be removed on re-write`

## 4. SKILL.md — Init Step 5 (schema-authoritative write)

- [x] 4.1 Replace the inline YAML example block in Step 5 with: "Write `.project/config.yaml` conforming to `references/config.schema.json`"
- [x] 4.2 Add instruction: write `# yaml-language-server: $schema=../skills/project-management/references/config.schema.json` as line 1 of the generated file

## 5. SKILL.md — Start Step 5a (branching config override)

- [x] 5.1 Update `start` Step 5a to read `branching` from `.project/config.yaml` first
- [x] 5.2 When `branching.strategy: single` — use `branching.main` as base branch, skip git topology detection
- [x] 5.3 When `branching.strategy: multi` — use `branching.develop` as feature branch base; note `branching.staging` and `branching.main` for merge path context
- [x] 5.4 When `branching` is absent — fall through to existing git topology detection unchanged

## 6. Verification

- [x] 6.1 Validate `config.schema.json` is itself valid JSON Schema draft 2020-12 (no syntax errors)
- [x] 6.2 Confirm a minimal GitHub config passes schema validation
- [x] 6.3 Confirm a full GitLab CE config (all conditional fields present) passes schema validation
- [x] 6.4 Confirm a config with an unknown key is rejected by `unevaluatedProperties: false`
- [x] 6.5 Confirm a GitLab config missing `gitlab_edition` is rejected
- [x] 6.6 Confirm `branching: {strategy: single, main: main}` passes validation
- [x] 6.7 Confirm `branching: {strategy: multi, main: main, develop: develop}` passes validation
- [x] 6.8 Confirm `branching: {strategy: multi, main: main}` (missing develop) is rejected
- [x] 6.9 Confirm `branching: {strategy: single, develop: develop, main: main}` is rejected (unknown field for single)
