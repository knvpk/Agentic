## Purpose
Defines the interactive fill flow that populates project documentation through grouped Q&A. Questions are grouped so a single answer fills multiple sections across multiple files. The flow is triggered after scaffold or via explicit routing phrases and always appends rather than overwrites.

## Requirements

### Requirement: Fill flow is offered immediately after scaffold
After scaffolding one or more doc files for the first time, the skill SHALL offer to fill them in immediately via a single prompt before exiting.

#### Scenario: Scaffold offer is shown after first-time docs creation
- **WHEN** docs mode creates any new doc files during scaffold (Step 2)
- **THEN** the skill outputs: `Created: {file list}. Fill them in now? [y/n]`
- **AND** if the user replies `y`, the skill immediately runs the Interactive Fill Flow
- **AND** if the user replies `n`, the skill exits cleanly with no further prompts

#### Scenario: Fill offer is not shown when docs/ already exists
- **WHEN** docs mode is invoked and `docs/` already exists (scaffold is skipped)
- **THEN** no fill offer is shown — the skill proceeds to Step 3 as usual

---

### Requirement: Fill flow is reachable independently via routing phrases
The skill SHALL enter the Interactive Fill Flow when the user invokes docs mode with a fill-intent phrase, without re-scaffolding files.

#### Scenario: Fill-intent phrase triggers fill flow on existing docs
- **WHEN** user says "fill docs", "populate docs", "fill in docs", or "fill in the {file}" (any doc file name)
- **THEN** the skill runs the Interactive Fill Flow against existing files in `docs/`
- **AND** the skill does NOT create new files — it only fills sections in files that already exist

#### Scenario: Fill-intent phrase on a specific file targets only that file
- **WHEN** user says "fill in the PRD" or "fill in architecture"
- **THEN** the skill runs the fill flow only for the questions that target that specific file
- **AND** other doc files are not modified

---

### Requirement: Fill flow uses a grouped question set, not a per-section wizard
The skill SHALL ask at most 10 questions per fill session. Core questions cover all project types. Conditional questions are asked only for the applicable `project_type`. Optional questions may be skipped with Enter.

#### Scenario: Core questions are asked for every project type
- **WHEN** the Interactive Fill Flow begins
- **THEN** the skill asks the following core questions in order, showing target sections after each question label:

| # | Question | Fills |
|---|----------|-------|
| 1 | "What does this project do? (2-3 sentences)" | `prd.md §Overview` |
| 2 | "What are the main features? (one per line)" | `prd.md §Features` |
| 3 | "What is the tech stack? Include language, framework, testing, and linting tools." | `tools.md §Language`, `tools.md §Framework`, `tools.md §Testing`, `tools.md §Linting & Formatting` |
| 4 | "What are the main components or services?" | `architecture.md §Components` |
| 5 | "How does data flow through the system? (e.g. client → API → DB)" | `architecture.md §Data Flow` |

#### Scenario: Conditional questions are asked based on project_type
- **WHEN** the Interactive Fill Flow runs and `project_type` is `web`, `api`, or `generic`
- **THEN** after core questions, the skill asks: "What database(s) do you use, and what are the main entities/tables?"
- **AND** the answer fills `database.md §Overview` and `database.md §Entities`

- **WHEN** `project_type` is `api`
- **THEN** the skill also asks: "How is the API authenticated and versioned? (e.g. Bearer token, URI versioning)"
- **AND** the answer fills `api.md §Authentication` and `api.md §Versioning Strategy`

- **WHEN** `project_type` is `microservices`
- **THEN** the skill asks: "List your services with their responsibilities (name: description, one per line)"
- **AND** the answer fills `services.md §Service Registry`

- **WHEN** `project_type` is `mobile`
- **THEN** the skill asks: "What local storage engine do you use, and how does data sync with the backend?"
- **AND** the answer fills `local-storage.md §Storage Engine` and `local-storage.md §Sync Strategy`

#### Scenario: Optional questions are skippable with Enter
- **WHEN** the skill reaches an optional question
- **THEN** the question is prefixed with `(optional — press Enter to skip)`
- **AND** if the user presses Enter without typing anything, the skill skips that question and moves to the next
- **AND** the following questions are optional:
  - "Any non-functional requirements? (performance, security, compliance)" → `prd.md §Non-Functional Requirements`
  - "What CI/CD, command runner, and dev environment do you use?" → `tools.md §CI/CD`, `tools.md §Command Runner`, `tools.md §Dev Environment`
  - "Any Docker app dependencies? (e.g. postgres, redis)" → `tools.md §App Dependencies (Docker)`
  - "Any key architecture decisions already made?" → `architecture.md §Architecture Decisions`

#### Scenario: User can stop the fill flow early
- **WHEN** the user types `done` at any question prompt
- **THEN** the skill stops asking questions and proceeds to the post-fill summary immediately

---

### Requirement: Each answer targets one or more file sections
The skill SHALL write each answer's content to the specified target sections. Content SHALL be formatted to match the section's purpose (bullet list for features, prose for overview, table for service registry, etc.).

#### Scenario: Tech stack answer is distributed to multiple tools.md sections
- **WHEN** user answers the tech stack question with "TypeScript, Next.js, Jest, ESLint + Prettier"
- **THEN** `tools.md §Language` is filled with "TypeScript"
- **AND** `tools.md §Framework` is filled with "Next.js"
- **AND** `tools.md §Testing` is filled with "Jest"
- **AND** `tools.md §Linting & Formatting` is filled with "ESLint + Prettier"
- **AND** no other sections are modified

#### Scenario: Features answer is formatted as a bullet list
- **WHEN** user answers the features question with one feature per line
- **THEN** `prd.md §Features` is written with each line as a `- item` bullet

#### Scenario: Docker dependencies answer triggers docker-modular-stack check
- **WHEN** user answers the Docker app dependencies question with any service name
- **THEN** after writing to `tools.md §App Dependencies (Docker)`, the skill checks the docker-modular-stack catalog
- **AND** if any service matches, outputs the standard suggestion: `💡 {services} are available in docker-modular-stack. Run /docker-modular-stack to scaffold these services.`

---

### Requirement: Fill flow appends to sections that already contain content
When a target section is non-empty, the skill SHALL append new content below a `---` divider rather than overwriting.

#### Scenario: Append separator is inserted before new content when section has content
- **WHEN** the fill flow targets a section that already contains non-whitespace text
- **THEN** the skill appends `\n\n---\n\n{new content}` after the existing content
- **AND** the existing content is not modified

#### Scenario: Fill flow writes directly when section is empty
- **WHEN** the fill flow targets a section whose body is empty or contains only whitespace
- **THEN** the skill writes the new content directly without a separator

---

### Requirement: Fill flow ends with a per-file summary
After all questions are answered (or `done` is typed), the skill SHALL output a summary listing every section that was written.

#### Scenario: Post-fill summary lists all written sections
- **WHEN** the Interactive Fill Flow completes
- **THEN** the skill outputs a summary grouped by file, e.g.:
  ```
  ✓ docs/prd.md         — Overview, Features, Non-Functional Requirements
  ✓ docs/architecture.md — Components, Data Flow
  ✓ docs/tools.md       — Language, Framework, Testing, CI/CD
  ✓ docs/database.md    — Overview, Entities
  ```
- **AND** skipped or unanswered sections are not listed
