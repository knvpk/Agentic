## Purpose
Defines the JSON Schema that is the authoritative source of truth for all fields in `.project/config.yaml`, including provider-conditional requirements, enumerated values, and branching topology constraints.

## Requirements

### Requirement: Schema file exists at the canonical path
The file `skills/project-management/references/config.schema.json` SHALL exist and conform to JSON Schema draft 2020-12 (`$schema: https://json-schema.org/draft/2020-12/schema`).

#### Scenario: Schema is discoverable at canonical path
- **WHEN** a tool or editor loads `skills/project-management/references/config.schema.json`
- **THEN** it parses as valid JSON Schema draft 2020-12

### Requirement: Schema uses unevaluatedProperties to reject unknown keys
The schema SHALL declare `"unevaluatedProperties": false` at the root level and SHALL NOT use `additionalProperties: false` for this purpose, so that conditional fields introduced by `if/then` branches are correctly permitted.

#### Scenario: Unknown top-level key is rejected
- **WHEN** `.project/config.yaml` contains a key not defined in the schema (e.g. `typo_field: true`)
- **THEN** validation fails with a message identifying the unexpected property

#### Scenario: GitLab-conditional fields are permitted when provider is gitlab
- **WHEN** `.project/config.yaml` sets `provider.name: gitlab` and includes `gitlab_group`, `gitlab_edition`, `sprint_proxy`, `sprint_label_scope`, `sprint_convention`, `sprint_length_days`, `pm_meta_project`
- **THEN** validation passes and no unknown-property error is raised for those fields

### Requirement: Schema defines reusable subschemas via $defs
The schema SHALL define the following `$defs` entries: `provider_block`, `capabilities`, `active_sprint_standard`, `active_sprint_ce`, `project_type_enum`, `provider_name_enum`, `sprint_convention_enum`, `stack_enum`, `branching_single`, `branching_multi`.

#### Scenario: active_sprint_ce and active_sprint_standard are independently referenceable
- **WHEN** the schema is loaded
- **THEN** `$defs.active_sprint_ce` and `$defs.active_sprint_standard` exist as valid subschemas with non-overlapping required fields

### Requirement: Provider name is constrained to the four supported values
The schema SHALL restrict `provider.name` to the enum `["github", "gitlab", "jira", "plane"]`.

#### Scenario: Unsupported provider name is rejected
- **WHEN** `.project/config.yaml` sets `provider.name: linear`
- **THEN** validation fails citing an enum constraint violation

### Requirement: GitLab-specific fields are required when provider is gitlab
The schema SHALL use an `if/then` block: when `provider.name == "gitlab"`, the fields `gitlab_group`, `gitlab_edition`, `sprint_proxy`, `sprint_label_scope`, `sprint_convention`, `sprint_length_days`, and `pm_meta_project` SHALL be required.

#### Scenario: Missing gitlab_edition on gitlab config is rejected
- **WHEN** `provider.name: gitlab` is set but `gitlab_edition` is absent
- **THEN** validation fails citing a missing required property

#### Scenario: gitlab_edition is not required for non-gitlab providers
- **WHEN** `provider.name: github` and `gitlab_edition` is absent
- **THEN** validation passes

### Requirement: stack field is required when project_type is not generic
The schema SHALL use an `if/then` block: when `project_type` is not `"generic"`, `stack` SHALL be required.

#### Scenario: Missing stack on non-generic project is rejected
- **WHEN** `project_type: api` is set but `stack` is absent
- **THEN** validation fails citing `stack` as a missing required property

#### Scenario: stack is optional for generic projects
- **WHEN** `project_type: generic` and `stack` is absent
- **THEN** validation passes

### Requirement: active_sprint shape is discriminated by sprint_proxy
The `active_sprint` field SHALL use `oneOf` referencing `$defs.active_sprint_ce` (fields: `label_name`, `meta_issue_url`, `start`, `end`) and `$defs.active_sprint_standard` (fields: `id`, `name`). When `sprint_proxy == "label"`, only the CE shape SHALL be valid.

#### Scenario: CE shape is valid when sprint_proxy is label
- **WHEN** `sprint_proxy: label` and `active_sprint` contains `label_name`, `meta_issue_url`, `start`, `end`
- **THEN** validation passes

#### Scenario: Standard shape is rejected when sprint_proxy is label
- **WHEN** `sprint_proxy: label` and `active_sprint` contains only `id` and `name`
- **THEN** validation fails

### Requirement: branching block defines strategy and branch names
The schema SHALL define a `branching` object property with `unevaluatedProperties: false` containing:
- `strategy`: required enum `["single", "multi"]`
- `main`: required string (default `"main"`) — the production/main branch name
- `develop`: string — required only when `strategy == "multi"`, default `"develop"`
- `staging`: string — optional, valid only when `strategy == "multi"`, default `"staging"`

When `branching` is absent, the field is optional and `start` mode falls back to git topology auto-detection. When `branching` is present, `strategy` and `main` are always required.

#### Scenario: Single strategy requires only main
- **WHEN** `branching.strategy: single` and `branching.main: main` are set with no other fields
- **THEN** validation passes

#### Scenario: Multi strategy requires develop
- **WHEN** `branching.strategy: multi` and `branching.develop` is absent
- **THEN** validation fails citing `develop` as a missing required property

#### Scenario: staging is optional for multi
- **WHEN** `branching.strategy: multi` and `branching.staging` is absent
- **THEN** validation passes

#### Scenario: staging is rejected on single strategy
- **WHEN** `branching.strategy: single` and `branching.staging: staging` is set
- **THEN** validation fails (unknown property via `unevaluatedProperties: false` on the branching subschema)

#### Scenario: develop is rejected on single strategy
- **WHEN** `branching.strategy: single` and `branching.develop: develop` is set
- **THEN** validation fails (unknown property via `unevaluatedProperties: false` on the branching subschema)

#### Scenario: Missing branching block is valid
- **WHEN** `.project/config.yaml` has no `branching` field
- **THEN** validation passes and start mode uses git topology detection

### Requirement: Schema is the authoritative source of truth for config fields
The `init` Step 5 in SKILL.md SHALL reference `config.schema.json` as the canonical field definition rather than enumerating fields inline. Any new field added to the config MUST be defined in the schema first.

#### Scenario: New config field is added to schema before SKILL.md
- **WHEN** a new config field is required
- **THEN** it is defined in `config.schema.json` with type, description, and constraints before any SKILL.md reference is written
