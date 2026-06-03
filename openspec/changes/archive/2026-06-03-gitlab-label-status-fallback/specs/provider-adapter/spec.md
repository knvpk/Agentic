## MODIFIED Requirements

### Requirement: providers.json declares tool contracts, state mapping, plan variants, and fallbacks per provider
The `references/providers.json` file SHALL contain an entry for each supported provider (github, gitlab, jira, plane) with fields: `name`, `mcp_prefix`, `tool_contracts`, `state_mapping`, `plan_variants`, `fallbacks`, and optionally `write_fallbacks`. The `write_fallbacks` field, when present, declares an ordered list of fallback strategies for issue mutation operations when the primary MCP tool is unavailable.

#### Scenario: Adding a new provider requires only a new providers.json entry
- **WHEN** a new entry is added to `providers.json` with all required fields
- **THEN** the skill supports that provider without any changes to `SKILL.md`

#### Scenario: tool_contracts maps canonical operations to MCP tool suffixes
- **WHEN** the skill needs to create a ticket in GitHub
- **THEN** it resolves `tool_contracts.create_ticket` to `mcp__github__create_issue` and calls that tool

#### Scenario: null tool_contract entry signals unsupported feature
- **WHEN** `tool_contracts.sprint` is `null` for a provider
- **THEN** the skill applies the declared fallback strategy instead of attempting an MCP call

#### Scenario: write_fallbacks present for GitLab enables fallback chain
- **WHEN** the skill resolves an update operation for GitLab and `write_fallbacks` is present
- **THEN** the skill walks the fallback chain in declared order rather than calling `update_issue` directly
