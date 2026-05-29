## MODIFIED Requirements

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
