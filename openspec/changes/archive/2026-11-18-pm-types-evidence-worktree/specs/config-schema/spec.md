## ADDED Requirements

### Requirement: project_type_enum and stack_enum include the extended types
The schema's `project_type_enum` SHALL accept `mobile`, `web`, `api`, `microservices`, `qa`, `ai`, `bi`, `cli`, `library`, and `generic`. `stack_enum` SHALL accept the stack values for the five new types listed in `project-type-detection`. The existing rule that `stack` is required when `project_type` is not `generic` SHALL apply to the new types.

#### Scenario: New type validates
- **WHEN** config sets `project_type: qa` and `stack: playwright`
- **THEN** validation passes

#### Scenario: New type without stack is rejected
- **WHEN** config sets `project_type: library` with no `stack`
- **THEN** validation fails because `stack` is required

### Requirement: Schema defines an optional start block with a worktree boolean
The schema SHALL define an optional top-level `start` object with `additionalProperties: false` and one property, `worktree` (boolean, default `true`).

#### Scenario: worktree false is valid
- **WHEN** config contains `start: { worktree: false }`
- **THEN** validation passes

#### Scenario: Non-boolean worktree rejected
- **WHEN** config contains `start: { worktree: "no" }`
- **THEN** validation fails

### Requirement: Schema defines an optional ship.evidence block
The schema SHALL define an optional top-level `ship` object with `additionalProperties: false` containing an optional `evidence` object with `additionalProperties: false` and properties `kinds` (array of `image|link|markdown|text`), `image` (`start_command` string, `base_url` string, `viewports` array of positive integers), `link` (`report_url` string), `markdown` (`spec_path` string), and `extra` (array of strings).

#### Scenario: Valid evidence block
- **WHEN** config contains `ship.evidence.kinds: [image]` and `ship.evidence.image.viewports: [375, 1280]`
- **THEN** validation passes

#### Scenario: Unknown kind rejected
- **WHEN** `ship.evidence.kinds` contains `video`
- **THEN** validation fails

### Requirement: stack value must belong to the declared project_type
When `project_type` is one of `mobile`, `web`, `api`, `microservices`, `qa`, `ai`, `bi`, `cli`, or `library`, the schema SHALL restrict `stack` to the values listed for that type in `project-type-detection` plus `other`. `generic` SHALL impose no restriction beyond `stack_enum`.

#### Scenario: Matching stack passes
- **WHEN** config sets `project_type: web` and `stack: nextjs`
- **THEN** validation passes

#### Scenario: Mismatched stack is rejected
- **WHEN** config sets `project_type: web` and `stack: go`
- **THEN** validation fails

#### Scenario: other is accepted for every typed project
- **WHEN** config sets `project_type: qa` and `stack: other`
- **THEN** validation passes

### Requirement: Schema defines optional base_branch as a string
The schema SHALL define an optional top-level `base_branch` string property (default `main`), the key `ship` mode already reads for the pull-request base.

#### Scenario: base_branch is accepted
- **WHEN** config contains `base_branch: develop`
- **THEN** validation passes and no unknown-property error is raised

#### Scenario: Non-string base_branch rejected
- **WHEN** config contains `base_branch: 5`
- **THEN** validation fails
