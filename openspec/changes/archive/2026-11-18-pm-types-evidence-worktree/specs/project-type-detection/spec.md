## MODIFIED Requirements

### Requirement: Skill asks project type at init before capability probe
At init Step 2 (after provider detection, before capability probe), the skill SHALL ask: "What kind of project is this?" with options: mobile, web, api, microservices, qa, ai, bi, cli, library, generic. The answer SHALL be stored as `project_type` in `.project/config.yaml`.

#### Scenario: Project type question appears at init
- **WHEN** init mode is invoked and no `.project/config.yaml` exists
- **THEN** skill asks the project type question after confirming the provider

#### Scenario: project_type stored in config
- **WHEN** user selects "api" as project type
- **THEN** `.project/config.yaml` contains `project_type: api`

#### Scenario: New type stored in config
- **WHEN** user selects "cli" as project type
- **THEN** `.project/config.yaml` contains `project_type: cli`

#### Scenario: Existing config without project_type defaults to generic
- **WHEN** init is invoked and `.project/config.yaml` exists but has no `project_type` field
- **THEN** skill treats `project_type` as `generic` without re-asking

## ADDED Requirements

### Requirement: Extended project types ask a stack question
For the types `qa`, `ai`, `bi`, `cli`, and `library` the skill SHALL ask one stack question and store the answer as `stack`:

| project_type | Question | Options |
|---|---|---|
| library | Language? | python, typescript, go, rust, other |
| ai | Shape? | llm-app, rag, agent, ml-training, other |
| bi | Tooling? | dbt, metabase, superset, looker, powerbi, other |
| cli | Language? | python, go, node, rust, other |
| qa | Test tool? | playwright, cypress, pytest, k6, other |

#### Scenario: cli stack stored
- **WHEN** user selects `cli` and answers `go`
- **THEN** `.project/config.yaml` contains `project_type: cli` and `stack: go`

### Requirement: Extended project types select doc scaffold files
When the docs scaffold runs, the skill SHALL create these files: `library`, `ai`, `cli`, `qa` → prd.md, architecture.md, tools.md; `bi` → prd.md, architecture.md, database.md, tools.md. No new doc file types are introduced.

#### Scenario: Library scaffold
- **WHEN** docs scaffold runs with `project_type: library`
- **THEN** prd.md, architecture.md, and tools.md are created and database.md, api.md are not

#### Scenario: bi scaffold includes database.md
- **WHEN** docs scaffold runs with `project_type: bi`
- **THEN** database.md is created alongside prd.md, architecture.md, and tools.md

### Requirement: Extended project types bootstrap supplementary labels
At init label bootstrap the skill SHALL create: `library` → semver, breaking-change, deprecation, docs-gap; `ai` → prompt, eval, model, guardrail, cost, latency; `bi` → metric-definition, data-quality, dashboard, source; `cli` → breaking-change, ux, flags, exit-codes, completion, packaging, cross-platform; `qa` → flaky, coverage-gap, regression, test-data, env.

#### Scenario: qa labels created
- **WHEN** init completes with `project_type: qa` on a provider supporting label creation
- **THEN** labels `flaky`, `coverage-gap`, `regression`, `test-data`, `env` are created
