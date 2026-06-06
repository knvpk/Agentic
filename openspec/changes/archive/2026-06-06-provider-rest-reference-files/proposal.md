## Why

The REST-first resolution change added `rest_config` to `providers.json` with base URLs and auth headers. But the actual API paths (e.g. `PUT /api/v4/projects/{id}/issues/{iid}`) are not declared anywhere in the skill — Claude is expected to infer them at runtime. This is fragile: paths can change between provider API versions, Claude's training data may be stale, and there is no auditable record of which operations the skill relies on.

The fix is not to embed full request templates (which go stale and balloon the skill size) and not to download OpenAPI specs (too large, irrelevant surface). Instead, each provider gets a compact reference file that names the operations used, gives their canonical path pattern as of the current known version, and links to the official API docs / OpenAPI spec URL so Claude can verify or recover if a path has changed. Provider owns the paths; the skill owns the operation names.

## What Changes

- **`references/rest/github.md`** — auth format, base URL, ~10 operation path patterns, link to GitHub REST API docs
- **`references/rest/gitlab.md`** — auth format, base URL, ~12 operation path patterns, link to GitLab API docs and OpenAPI spec URL
- **`references/rest/jira.md`** — auth format (Basic + base64), base URL, ~10 operation path patterns, link to Atlassian REST API docs
- **`references/rest/plane.md`** — auth format, base URL, ~8 operation path patterns, link to Plane API docs
- **`SKILL.md`** — add instruction before any REST call: read `references/rest/{provider}.md`; if a path returns 404 or 401, consult the docs URL in that file before retrying

## Capabilities

### New Capabilities

- `provider-rest-references`: per-provider REST reference files covering operations used by the skill, with doc links as the recovery path for API changes

### Modified Capabilities

- `provider-io-resolution` (formerly `gitlab-write-fallback`): SKILL.md REST dispatch now references these files rather than relying on implicit path knowledge

## Impact

- `skills/project-management/references/rest/github.md` (new)
- `skills/project-management/references/rest/gitlab.md` (new)
- `skills/project-management/references/rest/jira.md` (new)
- `skills/project-management/references/rest/plane.md` (new)
- `skills/project-management/SKILL.md` — one instruction line added to the REST dispatch step
- No changes to `providers.json`, specs, or any other skill logic
