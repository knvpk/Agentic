## Delta: targeted-ticket-start

### Changed Requirements

#### Requirement: start mode transitions a backlog ticket to in-progress with user confirmation

**Replaces**: "Scenario: backlog ticket triggers a warning"

The existing spec says a backlog ticket triggers a continue-anyway warning with no state transition. This is incorrect behaviour — the user running `start` intends to work on the ticket. The new behaviour combines the sprint warning and transition offer into a single prompt.

##### Scenario: backlog ticket prompts for transition with sprint context
- **WHEN** ticket state is `backlog`
- **THEN** skill asks: "TICK-42 is in backlog (not assigned to the active sprint). Move to in-progress? [y/n]"

##### Scenario: backlog transition confirmed — WIP check runs then state is updated
- **WHEN** ticket state is `backlog` and user answers `y` to the transition prompt
- **THEN** skill runs the WIP Limit Check; if check passes (or no wip_limit is set), skill calls `update_ticket` to transition the ticket to `in-progress` via the provider-specific path

##### Scenario: backlog transition declined — continues without state change
- **WHEN** ticket state is `backlog` and user answers `n`
- **THEN** skill outputs `Transition cancelled — continuing in exploration mode (ticket stays in current state).` and proceeds to branch creation without any state change

##### Scenario: WIP check applied on backlog transition too
- **WHEN** ticket state is `backlog`, user confirms transition, and wip_limit would be exceeded
- **THEN** skill shows the WIP warning and asks `Continue? [y/n]` before calling the provider — same as for todo→in-progress

---

#### Requirement: start mode uses provider-specific write path and label-delta for state transitions

**Adds** to the existing "start mode transitions a todo ticket to in-progress" requirement.

Both the `todo` and `backlog` transition paths SHALL use provider-specific dispatch:

##### Scenario: GitLab in-progress transition removes old state label
- **WHEN** a GitLab ticket with the `To Do` label is transitioned to `in-progress` via start mode
- **THEN** skill uses the label-delta helper to add the `In Progress` label AND remove the `To Do` label in the same call — not just add the new label

##### Scenario: GitHub in-progress transition removes old state label
- **WHEN** a GitHub ticket with the `todo` label is transitioned to `in-progress` via start mode
- **THEN** skill uses the label-delta helper to add the `in-progress` label AND remove the `todo` label

##### Scenario: Plane in-progress transition uses state UUID
- **WHEN** a Plane ticket is transitioned to `in-progress` via start mode
- **THEN** skill reads the UUID for `in-progress` from `plane_state_ids` in `.project/config.yaml` and passes it as the `state` field in the `update_issue` call

##### Scenario: Jira in-progress transition uses transition name directly
- **WHEN** a Jira ticket is transitioned to `in-progress` via start mode
- **THEN** skill calls `update_ticket` with the transition name `In Progress` from `state_mapping` — no label-delta or UUID lookup needed
