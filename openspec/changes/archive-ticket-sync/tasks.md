# Tasks: archive-ticket-sync

## 1. Store linked issue at change creation

- [ ] **1.1** Update `opsx:new` — after creating `.openspec.yaml`, check if a ticket context (`linked_issue` block) is present in the session (from `project-management start` context or user mention). If found, append `linked_issue` (provider, project_ref, id, url) to `.openspec.yaml`.
- [ ] **1.2** Update `opsx:new` — optionally store `base_ref` (output of `git rev-parse HEAD`) in `.openspec.yaml` at creation time to anchor git diff later.
- [ ] **1.3** Update `project-management start` Step 7a — when invoking `opsx:explore` or `opsx:new`, pass ticket context (id, provider, project_ref, url) explicitly in the prompt so `opsx:new` can write it to `.openspec.yaml`.

**Verify:** Create a change via `project-management start #42` → `opsx:new`. Confirm `.openspec.yaml` contains `linked_issue` block with correct values.

---

## 2. Post-archive signal gathering (opsx:archive step 7)

- [ ] **2.1** Add step 7 to `.claude/commands/opsx/archive.md`: read `linked_issue` from `.openspec.yaml` in the archived path. If absent, print terminal-only summary and skip remaining steps.
- [ ] **2.2** Implement **spec signal**: if delta specs exist at `openspec/changes/<name>/specs/`, diff each against `openspec/specs/<capability>/spec.md`. Extract: new requirements, modified requirements, new capabilities, removed capabilities.
- [ ] **2.3** Implement **git signal**: run `git diff $(git merge-base HEAD <base-branch>)..HEAD --stat` (or use stored `base_ref`). Extract: list of changed files (top 10 by lines), summary of additions/deletions. Skip binary files.
- [ ] **2.4** Implement **session thread signal**: scan the current conversation for explicit decisions, scope changes, ruled-out items, and ticket references (`#N`, `PROJ-N`, issue URLs). Extract as a bullet list.
- [ ] **2.5** Implement **skip heuristic**: if spec diff is formatting-only AND git diff is docs-only AND thread has no decisions → skip posting, note "No substantive changes detected" in terminal summary.

**Verify:** Archive a change with real code changes. Confirm all three signals are gathered and the skip heuristic fires correctly on a docs-only change.

---

## 3. Synthesis and confirmation

- [ ] **3.1** Implement synthesis: combine non-empty signals into a structured comment draft:
  ```
  ## Change `<name>` archived — what changed

  **Specs:** <spec diff summary or "no delta specs">
  **Code:** <top files changed, additions/deletions>
  **Decisions:** <thread conclusions or "none recorded">
  ```
- [ ] **3.2** Show the draft comment to the user and ask: "Post this to <provider> issue #<id>?" (yes / edit / skip).
- [ ] **3.3** If spec diff added new requirements, offer separately: "Append these acceptance criteria to the ticket body?" (yes / skip). Require explicit yes.
- [ ] **3.4** Detect related ticket references in signals. If found (different from primary), show list and ask: "Also comment on: #X, #Y?" (confirm per ticket or all).

**Verify:** Run archive on a change with spec additions. Confirm user sees draft, can edit or skip, and related tickets are detected from git commit messages or thread.

---

## 4. Post to issue tracker

- [ ] **4.1** Route ticket write through the provider adapter: use `mcp__gitlab__create_note` / `mcp__github__add_issue_comment` / Jira comment API / Plane comment API based on `linked_issue.provider`.
- [ ] **4.2** For GitLab: if MCP write unavailable, follow `gitlab-write-fallback` pattern (`glab issue note` → `curl` REST). If neither available, print comment text to terminal with instruction to post manually.
- [ ] **4.3** If body update confirmed, fetch current ticket body, append new acceptance criteria section (do not overwrite), write back via provider adapter.
- [ ] **4.4** Update terminal summary to reflect: "✓ Commented on #<id>", "✓ Body updated", "✓ Also commented on #X", or "⚠ Could not write to tracker — comment printed above".

**Verify:** Post a comment to a real GitLab issue and a real GitHub issue. Confirm the comment appears with correct content. Confirm body append does not overwrite existing content.

---

## 5. "Capture this" in opsx:explore

- [ ] **5.1** Add "capture this" detection to `opsx:explore`: when Claude detects an explicit conclusion (scope decision, requirement ruled out, new requirement discovered), offer: "Want to capture this on the ticket? (`capture` to post, or continue exploring)".
- [ ] **5.2** When user types `capture` (or equivalent): extract the conclusion, draft a short comment, show preview, post to `linked_issue` if present (same provider routing as step 4.1–4.2).
- [ ] **5.3** If no `linked_issue` in `.openspec.yaml` (or no active change): offer to record the conclusion in a `notes.md` file in the change directory instead. If no active change at all, skip silently.

**Verify:** Run an explore session with `project-management start #42`. Reach a conclusion. Confirm "capture this" offer appears. Confirm comment is posted to the correct ticket.

---

## 6. Spec: archive-ticket-sync capability

- [ ] **6.1** Create `openspec/specs/archive-ticket-sync/spec.md` documenting:
  - The `linked_issue` schema in `.openspec.yaml`
  - The three signal sources and skip heuristic
  - The comment format template
  - Provider routing table
  - Fallback behaviour when write is unavailable

**Verify:** Spec file exists and is consistent with design decisions.
