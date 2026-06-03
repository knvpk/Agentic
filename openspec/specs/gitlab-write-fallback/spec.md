## Purpose
TBD — defines the fallback chain for GitLab write operations (state changes, label mutations, milestone assignments) when the primary MCP update tool is unavailable.

## Requirements

### Requirement: GitLab write operations use a 3-path fallback chain
When the PM skill needs to mutate a GitLab issue (state change, label add/remove, milestone assign), it SHALL attempt paths in this order: (1) MCP `update_issue` tool if discovered via ToolSearch, (2) `glab` CLI if available, (3) GitLab REST API via curl using `GITLAB_TOKEN`. The skill SHALL halt and report an error only if all three paths are unavailable.

#### Scenario: MCP update_issue present — MCP path used
- **WHEN** ToolSearch discovers `mcp__gitlab__update_issue` at write time
- **THEN** the skill calls it directly and skips the fallback chain

#### Scenario: MCP update_issue absent, glab installed — glab path used
- **WHEN** ToolSearch does not find `mcp__gitlab__update_issue` and `glab` is on PATH
- **THEN** the skill executes `glab issue update` with the appropriate flags
- **AND** emits a one-line notice: `"Using glab CLI for GitLab write (MCP update_issue not available)"`

#### Scenario: MCP absent, glab absent, GITLAB_TOKEN set — REST path used
- **WHEN** neither MCP tool nor glab is available and `GITLAB_TOKEN` is set
- **THEN** the skill constructs a `curl -X PUT` call to the GitLab REST API
- **AND** emits a one-line notice: `"Using REST API for GitLab write (MCP update_issue not available)"`

#### Scenario: All paths unavailable — error reported
- **WHEN** MCP tool absent, glab absent, and `GITLAB_TOKEN` unset
- **THEN** the skill halts with a clear message listing the three options for enabling writes

### Requirement: Label-based state transitions use delta form (add + remove)
When transitioning GitLab issue state via label, the skill SHALL fetch the issue's current labels first, identify which state label to remove, then apply the write path with `add_labels` and `remove_labels` as separate parameters. It SHALL NOT overwrite the full label list.

#### Scenario: in-progress transition removes To Do, adds In Progress
- **WHEN** user transitions issue #42 from `todo` to `in-progress`
- **THEN** the skill fetches current labels, removes `To Do`, adds `In Progress`
- **AND** all other existing labels are preserved

#### Scenario: No prior state label — add only
- **WHEN** a GitLab issue has no existing state label (e.g., newly created)
- **THEN** the skill adds the target state label without a remove operation

### Requirement: Numeric project ID captured at init for REST fallback
During provider init for GitLab, the skill SHALL call `mcp__gitlab__get_project` (or equivalent) and store the numeric `id` field as `gitlab_project_id` in `.project/config.yaml`. This enables REST API calls without URL-encoding the project path at write time.

#### Scenario: Project ID stored at init
- **WHEN** the user runs `/project-management init` with GitLab as provider
- **THEN** `.project/config.yaml` contains `gitlab_project_id: <integer>`

#### Scenario: Existing config without project ID — lazy fetch on first write
- **WHEN** an existing `.project/config.yaml` lacks `gitlab_project_id` and a write is needed
- **THEN** the skill fetches the project and stores `gitlab_project_id` before proceeding
- **AND** the write operation continues without user intervention

### Requirement: providers.json declares write_fallbacks for GitLab
The GitLab entry in `references/providers.json` SHALL include a `write_fallbacks` array listing the ordered fallback strategies for issue mutations. SKILL.md SHALL read this array at write time to determine the resolution path.

#### Scenario: write_fallbacks array is present and ordered
- **WHEN** the GitLab providers.json entry is read
- **THEN** `write_fallbacks` contains entries in order: mcp, cli, rest

#### Scenario: Other providers have no write_fallbacks
- **WHEN** the GitHub or Jira providers.json entry is read
- **THEN** `write_fallbacks` is absent or empty (they have working MCP update tools)
