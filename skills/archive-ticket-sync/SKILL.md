---
name: archive-ticket-sync
description: >
  Post-archive ticket sync skill. After opsx:archive completes, gathers three signals
  (spec diff, git diff, session thread), synthesises a comment summarising what changed,
  and posts it to the linked issue tracker ticket. Also handles "capture this" during
  explore sessions — posts a short note to the linked ticket when the user explicitly
  requests it. Works with GitHub, GitLab, Jira, and Plane. Degrades gracefully when no
  linked issue is stored, when signals are trivial, or when the tracker write fails.
license: MIT
compatibility: >
  Requires a supported issue tracker MCP server (mcp__github__, mcp__gitlab__,
  mcp__jira__, or mcp__plane__) for automatic posting. Falls back to terminal output
  when no write tool is available.
metadata:
  author: knvpk
  version: "1.0"
---

# archive-ticket-sync

Two entry points:

- **`sync`** (default) — run after `opsx:archive` to post a change summary to the linked ticket
- **`capture`** — called during an explore session to post a single conclusion to the linked ticket

---

## Entry point: sync

Triggered by: `/archive-ticket-sync`, `/archive-ticket-sync sync`, or invoked after `opsx:archive` completes.

**Input**: change name (kebab-case). If omitted, look for a recently archived change (most recent directory under `openspec/changes/archive/` by date prefix). If still ambiguous, ask.

### Step 1 — Read linked_issue

Read `.openspec.yaml` from the archived change at `openspec/changes/archive/<YYYY-MM-DD-name>/.openspec.yaml`.

If `linked_issue` is absent: print `No linked issue found in .openspec.yaml — skipping ticket sync.` and stop.

If present, extract:
```yaml
linked_issue:
  provider: gitlab|github|jira|plane
  project_ref: org/repo
  id: "42"
  url: https://...
base_ref: <sha>   # optional
```

### Step 2 — Gather signals

Run all three in parallel.

#### Signal 1 — Spec diff

Check for delta specs at `openspec/changes/archive/<YYYY-MM-DD-name>/specs/`.

If none: `spec_signal = []`.

For each delta spec found at `openspec/changes/archive/<YYYY-MM-DD-name>/specs/<capability>/spec.md`:
- Read the delta spec
- Read the main spec at `openspec/specs/<capability>/spec.md` (may not exist for new capabilities)
- Extract as bullet points: new requirements, modified requirements, new/removed capabilities

#### Signal 2 — Git diff

Determine anchor:
1. Use `base_ref` from `.openspec.yaml` if present: `git diff <base_ref>..HEAD --stat`
2. Otherwise: `git diff $(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null || git merge-base HEAD develop 2>/dev/null)..HEAD --stat`

Extract:
- Top 10 changed files by lines (exclude binaries)
- Summary line: `N files changed, X insertions(+), Y deletions(-)`

#### Signal 3 — Session thread

Scan the current conversation for:
- Decisions: phrases like "we decided", "going with", "ruled out", "won't", "will not", "confirmed"
- Scope changes: "out of scope", "added to scope", "scope changed"
- Ticket refs: `#N`, `PROJ-N`, full issue URLs — store separately as `related_refs` (exclude the primary `linked_issue.id`)

### Step 3 — Skip heuristic

Skip posting if ALL are true:
- `spec_signal` is empty or formatting/whitespace changes only
- Git diff touches only `.md` files or is empty
- `thread_signal` has no decisions or scope changes

Output: `No substantive changes detected — skipping ticket comment.` and stop.

### Step 4 — Synthesise comment draft

```markdown
## Change `<name>` archived

**Specs:** <spec diff bullets, or "no delta specs">
**Code:** <top changed files with +/- counts, or "no code changes detected">
**Decisions:** <thread conclusions as bullets, or "none recorded this session">
```

### Step 5 — Confirm and post

Show the draft. Use **AskUserQuestion** to ask:
> "Post this summary to <provider> issue #<id>?"

Options: `Post it` | `Edit first` | `Skip`

If `Edit first`: show draft as plain text, accept user edits, re-confirm before posting.

**Post via provider routing:**

| Provider | Tool | Fallback 1 | Fallback 2 |
|----------|------|-----------|-----------|
| GitHub | `mcp__github__add_issue_comment(owner, repo, issue_number, body)` | — | — |
| GitLab | `mcp__gitlab__create_note(project_id, issue_iid, body)` | `glab issue note <id> --project <project_ref> -m "..."` | `curl -X POST "$GITLAB_URL/api/v4/projects/<encoded_project_ref>/issues/<id>/notes" -H "PRIVATE-TOKEN: $GITLAB_TOKEN" -d "body=..."` |
| Jira | Jira MCP comment tool | — | — |
| Plane | Plane MCP comment tool | — | — |

On write failure: print comment to terminal with `⚠ Could not write to tracker — copy and post manually.`

### Step 6 — Acceptance criteria offer (if spec added requirements)

If `spec_signal` contains new requirements, ask separately:
> "Append these new acceptance criteria to the ticket body?"

Options: `Yes, append` | `Skip`

If yes:
1. Fetch current ticket body via provider read tool
2. Append (do NOT overwrite):
   ```markdown
   ## Acceptance Criteria (from <change-name>)

   <new requirements from spec diff>
   ```
3. Write back via provider update tool
4. On failure: print the section to terminal

### Step 7 — Related tickets offer

If `related_refs` is non-empty (ticket refs found in signals, different from `linked_issue.id`):
- Show: `Signals mention these other tickets: <list>`
- Ask: `Comment on any of these?` (multi-select)
- For each selected: post `Related change \`<name>\` was archived. See <primary issue URL> for details.`

---

## Entry point: capture

Triggered by: `/archive-ticket-sync capture "<conclusion text>"` or invoked internally by the `project-management` skill during explore sessions.

**Input**: conclusion text (what was decided/discovered). May be passed as argument or extracted from conversation context.

### Step 1 — Find active change and linked_issue

Scan `openspec/changes/` (excluding `archive/`) for `.openspec.yaml` files. Pick the most recently created (by `created` field) that has a `linked_issue` block.

If none found with `linked_issue`: offer to write to `openspec/changes/<name>/notes.md` instead.
If no active change at all: print `No active change found — conclusion not saved.` and stop.

### Step 2 — Draft and confirm comment

Draft:
```markdown
**Explore note — <change-name>**

<conclusion text>
```

Show preview. Ask: `Post this to <provider> #<id>?` (yes / edit / skip)

### Step 3 — Post

Use same provider routing table as sync entry point.

On success: `✓ Posted to #<id>.`
On failure: print text with `⚠ Could not post — copy above to post manually.`

---

## Guardrails

- Never auto-post without user confirmation — always show draft first
- Never overwrite ticket body — append only; require explicit confirmation
- `related_refs` comments require per-ticket or batch confirmation — never auto-post
- If all write paths fail, always print comment text to terminal
- `base_ref` diff is preferred over `merge-base` heuristic — store it at change creation
- Spec signal is skipped silently when no delta specs exist; this is not an error
