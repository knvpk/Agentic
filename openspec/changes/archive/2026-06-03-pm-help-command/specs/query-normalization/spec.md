## MODIFIED Requirements

### Requirement: Skill normalizes natural language input to intent + filter object before routing
Before dispatching to a mode, the skill SHALL run a normalization step that extracts an intent verb and a filter object from the user's input. The normalized output SHALL be used to determine the mode, sub-mode, and pre-filled filters for the operation. Help triggers (`help`, `help <mode>`, `?`, `what can you do`, `commands`, `list commands`) SHALL be intercepted before normalization runs and routed directly to help mode without passing through the intent extraction step.

#### Scenario: List intent extracted from natural language
- **WHEN** user says "show me all of alice's in-progress tickets"
- **THEN** normalization produces `{ intent: "list", filters: { assignee: "alice", state: "in-progress" } }`
- **AND** skill routes to `ticket → list` with those filters pre-filled

#### Scenario: Create intent extracted
- **WHEN** user says "add a new task for the login page"
- **THEN** normalization produces `{ intent: "create", filters: {} }`
- **AND** skill routes to `ticket → new`

#### Scenario: Update intent extracted with ticket reference
- **WHEN** user says "move TICK-42 to in-review"
- **THEN** normalization produces `{ intent: "update", filters: { ticket: "TICK-42", state: "in-review" } }`
- **AND** skill routes to `ticket → update` with TICK-42 and state pre-filled

#### Scenario: Ambiguous intent defaults to ticket list
- **WHEN** user input does not clearly match any intent verb AND is not a help trigger
- **THEN** skill routes to `ticket → list` as the safe default

#### Scenario: Help trigger bypasses normalization
- **WHEN** user input matches a help trigger ("help", "?", "help sprint", "what can you do", etc.)
- **THEN** skill routes directly to help mode without running intent extraction or filter grammar parsing
