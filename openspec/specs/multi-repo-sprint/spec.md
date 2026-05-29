## Purpose
Defines how the skill reads and uses configuration from multiple sibling repositories when `context_repos` is configured, enabling fan-out ticket fetches, merged results, and per-repo status boards.

## Requirements

### Requirement: Skill reads each context_repo's own .project/config.yaml at query time
When `next` or `status` mode is invoked and `context_repos` is non-empty in the anchor config, the skill SHALL read `.project/config.yaml` from each sibling repo path and extract: `provider.mcp_prefix`, `active_sprint`, and `provider.capabilities`.

#### Scenario: Sibling config read at query time
- **WHEN** anchor config has `context_repos: [../api-gateway]` and status mode is invoked
- **THEN** skill reads `../api-gateway/.project/config.yaml` to get its provider and active sprint

#### Scenario: Each sibling uses its own MCP prefix
- **WHEN** anchor uses `mcp__github__` and `../api-gateway` uses `mcp__jira__`
- **THEN** ticket fetches for the anchor use `mcp__github__` and fetches for `../api-gateway` use `mcp__jira__`

#### Scenario: Missing sibling config produces a warning, not a failure
- **WHEN** a path in `context_repos` has no `.project/config.yaml`
- **THEN** skill outputs "⚠ ../service-name has no .project/config.yaml — skipped" and continues with the remaining repos

### Requirement: Ticket fetches fan out across all configured repos and results are merged
The skill SHALL issue one ticket fetch call per configured repo (anchor + each context_repo with a valid config), using that repo's own provider and active sprint, and merge all results into a unified list.

#### Scenario: Tickets from all repos appear in merged results
- **WHEN** anchor has 5 tickets and `../api-gateway` has 3 tickets in their respective active sprints
- **THEN** the merged list contains all 8 tickets, each tagged with its source repo

#### Scenario: Each ticket tagged with its source repo path
- **WHEN** results are merged from multiple repos
- **THEN** each ticket record includes a `source_repo` field with the relative repo path (e.g., `"."` for anchor, `"../api-gateway"` for the sibling)

### Requirement: Status board shows a per-repo breakdown when context_repos are configured
When `status` mode is invoked and `context_repos` is non-empty, the skill SHALL display a per-repo breakdown of ticket counts by canonical state, followed by cross-repo totals.

#### Scenario: Status output has per-repo sections
- **WHEN** status is invoked with three repos configured
- **THEN** output shows a section per repo with counts by state, then a totals row

#### Scenario: Cross-repo blocked tickets listed with source repo
- **WHEN** a blocked ticket exists in a sibling repo
- **THEN** the blocked list identifies both the ticket ID and its source repo (e.g., `TICK-12 (../api-gateway)`)

#### Scenario: Single-repo view unchanged when no context_repos configured
- **WHEN** status is invoked and `context_repos` is empty or absent
- **THEN** output is the v1 single-repo board format without any repo columns

### Requirement: Next-ticket recommendation includes source repo when context_repos present
When `next` mode is invoked and the recommended ticket comes from a sibling repo, the skill SHALL include the source repo in the recommendation output.

#### Scenario: Recommendation identifies source repo
- **WHEN** the highest-scored ticket is TICK-42 from `../api-gateway`
- **THEN** output reads: `Next ticket: TICK-42 (../api-gateway/) — Auth token refresh`

#### Scenario: Cross-repo unblocking reasoning shown
- **WHEN** TICK-42 in the anchor repo unblocks tickets in a sibling repo
- **THEN** the reasoning line reads: `Unblocks 2 tickets (../mobile-app/)`

### Requirement: context_repos paths are relative and resolved from the anchor repo's directory
All paths in `context_repos` SHALL be resolved relative to the directory containing the anchor repo's `.project/config.yaml`. Absolute paths are also accepted.

#### Scenario: Relative path resolved correctly
- **WHEN** anchor is at `/projects/mobile-app` and `context_repos` contains `../api-gateway`
- **THEN** skill reads config from `/projects/api-gateway/.project/config.yaml`
