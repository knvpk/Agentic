## ADDED Requirements

### Requirement: Init asks project type and stack after provider confirmation
After provider confirmation (init Step 2) and before the capability probe (init Step 4), the skill SHALL ask the project type question and the conditional stack question. Results are stored in `.project/config.yaml` as `project_type` and `stack`.

#### Scenario: Project type question inserted into init flow
- **WHEN** init mode runs and provider is confirmed
- **THEN** the next question is "What kind of project is this?" before any capability probe

#### Scenario: project_type and stack written to config at init completion
- **WHEN** user answers project type: "api" and stack: "REST"
- **THEN** `.project/config.yaml` contains `project_type: api` and `stack: rest`

### Requirement: Init prompts to scaffold docs after completing init
After all init steps complete (config written, labels bootstrapped, fallbacks notified), the skill SHALL ask: "Scaffold project docs now? [y/n]". If yes, it SHALL immediately invoke the docs scaffold flow for the configured `project_type`.

#### Scenario: Docs scaffold prompt appears after init completes
- **WHEN** init completes successfully (config written, labels created)
- **THEN** skill outputs "Scaffold project docs now? [y/n]" before returning to idle

#### Scenario: Yes answer immediately scaffolds docs
- **WHEN** user answers yes to the docs scaffold prompt
- **THEN** skill creates the type-appropriate docs files without requiring a separate `/project-management docs` invocation

#### Scenario: No answer skips scaffold without error
- **WHEN** user answers no to the docs scaffold prompt
- **THEN** skill exits init mode; docs can be scaffolded later via docs mode
