## Purpose
Defines the universal provider I/O resolution chain for all skill operations. All providers use the same fixed order: REST API first, CLI tool second (if available), MCP last. GitLab-specific requirements for label delta writes and project ID capture are included here as they inform how the REST path is constructed.

## Requirements

### Requirement: All provider operations use a fixed 3-path resolution chain
For every operation across all providers, the skill SHALL attempt paths in this order: (1) REST API via `rest_config` fields from `providers.json`, (2) CLI tool named in `cli_tool` if non-null and on PATH, (3) MCP tool via `tool_contracts`. The skill SHALL halt and report an error only if all three paths fail or are unavailable.

#### Scenario: REST path succeeds — chain stops
- **WHEN** a REST API call returns a 2xx response
- **THEN** the skill does not attempt CLI or MCP

#### Scenario: REST unavailable, CLI installed — CLI path used
- **WHEN** REST call fails or token is unset, and `cli_tool` is non-null and on PATH
- **THEN** the skill executes the CLI command
- **AND** emits a one-line notice: `ℹ Using {cli_tool} CLI (REST unavailable)`

#### Scenario: REST unavailable, CLI absent, MCP configured — MCP path used
- **WHEN** REST fails and CLI is absent or `cli_tool` is null, and MCP tool is discoverable
- **THEN** the skill calls the MCP tool
- **AND** emits a one-line notice: `ℹ Using MCP (REST and CLI unavailable)`

#### Scenario: null cli_tool skips CLI step silently
- **WHEN** `cli_tool` is `null` for a provider (Jira, Plane)
- **THEN** the skill moves directly from REST to MCP without any notice or error

#### Scenario: All paths unavailable — error reported
- **WHEN** REST fails, CLI absent, and MCP not discoverable
- **THEN** the skill halts with a message listing the three options for enabling operations

### Requirement: Label-based state transitions use delta form (add + remove)
When transitioning issue state via label (required for GitLab, which uses labels as state proxies), the skill SHALL fetch the issue's current labels first, identify which state label to remove, then apply the write path with `add_labels` and `remove_labels` as separate parameters. It SHALL NOT overwrite the full label list.

#### Scenario: in-progress transition removes prior state label, adds new one
- **WHEN** a ticket is transitioned from `todo` to `in-progress` on a label-based provider
- **THEN** the skill fetches current labels, removes the `todo` state label, adds the `in-progress` label
- **AND** all other existing labels are preserved

#### Scenario: No prior state label — add only
- **WHEN** an issue has no existing state label (e.g., newly created)
- **THEN** the skill adds the target state label without a remove operation

### Requirement: Numeric project ID captured at init for GitLab REST calls
During provider init for GitLab, the skill SHALL obtain the numeric project `id` from the GitLab API and store it as `gitlab_project_id` in `.project/config.yaml`. This is required for REST API calls, which use the numeric ID rather than the URL-encoded project path.

#### Scenario: Project ID stored at init
- **WHEN** the user runs `/project-management init` with GitLab as provider
- **THEN** `.project/config.yaml` contains `gitlab_project_id: <integer>`

#### Scenario: Existing config without project ID — lazy fetch on first write
- **WHEN** an existing `.project/config.yaml` lacks `gitlab_project_id` and a write is needed
- **THEN** the skill fetches the project ID (via REST or MCP) and stores it before proceeding
- **AND** the write operation continues without user intervention
