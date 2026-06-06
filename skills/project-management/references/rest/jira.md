# Jira REST API Reference

## Auth

| Field | Value |
|-------|-------|
| Email env | `JIRA_EMAIL` |
| Token env | `JIRA_TOKEN` |
| Auth header | `Authorization: Basic {base64(email:token)}` |
| Base URL | `{host}/rest/api/3` |
| Host env | `JIRA_URL` (e.g. `https://yourcompany.atlassian.net`) |

**Generate base64 value**: `echo -n "{email}:{token}" | base64`

Example: `echo -n "user@company.com:ATATT3x..." | base64`

## Operations

| Operation | Method | Path |
|-----------|--------|------|
| ping / verify token | GET | `/rest/api/3/myself` |
| get_issue | GET | `/rest/api/3/issue/{issueIdOrKey}` |
| search_issues | GET | `/rest/api/3/search?jql={jql}` |
| create_issue | POST | `/rest/api/3/issue` |
| update_issue | PUT | `/rest/api/3/issue/{issueIdOrKey}` |
| get_fields | GET | `/rest/api/3/field` |
| list_boards | GET | `/rest/agile/1.0/board` |
| list_sprints | GET | `/rest/agile/1.0/board/{boardId}/sprint` |
| create_sprint | POST | `/rest/agile/1.0/sprint` |
| list_versions | GET | `/rest/api/3/project/{projectIdOrKey}/versions` |

Note: sprint operations use the Agile API base (`/rest/agile/1.0`) not the core API base.

## Docs

- Core API reference: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
- Agile API reference: https://developer.atlassian.com/cloud/jira/software/rest/
- OpenAPI spec: https://dac-static.atlassian.com/cloud/jira/platform/swagger-v3.v3.json

If a path returns an unexpected 404 or auth error, consult the API reference above to verify the current path before retrying.
