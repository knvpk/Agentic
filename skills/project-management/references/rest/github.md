# GitHub REST API Reference

## Auth

| Field | Value |
|-------|-------|
| Token env | `GITHUB_TOKEN` |
| Auth header | `Authorization: Bearer {token}` |
| Base URL | `https://api.github.com` |
| Required headers | `Accept: application/vnd.github+json` · `X-GitHub-Api-Version: 2022-11-28` |

## Operations

| Operation | Method | Path |
|-----------|--------|------|
| ping / verify token | GET | `/user` |
| get_issue | GET | `/repos/{owner}/{repo}/issues/{number}` |
| list_issues | GET | `/repos/{owner}/{repo}/issues` |
| create_issue | POST | `/repos/{owner}/{repo}/issues` |
| update_issue | PATCH | `/repos/{owner}/{repo}/issues/{number}` |
| list_labels | GET | `/repos/{owner}/{repo}/labels` |
| create_label | POST | `/repos/{owner}/{repo}/labels` |
| add_labels | POST | `/repos/{owner}/{repo}/issues/{number}/labels` |
| list_milestones | GET | `/repos/{owner}/{repo}/milestones` |
| create_milestone | POST | `/repos/{owner}/{repo}/milestones` |

`{owner}` and `{repo}` are parsed from the git remote URL at init and stored in `.project/config.yaml`.

## Docs

- API reference: https://docs.github.com/en/rest
- OpenAPI spec: https://github.com/github/rest-api-description

If a path returns an unexpected 404 or auth error, consult the API reference above to verify the current path before retrying.
