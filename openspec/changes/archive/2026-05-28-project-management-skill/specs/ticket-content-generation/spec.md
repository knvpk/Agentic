## ADDED Requirements

### Requirement: Generated ticket body contains all six required sections
Every ticket created by the skill SHALL include: Summary, Context (derived from docs/), Requirements (SHALL statements), Scenarios (GIVEN/WHEN/THEN), Use Cases (actor + flow), Non-Functional Constraints, and an opsx hand-off hint.

#### Scenario: New ticket body contains all required sections
- **WHEN** a ticket is created via the skill
- **THEN** the body contains `## Summary`, `## Context`, `## Requirements`, `## Scenarios`, `## Use Cases`, `## Non-Functional`, and `## OpenSpec Hint` sections

#### Scenario: OpenSpec hint line is always present
- **WHEN** any ticket is created
- **THEN** the `## OpenSpec Hint` section contains a `/opsx:ff` command line referencing the ticket title

### Requirement: Context extraction is relevance-filtered across a fallback chain
The skill SHALL populate the `## Context` block by searching for relevant pieces only — not dumping entire files. It SHALL follow a fallback chain until relevant context is found or exhausted: (1) docs/ files, (2) local files in the same repo, (3) files in other configured repos.

#### Scenario: Only matching sections from docs are included
- **WHEN** a ticket is created for "auth token refresh" and `docs/prd.md` has sections for both auth and payments
- **THEN** `## Context` includes only the auth section, not the payments section

#### Scenario: Context references all four docs files when relevant
- **WHEN** a ticket involves a feature in prd.md, a component in architecture.md, an entity in database.md, and a tool in tools.md
- **THEN** `## Context` contains a reference line for each relevant piece, each with its source path and section

#### Scenario: Fallback to local repo files when docs have no match
- **WHEN** `docs/` has no section relevant to the ticket topic
- **THEN** the skill searches local repo files (e.g., `src/`, `lib/`, config files) for relevant files by name and content match
- **AND** references any matching local files in the `## Context` block (e.g., `> See: src/auth/token_service.py`)

#### Scenario: Fallback to other configured repos when local search yields nothing
- **WHEN** no relevant content is found in `docs/` or the local repo
- **AND** `.project/config.yaml` contains a `context_repos` list
- **THEN** the skill searches those repos for relevant files and references any matches

#### Scenario: Warn when entire fallback chain yields no context
- **WHEN** no relevant content is found across docs, local files, and other repos
- **THEN** skill notes "No relevant context found — Context section may be incomplete" and continues without failing

#### Scenario: tools.md referenced for relevant tech stack entries
- **WHEN** ticket topic matches a tool declared in `docs/tools.md` (e.g., auth ticket → authentik)
- **THEN** `## Context` includes `> Stack: authentik (docs/tools.md §App Dependencies)`

### Requirement: Requirements section uses SHALL normative language
All requirements in the ticket body SHALL use the word SHALL for normative statements, not "should", "must", or "will".

#### Scenario: Generated requirements use SHALL
- **WHEN** skill generates requirements for "auth token refresh"
- **THEN** each requirement line contains "SHALL" (e.g., "The system SHALL refresh tokens 5 minutes before expiry")

### Requirement: Scenarios section uses GIVEN/WHEN/THEN BDD format
All scenarios in the ticket body SHALL follow the GIVEN/WHEN/THEN structure with one scenario per distinct behaviour.

#### Scenario: Generated scenario follows BDD format
- **WHEN** skill generates a scenario for token expiry handling
- **THEN** it is structured as `GIVEN <precondition>` / `WHEN <action>` / `THEN <outcome>`

#### Scenario: Multiple distinct behaviours produce multiple scenarios
- **WHEN** a feature has two distinct edge cases
- **THEN** the ticket body contains two separate GIVEN/WHEN/THEN blocks

### Requirement: Use Cases section names the actor and describes the flow
Each use case SHALL identify a named actor, a precondition, a numbered flow, and a postcondition.

#### Scenario: Use case block has actor, flow, and postcondition
- **WHEN** skill generates a use case for "session persists across restart"
- **THEN** the use case block contains `**Actor**`, `**Precondition**`, `**Flow**` (numbered), and `**Postcondition**` fields

### Requirement: Skill does NOT create openspec/specs/ files — only ticket content
The ticket content generation responsibility ends at the ticket body. The skill SHALL NOT write files under `openspec/specs/` or `openspec/changes/`.

#### Scenario: opsx:ff hand-off hint is a line of text, not a file write
- **WHEN** ticket content is generated
- **THEN** the `## OpenSpec Hint` section contains only a text command line, and no files are written to `openspec/`
