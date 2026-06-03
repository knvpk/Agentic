## Purpose
Defines how the skill maps the canonical sprint model to provider-native mechanisms, manages sprint membership, handles label CRUD, and displays sprint status.

## Requirements

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

### Requirement: Skill supports adding and removing tickets from the active sprint
The skill SHALL assign a ticket to the current sprint and remove it from the sprint using the provider's mechanism.

#### Scenario: Add ticket to active sprint on GitHub
- **WHEN** user assigns TICK-42 to active sprint (milestone)
- **THEN** skill calls the milestone assignment MCP tool for that issue

#### Scenario: Remove ticket from active sprint
- **WHEN** user removes TICK-42 from the sprint
- **THEN** skill clears the milestone assignment on the issue

### Requirement: Skill supports label CRUD for all providers
The skill SHALL create, list, and assign labels in the provider via MCP tool contracts declared in `providers.json`.

#### Scenario: Create a new label on GitHub
- **WHEN** user creates label "backend" with color
- **THEN** skill calls `mcp__github__create_label` with name and color

#### Scenario: Labels used as epic simulacrum follow the epic: prefix convention
- **WHEN** epics capability is false and a new epic "Auth System" is created
- **THEN** skill creates label `epic:auth-system` in the provider

### Requirement: Sprint status shows canonical state breakdown for active sprint tickets
The skill SHALL display active sprint tickets grouped by canonical state when status mode is invoked. When `context_repos` is configured and non-empty, the breakdown SHALL be shown per repo with cross-repo totals at the bottom.

#### Scenario: Status view groups tickets by canonical state (single repo — unchanged)
- **WHEN** user invokes `/project-management status` and no `context_repos` are configured
- **THEN** output shows counts and ticket IDs grouped under `backlog`, `todo`, `in-progress`, `in-review`, `done`, `blocked` — identical to v1 format

#### Scenario: Multi-repo status shows per-repo breakdown
- **WHEN** user invokes `/project-management status` and `context_repos` contains two configured siblings
- **THEN** output shows one section per repo (anchor + each sibling) each with state counts
- **AND** a totals row aggregates counts across all repos

#### Scenario: Cross-repo blocked tickets include source repo
- **WHEN** a blocked ticket exists in a sibling repo
- **THEN** the blocked list shows the ticket ID annotated with its source repo path (e.g., `TICK-12 (../api-gateway)`)

#### Scenario: Repos with no active sprint omitted from multi-repo board
- **WHEN** a sibling repo has no `active_sprint` in its config
- **THEN** that repo is omitted from the board with a note: `../service-name: no active sprint`

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

### Requirement: sprint plan is a new sub-mode of sprint
The `sprint plan` sub-mode SHALL be triggered by input matching: "plan sprint", "sprint planning", "sprint plan". It SHALL follow the behaviour defined in the `sprint-ceremonies` capability: fetch DoR-checked backlog candidates ranked by priority, present them for selection, and add selected tickets to the active sprint.

#### Scenario: sprint plan is routed correctly
- **WHEN** user inputs "sprint plan" or "plan sprint"
- **THEN** skill routes to the sprint plan sub-mode, not to any other sprint sub-mode

### Requirement: sprint review is a new sub-mode of sprint
The `sprint review` sub-mode SHALL be triggered by input matching: "sprint review", "review sprint", "what shipped". It SHALL follow the behaviour defined in the `sprint-ceremonies` capability.

#### Scenario: sprint review is routed correctly
- **WHEN** user inputs "sprint review" or "what shipped"
- **THEN** skill routes to sprint review

### Requirement: sprint retro is a new sub-mode of sprint
The `sprint retro` sub-mode SHALL be triggered by input matching: "sprint retro", "retrospective", "retro". It SHALL follow the behaviour defined in the `sprint-ceremonies` capability.

#### Scenario: sprint retro is routed correctly
- **WHEN** user inputs "sprint retro" or "retrospective"
- **THEN** skill routes to sprint retro

### Requirement: sprint close is a new sub-mode of sprint
The `sprint close` sub-mode SHALL be triggered by input matching: "sprint close", "close sprint", "end sprint", "finish sprint". It SHALL follow the behaviour defined in the `sprint-ceremonies` capability, including appending to `velocity_log` and clearing `active_sprint`.

#### Scenario: sprint close is routed correctly
- **WHEN** user inputs "sprint close" or "close sprint"
- **THEN** skill routes to sprint close

#### Scenario: sprint close intent routing does not conflict with sprint create
- **WHEN** user inputs "close sprint"
- **THEN** skill routes to sprint close, not sprint create
