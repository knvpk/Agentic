## Purpose
Defines how the skill manages the `docs/` directory, scaffolds canonical documentation files, and reads those files as context when generating ticket content.

## Requirements

### Requirement: Skill creates docs directory and scaffold files on first use
When docs mode is invoked and `docs/` does not exist, the skill SHALL create the directory and scaffold `docs/prd.md`, `docs/architecture.md`, `docs/database.md`, and `docs/tools.md` with structured section headers before editing.

#### Scenario: First-time docs init creates all four files
- **WHEN** docs mode is invoked and no `docs/` directory exists
- **THEN** the skill creates `docs/prd.md`, `docs/architecture.md`, `docs/database.md`, and `docs/tools.md` with empty section scaffolds

#### Scenario: Existing files are updated, not recreated
- **WHEN** docs mode is invoked and `docs/prd.md` already exists
- **THEN** the skill edits the existing file without overwriting unrelated sections

### Requirement: prd.md has canonical sections for features, NFRs, requirements, and scenarios
The `docs/prd.md` file SHALL be structured with sections: Overview, Features, Non-Functional Requirements, Requirements, and Scenarios.

#### Scenario: New prd.md scaffold contains all required sections
- **WHEN** `docs/prd.md` is scaffolded for the first time
- **THEN** it contains `## Overview`, `## Features`, `## Non-Functional Requirements`, `## Requirements`, and `## Scenarios` headers

#### Scenario: Skill adds a new feature to the Features section
- **WHEN** user asks to add feature "Token refresh" to the PRD
- **THEN** a new entry is appended under `## Features` without disturbing existing entries

### Requirement: architecture.md has canonical sections for system overview, components, and decisions
The `docs/architecture.md` file SHALL be structured with sections: Overview, Components, Data Flow, and Architecture Decisions.

#### Scenario: New architecture.md scaffold contains required sections
- **WHEN** `docs/architecture.md` is scaffolded
- **THEN** it contains `## Overview`, `## Components`, `## Data Flow`, and `## Architecture Decisions`

### Requirement: database.md has canonical sections for entities, relationships, and schema notes
The `docs/database.md` file SHALL be structured with sections: Overview, Entities, Relationships, and Schema Notes.

#### Scenario: New database.md scaffold contains required sections
- **WHEN** `docs/database.md` is scaffolded
- **THEN** it contains `## Overview`, `## Entities`, `## Relationships`, and `## Schema Notes`

### Requirement: tools.md has canonical sections for the project tech stack
The `docs/tools.md` file SHALL be structured with sections: Language, Framework, CI/CD, Command Runner, Dev Environment, Testing, App Dependencies (Docker), and Linting & Formatting.

#### Scenario: New tools.md scaffold contains all required sections
- **WHEN** `docs/tools.md` is scaffolded
- **THEN** it contains `## Language`, `## Framework`, `## CI/CD`, `## Command Runner`, `## Dev Environment`, `## Testing`, `## App Dependencies (Docker)`, and `## Linting & Formatting` headers

#### Scenario: Adding a Docker app dependency suggests docker-modular-stack
- **WHEN** user adds a Docker dependency under `## App Dependencies (Docker)` (e.g., postgres, valkey, authentik, keycloak)
- **THEN** the skill checks whether the service name exists in the `docker-modular-stack` skill catalog
- **AND** if found, outputs: "Run `/docker-modular-stack` to scaffold these services"

#### Scenario: tools.md is updated, not recreated, on subsequent edits
- **WHEN** user adds a new tool to an existing `docs/tools.md`
- **THEN** the skill appends to the relevant section without overwriting other sections

### Requirement: Skill reads all four docs files as context before creating tickets
When creating ticket content, the skill SHALL read `docs/prd.md`, `docs/architecture.md`, `docs/database.md`, and `docs/tools.md` to derive relevant context links and populate the ticket brief.

#### Scenario: Ticket creation references the correct prd.md section
- **WHEN** a ticket is created for a feature that appears in `docs/prd.md` under `## Features`
- **THEN** the ticket body includes a context line referencing that section (e.g., `> Derived from docs/prd.md §Features — Token Refresh`)

#### Scenario: Ticket references relevant tools from tools.md
- **WHEN** a ticket involves authentication and `docs/tools.md` lists authentik under `## App Dependencies (Docker)`
- **THEN** the ticket body references authentik in the context block
