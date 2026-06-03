## MODIFIED Requirements

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
- **THEN** skill creates `docs/prd.md`, `docs/architecture.md`, `docs/database.md`, and `docs/tools.md`

#### Scenario: Existing files are updated, not recreated
- **WHEN** docs mode is invoked and `docs/prd.md` already exists
- **THEN** the skill edits the existing file without overwriting unrelated sections

#### Scenario: Fill flow offer is shown after scaffold
- **WHEN** docs mode creates any new doc files during scaffold
- **THEN** the skill outputs `Created: {file list}. Fill them in now? [y/n]` before exiting
- **AND** `y` triggers the Interactive Fill Flow; `n` exits cleanly

---

## ADDED Requirements

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
