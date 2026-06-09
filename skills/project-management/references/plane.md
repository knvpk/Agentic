# Plane Provider Reference

## MCP Server

**Docs**: https://developers.plane.so/dev-tools/mcp-server
**Cloud endpoint**: `https://mcp.plane.so/http/api-key/mcp`  ← URL is fixed; `api-key` is a literal path segment
**Self-hosted**: `{instance_url}/http/api-key/mcp`
**Transport**: HTTP (no local process needed)

Auth is via `x-api-key` header — the API key is NOT embedded in the URL path.

**Claude Code setup:**
```bash
claude mcp add plane --scope project --transport http https://mcp.plane.so/http/api-key/mcp \
  --header "x-api-key=YOUR_PLANE_API_KEY"
```

**Self-hosted:**
```bash
claude mcp add plane --scope project --transport http https://plane.company.com/http/api-key/mcp \
  --header "x-api-key=YOUR_PLANE_API_KEY"
```

**API key**: Plane workspace → Settings → API Tokens
**Required env**: `PLANE_WORKSPACE_SLUG` (from app.plane.so/{slug})
**Optional**: `PLANE_PROJECT_ID` (can be set per-project in .project/config.yaml)

## Plan Variants

| Feature | Free | Pro / Business |
|---------|------|----------------|
| Cycles (sprints) | ✓ (1 active at a time) | ✓ (unlimited active) |
| Modules | ✓ | ✓ |
| Epics (work item type) | ✗ | ✓ |
| Blocking relations | ✓ | ✓ |
| relates-to | ✓ | ✓ |
| Sub-issues | ✓ | ✓ |
| Custom states | ✓ | ✓ |

The skill probes `list_modules` at init. If it returns 200 → Modules available (all plans). The skill separately probes for the Epic work item type (Pro-only); if unavailable, label fallback is activated. On free plan, `active_cycles_limit: 1` is stored in config.

## Sprint Model (Cycles)

Plane calls sprints **Cycles**. They have start/end dates and explicit issue membership.

```
Create:   POST /api/v1/workspaces/{slug}/projects/{id}/cycles/
Add:      POST /api/v1/workspaces/{slug}/projects/{id}/cycles/{cycle_id}/cycle-issues/
Remove:   DELETE cycle-issues endpoint
Status:   GET  /api/v1/workspaces/{slug}/projects/{id}/cycles/{id}/cycle-issues/
```

## Epic Model (Modules)

Plane calls epics **Modules** (available on Pro+). Issues are linked to modules.

```
Create:   POST /api/v1/workspaces/{slug}/projects/{id}/modules/
Add:      POST /api/v1/workspaces/{slug}/projects/{id}/modules/{module_id}/module-issues/
```

**Free plan fallback**: label `epic:{slug}` applied to all child issues.

## State Model

Plane has fully custom states per project. The skill maps canonical states to Plane state names at init.

Default Plane states (may vary):
```
canonical       Plane state name
────────────    ─────────────────
backlog         Backlog
todo            Unstarted
in-progress     In Progress
in-review       In Progress (+ label in-review)
done            Done
blocked         In Progress (+ label blocked)
```

At init, the skill calls `list_states` and builds the mapping from actual state names.

## Relationship Types

Plane native relations: `blocking`, `blocked_by`, `duplicate_of`, `duplicated_by`, `relates_to`

```
Create:   POST /api/v1/workspaces/{slug}/projects/{id}/issues/{issue_id}/issue-relations/
          { relation_type: "blocking", related_issue: "uuid" }
```

## Setup Checklist

1. Add Plane MCP server with `PLANE_API_TOKEN`, `PLANE_WORKSPACE_SLUG`, `PLANE_PROJECT_ID`
2. Run `/project-management init`
3. Init probes `list_modules` → if 403, activates label fallback and notifies you
4. Init maps Plane state names to canonical states
