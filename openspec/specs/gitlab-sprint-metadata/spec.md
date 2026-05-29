## Purpose
Defines how sprint metadata is stored and retrieved for GitLab CE projects, which lack native iteration support. Metadata is persisted as GitLab issues in a shared `pm-meta` project, with the issue URL anchored in the scoped sprint label's description field.

## Requirements

### Requirement: Sprint metadata is stored as a GitLab issue in a designated pm-meta project
For GitLab CE projects, the skill SHALL create one GitLab issue per sprint in a designated `pm-meta` project. The issue title SHALL follow the pattern `[Sprint] {label_value} | {start} – {end}`. The issue body SHALL contain a machine-parseable block delimited by `<!-- pm:start -->` and `<!-- pm:end -->` containing `start`, `end`, `goal`, `capacity`, `status`, and `convention` fields in YAML format. Content outside the delimiters is freeform and human-editable.

#### Scenario: Sprint metadata issue created on sprint create
- **WHEN** user creates a sprint on a GitLab CE project
- **THEN** skill calls `mcp__gitlab__create_issue` in the pm-meta project with title `[Sprint] {label_value} | {start} – {end}` and a body containing the structured `<!-- pm:start --> ... <!-- pm:end -->` block

#### Scenario: Machine-parseable block survives human edits outside delimiters
- **WHEN** skill reads sprint metadata via `mcp__gitlab__get_issue`
- **THEN** it extracts only the content between `<!-- pm:start -->` and `<!-- pm:end -->`, ignoring content outside

#### Scenario: Sprint metadata accessible from any repo in the group
- **WHEN** any project in the GitLab group calls `mcp__gitlab__get_issue` with the metadata issue URL
- **THEN** the sprint metadata is returned regardless of which git repository is currently active

### Requirement: Sprint label description holds the pm-meta issue URL as a FK
The skill SHALL set the GitLab label description to the full URL of the sprint metadata issue when creating a sprint label. This URL SHALL be the sole content of the label description field.

#### Scenario: Label description contains issue URL after sprint creation
- **WHEN** sprint `sprint::2025-W23` is created
- **THEN** the label `sprint::2025-W23` has description `https://{host}/{group}/pm-meta/-/issues/{n}`

#### Scenario: Skill resolves metadata from label description
- **WHEN** skill needs sprint metadata for `sprint::2025-W23`
- **THEN** it reads the label description to get the issue URL, then fetches that issue via MCP

### Requirement: pm-meta project is created automatically at init if absent
During `pm init` for a GitLab CE project, the skill SHALL check whether the `pm-meta` project exists in the group. If absent, it SHALL create it via `mcp__gitlab__create_project`. If project creation fails due to insufficient permissions, the skill SHALL fall back to using the current project for sprint metadata issues and notify the user.

#### Scenario: pm-meta project auto-created at init
- **WHEN** init detects GitLab CE edition and `{group}/pm-meta` does not exist
- **THEN** skill calls `mcp__gitlab__create_project` with name `pm-meta` under the detected group
- **AND** stores the resulting project path in `.project/config.yaml` as `pm_meta_project`

#### Scenario: pm-meta creation failure falls back to current project
- **WHEN** `mcp__gitlab__create_project` returns 403 during init
- **THEN** skill sets `pm_meta_project` to the current project path
- **AND** outputs `⚠ Could not create pm-meta project — sprint metadata will be stored in the current project`

#### Scenario: Existing pm-meta project reused without re-creation
- **WHEN** init detects GitLab CE edition and `{group}/pm-meta` already exists
- **THEN** skill stores the existing project path and does NOT call create

### Requirement: Sprint naming convention is chosen once at init and stored in config
For GitLab CE projects, the skill SHALL present a naming convention picker during init. The chosen convention SHALL be stored in `.project/config.yaml` as `sprint_convention`. Once set, the convention SHALL be applied to all subsequent sprint label names. The skill SHALL warn if the user attempts to change the convention after sprints have been created.

#### Scenario: Convention picker presented at init for GitLab CE
- **WHEN** init detects GitLab CE edition
- **THEN** skill presents options: sequential (1, 2, 3), year-week (2025-W23), year-month-week (2025-06-W3), quarterly (Q2-2025-S1) with `year-week` as the default

#### Scenario: Chosen convention stored in config
- **WHEN** user selects `year-week` convention at init
- **THEN** `.project/config.yaml` contains `sprint_convention: year-week`

#### Scenario: Warning shown if convention change attempted after sprints exist
- **WHEN** user runs `pm init --probe` and selects a different convention after `sprint::*` labels already exist in the provider
- **THEN** skill outputs `⚠ Sprint labels already exist using {old_convention} convention — changing convention requires manually relabelling existing sprints`
- **AND** writes the new convention to config only after explicit user confirmation

### Requirement: Active sprint stored by label name in config for GitLab CE
For GitLab CE projects, `.project/config.yaml` SHALL store the active sprint as `label_name` and `meta_issue_url` instead of a numeric milestone ID. The `label_name` field SHALL be the full scoped label name (e.g. `sprint::2025-W23`). Ticket list queries for the active sprint SHALL filter by this label name.

#### Scenario: Active sprint written to config after sprint create
- **WHEN** user creates sprint `sprint::2025-W23` on a GitLab CE project
- **THEN** `.project/config.yaml` contains `active_sprint.label_name: sprint::2025-W23` and `active_sprint.meta_issue_url: https://...`

#### Scenario: next and status modes filter by label_name for GitLab CE
- **WHEN** next or status mode is invoked on a GitLab CE project
- **THEN** skill calls `mcp__gitlab__list_issues` with `labels: {active_sprint.label_name}` as the filter parameter
