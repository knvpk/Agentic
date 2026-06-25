# Plane REST API Reference

## Auth

| Field | Value |
|-------|-------|
| Token env | `PLANE_TOKEN` |
| Auth header | `X-API-Key: {token}` |
| Base URL | `https://api.plane.so/api/v1` (self-hosted: `{host}/api/v1`) |
| Host env | `PLANE_URL` (set for self-hosted instances) |

## Required Context Variables

| Variable | Description |
|----------|-------------|
| `PLANE_WORKSPACE_SLUG` | Workspace slug visible in URL: `app.plane.so/{slug}` |
| `PLANE_PROJECT_ID` | Project ID — stored in `.project/config.yaml` as `plane_project_id` |

Both appear in every issue/label/cycle/module path.

## Operations

| Operation | Method | Path |
|-----------|--------|------|
| ping / verify token | GET | `/api/v1/workspaces/` |
| list_issues | GET | `/api/v1/workspaces/{slug}/projects/{project_id}/issues/` |
| get_issue | GET | `/api/v1/workspaces/{slug}/projects/{project_id}/issues/{issue_id}/` |
| create_issue | POST | `/api/v1/workspaces/{slug}/projects/{project_id}/issues/` |
| update_issue | PATCH | `/api/v1/workspaces/{slug}/projects/{project_id}/issues/{issue_id}/` |
| list_labels | GET | `/api/v1/workspaces/{slug}/projects/{project_id}/labels/` |
| create_label | POST | `/api/v1/workspaces/{slug}/projects/{project_id}/labels/` |
| list_cycles | GET | `/api/v1/workspaces/{slug}/projects/{project_id}/cycles/` |
| create_cycle | POST | `/api/v1/workspaces/{slug}/projects/{project_id}/cycles/` |
| list_modules | GET | `/api/v1/workspaces/{slug}/projects/{project_id}/modules/` |
| list_states | GET | `/api/v1/workspaces/{slug}/projects/{project_id}/states/` |

## State UUID Resolution

The `state` field in `PATCH .../issues/{issue_id}/` accepts a **UUID**, not a state name.
Resolve state names to UUIDs at init by calling `list_states` and caching the result
in `.project/config.yaml` as `plane_state_ids` (canonical → UUID map).

## Docs

- API reference: https://developers.plane.so/api-reference/

If a path returns an unexpected 404 or auth error, consult the API reference above to verify the current path before retrying.
