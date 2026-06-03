## ADDED Requirements

### Requirement: Schema defines optional wip_limit field as a positive integer
The `config.schema.json` SHALL include `wip_limit` as an optional top-level property of type `integer` with `minimum: 1`. When absent, no WIP limit is enforced by the skill.

#### Scenario: wip_limit accepts a positive integer
- **WHEN** `.project/config.yaml` contains `wip_limit: 3`
- **THEN** schema validation passes

#### Scenario: wip_limit rejects zero or negative values
- **WHEN** `.project/config.yaml` contains `wip_limit: 0`
- **THEN** schema validation fails citing the minimum constraint

#### Scenario: wip_limit is optional
- **WHEN** `.project/config.yaml` does not contain `wip_limit`
- **THEN** schema validation passes

### Requirement: Schema defines optional definition_of_done field as an array of enumerated strings
The `config.schema.json` SHALL include `definition_of_done` as an optional top-level property of type `array`, where each item is constrained to the enum `["has_bdd", "has_assignee"]`. An empty array SHALL be valid (effectively disables the gate).

#### Scenario: definition_of_done accepts valid criteria list
- **WHEN** `.project/config.yaml` contains `definition_of_done: [has_bdd, has_assignee]`
- **THEN** schema validation passes

#### Scenario: definition_of_done rejects unknown criteria
- **WHEN** `.project/config.yaml` contains `definition_of_done: [has_pr_link]`
- **THEN** schema validation fails citing an enum constraint violation on the item

#### Scenario: definition_of_done is optional
- **WHEN** `.project/config.yaml` does not contain `definition_of_done`
- **THEN** schema validation passes

### Requirement: Schema defines optional velocity_log field as an array of sprint-point-record objects
The `config.schema.json` SHALL include `velocity_log` as an optional top-level property of type `array`. Each item SHALL be an object with: `sprint` (required string), `points_committed` (required, type `["number", "null"]`), `points_completed` (required number, minimum 0). Additional properties on items SHALL be rejected.

#### Scenario: velocity_log entry with all fields is valid
- **WHEN** `velocity_log` contains `[{ sprint: "sprint::2025-W23", points_committed: 21, points_completed: 18 }]`
- **THEN** schema validation passes

#### Scenario: velocity_log entry with null committed is valid
- **WHEN** `velocity_log` contains `[{ sprint: "sprint::2025-W23", points_committed: null, points_completed: 13 }]`
- **THEN** schema validation passes

#### Scenario: velocity_log entry missing sprint field is rejected
- **WHEN** a velocity_log item has no `sprint` key
- **THEN** schema validation fails citing a missing required property

#### Scenario: velocity_log is optional
- **WHEN** `.project/config.yaml` does not contain `velocity_log`
- **THEN** schema validation passes
