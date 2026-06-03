## MODIFIED Requirements

### Requirement: Skill enforces canonical state machine for all ticket transitions
The skill SHALL validate all state transitions against the canonical machine (`backlog → todo → in-progress → in-review → done | blocked`) before dispatching to the provider. Invalid transitions SHALL be rejected with an explanation. For GitLab, the dispatch SHALL use the write fallback chain (MCP → glab → REST) rather than calling `update_issue` directly.

#### Scenario: Valid forward transition is dispatched to provider
- **WHEN** user transitions a ticket from `todo` to `in-progress`
- **THEN** skill maps to the provider state and calls the appropriate MCP update tool

#### Scenario: Valid GitLab transition uses fallback chain when MCP update_issue absent
- **WHEN** user transitions a GitLab ticket from `todo` to `in-progress`
- **AND** `mcp__gitlab__update_issue` is not discoverable via ToolSearch
- **THEN** skill resolves the write path via `write_fallbacks` and applies the label delta using the available path (glab or REST)

#### Scenario: Backward skip transition is rejected
- **WHEN** user attempts to transition from `backlog` directly to `in-review`
- **THEN** skill rejects the transition and lists valid next states

#### Scenario: Blocked state requires a reason
- **WHEN** user transitions a ticket to `blocked`
- **THEN** skill prompts for a blocking reason and optionally a blocking ticket reference
