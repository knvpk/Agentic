## ADDED Requirements

### Requirement: start mode applies the WIP limit check before transitioning the ticket to in-progress
When the user confirms transitioning a `todo` ticket to `in-progress` via `start` mode, the skill SHALL apply the WIP limit check as defined in the `agile-quality-gates` capability before making the provider state transition call. The check occurs after the user has confirmed the state change (`Move TICK-42 to in-progress? [y/n]` answered `y`) but before the provider MCP call.

#### Scenario: WIP check applied after user confirms transition
- **WHEN** user confirms moving TICK-42 to in-progress and wip_limit would be exceeded
- **THEN** skill shows the WIP warning and asks `Continue? [y/n]` before calling the provider

#### Scenario: WIP check skipped when ticket is already in-progress
- **WHEN** ticket fetched by start mode is already in `in-progress` state
- **THEN** no WIP check is performed (no new in-progress slot is being consumed)

#### Scenario: WIP check skipped when wip_limit is absent
- **WHEN** `.project/config.yaml` has no `wip_limit` key
- **THEN** start mode transitions to in-progress without any WIP check

#### Scenario: start mode with --no-branch still applies WIP check
- **WHEN** user runs `start TICK-42 --no-branch` and wip_limit would be exceeded
- **THEN** WIP check still runs — the --no-branch flag only suppresses branch creation
