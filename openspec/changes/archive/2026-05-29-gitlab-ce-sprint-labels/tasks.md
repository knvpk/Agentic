## 1. providers.json — GitLab CE entry

- [x] 1.1 Change `plan_variants.ce.sprint_proxy` from `"milestone"` to `"label"` and add `sprint_label_scope: "sprint"` field
- [x] 1.2 Add `plan_variants.ee-premium` entry with `sprint_proxy: "iteration"` (separate from CE)
- [x] 1.3 Replace `"sprint": "create_milestone"` in GitLab `tool_contracts` with `"sprint": "create_label"` (CE path; EE uses iteration tool)
- [x] 1.4 Replace `fallbacks.sprint` strategy from `"milestone"` to `"label"` with `label_scope: "sprint"` and `meta_issue_in_description: true`
- [x] 1.5 Add `gitlab_extras` block: `edition_probe` (tool name, CE result codes), `sprint_naming_conventions` (four patterns with examples)
- [x] 1.6 Update `milestone_contracts._note` to clarify milestones are release targets only; remove reference to sprint naming

## 2. SKILL.md — init mode (edition detection + CE setup)

- [x] 2.1 Add GitLab-specific branch in init Step 4 API probe: call `list_iterations` on the group; map 200 → `ee-premium`, 403/404 → `ce`; handle tool-absent case with user prompt
- [x] 2.2 Add GitLab group extraction step: parse `git remote get-url origin` for group path; prompt user if not parseable; store `gitlab_group` in config
- [x] 2.3 Add sprint naming convention picker (after edition probe, CE only): present four options with `year-week` default; store `sprint_convention` in config
- [x] 2.4 Add pm-meta project setup step (CE only): check if `{group}/pm-meta` exists via MCP; auto-create if absent; fall back to current project on 403; store `pm_meta_project` in config
- [x] 2.5 Update init Step 5 `.project/config.yaml` schema section: add `gitlab_edition`, `sprint_convention`, `sprint_label_scope`, `pm_meta_project` fields to the documented YAML example
- [x] 2.6 Replace init Step 8 CE sprint notification: change `⚠ Sprints not available — using milestone proxy` to `ℹ GitLab CE — sprints use scoped labels (sprint::*). Convention: {convention}. Metadata: {pm_meta_project_url}.`

## 3. SKILL.md — sprint create sub-mode (label flow)

- [x] 3.1 Add branch at top of `sprint create`: if `config.sprint_proxy == "label"` go to CE label flow, else continue existing milestone path
- [x] 3.2 Write CE label flow steps: derive label name from `sprint_convention` and user-provided date/number; collect start date, end date, goal (optional), capacity (optional)
- [x] 3.3 Write metadata issue creation step: call `mcp__gitlab__create_issue` in `pm_meta_project` with structured title and `<!-- pm:start --> ... <!-- pm:end -->` body block
- [x] 3.4 Write group-level label creation step: call `mcp__gitlab__create_label` at group scope with derived name and metadata issue URL as description
- [x] 3.5 Write active sprint config update: store `active_sprint.label_name` and `active_sprint.meta_issue_url` instead of numeric ID

## 4. SKILL.md — sprint milestone sub-mode (CE guard)

- [x] 4.1 Add CE guard at top of `sprint milestone create`: if `sprint_proxy == "label"` and name matches sprint convention pattern, reject with redirect message
- [x] 4.2 Define the convention-pattern check: match `Sprint \d+`, `\d{4}-W\d{2}`, `\d{4}-\d{2}-W\d`, `Q\d-\d{4}-S\d+` — any match triggers the guard

## 5. SKILL.md — next and status modes (CE label filter)

- [x] 5.1 Update next mode Step 2 ticket fetch: for CE projects, filter `mcp__gitlab__list_issues` by `labels: {active_sprint.label_name}` instead of `milestone: {active_sprint.id}`
- [x] 5.2 Update status mode: same label-based filter substitution for CE active sprint ticket fetch
