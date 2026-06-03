## Context

`opsx:archive` currently ends after moving the change directory and displaying a summary. The linked issue tracker ticket (GitLab, GitHub, Jira, Plane) receives no update — what was built, what specs changed, and what was decided in conversation are all lost from the ticket's perspective.

Three independent signal sources exist after archive:

1. **Spec diff** — comparing delta specs (in the change) against main specs (already merged at sync time, or diffable at archive time)
2. **Git diff** — files changed since the branch was created (or since the last tag/ref anchored at change creation)
3. **Session thread** — the current conversation, which may contain explicit conclusions, scope decisions, or references to other tickets

The challenge: these signals only partially overlap, and none alone is sufficient. Specs may not exist. The session may be brief. Git diff is always present but may be purely mechanical. The synthesis step must weigh all three and decide whether an update is worth posting.

A second challenge: the linked ticket ID is not stored today. The session may know it (via `project-management start`), or the user may have mentioned it in conversation, but it is never written to disk.

## Goals / Non-Goals

**Goals:**
- Ticket receives a meaningful comment when `opsx:archive` completes and a linked issue exists
- The comment reflects what actually changed (spec + code + conversation), not just the archive event
- New requirements discovered in specs are surfaced as potential body additions (user confirms)
- Works without `opsx:explore` — git diff + thread are sufficient fallback signals
- Works without specs — git diff + thread alone can produce a useful comment
- Works without a linked issue — degrades to terminal-only summary, no error
- `opsx:explore` "capture this" updates the ticket during the session, not only at archive

**Non-Goals:**
- Automatically closing or transitioning ticket state (too risky without explicit user intent)
- Rewriting the full ticket body (append-only or comment-only; preserve existing content)
- Summarising commits from other branches or PRs (scope: the current change's branch only)
- Supporting providers without MCP write capability (follow existing `gitlab-write-fallback` pattern for GitLab; skip gracefully if write unavailable)

## Decisions

### Decision 1: Store `linked_issue` in `.openspec.yaml`

**Chosen**: `opsx:new` writes a `linked_issue` block to `.openspec.yaml` when ticket context is present in the session. `project-management start` passes this context explicitly when it invokes `opsx:new`.

```yaml
schema: spec-driven
created: 2026-06-03
linked_issue:
  provider: gitlab        # gitlab | github | jira | plane
  project_ref: org/repo  # project path or key
  id: "42"               # issue/ticket ID as string
  url: https://gitlab.com/org/repo/-/issues/42
```

**Rationale**: The link must survive across sessions. `.openspec.yaml` is the change's metadata file and is preserved through archive. Writing it at creation time costs nothing and enables all downstream sync steps.

**Alternatives considered**:
- Infer ticket from branch name: Fragile — branch naming conventions vary, not always `42-slug`.
- Infer ticket from git commit messages: Unreliable — not all commits reference issues.
- Ask the user at archive time: Works but adds friction at the wrong moment.

### Decision 2: Three-signal synthesis with skip heuristic

**Chosen**: Gather all three signals, then apply a skip heuristic before posting.

**Skip if ALL of these are true:**
- Spec diff is empty or contains only formatting/whitespace changes
- Git diff touches only documentation files (`.md`, comments) or is empty
- Session thread contains no explicit decisions, scope changes, or ticket references

Otherwise, synthesise and post.

**Rationale**: Avoids noise comments on purely mechanical changes (rename, fix typo). The bar is low — any one substantive signal triggers the update.

### Decision 3: Git diff anchored at branch creation

**Chosen**: Use `git merge-base HEAD <base-branch>` to find the divergence point, then `git diff <merge-base>..HEAD` as the code signal. If `linked_issue` stores a `base_ref` (added optionally at `opsx:new` time), use that instead.

**Rationale**: Captures everything done in the change's branch, regardless of how many commits. No tagging ceremony required.

**Alternatives considered**:
- `git log --since=<created date>`: Date-based — fragile with rebases or uncommitted work.
- Tag at `opsx:new` time: Clean but adds a required step that may be forgotten.
- Only look at uncommitted diff at archive time: Misses committed work.

### Decision 4: Spec diff from delta specs or main spec comparison

**Chosen**: If delta specs exist at `openspec/changes/<name>/specs/`, diff them against `openspec/specs/<capability>/spec.md`. If no delta specs exist, skip spec signal.

**Rationale**: Delta specs are the canonical record of spec-level intent for the change. If they were synced to main before archive, the diff will show what landed. If they were not synced, the diff shows what was planned but possibly not landed — still useful context.

### Decision 5: Ticket comment is always posted; body update requires confirmation

**Chosen**: Post a comment unconditionally (when signals are non-trivial). Offer to append acceptance criteria to the ticket body only if specs added new requirements — require explicit user confirmation before touching the body.

**Rationale**: Comments are low-risk (append-only, visible history). Body edits are higher-risk (may overwrite carefully crafted content). Separating these gives confidence without sacrificing utility.

### Decision 6: "Capture this" in explore is user-triggered

**Chosen**: During `opsx:explore`, Claude may offer "Want to capture this decision on the ticket?" when a clear conclusion is reached. The user must explicitly accept. No auto-posting.

**Rationale**: Explore is a thinking space. Auto-posting mid-session would be disruptive and could post half-formed ideas. The offer keeps the user in control.

### Decision 7: Related ticket detection from signals

**Chosen**: Scan all three signals for ticket references (`#42`, `PROJ-42`, issue URLs). If found and different from the primary linked issue, offer to comment on those tickets too. Do not auto-post to related tickets — show the list and confirm.

**Rationale**: Related ticket updates are higher-blast-radius than primary ticket updates. Confirmation is required.

## Risks / Trade-offs

- **No linked issue in `.openspec.yaml`**: Archive post-step is skipped. User sees terminal-only summary. No error.
- **GitLab MCP write unavailable**: Follow `gitlab-write-fallback` pattern (`glab` CLI → REST). If neither available, print the comment text to terminal and instruct user to post manually.
- **Large git diff**: Summarise rather than dump raw diff. Cap at top 10 changed files by line count; note total files changed.
- **Session thread from a different session**: The conversation signal is only available if archive runs in the same session as the work. Cross-session case falls back to spec diff + git diff only — still useful.
- **Explore conclusions posted prematurely**: Mitigated by Decision 6 (user-triggered "capture this").

## Migration Plan

1. Add `linked_issue` write to `opsx:new` — check session for ticket context before creating `.openspec.yaml`
2. Update `project-management start` Step 7a — pass ticket id/provider/url as context when invoking `opsx:explore` / `opsx:new`
3. Add step 7 to `opsx:archive` — signal gathering, synthesis, confirmation, post
4. Add "capture this" offer to `opsx:explore` — fires when explicit conclusions are detected
5. Create `openspec/specs/archive-ticket-sync/spec.md`
6. No schema changes to existing `.openspec.yaml` files — `linked_issue` is optional; absence is handled

## Open Questions

- Should `base_ref` (the git ref at change creation) be stored in `.openspec.yaml` by `opsx:new`? (Lean: yes — makes git diff anchoring reliable without `git merge-base` heuristics)
- Should the synthesised comment be shown to the user for review before posting, or posted directly? (Lean: show preview + confirm for first use; offer "always post without preview" preference)
