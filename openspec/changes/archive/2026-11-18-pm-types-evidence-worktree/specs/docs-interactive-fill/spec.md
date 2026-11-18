## ADDED Requirements

### Requirement: Step B asks one conditional question per extended project type
Step B conditional questions SHALL include: `bi` → joins the existing database question (sources and main entities, targeting `database.md §Overview` and `§Entities`); `library` → "What is the public API surface and versioning policy?" (`architecture.md §Components`, `§Architecture Decisions`); `ai` → "Which models/providers are used and how are outputs evaluated?" (`architecture.md §Components`, `§Architecture Decisions`); `cli` → "What commands and flags form the public interface, and what is the output contract (stdout, stderr, exit codes)?" (`architecture.md §Components`); `qa` → "What is under test, and which tools and environments are used?" (`architecture.md §Components`, `tools.md`).

#### Scenario: cli project is asked the interface question
- **WHEN** the interactive fill runs with `project_type: cli`
- **THEN** the skill asks about commands, flags, and the output contract and writes the answer to `architecture.md §Components`

#### Scenario: bi project is asked the database question
- **WHEN** the interactive fill runs with `project_type: bi`
- **THEN** the skill asks about data sources and main entities and writes to `database.md`
