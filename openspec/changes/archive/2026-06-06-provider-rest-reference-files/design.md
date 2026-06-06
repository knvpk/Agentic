## Context

With REST as the primary operation path, Claude constructs API calls at runtime using `rest_config` from `providers.json` (base URL, auth header). The path segment — e.g. `/repos/{owner}/{repo}/issues/{number}` — is not declared anywhere. Claude must infer it from training data, which may be outdated or wrong.

The goal is a lightweight anchor: a file per provider that lists the exact path patterns for the ~10–15 operations the skill uses, plus a docs URL to recover from any mismatch. No full request/response shapes, no OpenAPI embedding.

## Goals / Non-Goals

**Goals:**
- One reference file per provider in `references/rest/`
- Each file: auth format reminder, base URL, operation table (name → path pattern), docs/OpenAPI link
- SKILL.md tells Claude to read the relevant file before any REST call
- If a path returns unexpected 404/401, Claude consults the docs link — no skill release needed

**Non-Goals:**
- Full request body schemas (too verbose, go stale)
- Response field documentation (only what's needed for parsing is noted inline in SKILL.md)
- Downloading or embedding OpenAPI specs
- Covering API surface beyond what the skill actually calls

## Decisions

### D1 — Operation table format: name + path pattern only

Each operation listed as:
```
| create_issue    | POST   /repos/{owner}/{repo}/issues             |
| update_issue    | PATCH  /repos/{owner}/{repo}/issues/{number}    |
```

No body params, no response shapes. The operation name maps directly to `tool_contracts` in `providers.json`, making the table a cross-reference between the REST path and the MCP fallback.

**Rationale**: Body params are stable enough to infer (title, state, labels) and are documented at the linked URL. Path patterns are what drifts and causes 404s — that's the specific problem being solved.

### D2 — Docs URL is the recovery mechanism, not a fallback path list

Each file includes one `docs` URL (the official REST API reference) and optionally an `openapi_spec` URL where a machine-readable spec is available. When a path returns 404, Claude visits the docs URL to find the current path.

**Rationale**: Maintaining a secondary path list in the skill would just create two things to go stale instead of one. The docs URL is always canonical.

### D3 — SKILL.md instruction: read reference file before first REST call per session

Add to the REST dispatch section: "Before constructing any REST call, read `references/rest/{provider}.md`. If a call returns 404 or an unexpected auth error, consult the `docs` link in that file to verify the current path before retrying."

**Rationale**: Keeps the reference files actually used rather than dormant. One-time read per session is low overhead.

### D4 — Operations covered per provider

Derived from `tool_contracts` in `providers.json` and the init/write flows in SKILL.md:

**GitHub** (10): get_issue, list_issues, create_issue, update_issue, add_labels, list_labels, create_label, create_milestone, list_milestones, get_user (ping)

**GitLab** (13): get_issue, list_issues, create_issue, update_issue, list_labels, create_label, get_project, create_project, list_iterations, list_milestones, create_milestone, create_note, get_user (ping)

**Jira** (10): get_issue, search_issues, create_issue, update_issue, get_fields, list_boards, list_sprints, create_sprint, list_versions, get_myself (ping)

**Plane** (9): list_issues, get_issue, create_issue, update_issue, list_labels, create_label, list_cycles, create_cycle, list_modules (ping via list_issues)
