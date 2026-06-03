## Why

The GitLab MCP server does not expose an `update_issue` tool, which the PM skill relies on for all writes to existing issues — state transitions, label changes (used to simulate status), sprint assignment, and milestone assignment. This breaks GitLab state management entirely for all connected users.

## What Changes

- Add a 3-path fallback chain for GitLab issue writes: MCP tool → `glab` CLI → REST API (curl)
- Update `providers.json` to declare `update_ticket` and `add_label` fallback strategies for GitLab
- Update SKILL.md ticket → update flow to probe for available write tools at transition time and route accordingly
- Store numeric project ID in `.project/config.yaml` at init time (needed for REST fallback)

## Capabilities

### New Capabilities

- `gitlab-write-fallback`: Fallback chain for GitLab issue mutations (state, labels, milestone) when MCP `update_issue` is unavailable

### Modified Capabilities

- `provider-adapter`: GitLab tool contracts for `update_ticket` and `add_label` gain fallback declarations
- `ticket-management`: State transition and label logic gains write-path resolution that walks the fallback chain

## Impact

- `skills/project-management/SKILL.md` — ticket → update, sprint add/remove, milestone assign sections
- `skills/project-management/references/providers.json` — GitLab `tool_contracts` and new `write_fallbacks` block
- `skills/project-management/references/gitlab.md` — document the fallback chain and `glab` requirement
- `.project/config.yaml` — new optional field `gitlab_project_id` (numeric) stored at init
