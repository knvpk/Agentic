## ADDED Requirements

### Requirement: Evidence has four kinds with a default per project type
The skill SHALL support exactly four evidence kinds: `image` (inline screenshot), `link` (URL to a report or run), `markdown` (block pasted into the PR body), and `text` (fenced transcript). When `ship.evidence.kinds` is absent, the default kind SHALL come from `project_type`: `web`, `mobile`, `bi` → `image`; `qa` → `link`; `api` → `markdown`; `cli`, `library`, `ai`, `microservices`, `generic` → `text`.

#### Scenario: Web project defaults to image evidence
- **WHEN** `ship` runs on a project with `project_type: web` and no `ship.evidence.kinds`
- **THEN** the evidence plan lists `image` as the evidence kind

#### Scenario: qa project defaults to link evidence
- **WHEN** `ship` runs on a project with `project_type: qa` and no `ship.evidence.kinds`
- **THEN** the evidence plan lists `link` as the evidence kind

#### Scenario: Absent project_type behaves as generic
- **WHEN** `.project/config.yaml` has no `project_type`
- **THEN** the evidence plan lists `text` as the evidence kind

### Requirement: ship.evidence config is explicit, optional, and overrides detection
`.project/config.yaml` MAY contain `ship.evidence` with keys `kinds` (array of kind names), `image` (`start_command`, `base_url`, `viewports`), `link` (`report_url`), `markdown` (`spec_path`), and `extra` (array of strings). Every key SHALL be optional. When `kinds` is present it SHALL be the complete list of kinds and SHALL replace the project-type default. Any per-kind key present SHALL take precedence over the corresponding detected value.

#### Scenario: kinds replaces the type default
- **WHEN** `project_type: web` and `ship.evidence.kinds: [image, markdown]`
- **THEN** the evidence plan lists exactly `image` and `markdown`

#### Scenario: Zero config works
- **WHEN** `ship.evidence` is absent entirely
- **THEN** `ship` uses the project-type default kind and detection, and does not fail

#### Scenario: Config value wins over detection
- **WHEN** `ship.evidence.markdown.spec_path` is set and a different OpenAPI file is also auto-detectable
- **THEN** the configured path is used

#### Scenario: Unknown evidence key is rejected by the schema
- **WHEN** `ship.evidence` contains a key not listed above
- **THEN** schema validation fails with an unknown-property error

### Requirement: Detection runs at ship time and is shown at confirmation
When a needed override key is absent, `ship` SHALL detect the value from the repository at ship time and SHALL display the resolved evidence plan (kinds, detected tool, spec path, report source) in the Step 4 confirmation. The skill SHALL NOT write detected values back to `.project/config.yaml`.

#### Scenario: Evidence plan appears in confirmation
- **WHEN** `ship` reaches Step 4 on a web project
- **THEN** the confirmation output includes the evidence kinds and the resolved start command and base URL

#### Scenario: Detected values are not persisted
- **WHEN** `ship` completes after detecting a Playwright config
- **THEN** `.project/config.yaml` is unchanged

### Requirement: qa detection identifies the test tool and report source from repo files
For `qa` evidence the skill SHALL detect the test tool from `playwright.config.*` reporters or `@playwright/test`, from `allure-results/`, `--alluredir`, or allure plugins in dependencies, and the report source from CI configuration (`.github/workflows/*`, `.gitlab-ci.yml`) steps such as `upload-artifact`, `deploy-pages`, or `allure generate`.

#### Scenario: Allure with Pages deployment detected
- **WHEN** the repo has allure dependencies and a workflow with a `deploy-pages` step
- **THEN** the detected report source is the published Pages report

#### Scenario: No tool detected
- **WHEN** none of the signals are found
- **THEN** the evidence section states `No evidence captured: test tool not detected`

### Requirement: qa link degrades to the CI runs page without editing the PR later
For `link` evidence the skill SHALL use a published report URL when one can be resolved at ship time; otherwise it SHALL use the branch's CI runs page labelled `CI run (report published on completion)`. The skill SHALL NOT edit the PR body after creation to add a report link.

#### Scenario: Report not yet published
- **WHEN** `ship` creates a GitHub PR on a qa project and CI has not produced a report
- **THEN** the Evidence section links the branch's Actions runs page with the label `CI run (report published on completion)`

#### Scenario: GitLab has no qa link in this change
- **WHEN** `ship` creates a GitLab merge request on a qa project
- **THEN** the Evidence section states `No evidence captured: link evidence is GitHub-only`

### Requirement: api evidence is derived from the OpenAPI spec diff
For `markdown` evidence on an API project the skill SHALL diff the detected OpenAPI spec (`openapi.{yaml,yml,json}`, `docs/openapi*`, `swagger.*`, or `ship.evidence.markdown.spec_path`) between `base_branch` and `HEAD` and render each added or changed operation as markdown containing method and path, parameters, request body, and response. If the changed paths include source files but the spec file is unchanged, the section SHALL read `spec unchanged`.

#### Scenario: New endpoint rendered
- **WHEN** the spec diff adds `POST /orders` with a request body and a 201 response
- **THEN** the Evidence section contains a block with `POST /orders`, its parameters, request body schema, and 201 response schema

#### Scenario: Code changed but spec did not
- **WHEN** source files changed and the OpenAPI file has no diff
- **THEN** the Evidence section states `spec unchanged`

#### Scenario: No spec found
- **WHEN** no OpenAPI spec is detectable and `spec_path` is unset
- **THEN** the Evidence section states `No evidence captured: OpenAPI spec not found`

### Requirement: web evidence images are hosted on an orphan branch for GitHub
For `image` evidence on GitHub the skill SHALL commit images to an orphan branch named `pr-evidence` and reference them from the PR body by `blob/{sha}/{path}?raw=true` URLs. Images SHALL NOT be committed to the feature branch. On GitLab, image evidence is out of scope and the section SHALL state so.

#### Scenario: Images linked from orphan branch
- **WHEN** screenshots exist for a web PR on GitHub
- **THEN** the PR body references each image via a `pr-evidence` branch `blob/{sha}/…?raw=true` URL and the feature branch contains no image files from evidence

#### Scenario: Capture cannot run
- **WHEN** the dev server fails to start
- **THEN** the Evidence section reads `No evidence captured: {reason}` and `ship` still completes

### Requirement: cli, library, ai, and generic evidence is a text transcript
For `text` evidence the skill SHALL include a fenced transcript of the relevant commands and their output (CLI invocations with exit codes, test run output, or sample inputs and outputs for `ai`).

#### Scenario: CLI transcript includes exit code
- **WHEN** `ship` produces text evidence for a cli project
- **THEN** each transcript entry shows the command, its output, and its exit code

### Requirement: extra strings are appended verbatim to the Evidence section
Each string in `ship.evidence.extra` SHALL be appended to the PR's Evidence section as written, after generated content, unconditionally.

#### Scenario: extra appended
- **WHEN** `ship.evidence.extra: ["Rollback plan: revert PR"]`
- **THEN** the Evidence section ends with `Rollback plan: revert PR`

### Requirement: Missing evidence is always explained
When no evidence is produced for any reason, the Evidence section SHALL be present and SHALL read `No evidence captured: {reason}`. `ship` SHALL NOT block on missing evidence.

#### Scenario: Refactor with no visible change
- **WHEN** a web ticket has no UI change and capture produces no images
- **THEN** the PR still opens with `No evidence captured: no UI change detected`
