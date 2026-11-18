## ADDED Requirements

### Requirement: Bulk reads the same doc files per extended project type as docs scaffold
For `qa`, `ai`, `cli`, and `library` the skill SHALL read `prd.md`, `architecture.md`, and `tools.md`; for `bi` it SHALL read `prd.md`, `architecture.md`, `database.md`, and `tools.md`. Missing files are silently skipped.

#### Scenario: bi reads database.md
- **WHEN** bulk mode runs with `project_type: bi`
- **THEN** the skill reads `docs/database.md` for entity candidates

#### Scenario: library skips database.md
- **WHEN** bulk mode runs with `project_type: library`
- **THEN** the skill does not attempt to read `docs/database.md`
