## 1. providers.json — GitLab write_fallbacks

- [x] 1.1 Add `write_fallbacks` array to GitLab entry in `skills/project-management/references/providers.json` with ordered entries: mcp (`update_issue`), cli (`glab issue update`), rest (PUT `/api/v4/projects/{gitlab_project_id}/issues/{iid}`)
- [x] 1.2 Verify GitHub, Jira, and Plane entries do NOT gain `write_fallbacks` (they have working update tools)

## 2. Init — capture numeric project ID

- [x] 2.1 In SKILL.md init flow (after Step 3/provider confirmed), add a step that calls `mcp__gitlab__get_project` and stores the numeric `id` as `gitlab_project_id` in `.project/config.yaml`
- [x] 2.2 Add `gitlab_project_id` as an optional integer field to `references/config.schema.json`
- [x] 2.3 In SKILL.md ticket → update flow, add a lazy-fetch guard: if `gitlab_project_id` is absent from config and provider is gitlab, fetch and store it before proceeding with write

## 3. SKILL.md — write path resolution function

- [x] 3.1 Add a "GitLab Write Path Resolution" section to SKILL.md that defines the fallback chain logic: ToolSearch probe for `mcp__gitlab__update_issue` → check glab via `which glab` → fall back to REST
- [x] 3.2 Define the label-delta helper in SKILL.md: fetch current labels via `get_issue`, identify state label to remove (any label matching a `state_mapping` value), then call the resolved write path with `add_labels` and `remove_labels`

## 4. SKILL.md — ticket → update integration

- [x] 4.1 Replace direct `mcp__gitlab__update_issue` call in ticket → update (state change) with the write path resolution + label-delta helper
- [x] 4.2 Replace direct `mcp__gitlab__update_issue` call in sprint add/remove (`sprint_proxy == "label"`) with the write path resolution
- [x] 4.3 Replace direct `mcp__gitlab__update_issue` call in milestone assign (`milestone_contracts.assign`) with the write path resolution

## 5. SKILL.md — user-facing notices

- [x] 5.1 Emit a one-line notice when falling back to glab: `"Using glab CLI for GitLab write (MCP update_issue not available)"`
- [x] 5.2 Emit a one-line notice when falling back to REST: `"Using REST API for GitLab write (MCP update_issue not available)"`
- [x] 5.3 Emit a clear error listing all three options when all paths are unavailable

## 6. references/gitlab.md — documentation

- [x] 6.1 Add a "Write Fallback Chain" section documenting the 3-path order and what triggers each
- [x] 6.2 Document `glab` as an optional dependency with install link (`brew install glab` / package manager)
- [x] 6.3 Document `GITLAB_URL` env var requirement for REST fallback on self-hosted instances
