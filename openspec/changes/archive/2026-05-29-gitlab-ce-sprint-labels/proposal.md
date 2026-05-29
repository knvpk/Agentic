## Why

The GitLab provider currently routes sprint creation through `create_milestone` for both CE and EE — the same API used for release targets (v1.0, Beta, Q3 Launch). This conflates two semantically distinct concepts: a sprint is a fixed-duration timebox, a milestone is a specific point in time marking a major achievement. On GitLab CE self-hosted, native iterations (sprints) are an EE-only feature, so the skill must use a different mechanism — and it must not pollute milestones to do it.

## What Changes

- GitLab CE sprint creation switches from `create_milestone` to scoped label creation (`sprint::*`), preserving milestones exclusively for release targets
- Init probes the GitLab iteration API to detect CE vs EE edition; CE activates the label-based sprint strategy
- Init presents a sprint naming convention picker (sequential, year-week, year-month-week, quarterly) for GitLab CE projects; choice is stored in config
- Sprint metadata (dates, goal, capacity) is stored in a dedicated GitLab issue in a designated `pm-meta` project; the label description holds the issue URL as a cross-repo-accessible FK
- `sprint create` sub-mode branches on `sprint_proxy`: CE takes the label flow, GitHub/GitLab EE keep the existing milestone path
- `sprint milestone` sub-mode gains a hard guard for GitLab CE: rejects `sprint::*`-style names and redirects to sprint create
- `providers.json` GitLab CE entry updated: `sprint_proxy: label`, adds `sprint_label_scope`, `sprint_naming_conventions`, edition probe config, and label-strategy fallback for sprint
- Active sprint in `.project/config.yaml` for CE stores `label_name` and `meta_issue_url` instead of a milestone ID

## Capabilities

### New Capabilities
- `gitlab-sprint-metadata`: Cross-repo sprint metadata via GitLab issues — the pattern of creating a sprint metadata issue in a designated `pm-meta` project, storing its URL in the scoped label description, and retrieving it via MCP from any repo in the group

### Modified Capabilities
- `sprint-management`: GitLab CE sprint creation uses scoped labels (`sprint::*`) instead of milestones; naming convention selection at create time; milestone guard added for CE
- `capability-detection`: GitLab edition probe (CE vs EE-Premium) via iterations API; CE edition activates label sprint strategy and naming convention prompt

## Impact

- `skills/project-management/SKILL.md`: init mode (edition probe, naming convention, pm-meta prompt), sprint create sub-mode (CE label flow branch), sprint milestone sub-mode (CE guard), init Step 8 notification
- `skills/project-management/references/providers.json`: GitLab CE `sprint_proxy`, `sprint_label_scope`, `sprint_naming_conventions`, edition probe block, fallbacks.sprint label strategy
- `.project/config.yaml` schema: adds `gitlab_edition`, `sprint_convention`, `sprint_label_scope`, `pm_meta_project`, `active_sprint.label_name`, `active_sprint.meta_issue_url` fields for CE
