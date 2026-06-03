## Purpose
Defines the quality gates applied before state transitions: the Definition of Done (DoD) gate for transitions to `done`, and the WIP limit check for transitions to `in-progress`.

## Requirements

### Requirement: DoD gate checks configured criteria before allowing transition to done
When `definition_of_done` is set in `.project/config.yaml`, the skill SHALL evaluate each criterion for the target ticket before completing a `ticket update → done` transition. Supported criteria: `has_bdd` (ticket description contains at least one `## Scenarios` section), `has_assignee` (ticket has at least one assignee). If any criterion fails, the skill SHALL list the unmet criteria and ask `Close anyway? [y/n]`. On `n` the transition is cancelled. On `y` or when `--force` is passed, the transition proceeds. When `definition_of_done` is absent from config, the gate is not applied.

#### Scenario: All DoD criteria met — transition proceeds silently
- **WHEN** definition_of_done is `[has_bdd, has_assignee]` and the ticket has both a Scenarios section and an assignee
- **THEN** the transition to done proceeds without any warning

#### Scenario: Unmet criteria trigger confirmation prompt
- **WHEN** definition_of_done is `[has_bdd, has_assignee]` and the ticket has no assignee
- **THEN** skill outputs `⚠ DoD unmet: has_assignee` and asks `Close anyway? [y/n]`

#### Scenario: User declines DoD confirmation cancels transition
- **WHEN** user answers `n` to the DoD confirmation prompt
- **THEN** ticket state is not changed and skill outputs `Transition cancelled`

#### Scenario: --force bypasses DoD confirmation
- **WHEN** user runs `ticket update TICK-42 --force` and transitions to done
- **THEN** DoD check is skipped entirely

#### Scenario: DoD gate is not applied when definition_of_done is absent from config
- **WHEN** `.project/config.yaml` has no `definition_of_done` key
- **THEN** `ticket update → done` proceeds as before without any DoD check

### Requirement: WIP limit check warns when in-progress count would exceed wip_limit
When `wip_limit` is set in `.project/config.yaml`, before transitioning any ticket to `in-progress` (via `ticket update` or `start`), the skill SHALL count tickets currently in the `in-progress` state in the active sprint. If the count is at or above `wip_limit`, the skill SHALL warn and ask `Continue? [y/n]`. On `n` the transition is cancelled. When `wip_limit` is absent, no check is performed.

#### Scenario: WIP below limit — transition proceeds silently
- **WHEN** wip_limit is 3 and only 2 tickets are in-progress
- **THEN** transition to in-progress proceeds without any warning

#### Scenario: WIP at limit triggers confirmation
- **WHEN** wip_limit is 3 and 3 tickets are already in-progress
- **THEN** skill outputs `⚠ WIP limit is 3 — you have 3 tickets in-progress` and asks `Continue? [y/n]`

#### Scenario: User declines WIP confirmation cancels transition
- **WHEN** user answers `n` to the WIP confirmation prompt
- **THEN** ticket state is not changed and skill outputs `Transition cancelled`

#### Scenario: WIP check not applied when wip_limit is absent
- **WHEN** `.project/config.yaml` has no `wip_limit` key
- **THEN** `ticket update → in-progress` and `start` proceed without any WIP check

#### Scenario: WIP check applies in start mode
- **WHEN** user runs `start TICK-42` and wip_limit would be exceeded by the transition
- **THEN** same warn-and-confirm flow applies as for `ticket update → in-progress`
