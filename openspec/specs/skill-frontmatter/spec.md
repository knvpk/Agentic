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

### Requirement: SKILL.md declares a mode routing table
The skill SHALL include a mode routing table mapping user intent patterns to one of: `init`, `docs`, `sprint`, `ticket`, `next`, `status`.

#### Scenario: Mode table covers all six modes
- **WHEN** the SKILL.md is inspected
- **THEN** it contains a table or list mapping at least one trigger phrase to each of the six modes

### Requirement: Skill directory follows agentskills.io structure
The skill directory SHALL contain `SKILL.md` at the root and a `references/` subdirectory holding `providers.json` and one reference file per supported provider.

#### Scenario: Required files are present
- **WHEN** `skills/project-management/` is listed
- **THEN** `SKILL.md` and `references/providers.json` exist
- **AND** `references/github.md`, `references/gitlab.md`, `references/jira.md`, `references/plane.md` exist
