## Why

`start` mode currently stops twice per invocation — once to confirm the todo/backlog→in-progress transition, once to confirm branch creation — even though both are almost always a "yes." That friction is what blocks `start` from being used as the entry point of a tighter, more autonomous ticket-by-ticket workflow. Separately, `start` does all its ticket-fetching, comment-ranking, cross-reference scanning, and doc-context assembly inline in the main conversation thread, and (when confirmed) creates the feature branch directly in the current checkout — mixing ticket-loading noise into the main thread and putting ticket work on the same working directory the user might already be mid-task in.

## What Changes

- **BREAKING**: `start` mode no longer asks "Move to in-progress? [y/n]" or "Create branch? [Y/n]" by default — it transitions and branches automatically and reports what it did, unless a risk heuristic fires.
- Add a risk-gate check before auto-proceeding: pause for confirmation only when (a) the WIP limit would be exceeded (existing check, unchanged), or (b) the ticket's title+description trips the existing Scope-Width Detection signal (reused from `ticket new`/`ticket-breakdown-detection`, evaluated against the fetched ticket instead of raw user input), or (c) the ticket's estimate is set and exceeds a configurable threshold. A missing/unset estimate does NOT by itself trigger a pause.
- Add a `--confirm` flag that restores the old "ask every time" behavior for a single invocation.
- Move ticket fetch, comment ranking, code cross-reference scanning, linked-issue lookup, and Context Fallback Chain resolution (current Steps 1–3) into a spawned subagent; only the assembled, already-bounded context block (and worktree path, if created) returns to the main thread.
- When a branch is created, always create it as a `git worktree` in a sibling directory rather than switching the branch in the current checkout. `--no-branch` continues to skip both branch and worktree creation.
- Step 7 (invoking `opsx:explore`) continues to run in the main thread, using the context block handed back by the subagent, so the explore conversation still happens directly with the user.
- After `ship` mode successfully creates a GitHub PR, offer a recurring, report-only watch — handed off to the `/loop` skill — that checks the PR's GitHub Actions run status and new comments each tick, until the PR is merged or closed. The watch reports findings; it never pushes fixes or replies to comments on its own. Scoped to GitHub only.

## Capabilities

### New Capabilities
- `start-mode-autonomy`: defines the risk-gate heuristic (WIP / scope-width / estimate threshold) that decides whether `start` auto-proceeds or asks, and the `--confirm` escape hatch.
- `start-mode-worktree-delegation`: defines the subagent split (what runs in the subagent vs. the main thread) and the always-worktree branch creation rule, including how the worktree path is surfaced to later steps.
- `pr-watch`: defines the recurring, report-only watch on a GitHub PR's CI status and comments — what's checked each tick, how state persists across ticks, and the stop condition (merge/close).

### Modified Capabilities
- `targeted-ticket-start`: the state-transition and branch-creation requirements change from "ask, then act on confirmation" to "act, then report unless gated"; branch creation requirements change from "create in current checkout on confirmation" to "create a worktree, no confirmation unless gated."
- `ship-mode`: gains a new offer, after a GitHub PR is created, to start the `pr-watch` loop. No other `ship` behavior changes.

## Impact

- Affects `skills/project-management/SKILL.md` — MODE: start (Steps 1–6 restructured around a subagent call; Step 4 and Step 5 gating logic rewritten; Step 5 branch creation becomes worktree creation).
- Affects `.project/config.yaml` schema — no new fields required for the recommended defaults (estimate threshold can reuse an existing field or ship with a sane default; confirmed via `--confirm` flag rather than a config toggle).
- Affects `skills/project-management/SKILL.md` — MODE: ship (new post-PR-creation offer) and a new `pr-watch` mode tick invoked by `/loop`.
- Adds a new per-PR state file, e.g. `.project/pr-watch/<pr-number>.yaml`, tracking the last-seen CI run and comment so repeat ticks don't re-report the same finding.
- No change to `openspec-apply-change` in this change — follow-on coordination for "which directory is the ticket's work happening in" (worktrees) is still a known gap, not solved here.
