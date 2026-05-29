## ADDED Requirements

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
