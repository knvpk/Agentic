## Purpose
Defines how the skill probes and caches provider capability flags at init time, handles mid-session capability failures, and communicates fallback strategies to the user.

## Requirements

### Requirement: Skill probes provider capabilities via two-signal detection at init
At init, the skill SHALL use two signals to determine capability support: (1) whether the MCP tool exists (ToolSearch), and (2) whether a safe read call to that tool returns 200 or 403.

#### Scenario: ToolSearch miss triggers user prompt
- **WHEN** `ToolSearch("mcp__plane__list_modules")` returns no results
- **THEN** the skill cannot probe and asks the user whether epics are supported on their plan

#### Scenario: 200 response marks capability as supported
- **WHEN** `mcp__plane__list_cycles` is called and returns 200
- **THEN** `capabilities.sprints` is set to `true` in `.project/config.yaml`

#### Scenario: 403 response marks capability as unsupported
- **WHEN** `mcp__plane__list_modules` is called and returns 403
- **THEN** `capabilities.epics` is set to `false` in `.project/config.yaml`
- **AND** the fallback strategy from `providers.json` is activated for epics

### Requirement: Capability results are cached in .project/config.yaml after init
The skill SHALL write probed capability flags to `.project/config.yaml` under `provider.capabilities` with a `probed_at` timestamp.

#### Scenario: Subsequent invocations read from cache
- **WHEN** `.project/config.yaml` exists with a recent `probed_at`
- **THEN** the skill reads capabilities from cache without re-probing

#### Scenario: Cache contains probed_at timestamp
- **WHEN** init completes successfully
- **THEN** `.project/config.yaml` contains `provider.capabilities.probed_at` as an ISO-8601 datetime

### Requirement: Unexpected 403 mid-session triggers lazy re-probe for that feature
If a provider call returns 403 unexpectedly during normal operation, the skill SHALL re-probe that specific capability, update the cache, and retry the operation using the fallback strategy.

#### Scenario: Mid-session epic creation 403 triggers label fallback
- **WHEN** a ticket creation with `parent_id` returns 403 after init declared epics supported
- **THEN** the skill re-probes epics, updates `config.yaml` to `false`, and retries using the label fallback
- **AND** notifies the user: "Epic support not available, switched to label fallback"

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

### Requirement: User is always notified when a fallback strategy is active
The skill SHALL explicitly tell the user which fallback is in use whenever a capability gap is detected or activated.

#### Scenario: Label fallback notification on epic creation
- **WHEN** epics capability is false and user creates a parent ticket
- **THEN** skill outputs: "Plane free plan detected — using label `epic:{slug}` to simulate epic membership"

#### Scenario: init --probe forces re-detection ignoring cache
- **WHEN** user runs `/project-management init --probe`
- **THEN** the skill re-runs all capability probes and overwrites `.project/config.yaml`

### Requirement: GitLab edition is detected at init via iterations API probe
When the provider is GitLab, the skill SHALL probe the group-level iterations endpoint during init Step 4 to determine the GitLab edition. A 200 response indicates EE Premium or Ultimate (native iterations available). A 403 or 404 response indicates Community Edition (CE). The result SHALL be stored as `gitlab_edition` in `.project/config.yaml` and SHALL determine which `plan_variants` entry is active.

#### Scenario: 200 from iterations probe sets edition to ee-premium
- **WHEN** `mcp__gitlab__list_iterations` (or equivalent) returns 200 during init
- **THEN** `gitlab_edition: ee-premium` is written to `.project/config.yaml`
- **AND** `sprint_proxy: iteration` is set for the project

#### Scenario: 404 from iterations probe sets edition to ce
- **WHEN** `mcp__gitlab__list_iterations` returns 404 during init
- **THEN** `gitlab_edition: ce` is written to `.project/config.yaml`
- **AND** `sprint_proxy: label` and `sprint_label_scope: sprint` are set for the project

#### Scenario: 403 from iterations probe also sets edition to ce
- **WHEN** `mcp__gitlab__list_iterations` returns 403 during init
- **THEN** `gitlab_edition: ce` is written to `.project/config.yaml`
- **AND** `sprint_proxy: label` is set — CE treats 403 the same as 404 for this probe

#### Scenario: Iterations tool absent triggers user prompt
- **WHEN** `ToolSearch("mcp__gitlab__list_iterations")` returns no results during init
- **THEN** skill asks `"Could not detect GitLab edition. Is your instance EE Premium or Ultimate? [y/n]"`
- **AND** sets `gitlab_edition: ee-premium` or `gitlab_edition: ce` based on the answer

### Requirement: GitLab group is detected from git remote at init
When the provider is GitLab, the skill SHALL extract the GitLab group path from the git remote URL during init. The group path SHALL be stored as `gitlab_group` in `.project/config.yaml` and used for group-level label creation and pm-meta project placement.

#### Scenario: Group path extracted from HTTPS remote
- **WHEN** `git remote get-url origin` returns `https://gitlab.example.com/mygroup/my-repo.git`
- **THEN** `gitlab_group: mygroup` is stored in config

#### Scenario: Group path extracted from SSH remote
- **WHEN** `git remote get-url origin` returns `git@gitlab.example.com:mygroup/my-repo.git`
- **THEN** `gitlab_group: mygroup` is stored in config

#### Scenario: No group detected prompts user input
- **WHEN** the remote URL cannot be parsed for a group path (e.g. root-level project)
- **THEN** skill asks `"Enter your GitLab group path (e.g. mycompany):"` and stores the answer
