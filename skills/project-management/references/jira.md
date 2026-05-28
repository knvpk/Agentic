# Jira Provider Reference

## MCP Server

**Docs**: https://support.atlassian.com/atlassian-rovo-mcp-server/docs/getting-started-with-the-atlassian-remote-mcp-server/
**Official endpoint**: `https://mcp.atlassian.com/v1/mcp/authv2`
**Deprecated endpoint**: `https://mcp.atlassian.com/v1/sse` (removed after 2026-06-30)

**Setup — OAuth (recommended):**
```bash
claude mcp add jira --scope project --transport http https://mcp.atlassian.com/v1/mcp/authv2
# Then type /mcp in Claude to complete OAuth 2.1 browser flow
```

**Setup — API token:**
```bash
# Generate base64: echo -n "email@company.com:YOUR_API_TOKEN" | base64
claude mcp add jira --scope project --transport http https://mcp.atlassian.com/v1/mcp/authv2 \
  --header "Authorization=Basic BASE64_STRING"
# API token: https://id.atlassian.com/manage-profile/security/api-tokens
```

## Plan Variants

| Feature | Jira Core | Jira Software |
|---------|-----------|---------------|
| Epics | ✗ | ✓ (Epic issue type) |
| Sprints | ✗ | ✓ (requires board) |
| blocks relation | ✓ | ✓ |
| relates-to | ✓ | ✓ |
| Sub-tasks | ✓ | ✓ |
| Custom workflow | ✓ | ✓ |

The skill probes `list_boards` at init. If it returns results → Jira Software (sprints/epics available).

## Sprint Model

Sprints in Jira require a **Software board**. The skill probes and caches `board_id` in `.project/config.yaml`.

```
Init:    GET /agile/1.0/board  → present selection → store board_id in config
Create:  POST /agile/1.0/sprint  { originBoardId, name, startDate, endDate }
Add:     POST /agile/1.0/sprint/{id}/issue  { issues: ["PROJ-42"] }
Status:  GET /agile/1.0/sprint/{id}/issue
```

## Epic Model

Epics are a separate issue type. Parent-child link uses `customfield_10014` (Epic Link) or `parent` field depending on Jira version.

## State Transitions

Jira uses workflow transitions by name. Default Software workflow:

```
canonical       Jira transition
────────────    ───────────────
backlog         (initial state, no transition needed)
todo            To Do
in-progress     In Progress
in-review       In Review
done            Done
blocked         label 'blocked' only — no standard Jira transition
```

The skill calls `GET /issue/{id}/transitions` to get valid transition IDs before applying.

> **Note on `blocked` state**: Jira does not include a "Blocked" workflow status in any default project template. The skill adds a `blocked` label to the issue and leaves its workflow state unchanged. If your team has added a custom "Blocked" status to your workflow, you can manually transition the issue to it — the skill will not attempt this transition automatically because it is not universally available.

## Relationship Types

Native Jira link types:
- `Blocks` / `is blocked by`
- `Relates` (bidirectional)
- `Clones` / `is cloned by`
- `Duplicates` / `is duplicated by`

Endpoint: `POST /rest/api/2/issueLink`

## Labels

Jira labels are free-text strings on issues — no separate label objects to create. Add by updating the `labels` field on an issue.

## Setup Checklist

1. Add Jira MCP server with `JIRA_TOKEN`, `JIRA_BASE_URL`, `JIRA_USER_EMAIL`
2. Run `/project-management init`
3. Init will probe boards, ask you to select one if on Jira Software
4. Init will probe sprint/epic availability and cache results
