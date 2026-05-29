## MODIFIED Requirements

### Requirement: Sprint concept is mapped to the provider's native mechanism
The skill SHALL map the canonical sprint model to: GitHub (milestone), GitLab EE/Premium (native iteration), GitLab CE (scoped label `sprint::*`), Jira (sprint on a software board), Plane (cycle). The mapping SHALL be declared in `providers.json` under `plan_variants` per edition. For GitLab, the active variant (`ce` or `ee-premium`) SHALL be selected based on `gitlab_edition` in `.project/config.yaml`.

#### Scenario: Sprint create on GitHub creates a milestone
- **WHEN** user creates sprint "Sprint 4" on a GitHub-backed project
- **THEN** skill calls `mcp__github__create_milestone` with title "Sprint 4" and a due date

#### Scenario: Sprint create on GitLab CE creates a scoped label
- **WHEN** user creates a sprint on a GitLab CE project
- **THEN** skill derives the label name from the configured `sprint_convention` (e.g. `sprint::2025-W23`)
- **AND** calls `mcp__gitlab__create_label` at group scope with name `sprint::{value}` and description set to the pm-meta issue URL
- **AND** does NOT call `create_milestone`

#### Scenario: Sprint create on GitLab EE uses native iterations
- **WHEN** user creates a sprint on a GitLab EE Premium project
- **THEN** skill calls the native iterations API tool, not `create_milestone` and not `create_label`

#### Scenario: Sprint create on Plane creates a cycle
- **WHEN** user creates sprint "Sprint 4" on a Plane-backed project
- **THEN** skill calls `mcp__plane__create_cycle` with the sprint name and date range

#### Scenario: Sprint create on Jira requires board selection
- **WHEN** user creates a sprint on Jira and no board_id is in config
- **THEN** skill probes available boards via `mcp__jira__list_boards`, presents a selection, stores the chosen board_id in `.project/config.yaml`, then creates the sprint

## ADDED Requirements

### Requirement: Milestone sub-mode rejects sprint-style names for GitLab CE
For GitLab CE projects, the `sprint milestone create` sub-mode SHALL reject any name that matches the active `sprint_convention` pattern (e.g. `Sprint N`, `2025-W23`, `Q2-2025-S1`). On rejection, the skill SHALL redirect the user to `sprint create`.

#### Scenario: Milestone create with sprint-style name rejected on GitLab CE
- **WHEN** user invokes `sprint milestone create "Sprint 4"` on a GitLab CE project
- **THEN** skill outputs `For GitLab CE, sprints use scoped labels (sprint::*). Use sprint create instead. Milestones are for release targets only (e.g. v1.0, Beta).`
- **AND** does not call any milestone API

#### Scenario: Milestone create with release-style name proceeds on GitLab CE
- **WHEN** user invokes `sprint milestone create "v1.0"` on a GitLab CE project
- **THEN** skill calls `mcp__gitlab__create_milestone` normally — milestones remain available for release targets

### Requirement: Init Step 8 notification distinguishes CE label strategy from a degraded fallback
For GitLab CE projects, the init completion notification for sprint strategy SHALL frame label-based sprints as the designed path, not a warning. The notification SHALL include the chosen convention and the pm-meta project URL.

#### Scenario: CE sprint strategy notified at init completion
- **WHEN** init completes on a GitLab CE project
- **THEN** skill outputs `ℹ GitLab CE — sprints use scoped labels (sprint::*). Convention: {convention}. Metadata: {pm_meta_project_url}.`
- **AND** does NOT output `⚠ Sprints not available — using milestone proxy`
