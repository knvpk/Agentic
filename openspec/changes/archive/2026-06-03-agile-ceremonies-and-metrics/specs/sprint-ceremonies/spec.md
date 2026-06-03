## ADDED Requirements

### Requirement: sprint plan fetches backlog candidates and checks DoR before sprint assignment
The skill SHALL fetch all tickets in the `backlog` or `todo` state that are not assigned to the active sprint, rank them by priority (high → medium → low → none), and flag any ticket that fails the Definition of Ready (DoR). A ticket passes DoR if it has a non-empty description and at least one label. The user SHALL select tickets interactively; selected tickets are added to the active sprint. No capacity calculation is performed.

#### Scenario: Candidates are ranked by priority
- **WHEN** user invokes `sprint plan`
- **THEN** tickets are listed in order high → medium → low → unset priority, each showing ID, title, estimate (or `—`), and DoR status

#### Scenario: Ticket failing DoR is flagged but selectable
- **WHEN** a backlog ticket has no description or no labels
- **THEN** it is listed with a `⚠ not ready` tag
- **AND** the user can still select it for inclusion

#### Scenario: Selected tickets are added to active sprint
- **WHEN** user confirms a selection of ticket IDs
- **THEN** skill calls the sprint-add flow for each selected ticket using the active sprint from config

#### Scenario: No active sprint blocks plan
- **WHEN** `active_sprint` is absent from `.project/config.yaml`
- **THEN** skill outputs `No active sprint — run sprint create first` and exits

### Requirement: sprint review generates a shipped-summary from done tickets in the active sprint
The skill SHALL fetch all tickets in the `done` state assigned to the active sprint, group them by label/epic, and output a structured shipped summary. The summary SHALL include: sprint name, total tickets shipped, total story points completed (or `N/A` if no estimates), and a per-label breakdown. The skill SHALL also show commitment vs. delivered: tickets that were in the sprint at planning time vs. tickets done at review time.

#### Scenario: Review summary shows shipped tickets grouped by label
- **WHEN** user invokes `sprint review` and 5 done tickets exist across 2 labels
- **THEN** output shows each label section with ticket IDs and titles

#### Scenario: Story points total shown when estimates are present
- **WHEN** all done tickets have an estimate field
- **THEN** summary includes `Points shipped: 18`

#### Scenario: Points show N/A when estimates are absent
- **WHEN** no done tickets have an estimate
- **THEN** summary shows `Points shipped: N/A`

#### Scenario: Commitment vs. delivered delta is shown
- **WHEN** sprint started with 8 tickets and 6 are done at review time
- **THEN** output includes `Delivered: 6/8 tickets (75%)`

### Requirement: sprint retro creates a structured retro issue in the tracker
The skill SHALL prompt the user for three sections: went-well (free text), to-improve (free text), action-items (list). It SHALL then create a tracker issue with a fixed template embedding the three sections, a `retro` label, no sprint assignment, and a title of the form `Retro: {sprint_name}`.

#### Scenario: Retro issue created with three-section body
- **WHEN** user completes the retro prompts
- **THEN** skill creates a ticket titled `Retro: Sprint::2025-W23` with sections `## Went Well`, `## To Improve`, `## Action Items`

#### Scenario: Retro issue has retro label and no sprint assignment
- **WHEN** retro issue is created
- **THEN** it carries the `retro` label (created if absent) and is NOT assigned to the active sprint

#### Scenario: Empty sections are preserved in the template
- **WHEN** user leaves a section blank
- **THEN** that section header still appears in the created issue body with `(none)` as placeholder

### Requirement: sprint close tallies completed points, appends to velocity_log, and marks sprint done in the provider
The skill SHALL sum the story point estimates of all `done` tickets in the active sprint to compute `points_completed`. It SHALL also record `points_committed` from the sprint metadata (captured at `sprint create`). It SHALL append a `velocity_log` entry with `sprint`, `points_committed`, and `points_completed`. It SHALL then close the sprint in the provider (close milestone / close iteration / complete sprint / close cycle) and clear `active_sprint` from `.project/config.yaml`. If a `velocity_log` entry already exists for the same sprint identifier, the skill SHALL skip appending and warn instead of creating a duplicate.

#### Scenario: velocity_log entry appended on close
- **WHEN** user invokes `sprint close` on a sprint with 3 done tickets totalling 13 points
- **THEN** config gains entry: `{ sprint: "sprint::2025-W23", points_committed: 21, points_completed: 13 }`

#### Scenario: Duplicate close is idempotent
- **WHEN** `sprint close` is run a second time for the same sprint
- **THEN** skill outputs `velocity_log already has an entry for sprint::2025-W23 — skipping` and does NOT append

#### Scenario: GitHub sprint close closes the milestone
- **WHEN** provider is GitHub and user closes the sprint
- **THEN** skill calls `mcp__github__update_milestone` with `state: closed`

#### Scenario: GitLab CE sprint close clears config only
- **WHEN** provider is GitLab CE (`sprint_proxy: label`)
- **THEN** skill clears `active_sprint` from `.project/config.yaml` and outputs a note that label-based sprints have no native close API

#### Scenario: Jira sprint close completes the sprint
- **WHEN** provider is Jira
- **THEN** skill calls the complete-sprint MCP tool with `active_sprint.id`

#### Scenario: Points committed shown as N/A when sprint had no capacity set
- **WHEN** the sprint metadata issue has `capacity:` blank
- **THEN** `points_committed` is recorded as `null` and summary shows `Committed: N/A`
