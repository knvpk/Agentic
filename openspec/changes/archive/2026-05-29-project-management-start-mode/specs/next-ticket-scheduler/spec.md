## MODIFIED Requirements

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
