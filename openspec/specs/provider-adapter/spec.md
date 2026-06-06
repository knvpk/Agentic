## Purpose
Defines the data-driven adapter contract that maps canonical skill operations to provider-specific REST endpoints, CLI tools, MCP tools, state values, and fallback strategies via `references/providers.json`.

## Requirements

### Requirement: providers.json declares rest_config, cli_tool, tool contracts, state mapping, plan variants, and fallbacks per provider
The `references/providers.json` file SHALL contain an entry for each supported provider (github, gitlab, jira, plane) with fields: `name`, `mcp_prefix`, `rest_config`, `cli_tool`, `tool_contracts`, `state_mapping`, `plan_variants`, and `fallbacks`. The `rest_config` field declares the REST API base URL pattern, token env var, and auth header. The `cli_tool` field names the CLI binary (or `null` if none exists for that provider).

#### Scenario: Adding a new provider requires only a new providers.json entry
- **WHEN** a new entry is added to `providers.json` with all required fields
- **THEN** the skill supports that provider without any changes to `SKILL.md`

#### Scenario: rest_config provides base URL and auth for REST operations
- **WHEN** the skill needs to update a ticket in GitLab via REST
- **THEN** it reads `rest_config.base`, substitutes `{host}` from config, reads the token from `rest_config.token_env`, and constructs the auth header from `rest_config.auth_header`

#### Scenario: cli_tool null causes CLI step to be skipped silently
- **WHEN** `cli_tool` is `null` for Jira or Plane
- **THEN** the skill skips step 2 of the resolution chain without error and tries MCP next

#### Scenario: tool_contracts maps canonical operations to MCP tool suffixes (last-resort path)
- **WHEN** both REST and CLI paths are unavailable and the skill falls back to MCP
- **THEN** it resolves `tool_contracts.create_ticket` to `mcp__github__create_issue` and calls that tool

#### Scenario: null tool_contract entry signals unsupported feature
- **WHEN** `tool_contracts.sprint` is `null` for a provider
- **THEN** the skill applies the declared fallback strategy instead of attempting any call

### Requirement: All provider operations use REST → CLI → MCP resolution order
For every operation (read and write), the skill SHALL attempt paths in this fixed order: (1) REST API using `rest_config`, (2) CLI tool named in `cli_tool` if non-null, (3) MCP tool via `tool_contracts`. The skill SHALL NOT vary this order per provider.

#### Scenario: REST path succeeds — chain stops
- **WHEN** a REST API call for ticket update returns 200
- **THEN** the skill does not attempt CLI or MCP

#### Scenario: REST fails, CLI available — CLI used
- **WHEN** REST call fails and `cli_tool` is non-null and the binary is on PATH
- **THEN** the skill uses the CLI and emits a one-line notice

#### Scenario: REST fails, CLI absent, MCP available — MCP used
- **WHEN** REST call fails, `cli_tool` is null or binary absent, and MCP tool is discoverable
- **THEN** the skill uses the MCP tool and emits a one-line notice

#### Scenario: All paths unavailable — error reported
- **WHEN** REST, CLI, and MCP all fail or are unavailable
- **THEN** the skill halts with a message listing all three options for enabling operations

### Requirement: Skill reads rest_config.token_env at runtime; token is never stored in config files
The skill SHALL read the auth token from the environment variable named in `rest_config.token_env` at the time of each REST call. The token value SHALL NOT be written to `.project/config.yaml` or any other file.

#### Scenario: Token read from environment at call time
- **WHEN** the skill makes a REST call for GitHub
- **THEN** it reads `GITHUB_TOKEN` from the environment and injects it into the `Authorization` header

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

### Requirement: Init Step 5 references config.schema.json rather than enumerating fields inline
The `init` mode Step 5 in SKILL.md SHALL replace the inline YAML example block with a reference to `config.schema.json` as the canonical field definition. The step description SHALL state: "Write `.project/config.yaml` conforming to `references/config.schema.json`."

#### Scenario: SKILL.md Step 5 contains no standalone field enumeration
- **WHEN** SKILL.md init Step 5 is read
- **THEN** it references `config.schema.json` for field definitions and does not duplicate the full field list inline
