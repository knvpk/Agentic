## Context

`project-management start` today: fetch ticket → pre-flight gate → transition + worktree → invoke `opsx:explore` with a context block. Explore is a stance with "no required ending", and the OpenSpec change (the only durable carrier of `linked_issue`) is created, if at all, by whatever the model decides to do next. `start` checks for a change "after the session ends", which no step actually triggers. Result: the ticket is `in-progress`, a worktree exists, and the model edits code with no change, so `sync archive` finds no `linked_issue` and the ticket never gets a summary.

Constraints: skills live in `skills/` and follow the agentskills.io spec; hooks are harness-level (settings), not part of a skill; `.openspec.yaml` already supports `linked_issue` + `base_ref` (see `archive-ticket-sync`).

## Goals / Non-Goals

**Goals:**
- The handoff from `start` to explore is a file on disk, not a promise.
- Explore always ends in an explicit verdict; open questions stop the ticket and are resumable.
- Edits without a linked change are blocked by the harness, not by model discipline.

**Non-Goals:**
- The `auto` orchestrator, verify loop, and `merge` mode (follow-up change `project-management-auto`).
- Changing how explore behaves outside of `start` (plain `/opsx:explore` stays free-form).
- Enforcing the guard for non-ticket branches.

## Decisions

**D1. `start` creates the change shell.** After the gate resolves and the branch/worktree exists, `start` runs `openspec new change "<ticket-id>-<slug>"` (slug reused from the branch slug) and writes `linked_issue` + `base_ref` into `.openspec.yaml` immediately. The worktree/branch is created first so the change lives on the ticket branch.
*Alternative:* keep backfilling after explore. Rejected: the exact step that fails today.
*Alternative:* have `opsx:new` read the ticket from the session. Rejected: couples openspec skills to project-management.

**D2. Explore gets a contract prompt, with a verdict.** The invocation prompt requires the session to end by writing, into the change's `design.md`, a `## Verdict` block: `ready` or `needs-input`, plus `## Assumptions` and (for `needs-input`) `## Open Questions`. A question is **blocking** only if its answer would change scope, design, or a spec scenario; otherwise it is recorded as an assumption. This definition lives in the skill so the model has a rule, not a vibe.
*Alternative:* a separate "explore-lite" subagent. Deferred to the auto change; interactive explore stays interactive.

**D3. `needs-input` is a persisted, resumable stop.** On `needs-input`: questions are in `design.md`, a comment is posted on the ticket (provider write path), and `.openspec.yaml` gets `status: awaiting-answers`. Re-running `start <ticket>` detects an existing change with `linked_issue.id` matching the ticket, skips ticket-fetch side effects (no second transition/branch), folds answers (from the user or new ticket comments) into `design.md`, and re-evaluates the verdict. `start` never creates a second change for the same ticket.

**D4. Edit-guard hook in the skill, wired via settings.** A small script `skills/project-management/scripts/require-change.sh` is invoked from a PreToolUse hook on `Edit|Write|NotebookEdit`. It reads the current branch, extracts a ticket id with the same `[A-Z]+-\d+` / numeric rules `ship` uses, and exits non-zero with a message if no `openspec/changes/*/.openspec.yaml` (excluding `archive/`) has a matching `linked_issue.id`. It allows edits inside `openspec/changes/` itself (so artifacts can be written), and does nothing on branches without a ticket id. The settings snippet is documented in the skill; installation is opt-in, since hooks are user config.
*Alternative:* instruct the model harder. Rejected: that is the current failure mode.

**D5. Fallback loses "Start implementing now".** When `opsx:explore` is not detected, the menu offers "create a change for this ticket" (`opsx:new`/`ff`) in its place. The detection stays as is.

## Risks / Trade-offs

- [Hook blocks legitimate edits, e.g. docs fixes on a ticket branch] → The guard only requires *a* linked change to exist, not that edits match it; `--no-branch` / non-ticket branches are unaffected.
- [Change shell created for a ticket that is then abandoned] → Stale shells are visible in `openspec list`; `awaiting-answers` makes the reason explicit. Acceptable cost for a durable handoff.
- [Model ignores the verdict block] → `start` Step 5 checks `design.md` for the verdict after explore and, if absent, re-prompts once instead of proceeding.
- [Ticket comment on `needs-input` is noisy] → One comment per stop, containing only blocking questions.
- [Hook script depends on `yq`/grep availability] → Use plain `grep`/`sed` on the two fields; no new dependency.

## Migration Plan

1. Update SKILL.md (`start` Steps 2h, 5a, 5b; help text).
2. Add the hook script and document the settings snippet; user opts in.
3. Existing in-flight changes without `linked_issue` are unaffected (guard only fires on ticket-named branches with no matching change).
Rollback: revert SKILL.md edits and remove the hook entry; no data migration.

## Open Questions

- Should the hook ship as a plugin hook so it installs with the skill, or stay a documented snippet? (Leaning snippet: skills are portable via `npx skills`, hooks are not.)
