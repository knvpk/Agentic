# Spec: archive-ticket-sync

## Purpose

When a change is archived via `opsx:archive`, the linked issue tracker ticket receives a comment summarising what changed — drawing from three independent signal sources. This closes the loop between implementation and ticket, without requiring manual updates.

---

## `linked_issue` Schema in `.openspec.yaml`

```yaml
schema: spec-driven
created: YYYY-MM-DD
linked_issue:
  provider: gitlab        # gitlab | github | jira | plane
  project_ref: org/repo  # GitLab/GitHub: org/repo path; Jira: project key; Plane: project slug
  id: "42"               # issue/ticket ID as string (never numeric — avoids YAML type coercion)
  url: https://...       # full canonical URL to the issue
base_ref: <git sha>      # HEAD at change creation time; used to anchor git diff
```

Both `linked_issue` and `base_ref` are optional. All downstream steps degrade gracefully when absent.

Written by `opsx:new` at change creation time if ticket context is present in the session. The `base_ref` is always written when `opsx:new` runs in a git repository.

---

## Signal Sources

### Signal 1 — Spec diff

**Source**: Delta specs at `openspec/changes/<name>/specs/<capability>/spec.md` vs main specs at `openspec/specs/<capability>/spec.md`.

**Extracted**:
- New requirements (lines/sections added)
- Modified requirements
- New capabilities (delta spec has no corresponding main spec)
- Removed capabilities (main spec has content missing from delta)

**Absent when**: No delta specs directory exists in the change.

### Signal 2 — Git diff

**Source**: `git diff <anchor>..HEAD --stat` where anchor is:
1. `base_ref` from `.openspec.yaml` (preferred)
2. `git merge-base HEAD <base-branch>` (fallback; tries `main`, `master`, `develop`)

**Extracted**:
- Top 10 changed files by line count (binary files excluded)
- Total: N files, X insertions, Y deletions

**Absent when**: No commits exist since anchor (empty diff).

### Signal 3 — Session thread

**Source**: Current conversation context.

**Extracted**:
- Explicit decisions (phrases: "we decided", "going with", "ruled out", "won't", "will not")
- Scope changes ("out of scope", "added to scope", "scope changed")
- Ticket references: `#N`, `PROJ-N`, issue URLs — collected as `related_refs`

**Absent when**: Archive runs in a different session from where the work happened. In this case, spec diff + git diff are used alone.

---

## Skip Heuristic

Do NOT post a ticket comment if ALL of the following are true:
- Spec signal is empty or contains only whitespace/formatting changes
- Git signal touches only `.md` files or is empty
- Thread signal has no detected decisions or scope changes

Output: `"No substantive changes detected — skipping ticket comment."`

Otherwise: synthesise and post.

---

## Comment Format

```markdown
## Change `<name>` archived

**Specs:** <spec diff summary, or "no delta specs">
**Code:** <top changed files with +/- counts, or "no code changes detected">
**Decisions:** <thread conclusions as bullets, or "none recorded this session">
```

The comment is always shown to the user for review before posting. The user may edit or skip.

---

## Provider Routing Table

| Provider | Write tool | Fallback 1 | Fallback 2 |
|----------|-----------|-----------|-----------|
| GitHub   | `mcp__github__add_issue_comment` | — | — |
| GitLab   | `mcp__gitlab__create_note` | `glab issue note <id> -m "..."` | `curl POST /api/v4/projects/<id>/issues/<iid>/notes` |
| Jira     | Jira MCP comment tool | — | — |
| Plane    | Plane MCP comment tool | — | — |

If all write paths fail: print comment to terminal with `"⚠ Could not write to tracker — copy and post manually."`

---

## Body Update (Acceptance Criteria Append)

Triggered only when spec diff added new requirements. Requires explicit user confirmation.

Procedure:
1. Fetch current ticket body via provider read tool
2. Append section at end (never overwrite):
   ```markdown
   ## Acceptance Criteria (from <change-name>)

   <new requirements from spec diff>
   ```
3. Write back via provider update tool
4. On failure: print the section to terminal for manual addition

---

## Related Ticket Comments

When `related_refs` contains ticket references different from the primary `linked_issue.id`:
- Show list to user: "Signals mention these other tickets: #X, #Y"
- Require confirmation before posting (per-ticket or batch)
- Comment format: `"Related change \`<name>\` was archived. See <primary issue URL> for details."`

---

## "Capture this" in opsx:explore

During an explore session, when a conclusion crystallises, Claude offers: `"Want to capture this on the ticket? Type 'capture' to post."`

User must explicitly confirm. On confirmation:
- If `linked_issue` is present in active change's `.openspec.yaml`: post short comment via provider routing
- If no `linked_issue` but active change exists: offer `notes.md` in change directory
- If no active change: skip silently

Comment format:
```markdown
**Explore note — <change-name>**

<conclusion text>
```

---

## Degradation Behaviour

| Missing element | Behaviour |
|----------------|-----------|
| No `linked_issue` in `.openspec.yaml` | Terminal-only summary; no error |
| No delta specs | Spec signal = empty; continue with git + thread |
| Different session from work | Thread signal = empty; continue with spec + git |
| All signals below skip heuristic | "No substantive changes detected" — skip post |
| Tracker write fails | Print comment to terminal; `"⚠ post manually"` |
| No active change (in explore) | Skip "capture this" silently |
