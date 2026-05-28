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
The skill SHALL include `references/github.md`, `references/gitlab.md`, `references/jira.md`, and `references/plane.md` documenting provider-specific notes, known limitations, and setup instructions.

#### Scenario: Reference file documents plan limitations
- **WHEN** `references/plane.md` is read
- **THEN** it lists which features are unavailable on the free plan and their label fallback convention
