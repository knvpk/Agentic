## ADDED Requirements

### Requirement: Sprint concept is mapped to the provider's native mechanism
The skill SHALL map the canonical sprint model to: GitHub (milestone), GitLab (milestone), Jira (sprint on a software board), Plane (cycle). The mapping SHALL be declared in `providers.json`.

#### Scenario: Sprint create on GitHub creates a milestone
- **WHEN** user creates sprint "Sprint 4" on a GitHub-backed project
- **THEN** skill calls `mcp__github__create_milestone` with title "Sprint 4" and a due date

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
The skill SHALL display active sprint tickets grouped by canonical state when status mode is invoked.

#### Scenario: Status view groups tickets by canonical state
- **WHEN** user invokes `/project-management status`
- **THEN** output shows counts and ticket IDs grouped under `backlog`, `todo`, `in-progress`, `in-review`, `done`, `blocked`
