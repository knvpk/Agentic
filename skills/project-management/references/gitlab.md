# GitLab Provider Reference

## MCP Server

**Docs**: https://docs.gitlab.com/editor_extensions/gitlab_mcp_server/
**Official endpoint**: `https://gitlab.com/api/v4/mcp`
**Self-hosted pattern**: `{instance_url}/api/v4/mcp`

**Setup — OAuth (browser flow, recommended):**
```bash
claude mcp add gitlab --scope project --transport http https://gitlab.com/api/v4/mcp
# Then type /mcp in Claude to complete OAuth 2.0 browser flow
```

**Setup — PAT (headless / CI-friendly):**
```bash
# Token requires api scope — create at: https://gitlab.com/-/user_settings/personal_access_tokens
claude mcp add gitlab --scope project --transport http https://gitlab.com/api/v4/mcp --header "Authorization=Bearer glpat-xxxx"
```
If `GITLAB_TOKEN` is already set in your environment, `/project-management init` will detect it and use PAT auth automatically.

**Self-hosted:**
```bash
claude mcp add gitlab --scope project --transport http https://git.company.com/api/v4/mcp
```

## Plan Variants

| Feature | CE (Community) | EE (Enterprise) |
|---------|---------------|-----------------|
| Epics | ✗ | ✓ (group-level) |
| Sprints | ✓ (milestones) | ✓ |
| blocks relation | ✗ | ✓ |
| relates-to | ✗ | ✓ |
| Sub-issues | ✓ | ✓ |
| Custom states | ✗ (open/closed) | ✗ |

The skill probes `list_epics` and `list_issue_links` at init to detect CE vs EE.

## Sprint Model (Milestones)

GitLab milestones serve as sprints. They support start/due dates and can be assigned to issues directly.

```
Sprint create   → POST /projects/{id}/milestones
Sprint add      → PUT  /projects/{id}/issues/{iid}  (milestone_id)
Sprint status   → GET  /projects/{id}/issues?milestone={title}&state=opened
```

## State Simulation via Labels

GitLab issues are open/closed with label-based state enrichment:

```
To Do         → label (created at init)
In Progress   → label
In Review     → label
Blocked       → label
```

State transitions remove prior state label before adding new one.

## Relationship Simulation (CE fallback)

```
blocks #{B}     → comment on #{B}: "Blocked by: !{A}"
                   add label 'blocked' to #{B}
relates to #{B} → label 'relates:#{B}' on #{A}
                   label 'relates:#{A}' on #{B}
```

EE native:
- `POST /projects/{id}/issues/{iid}/links` with `link_type: blocks | relates_to | is_cloned_by`

## Epic Simulation (CE fallback)

Label `epic:{slug}` applied to all child issues. Epic "title" lives in a label description.

## Write Fallback Chain

The GitLab MCP server does not expose `update_issue`. All writes to existing issues (state transitions, label changes, sprint and milestone assignment) use this fallback chain, tried in order:

| Priority | Path | Trigger |
|----------|------|---------|
| 1 | MCP `update_issue` | Tool is discoverable via ToolSearch |
| 2 | `glab` CLI | `which glab` exits 0 |
| 3 | GitLab REST API (curl) | `GITLAB_TOKEN` is set |

When falling back, the skill emits a one-line notice:
```
ℹ Using glab CLI for GitLab write (MCP update_issue not available)
ℹ Using REST API for GitLab write (MCP update_issue not available)
```

If all three paths are unavailable, the skill halts with instructions for enabling one.

### glab CLI (optional dependency)

`glab` is not required but enables the CLI fallback path:

```bash
# macOS
brew install glab

# Linux / other
# https://gitlab.com/gitlab-org/cli#installation
```

### REST API fallback

Requires `GITLAB_TOKEN` with `api` scope. The skill reads `GITLAB_URL` for self-hosted instances:

```bash
export GITLAB_TOKEN=glpat-xxxx          # always required
export GITLAB_URL=https://git.company.com   # self-hosted only; defaults to https://gitlab.com
```

The numeric project ID (`gitlab_project_id`) is captured at init and stored in `.project/config.yaml`. If absent, it is fetched lazily on the first write.

## Setup Checklist

1. Add GitLab MCP server to Claude Code
2. Set `GITLAB_TOKEN` with `api` scope
3. Run `/project-management init`
4. If self-hosted, set `GITLAB_URL` env var and configure base URL in MCP setup
