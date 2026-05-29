## Purpose
Defines the structure, language standards, and context-extraction logic used when generating ticket body content. Ticket content generation is scoped to producing the ticket body only — it does not write OpenSpec files.

## Requirements

### Requirement: Generated ticket body contains all six required sections
Every ticket created by the skill SHALL include: Summary, Context (derived from docs/), Requirements (SHALL statements), Scenarios (GIVEN/WHEN/THEN), Use Cases (actor + flow), Non-Functional Constraints, and an opsx hand-off hint.

This requirement now applies to tickets created through THREE entry points:
1. Direct `ticket new` conversational input (existing behavior).
2. `bulk` mode manifest creation — body is generated at create time per manifest row using the row's title, type, and source doc section as input.
3. `ticket new` breakdown manifest creation — same as bulk mode, scoped to matching doc sections.

For manifest-sourced tickets, the source doc section provides the primary context input in place of the conversational description. The Context block SHALL reference the originating doc section explicitly.

#### Scenario: New ticket body contains all required sections
- **WHEN** a ticket is created via the skill
- **THEN** the body contains `## Summary`, `## Context`, `## Requirements`, `## Scenarios`, `## Use Cases`, `## Non-Functional`, and `## OpenSpec Hint` sections

#### Scenario: Manifest-sourced ticket body contains all required sections
- **WHEN** a ticket is created from a bulk manifest row titled "Auth token silent refresh" sourced from `docs/prd.md §Features`
- **THEN** the generated body contains `## Summary`, `## Context`, `## Requirements`, `## Scenarios`, `## Use Cases`, `## Non-Functional`, and `## OpenSpec Hint`

#### Scenario: Context block references source doc section for manifest-sourced tickets
- **WHEN** a ticket is created from a manifest row sourced from `docs/architecture.md §Components — AuthService`
- **THEN** `## Context` contains: `> Derived from docs/architecture.md §Components — AuthService`

#### Scenario: New ticket body via direct input still contains all required sections
- **WHEN** a ticket is created via direct `ticket new` conversational input
- **THEN** the body contains all required sections (existing behavior unchanged)

#### Scenario: OpenSpec hint line is always present
- **WHEN** any ticket is created (via direct input, bulk manifest, or breakdown manifest)
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

### Requirement: Scenario generation is seeded with type-specific BDD pattern hints
When generating the `## Scenarios` section of a ticket body, the skill SHALL include 2–3 seed BDD pattern examples appropriate to the `project_type` declared in config as context for the generation step. The seed patterns guide vocabulary and structure; the generated scenarios are still derived from the ticket topic, not copied from the seeds.

Seed patterns by type:

**mobile:**
- `GIVEN user has denied camera permission / WHEN feature requires camera access / THEN app shows permission rationale dialog and graceful fallback`
- `GIVEN device switches from WiFi to 5G mid-operation / WHEN network transfer is in progress / THEN app resumes without data loss via offline queue`
- `GIVEN app is backgrounded during a long operation / WHEN user returns to foreground / THEN session is restored and operation state is preserved`

**web:**
- `GIVEN API call is in-flight / WHEN component renders / THEN skeleton loader is shown, not blank screen`
- `GIVEN user submits form with invalid input / WHEN validation runs / THEN inline error messages appear and submit button stays disabled`
- `GIVEN user is on mobile viewport (375px) / WHEN page loads / THEN layout adapts to single-column with accessible touch targets`

**api:**
- `GIVEN authenticated user with scope=read:orders / WHEN GET /orders?status=pending / THEN 200 with paginated list and X-Total-Count header`
- `GIVEN request without Authorization header / WHEN POST /payments / THEN 401 Unauthorized with WWW-Authenticate challenge`
- `GIVEN 51st request arrives within a 60-second window (limit = 50/min) / WHEN rate limiter evaluates / THEN 429 Too Many Requests with Retry-After header`

**microservices:**
- `GIVEN orders-svc calls inventory-svc.reserveStock() / WHEN inventory-svc returns 503 three times / THEN circuit breaker trips and order remains in PENDING state`
- `GIVEN payment-svc publishes order.paid event / WHEN notifications-svc is temporarily down / THEN event persists in DLQ and notification is delivered after recovery`
- `GIVEN payment succeeds but order creation fails / WHEN saga compensates / THEN payment is refunded and no order record persists`

**generic:** (no seed patterns — current behaviour unchanged)

#### Scenario: Mobile project ticket scenarios use touch and permission vocabulary
- **WHEN** a ticket is created on a mobile project with `project_type: mobile`
- **THEN** the generated `## Scenarios` section contains at least one scenario using mobile-relevant language (permission, offline, background, or gesture vocabulary)

#### Scenario: API project ticket scenarios use HTTP verb and status code vocabulary
- **WHEN** a ticket is created on an API project with `project_type: api`
- **THEN** the generated `## Scenarios` section contains at least one scenario referencing HTTP methods, status codes, or auth patterns

#### Scenario: Generic project scenarios are unchanged from v1
- **WHEN** a ticket is created on a project with `project_type: generic` or no project_type
- **THEN** scenario generation behaviour is identical to v1 (no seed patterns applied)

#### Scenario: Seed patterns guide vocabulary, not content
- **WHEN** a mobile project ticket is created for "user profile photo upload"
- **THEN** the generated scenarios address the specific topic (photo upload) using mobile vocabulary, not verbatim copies of the seed patterns

### Requirement: Skill does NOT create openspec/specs/ files — only ticket content
The ticket content generation responsibility ends at the ticket body. The skill SHALL NOT write files under `openspec/specs/` or `openspec/changes/`.

#### Scenario: opsx:ff hand-off hint is a line of text, not a file write
- **WHEN** ticket content is generated
- **THEN** the `## OpenSpec Hint` section contains only a text command line, and no files are written to `openspec/`
