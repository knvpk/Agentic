## ADDED Requirements

### Requirement: tools.md for extended project types uses the generic variant
For `project_type` values `qa`, `ai`, `bi`, `cli`, and `library` the `tools.md` scaffold SHALL use the generic variant (the same sections as for `generic`).

#### Scenario: cli project gets generic tools.md
- **WHEN** docs scaffold runs with `project_type: cli`
- **THEN** `docs/tools.md` is created with the generic variant's sections
