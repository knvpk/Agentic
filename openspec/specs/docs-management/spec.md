## Purpose
Defines how the skill manages the `docs/` directory, scaffolds canonical documentation files, and reads those files as context when generating ticket content.

## Requirements

### Requirement: Skill creates docs directory and scaffold files on first use
When docs mode is invoked and `docs/` does not exist, the skill SHALL create the directory and scaffold the files appropriate to the `project_type` declared in `.project/config.yaml`. If no `project_type` is set, the skill SHALL scaffold the generic file set (prd.md, architecture.md, database.md, tools.md). After scaffolding, the skill SHALL offer the Interactive Fill Flow as defined in the `docs-interactive-fill` spec.

#### Scenario: First-time docs init creates type-appropriate files for mobile
- **WHEN** docs mode is invoked, no `docs/` exists, and `project_type: mobile`
- **THEN** skill creates `docs/prd.md`, `docs/architecture.md`, `docs/local-storage.md`, and `docs/tools.md`
- **AND** `docs/database.md` is NOT created

#### Scenario: First-time docs init creates type-appropriate files for API
- **WHEN** docs mode is invoked, no `docs/` exists, and `project_type: api`
- **THEN** skill creates `docs/prd.md`, `docs/architecture.md`, `docs/database.md`, `docs/tools.md`, and `docs/api.md`

#### Scenario: First-time docs init for microservices skips prd.md
- **WHEN** docs mode is invoked, no `docs/` exists, and `project_type: microservices`
- **THEN** skill creates `docs/architecture.md`, `docs/services.md`, and `docs/tools.md`
- **AND** `docs/prd.md` is NOT created

#### Scenario: First-time docs init for generic or missing project_type creates v1 file set
- **WHEN** docs mode is invoked, no `docs/` exists, and `project_type` is `generic` or absent
- **THEN** skill creates `docs/prd.md`, `docs/architecture.md`, `docs/database.md`, and `docs/tools.md` (unchanged from v1)

#### Scenario: Existing files are updated, not recreated
- **WHEN** docs mode is invoked and `docs/prd.md` already exists
- **THEN** the skill edits the existing file without overwriting unrelated sections

#### Scenario: Fill flow offer is shown after scaffold
- **WHEN** docs mode creates any new doc files during scaffold
- **THEN** the skill outputs `Created: {file list}. Fill them in now? [y/n]` before exiting
- **AND** `y` triggers the Interactive Fill Flow; `n` exits cleanly

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

### Requirement: tools.md sections vary by project type
The `docs/tools.md` scaffold SHALL include sections appropriate to the `project_type`. The `## App Dependencies (Docker)` section is only included for `web`, `api`, `microservices`, and `generic` types. Mobile type replaces it with signing and distribution sections.

#### Scenario: Mobile tools.md does not contain App Dependencies (Docker) section
- **WHEN** `docs/tools.md` is scaffolded for a mobile project
- **THEN** it contains `## App Signing & Certificates`, `## Build & Distribution`, `## App Store`, `## OTA Updates` sections
- **AND** it does NOT contain `## App Dependencies (Docker)`

#### Scenario: Web and API tools.md retains App Dependencies (Docker) section
- **WHEN** `docs/tools.md` is scaffolded for a web or api project
- **THEN** it contains `## App Dependencies (Docker)` with the docker-modular-stack suggestion behaviour intact

### Requirement: api.md scaffold has canonical sections for an API service
When `docs/api.md` is scaffolded (api and microservices types), it SHALL contain sections: Endpoint Catalog, Versioning Strategy, Authentication, Rate Limiting, Error Format, and Deprecation Policy.

#### Scenario: New api.md scaffold contains all required sections
- **WHEN** `docs/api.md` is scaffolded
- **THEN** it contains `## Endpoint Catalog`, `## Versioning Strategy`, `## Authentication`, `## Rate Limiting`, `## Error Format`, and `## Deprecation Policy`

### Requirement: services.md scaffold has a service registry table and per-service sections
When `docs/services.md` is scaffolded (microservices type), it SHALL contain a services table (name, port, health endpoint, description) and `### Service: {name}` section stubs for team members to fill in with dependencies and data ownership.

#### Scenario: New services.md scaffold contains service registry table
- **WHEN** `docs/services.md` is scaffolded
- **THEN** it contains a markdown table with columns: `Name`, `Port`, `Health Endpoint`, `Responsibility`
- **AND** a `### Service: example-svc` stub section with Dependencies, Data Ownership, and Upstream/Downstream sub-sections

### Requirement: local-storage.md scaffold has sections for client-side persistence
When `docs/local-storage.md` is scaffolded (mobile type), it SHALL contain sections: Storage Engine, Data Model, Migration Strategy, and Sync Strategy.

#### Scenario: New local-storage.md scaffold contains required sections
- **WHEN** `docs/local-storage.md` is scaffolded for a mobile project
- **THEN** it contains `## Storage Engine`, `## Data Model`, `## Migration Strategy`, and `## Sync Strategy`

### Requirement: Context fallback chain recognises local-storage.md as the mobile equivalent of database.md
When generating ticket context for a mobile project, the skill SHALL search `docs/local-storage.md` in place of `docs/database.md` in the fallback chain step for database entities.

#### Scenario: Ticket context references local-storage.md for mobile project
- **WHEN** a ticket is created on a mobile project and the topic matches an entity in `docs/local-storage.md`
- **THEN** `## Context` references `docs/local-storage.md` rather than `docs/database.md`

### Requirement: Skill reads all four docs files as context before creating tickets
When creating ticket content, the skill SHALL read `docs/prd.md`, `docs/architecture.md`, `docs/database.md`, and `docs/tools.md` to derive relevant context links and populate the ticket brief.

#### Scenario: Ticket creation references the correct prd.md section
- **WHEN** a ticket is created for a feature that appears in `docs/prd.md` under `## Features`
- **THEN** the ticket body includes a context line referencing that section (e.g., `> Derived from docs/prd.md §Features — Token Refresh`)

#### Scenario: Ticket references relevant tools from tools.md
- **WHEN** a ticket involves authentication and `docs/tools.md` lists authentik under `## App Dependencies (Docker)`
- **THEN** the ticket body references authentik in the context block

### Requirement: Step 3 asks targeted question when the target section is empty
When the user requests an edit to a specific doc section and that section's body is empty or whitespace-only, the skill SHALL ask the targeted question from the `docs-interactive-fill` question map rather than waiting passively for the user to supply content.

#### Scenario: Empty overview section prompts for project description
- **WHEN** user says "update the architecture overview" and `docs/architecture.md §Overview` is empty
- **THEN** skill asks: "What does this project do at a high level? (2-3 sentences)"
- **AND** the answer is written to `docs/architecture.md §Overview`

#### Scenario: Empty features section prompts for feature list
- **WHEN** user says "add to the PRD features" and `docs/prd.md §Features` is empty
- **THEN** skill asks: "What are the main features? (one per line)"
- **AND** the answer is written as bullet list entries in `docs/prd.md §Features`

#### Scenario: Non-empty section is edited conversationally without prompting
- **WHEN** user says "update the architecture components" and `docs/architecture.md §Components` already has content
- **THEN** the skill edits the section using the user's stated changes without first asking a question
