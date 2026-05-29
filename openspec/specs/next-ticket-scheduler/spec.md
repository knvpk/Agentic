## Purpose
Defines the algorithmic logic for recommending the single highest-value next ticket from the active sprint, without requiring user input during invocation.

## Requirements

### Requirement: Scheduler fetches all open in-sprint tickets and reads their titles and descriptions
The skill SHALL fetch all open tickets in the active sprint from the provider via MCP and read their titles and descriptions to understand the nature of each ticket.

#### Scenario: Fetch uses sprint filter not full project
- **WHEN** next-ticket mode is invoked
- **THEN** skill queries only tickets assigned to the active sprint, not all open tickets in the project

#### Scenario: Fetch is a single read, not polling
- **WHEN** next-ticket mode is invoked
- **THEN** the skill makes exactly one batch fetch call and caches results for the duration of the invocation

### Requirement: Scheduler eliminates tickets with unresolved blockers
Any ticket where at least one `blocked-by` ticket is still in a non-done state SHALL be excluded from the candidate pool.

#### Scenario: Blocked ticket excluded from recommendation
- **WHEN** TICK-42 is blocked by TICK-10 and TICK-10 is `in-progress`
- **THEN** TICK-42 does not appear as a recommendation

#### Scenario: Ticket with resolved blocker is eligible
- **WHEN** TICK-42 is blocked by TICK-10 and TICK-10 is `done`
- **THEN** TICK-42 is eligible for recommendation

### Requirement: Scheduler scores candidates by: WIP continuation, priority, unblocks-others count, estimate
The skill SHALL rank the candidate pool in this order: (1) tickets already `in-progress` assigned to the user (WIP continuation), (2) tickets with highest priority, (3) tickets that appear most frequently as a blocker for other open tickets (highest fan-out), (4) smallest estimate.

#### Scenario: In-progress ticket recommended first
- **WHEN** user has one ticket `in-progress` and several `todo`
- **THEN** the `in-progress` ticket is the top recommendation

#### Scenario: High-priority unblocking ticket recommended over low-priority standalone
- **WHEN** TICK-05 is high priority and blocks 3 tickets, TICK-06 is medium priority and blocks 0
- **THEN** TICK-05 is ranked above TICK-06

### Requirement: Scheduler outputs the recommended ticket with plain-English reasoning
The skill SHALL output the recommended ticket's ID, title, and a one-to-two sentence explanation of why it was chosen. The output SHALL include a single `/project-management start <id>` call-to-action instead of the previous two-line manual hint.

#### Scenario: Recommendation includes reasoning
- **WHEN** TICK-42 is the top recommendation
- **THEN** output includes: `TICK-42 — Auth token refresh. High priority, unblocks 3 tickets, no open dependencies.`

#### Scenario: No eligible tickets produces a clear message
- **WHEN** all in-sprint tickets are done, blocked, or have unresolved dependencies
- **THEN** skill outputs "No eligible tickets in the active sprint" with a list of blocked tickets and their blockers

#### Scenario: Output hint is a single start command
- **WHEN** a recommendation is produced
- **THEN** the call-to-action line reads: `Ready to start? /project-management start <id>` — not the previous two-line form with a separate state-update command and opsx:ff hint

### Requirement: Scheduler operates without user input per invocation
The next-ticket recommendation SHALL be fully algorithmic. The skill SHALL NOT ask the user questions during invocation.

#### Scenario: Invocation requires no user interaction
- **WHEN** user runs `/project-management next`
- **THEN** the skill produces a recommendation without prompting for additional input
