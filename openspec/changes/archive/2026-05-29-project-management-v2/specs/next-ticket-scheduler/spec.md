## MODIFIED Requirements

### Requirement: Scheduler fetches all open in-sprint tickets and reads their titles and descriptions
The skill SHALL fetch all open tickets in the active sprint from the provider via MCP and read their titles and descriptions to understand the nature of each ticket. When `context_repos` is configured, the fetch SHALL fan out across all repos using each repo's own provider and active sprint, then merge results before scoring.

#### Scenario: Fetch uses sprint filter not full project
- **WHEN** next-ticket mode is invoked
- **THEN** skill queries only tickets assigned to the active sprint, not all open tickets in the project

#### Scenario: Fetch is a single read per repo, not polling
- **WHEN** next-ticket mode is invoked
- **THEN** the skill makes exactly one batch fetch call per configured repo and caches results for the duration of the invocation

#### Scenario: Multi-repo fetch fans out to all configured repos
- **WHEN** next-ticket mode is invoked and `context_repos` contains two sibling paths with valid configs
- **THEN** skill fetches from the anchor repo and both siblings — one MCP call per repo — and merges all tickets before scoring

#### Scenario: Sibling with no active sprint is skipped
- **WHEN** a sibling repo's config has no `active_sprint` set
- **THEN** skill skips that repo with a warning and continues scoring from the remaining repos

### Requirement: Scheduler outputs the recommended ticket with plain-English reasoning
The skill SHALL output the recommended ticket's ID, title, and a one-to-two sentence explanation of why it was chosen. The output SHALL include a single `/project-management start <id>` call-to-action. When the recommendation comes from a sibling repo, the source repo SHALL be identified in the output.

#### Scenario: Recommendation includes reasoning
- **WHEN** TICK-42 is the top recommendation from the anchor repo
- **THEN** output includes: `TICK-42 — Auth token refresh. High priority, unblocks 3 tickets, no open dependencies.`

#### Scenario: Recommendation identifies source repo for sibling tickets
- **WHEN** the top recommendation is TICK-17 from `../api-gateway`
- **THEN** output reads: `Next ticket: TICK-17 (../api-gateway/) — Rate limit middleware`

#### Scenario: Cross-repo unblocking shown in reasoning
- **WHEN** TICK-42 in the anchor unblocks tickets in `../mobile-app`
- **THEN** reasoning reads: `Unblocks 2 tickets (../mobile-app/)`

#### Scenario: No eligible tickets produces a clear message
- **WHEN** all in-sprint tickets across all repos are done, blocked, or have unresolved dependencies
- **THEN** skill outputs "No eligible tickets in the active sprint" with a list of blocked tickets and their blockers, each annotated with source repo
