# GitLab REST API Reference

## Auth

| Field | Value |
|-------|-------|
| Token env | `GITLAB_TOKEN` |
| Auth header | `PRIVATE-TOKEN: {token}` |
| Base URL | `{host}/api/v4` (default host: `https://gitlab.com`) |
| Host env | `GITLAB_URL` (set for self-hosted instances) |

## Operations

| Operation | Method | Path |
|-----------|--------|------|
| ping / verify token | GET | `/api/v4/user` |
| get_issue | GET | `/api/v4/projects/{id}/issues/{iid}` |
| list_issues | GET | `/api/v4/projects/{id}/issues` |
| create_issue | POST | `/api/v4/projects/{id}/issues` |
| update_issue | PUT | `/api/v4/projects/{id}/issues/{iid}` |
| list_labels | GET | `/api/v4/projects/{id}/labels` |
| create_label | POST | `/api/v4/projects/{id}/labels` |
| get_project | GET | `/api/v4/projects/{url-encoded-path}` |
| create_project | POST | `/api/v4/projects` |
| list_iterations | GET | `/api/v4/groups/{group_id}/iterations` |
| list_milestones | GET | `/api/v4/projects/{id}/milestones` |
| create_milestone | POST | `/api/v4/projects/{id}/milestones` |
| create_note | POST | `/api/v4/projects/{id}/issues/{iid}/notes` |

**Important**: `{id}` is the **numeric project ID** stored as `gitlab_project_id` in `.project/config.yaml` — not the URL-encoded project path. `{iid}` is the project-scoped issue number (not the global issue ID).

## Docs

- API reference: https://docs.gitlab.com/ee/api/rest/
- OpenAPI spec: https://gitlab.com/gitlab-org/gitlab/-/raw/master/doc/api/openapi/openapi.yaml

If a path returns an unexpected 404 or auth error, consult the API reference above to verify the current path before retrying.
