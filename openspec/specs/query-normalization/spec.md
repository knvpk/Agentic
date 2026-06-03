## Purpose
Defines the query normalization layer that extracts intent and filter objects from natural language user input before routing to an operating mode.

## Requirements

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

### Requirement: Skill understands a shared filter grammar across all list and status operations
The skill SHALL recognise the following filter patterns in any user input and extract them into the filter object before routing:

| Pattern | Filter key | Example |
|---|---|---|
| `@{name}` | assignee | `@alice` → `assignee: "alice"` |
| `#{id}` or `TICK-{n}` | ticket | `#42` → `ticket: "42"` |
| `"about {term}"` | search_term | `"about auth"` → `search_term: "auth"` |
| `"in sprint {n}"` | sprint | `"in sprint 4"` → `sprint: "Sprint 4"` |
| canonical state name | state | `"blocked"` → `state: "blocked"` |
| `"high priority"` / `"critical"` | priority | `"high priority"` → `priority: "high"` |
| `"label:{slug}"` | label | `"label:backend"` → `label: "backend"` |

#### Scenario: Assignee filter extracted from @-mention
- **WHEN** user says "what tickets does @bob have"
- **THEN** filter object contains `assignee: "bob"`

#### Scenario: Multiple filters compose in a single input
- **WHEN** user says "show me blocked high-priority tickets in sprint 4"
- **THEN** filter object contains `{ state: "blocked", priority: "high", sprint: "Sprint 4" }`

#### Scenario: Ticket reference extracted from # prefix
- **WHEN** user says "update #38 to done"
- **THEN** filter object contains `ticket: "38"` and `state: "done"`

#### Scenario: Search term extracted from "about" phrase
- **WHEN** user says "find tickets about the payment gateway"
- **THEN** filter object contains `search_term: "payment gateway"`

### Requirement: Normalization is a declared step in SKILL.md, not implicit
SKILL.md SHALL include an explicit "Query Normalization" section that defines the intent verbs, the filter grammar, and the default fallback. This section SHALL be referenced by the mode routing table.

#### Scenario: Query normalization section present in SKILL.md
- **WHEN** SKILL.md is inspected
- **THEN** it contains a "Query Normalization" or equivalent section listing intent verbs and filter patterns

#### Scenario: Filter grammar documented for user-facing discovery
- **WHEN** a user reads the skill's routing documentation
- **THEN** they can see what query patterns are understood (assignee, state, sprint, search_term, etc.)
