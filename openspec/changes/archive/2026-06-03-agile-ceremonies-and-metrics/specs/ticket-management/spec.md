## ADDED Requirements

### Requirement: ticket update to done applies the DoD gate when definition_of_done is configured
Before dispatching a state transition to `done`, the skill SHALL apply the DoD gate as defined in the `agile-quality-gates` capability. The check runs after state machine validation (confirming `done` is a valid next state) and before the provider MCP call.

#### Scenario: DoD gate runs after state machine validation
- **WHEN** user transitions a ticket from `in-review` to `done` and definition_of_done is configured
- **THEN** state machine validation passes first, then DoD criteria are checked

#### Scenario: DoD gate does not run for non-done transitions
- **WHEN** user transitions a ticket from `backlog` to `todo`
- **THEN** no DoD check is performed regardless of definition_of_done config

### Requirement: ticket update to in-progress applies the WIP limit check when wip_limit is configured
Before dispatching a state transition to `in-progress`, the skill SHALL apply the WIP limit check as defined in the `agile-quality-gates` capability. The check runs after state machine validation and before the provider MCP call.

#### Scenario: WIP check runs after state machine validation
- **WHEN** user transitions a ticket from `todo` to `in-progress` and wip_limit is set
- **THEN** state machine validation passes first, then WIP count is checked

#### Scenario: WIP check does not run for transitions to other states
- **WHEN** user transitions a ticket from `in-progress` to `in-review`
- **THEN** no WIP check is performed
