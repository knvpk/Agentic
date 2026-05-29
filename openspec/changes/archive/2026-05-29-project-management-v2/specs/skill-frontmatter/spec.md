## MODIFIED Requirements

### Requirement: SKILL.md declares a mode routing table
The skill SHALL include a mode routing table mapping user intent patterns to one of: `init`, `docs`, `sprint`, `ticket`, `next`, `status`. The table SHALL include both imperative command forms and natural language query forms for each mode. Ticket list sub-mode entries SHALL include examples of filter-style queries (`@{name}`, state keywords, sprint references).

#### Scenario: Mode table covers all six modes with query-style examples
- **WHEN** the SKILL.md routing table is inspected
- **THEN** the ticket → list entry includes examples such as "show me @alice's tickets", "what's blocked", "find tickets about auth"
- **AND** the ticket → update entry includes "move TICK-42 to in-review"

#### Scenario: Routing table references query normalization layer
- **WHEN** SKILL.md is inspected
- **THEN** the mode routing section references the Query Normalization step for filter extraction

## ADDED Requirements

### Requirement: SKILL.md includes an explicit Query Normalization section
SKILL.md SHALL include a "Query Normalization" section that defines: the intent verb list (show/list/find/search → list; create/add/new → create; update/move/change → update; close/done/finish → lifecycle), the filter grammar table, and the default fallback (ticket → list). This section SHALL appear before the mode routing table.

#### Scenario: Query normalization section present in SKILL.md
- **WHEN** SKILL.md is inspected
- **THEN** it contains a section named "Query Normalization" or "Shared: Query Normalization" before the mode routing table

#### Scenario: Filter grammar table documents all recognised patterns
- **WHEN** the Query Normalization section is read
- **THEN** it contains a table showing: `@{name}` → assignee, `#{id}` → ticket, `"about {term}"` → search_term, state keywords, priority keywords, sprint reference
