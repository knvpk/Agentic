## Purpose
Defines how the skill detects, stores, and applies project type classification at init time, driving conditional behaviour for doc scaffolding, label bootstrap, and ticket content generation.

## Requirements

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

### Requirement: Skill asks a stack clarification question conditional on project type
After the project type answer, the skill SHALL ask a single stack clarification question whose options depend on the selected type.

| project_type | Clarification question | Options |
|---|---|---|
| mobile | Cross-platform or native? | React Native, Flutter, Native (iOS/Android), Other |
| web | Framework? | Next.js / Nuxt / Remix, Vite SPA, Other |
| api | Protocol? | REST, GraphQL, gRPC, Mixed |
| microservices | Monorepo or separate repos per service? | Separate repos (recommended), Monorepo |
| generic | (no clarification question) | — |

The answer SHALL be stored as `stack` in `.project/config.yaml`.

#### Scenario: Stack question is skipped for generic type
- **WHEN** user selects "generic" as project type
- **THEN** skill proceeds directly to capability probe without asking a stack question

#### Scenario: Stack answer stored in config
- **WHEN** user selects "mobile" type and "React Native" stack
- **THEN** `.project/config.yaml` contains `project_type: mobile` and `stack: react-native`

### Requirement: project_type drives doc scaffold file selection at docs creation time
When the docs scaffold runs, the skill SHALL select which doc files to create based on `project_type` from config.

| project_type | Files created |
|---|---|
| mobile | prd.md, architecture.md, local-storage.md, tools.md |
| web | prd.md, architecture.md, database.md, tools.md |
| api | prd.md, architecture.md, database.md, tools.md, api.md |
| microservices | architecture.md, services.md, tools.md |
| generic | prd.md, architecture.md, database.md, tools.md |

#### Scenario: Mobile project skips database.md and creates local-storage.md
- **WHEN** docs scaffold runs and `project_type: mobile`
- **THEN** skill creates `docs/local-storage.md` instead of `docs/database.md`
- **AND** `docs/database.md` is NOT created

#### Scenario: API project creates api.md in addition to core files
- **WHEN** docs scaffold runs and `project_type: api`
- **THEN** skill creates `docs/api.md` alongside prd.md, architecture.md, database.md, tools.md

#### Scenario: Microservices project skips prd.md and creates services.md
- **WHEN** docs scaffold runs and `project_type: microservices`
- **THEN** skill creates `docs/services.md` and does NOT create `docs/prd.md`

### Requirement: project_type drives type-specific supplementary label bootstrap at init
At init Step 7 (state label bootstrap), the skill SHALL also create a type-specific supplementary label set alongside the canonical state labels.

| project_type | Supplementary labels created |
|---|---|
| mobile | platform:ios, platform:android, platform:shared, crash, a11y, store-review-blocker |
| web | seo, performance, a11y, responsive, pwa, breaking |
| api | breaking-change, contract-change, deprecation, versioning, consumer-impact |
| microservices | cross-cutting, contract-change, migration |
| generic | (none) |

#### Scenario: Mobile project bootstraps platform labels at init
- **WHEN** init completes with `project_type: mobile` on a GitHub-backed project
- **THEN** labels `platform:ios`, `platform:android`, `platform:shared`, `crash`, `a11y`, `store-review-blocker` are created in GitHub

#### Scenario: API project bootstraps breaking-change label at init
- **WHEN** init completes with `project_type: api`
- **THEN** label `breaking-change` is created alongside the canonical state labels

#### Scenario: Generic project bootstraps no supplementary labels
- **WHEN** init completes with `project_type: generic`
- **THEN** only the canonical state labels are created; no supplementary labels are added

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
