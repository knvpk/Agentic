## Purpose

Defines how the skill reads all files in `docs/` and decomposes their content into a typed, dependency-ordered set of ticket candidates that forms the raw input to the manifest review step.

## Requirements

### Requirement: Skill reads all applicable docs/ files based on project_type
The skill SHALL read every doc file present in `docs/` that is applicable to the configured `project_type`. The mapping of `project_type` to expected doc files SHALL follow the same table used by `docs` mode scaffold. Files that do not exist SHALL be silently skipped. The skill SHALL process at minimum: `prd.md`, `architecture.md`, `database.md` or `local-storage.md`, `api.md`, `tools.md`, `services.md`.

#### Scenario: All docs files are read for a web project
- **WHEN** bulk mode is invoked on a project with `project_type: web`
- **THEN** the skill reads `docs/prd.md`, `docs/architecture.md`, `docs/database.md`, and `docs/tools.md`
- **AND** silently skips `docs/api.md` and `docs/services.md` if they do not exist

#### Scenario: Mobile project uses local-storage.md instead of database.md
- **WHEN** bulk mode is invoked on a project with `project_type: mobile`
- **THEN** the skill reads `docs/local-storage.md` for entity/migration candidates
- **AND** does not attempt to read `docs/database.md`

#### Scenario: Missing docs file is skipped without error
- **WHEN** `docs/architecture.md` does not exist
- **THEN** the skill skips it and continues processing other docs files
- **AND** no error is shown to the user

---

### Requirement: Each doc section maps to a specific ticket type
The skill SHALL apply a deterministic section-to-ticket-type mapping. The mapping SHALL be case-insensitive and use prefix matching on section header text.

| Doc file | Section header prefix | Ticket type |
|---|---|---|
| `prd.md` | `Features` | `feature` |
| `prd.md` | `Non-Functional`, `NFR` | `maintenance` |
| `architecture.md` | `Components` | `scaffold` |
| `architecture.md` | `Data Flow` | `task` |
| `architecture.md` | `Decisions` | `spike` (only entries containing "TBD", "evaluate", or "?") |
| `database.md` / `local-storage.md` | `Entities`, `Data Model` | `migration` |
| `api.md` | `Endpoint` | `task` |
| `tools.md` | `CI/CD`, `Testing`, `Dev Environment` | `maintenance` |
| `tools.md` | `App Dependencies` | `maintenance` |
| `services.md` | Each `### Service:` block | `scaffold` |

Sections not matching any known prefix SHALL be ignored (not added to candidates).

#### Scenario: PRD Features section produces feature tickets
- **WHEN** `docs/prd.md` contains a `## Features` section with three named features
- **THEN** the candidate list contains one `feature` ticket per distinct feature entry

#### Scenario: Architecture Decisions with TBD produce spike tickets
- **WHEN** `docs/architecture.md §Architecture Decisions` contains an entry with "TBD" or "needs evaluation"
- **THEN** a `spike` ticket is generated for that decision
- **AND** entries without TBD markers are not converted to spike tickets

#### Scenario: tools.md App Dependencies produces maintenance tickets
- **WHEN** `docs/tools.md §App Dependencies` lists postgres and redis
- **THEN** two `maintenance` tickets are generated: "Set up postgres" and "Set up redis"

#### Scenario: Unknown section header is ignored
- **WHEN** `docs/prd.md` contains a `## Glossary` section
- **THEN** no ticket candidates are generated from that section

---

### Requirement: Skill infers dependency ordering between candidates
The skill SHALL order candidates so that `scaffold` and `migration` tickets appear before `feature` and `task` tickets that reference the same component or entity name. Dependency inference SHALL use name-matching between component/entity names in architecture.md/database.md and the descriptions of feature/task candidates.

#### Scenario: Scaffold ticket precedes its dependent feature ticket
- **WHEN** architecture.md defines an `AuthService` component and prd.md has an "Auth token refresh" feature
- **THEN** the "Set up AuthService" scaffold ticket appears before "Auth token refresh" in the manifest
- **AND** the manifest marks the feature ticket as depending on the scaffold ticket

#### Scenario: Migration ticket precedes its dependent task ticket
- **WHEN** database.md defines a `sessions` entity and api.md has a `POST /auth/token` endpoint
- **THEN** the "Create sessions table" migration ticket appears before "POST /auth/token endpoint" in the manifest

#### Scenario: Tickets with no dependency appear after scaffold/migration group
- **WHEN** a feature ticket has no matching component or entity name
- **THEN** it appears after all scaffold and migration tickets in the manifest

---

### Requirement: Skill deduplicates candidates against existing tracker tickets
Before presenting the manifest, the skill SHALL list open tickets from the active tracker using the `list_tickets` MCP tool. For each candidate, the skill SHALL check if any existing ticket title has >80% word overlap with the candidate title. Matches SHALL be flagged in the manifest with `⚠ possible duplicate of #<id>`. Flagged candidates SHALL remain in the manifest with their checkbox unchecked by default.

#### Scenario: Candidate matching an existing ticket is flagged and unchecked
- **WHEN** the tracker has an open ticket titled "Set up AuthService"
- **AND** bulk generates a candidate titled "Set up AuthService (scaffold)"
- **THEN** the candidate appears in the manifest with `⚠ possible duplicate of #<existing-id>`
- **AND** the candidate checkbox is unchecked by default

#### Scenario: Dedup failure does not block manifest generation
- **WHEN** the `list_tickets` MCP call fails or times out
- **THEN** the skill skips dedup, shows "⚠ Dedup skipped — could not reach tracker" in the manifest header
- **AND** all candidates appear checked by default

#### Scenario: Near-match but different ticket is not flagged
- **WHEN** the tracker has a ticket titled "Bootstrap database schema"
- **AND** bulk generates a candidate titled "Set up AuthService"
- **THEN** the candidate is not flagged as a duplicate

---

### Requirement: Skill presents a count and source summary before the manifest
Before displaying the manifest table, the skill SHALL emit a one-line summary of how many candidates were found and which docs files contributed.

#### Scenario: Summary line shown before manifest
- **WHEN** bulk generates 14 candidates from three doc files
- **THEN** the skill outputs: "Found 14 ticket candidates from docs/prd.md, docs/architecture.md, docs/database.md"
- **AND** the manifest table is displayed immediately after

---

### Requirement: Post-create sprint and epic label offers
After all checked tickets are successfully created, the skill SHALL offer two follow-up actions: (1) assign all created tickets to the active sprint, and (2) auto-create epic labels for each distinct epic group in the manifest.

#### Scenario: Sprint assignment offered after bulk create
- **WHEN** bulk creates 10 tickets
- **AND** `.project/config.yaml` has an `active_sprint`
- **THEN** the skill asks: "Add all 10 tickets to Sprint N? [y/n]"
- **AND** on `y` calls the sprint assignment MCP tool for each ticket

#### Scenario: Epic label creation offered after bulk create
- **WHEN** the manifest contained tickets grouped into 3 distinct epics (Auth, Users, DevOps)
- **THEN** the skill asks: "Create epic labels for Auth, Users, DevOps? [y/n]"
- **AND** on `y` calls `create_label` for each epic slug (if not already existing) then applies labels to the relevant tickets

#### Scenario: Sprint offer skipped when no active sprint configured
- **WHEN** `.project/config.yaml` has no `active_sprint`
- **THEN** the sprint assignment offer is skipped entirely
