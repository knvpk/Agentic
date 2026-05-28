## ADDED Requirements

### Requirement: Skill enforces canonical state machine for all ticket transitions
The skill SHALL validate all state transitions against the canonical machine (`backlog → todo → in-progress → in-review → done | blocked`) before dispatching to the provider. Invalid transitions SHALL be rejected with an explanation.

#### Scenario: Valid forward transition is dispatched to provider
- **WHEN** user transitions a ticket from `todo` to `in-progress`
- **THEN** skill maps to the provider state and calls the appropriate MCP update tool

#### Scenario: Backward skip transition is rejected
- **WHEN** user attempts to transition from `backlog` directly to `in-review`
- **THEN** skill rejects the transition and lists valid next states

#### Scenario: Blocked state requires a reason
- **WHEN** user transitions a ticket to `blocked`
- **THEN** skill prompts for a blocking reason and optionally a blocking ticket reference

### Requirement: Skill supports all three relationship types between tickets
The skill SHALL support creating `parent/child`, `blocks/blocked-by`, and `relates-to` relationships. For providers without native support, the skill SHALL simulate using structured labels and description comments.

#### Scenario: Native blocks relation created on Jira
- **WHEN** user links TICK-A as blocking TICK-B on Jira
- **THEN** skill calls `mcp__jira__create_issue_link` with type `Blocks`

#### Scenario: Blocks relation simulated via comment on GitHub
- **WHEN** user links TICK-A as blocking TICK-B on GitHub
- **THEN** skill adds a comment to TICK-B containing `Blocked by: #A` and adds label `blocked`

#### Scenario: Parent/child via label when epics unsupported
- **WHEN** epics capability is false and user sets TICK-B as child of TICK-A (epic:auth)
- **THEN** skill attaches label `epic:auth` to TICK-B and adds a description note referencing the parent

#### Scenario: relates-to is bidirectional
- **WHEN** user links TICK-A relates-to TICK-B
- **THEN** both TICK-A and TICK-B receive a `relates:#{other_id}` label or comment

### Requirement: Ticket create requires title and at least one label or sprint assignment
The skill SHALL not create a ticket with only a title. At minimum, a label or sprint/milestone assignment is required.

#### Scenario: Bare title ticket creation is refused
- **WHEN** user asks to create ticket with only "Fix login bug" and no other context
- **THEN** skill prompts for at least a label or sprint before creating

### Requirement: Ticket list and filter operations use the canonical state vocabulary
When listing tickets, the skill SHALL accept canonical state names as filters and translate them to provider query syntax.

#### Scenario: Filter by canonical in-progress on GitHub
- **WHEN** user asks "show in-progress tickets"
- **THEN** skill queries GitHub issues with label `in-progress` and state `open`

#### Scenario: Filter by canonical blocked on Plane
- **WHEN** user asks "show blocked tickets"
- **THEN** skill queries Plane issues with state `Blocked`
