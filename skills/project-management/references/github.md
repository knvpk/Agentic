# GitHub Provider Reference

## MCP Server

**Docs**: https://github.com/github/github-mcp-server
**Official endpoint**: `https://api.githubcopilot.com/mcp/`
**Self-hosted pattern**: `{instance_url}/mcp/` (Enterprise Server — local only, no remote HTTP)

**Setup — OAuth (recommended):**
```bash
claude mcp add github --scope project -t http --url https://api.githubcopilot.com/mcp/
# Then type /mcp in Claude to complete browser OAuth flow
```

**Setup — PAT:**
```bash
claude mcp add github --scope project -t http \
  --url https://api.githubcopilot.com/mcp/ \
  --header "Authorization=Bearer YOUR_GITHUB_PAT"
# PAT needs: repo scope → https://github.com/settings/tokens/new?scopes=repo
```

## Known Limitations

| Feature | Status | Fallback |
|---------|--------|----------|
| Epics | ✗ Not available | Label `epic:{slug}` |
| Sprints | ✗ Not available (Projects v2 needs GraphQL) | Milestone as sprint proxy |
| Release Milestones | ✓ Native (GitHub Milestones) | — |
| blocks/blocked-by | ✗ Not native | Comment on issue |
| relates-to | ✗ Not native | Label `relates:#{id}` |
| Sub-issues | ✗ Not native | Label `child:#{parent_id}` |
| Custom states | ✗ Open/closed only | Labels simulate states |

GitHub has **no native sprint concept** at the Issues API level. GitHub Projects v2 supports iteration fields but requires a separate GraphQL client and a `project`-scoped PAT — deferred to a future version of this skill. Milestones are used as sprint proxies.

## State Simulation via Labels

The skill manages the following labels automatically. Create them at init time:

```
todo          (colour: #e4e669)
in-progress   (colour: #0075ca)
in-review     (colour: #7057ff)
blocked       (colour: #d93f0b)
epic:*        (created per epic, colour: #e99695)
relates:*     (created per link, colour: #c5def5)
```

State transitions:
- `backlog` → issue open, no state label
- `todo` → add label `todo`
- `in-progress` → remove `todo`, add `in-progress`
- `in-review` → remove `in-progress`, add `in-review`
- `done` → close issue, remove all state labels
- `blocked` → add label `blocked` + comment with reason

## Milestones — Sprints AND Releases

GitHub milestones serve both purposes. The skill distinguishes them by naming convention:

| Purpose | Naming pattern | Examples |
|---------|---------------|---------|
| Sprint proxy | `Sprint N` or `YYYY-WW` | `Sprint 4`, `2026-W22` |
| Release milestone | Version or name | `v1.0.0`, `Beta`, `Q3 Launch` |

Both use the same GitHub Milestones API — the skill does not enforce naming, it's a convention to keep the list readable.

```
Create sprint    → POST /milestones  { title: "Sprint 4", due_on: ... }
Create release   → POST /milestones  { title: "v1.0.0",  due_on: ... }
Assign to ticket → PATCH /issues/{n} { milestone: id }
List milestones  → GET  /milestones?state=open
Close milestone  → PATCH /milestones/{id} { state: "closed" }
```

## Relationship Simulation

```
blocks #{B}     → comment on #{B}: "Blocked by: #{A}"
                   add label 'blocked' to #{B}
relates to #{B} → comment on #{A}: "Relates to: #{B}"
                   comment on #{B}: "Relates to: #{A}"
parent of #{B}  → comment on #{B}: "Parent: #{A}"
                   add label 'epic:{slug}' to #{B}
```

## Setup Checklist

1. Run `claude mcp add github --scope project -t http --url https://api.githubcopilot.com/mcp/`
2. Complete OAuth: type `/mcp` in Claude and follow the browser flow — **or** add `--header "Authorization=Bearer YOUR_PAT"` (PAT needs `repo` scope: https://github.com/settings/tokens/new?scopes=repo)
3. Run `/project-management init` — will detect GitHub from git remote
4. Init creates required state labels automatically
