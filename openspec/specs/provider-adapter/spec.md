## Purpose
Defines the data-driven adapter contract that maps canonical skill operations to provider-specific MCP tools, state values, and fallback strategies via `references/providers.json`.

## Requirements

### Requirement: providers.json declares tool contracts, state mapping, plan variants, and fallbacks per provider
The `references/providers.json` file SHALL contain an entry for each supported provider (github, gitlab, jira, plane) with fields: `name`, `mcp_prefix`, `tool_contracts`, `state_mapping`, `plan_variants`, and `fallbacks`.

#### Scenario: Adding a new provider requires only a new providers.json entry
- **WHEN** a new entry is added to `providers.json` with all required fields
- **THEN** the skill supports that provider without any changes to `SKILL.md`

#### Scenario: tool_contracts maps canonical operations to MCP tool suffixes
- **WHEN** the skill needs to create a ticket in GitHub
- **THEN** it resolves `tool_contracts.create_ticket` to `mcp__github__create_issue` and calls that tool

#### Scenario: null tool_contract entry signals unsupported feature
- **WHEN** `tool_contracts.sprint` is `null` for a provider
- **THEN** the skill applies the declared fallback strategy instead of attempting an MCP call

### Requirement: Skill uses ToolSearch to verify MCP tool availability before calling
The skill SHALL call `ToolSearch` with the provider's MCP prefix at init time and verify that required tools are discoverable before any ticket operation.

#### Scenario: Missing MCP server produces a clear setup message
- **WHEN** no `mcp__github__*` tools are found via ToolSearch
- **THEN** the skill outputs a message naming the required MCP server and how to add it, then halts

#### Scenario: Partial MCP coverage degrades gracefully
- **WHEN** `mcp__plane__list_cycles` exists but `mcp__plane__list_modules` does not
- **THEN** the skill marks epics as unsupported and applies the label fallback without halting

### Requirement: State mapping is bidirectional between canonical and provider states
The skill SHALL translate canonical states to provider states when writing and provider states to canonical states when reading.

#### Scenario: Canonical in-progress maps to GitHub label on write
- **WHEN** a ticket is transitioned to `in-progress` on GitHub
- **THEN** the skill sets issue state to `open` and attaches label `in-progress`

#### Scenario: GitHub closed issue reads as canonical done
- **WHEN** a GitHub issue has state `closed`
- **THEN** the skill reports its canonical state as `done`

### Requirement: Each provider has a dedicated reference file in references/
The skill SHALL include `references/github.md`, `references/gitlab.md`, `references/jira.md`, and `references/plane.md` documenting provider-specific notes, known limitations, and setup instructions. `references/gitlab.md` SHALL document both OAuth and PAT setup paths and SHALL NOT describe OAuth as the only available option.

#### Scenario: Reference file documents plan limitations
- **WHEN** `references/plane.md` is read
- **THEN** it lists which features are unavailable on the free plan and their label fallback convention

#### Scenario: GitLab reference file documents both auth methods
- **WHEN** `references/gitlab.md` is read
- **THEN** it shows setup commands for both OAuth (browser flow) and PAT (header-based), with token scope requirements noted for PAT

### Requirement: GitLab mcp_setup declares PAT as a valid auth method
The GitLab entry in `references/providers.json` SHALL include `"pat"` in `mcp_setup.auth_methods`, a `pat` key in `install_commands` using `--header "Authorization=Bearer {token}"`, a `pat_prompt` string, a `pat_url` pointing to the GitLab token settings page, and a `pat_env` field set to `"GITLAB_TOKEN"`.

#### Scenario: PAT install command includes Authorization header
- **WHEN** the skill resolves the PAT install command for GitLab
- **THEN** it produces `claude mcp add gitlab --scope project --transport http {url} --header "Authorization=Bearer {token}"`

#### Scenario: pat_env field names the expected environment variable
- **WHEN** the skill reads the GitLab mcp_setup block
- **THEN** `pat_env` resolves to `"GITLAB_TOKEN"`

### Requirement: Init pre-checks GITLAB_TOKEN before presenting auth method choice
During init Step B for GitLab, the skill SHALL read `mcp_setup.pat_env` from providers.json, check whether that environment variable is set, and if so skip the OAuth/PAT question, emit a confirmation line, and proceed directly to PAT registration using the existing token value.

#### Scenario: GITLAB_TOKEN present — question skipped
- **WHEN** `GITLAB_TOKEN` is set in the environment during GitLab init
- **THEN** the skill emits `Found GITLAB_TOKEN in environment — using PAT auth ✓` and proceeds to run the PAT install command without asking the user to choose

#### Scenario: GITLAB_TOKEN absent — user is asked
- **WHEN** `GITLAB_TOKEN` is not set in the environment during GitLab init
- **THEN** the skill presents the auth method choice: `1. OAuth` and `2. PAT / API token`

#### Scenario: User chooses PAT when no env var is set
- **WHEN** the user selects PAT and no `GITLAB_TOKEN` is in environment
- **THEN** the skill prompts for the token (masked), runs the PAT install command, and exports `GITLAB_TOKEN` to `~/.zshrc`
