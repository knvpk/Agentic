## Purpose
Defines the required structure and content of `SKILL.md` so the skill is discoverable via agentskills.io tooling and routes user intent to the correct operating mode.

## Requirements

### Requirement: SKILL.md has valid agentskills.io frontmatter
The skill SHALL include a `SKILL.md` file with YAML frontmatter containing `name: project-management`, a `description` under 1024 characters that covers all modes and their trigger conditions, and a `compatibility` field listing MCP server requirements.

#### Scenario: Skill is discoverable via npx skills
- **WHEN** `npx skills` is run in a project that has `skills/project-management/` in its path
- **THEN** the skill appears in the listing with name `project-management`

#### Scenario: Description triggers on docs queries
- **WHEN** a user says "update the PRD", "add a feature to architecture.md", or "update the database schema doc"
- **THEN** Claude identifies and activates the `project-management` skill in docs mode

#### Scenario: Description triggers on ticket queries
- **WHEN** a user says "create a ticket for X", "update ticket status", or "link these tickets"
- **THEN** Claude identifies and activates the `project-management` skill in ticket mode

#### Scenario: Description triggers on sprint queries
- **WHEN** a user says "start a new sprint", "add ticket to current sprint", or "show sprint status"
- **THEN** Claude identifies and activates the `project-management` skill in sprint mode

#### Scenario: Description triggers on scheduling queries
- **WHEN** a user says "what should I work on today", "next ticket", or "what's my next task"
- **THEN** Claude identifies and activates the `project-management` skill in next-ticket mode

### Requirement: SKILL.md includes an explicit Query Normalization section
SKILL.md SHALL include a "Query Normalization" section that defines: the intent verb list (show/list/find/search → list; create/add/new → create; update/move/change → update; close/done/finish → lifecycle), the filter grammar table, and the default fallback (ticket → list). This section SHALL appear before the mode routing table.

#### Scenario: Query normalization section present in SKILL.md
- **WHEN** SKILL.md is inspected
- **THEN** it contains a section named "Query Normalization" or "Shared: Query Normalization" before the mode routing table

#### Scenario: Filter grammar table documents all recognised patterns
- **WHEN** the Query Normalization section is read
- **THEN** it contains a table showing: `@{name}` → assignee, `#{id}` → ticket, `"about {term}"` → search_term, state keywords, priority keywords, sprint reference

### Requirement: SKILL.md declares a mode routing table
The skill SHALL include a mode routing table mapping user intent patterns to one of: `init`, `docs`, `sprint`, `ticket`, `next`, `status`. The table SHALL include both imperative command forms and natural language query forms for each mode. Ticket list sub-mode entries SHALL include examples of filter-style queries (`@{name}`, state keywords, sprint references).

#### Scenario: Mode table covers all six modes with query-style examples
- **WHEN** the SKILL.md routing table is inspected
- **THEN** the ticket → list entry includes examples such as "show me @alice's tickets", "what's blocked", "find tickets about auth"
- **AND** the ticket → update entry includes "move TICK-42 to in-review"

#### Scenario: Routing table references query normalization layer
- **WHEN** SKILL.md is inspected
- **THEN** the mode routing section references the Query Normalization step for filter extraction

### Requirement: Skill directory follows agentskills.io structure
The skill directory SHALL contain `SKILL.md` at the root and a `references/` subdirectory holding `providers.json` and one reference file per supported provider.

#### Scenario: Required files are present
- **WHEN** `skills/project-management/` is listed
- **THEN** `SKILL.md` and `references/providers.json` exist
- **AND** `references/github.md`, `references/gitlab.md`, `references/jira.md`, `references/plane.md` exist
