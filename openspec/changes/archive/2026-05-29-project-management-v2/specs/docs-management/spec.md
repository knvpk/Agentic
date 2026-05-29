## MODIFIED Requirements

### Requirement: Skill creates docs directory and scaffold files on first use
When docs mode is invoked and `docs/` does not exist, the skill SHALL create the directory and scaffold the files appropriate to the `project_type` declared in `.project/config.yaml`. If no `project_type` is set, the skill SHALL scaffold the generic file set (prd.md, architecture.md, database.md, tools.md).

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

## ADDED Requirements

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
