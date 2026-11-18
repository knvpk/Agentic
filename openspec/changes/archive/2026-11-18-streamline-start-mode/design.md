## Context

`start` mode (see `targeted-ticket-start` spec) currently runs entirely in the main conversation thread and stops twice: once to confirm the todo/backlog→in-progress transition (current Step 4), once to confirm branch creation (current Step 5c). Everything before that — ticket fetch, comment ranking, code cross-reference scanning, linked-issue lookup, and the Context Fallback Chain — also runs inline, which is where most of the tool-call noise comes from, not the final context block (which is already size-bounded: description capped at 3000 chars, comments ≤10, code refs ≤10).

Decided during exploration (confirmed via user question): missing estimate alone should not gate; the escape hatch is a `--confirm` flag, not a config toggle; worktrees are created unconditionally whenever a branch is created, not only when the checkout is dirty.

## Goals / Non-Goals

**Goals:**
- Collapse the two existing confirmation prompts into at most one combined checkpoint, and make "no prompt at all" the common case.
- Move the data-gathering steps (fetch, enrich, scan) out of the main thread so they don't bloat the conversation the user is actually having.
- Make ticket work happen in an isolated worktree by default, so `start` never mutates the branch of the checkout the user is already in.
- Preserve every existing safety property: the WIP Limit Check still runs and can still block; `--no-branch` still skips branch/worktree creation entirely.

**Non-Goals:**
- Not introducing a multi-ticket "work through the backlog automatically" loop mode — this change only makes a single `start` invocation less chatty. A proactive loop is a separate, later change.
- Not solving how `ship` or `openspec-apply-change` discover and operate against a ticket's worktree path — called out as a known gap, not closed here.
- Not adding worktree cleanup/removal automation.
- Not changing the WIP Limit Check's own semantics — reused exactly as defined in `agile-quality-gates`.

## Decisions

### 1. One combined gate, not two separate prompts
Replace the independent "transition?" and "branch?" confirmations with a single pre-flight gate evaluated once, before either action: **WIP limit would be exceeded** (unchanged, from `agile-quality-gates`) **OR** **scope-width signal fires** **OR** **estimate exceeds threshold**. If none fire, both the state transition and the worktree/branch creation happen automatically, then are reported together as one status line. If any fire, the user is asked once: `"TICK-42 looks {reason} — transition to in-progress and create its branch anyway? [y/n]"`.

*Alternative considered*: keep two separate prompts but make each individually skippable. Rejected — doubles the number of decision points for no benefit, since in practice transition and branch creation are a single logical "start working" action.

### 2. Reuse the scope-width signal against the fetched ticket, not raw input
`ticket-breakdown-detection`'s three signals (conjunction, plural-area-without-verb, docs-breadth ≥3 sections) are evaluated against the fetched `ticket.title + ticket.description`, instead of the raw text a user types into `ticket new`. The docs-breadth signal specifically is **not** recomputed with a second scan — it's derived from the match count the Context Fallback Chain (Step 3) already produces, since that step already walks the same doc set looking for the same kind of topical match.

*Alternative considered*: a dedicated "ticket size" classifier (LLM judgment call per ticket). Rejected for now — reusing an existing, already-tuned heuristic is simpler and keeps the two entry points (`ticket new` and `start`) consistent in what counts as "too big."

### 3. Estimate threshold: hardcoded default, points-oriented, no new required config
Default threshold: numeric estimate `> 5`. No new field is required in `.project/config.yaml` for this change to ship with sane defaults. This is a known simplification — some providers use hours or days rather than points for estimate fields — called out in Open Questions rather than solved here.

### 4. Subagent owns fetch + enrich + (conditionally) the mutations
A fresh (non-fork) subagent is spawned with just the ticket reference and the resolved `.project/config.yaml` — it doesn't need the user's prior conversation, only the ticket ID and project config, so a fresh agent keeps the call cheap and self-contained. It performs:
- Steps 1–3 (fetch ticket, rank comments, scan code refs, fetch linked issues if thin, Context Fallback Chain)
- Gate evaluation (WIP / scope-width / estimate)
- **If no gate fires**: also performs the state transition MCP call and worktree/branch creation itself, then returns the assembled context block plus a one-line summary of what it did and the `worktree_path`.
- **If a gate fires**: stops short of any mutation, returns the context block plus the gate reason and the action it would take, so the main thread can ask the user.

*Why let the subagent mutate at all*: in the no-gate path, the main thread would unconditionally perform the exact same action anyway — deferring it to the main thread would just be a round trip with no decision in between. Mutations only move to the main thread when a human decision is actually needed, which keeps the "ask-then-act" pattern visible in the conversation precisely when it matters.

*Alternative considered*: subagent never mutates; main thread always does transition + worktree creation after getting the context block back. Rejected — this reintroduces a second round trip (and a second pass at the branch-naming logic) for the common no-gate case, which is the thing this change is trying to remove.

### 5. Worktree, not in-checkout branch switch
When a branch would be created, it's created via `git worktree add ../{repo}-{ticket-id}-{slug} -b {branch} {base}` instead of `git checkout -b` in the current directory. `--no-branch` skips both branch and worktree creation, unchanged from today. No change to base-branch detection (Step 5a) or branch-name slugging (Step 5b) logic.

### 6. `--confirm` escape hatch
Passing `--confirm` forces the gate to fire unconditionally for that single invocation, reproducing today's "ask every time" behavior. This is a per-call flag, not a persistent config toggle — chosen to match the existing `--no-branch` flag pattern and to avoid adding a new field to `.project/config.yaml` for a one-off behavior override.

### 7. PR watch is report-only, driven by `/loop`, and GitHub-only
After `ship` creates a GitHub PR, it offers to hand off to the generic `/loop` skill with a prompt that re-enters a new `pr-watch` mode tick. Each tick fetches GitHub Actions run status for the PR's head commit and any PR comments created since the last tick, compares against per-PR state persisted at `.project/pr-watch/<pr-number>.yaml` (last-seen CI run ID, last-seen comment ID), and reports anything new. It never pushes a fix commit or replies to a comment — it only tells the user what it found. A tick that finds the PR merged or closed reports that and ends the loop instead of scheduling another tick.

*Why report-only*: CI failures and review comments are exactly the place where an autonomous action is most likely to collide with what a human reviewer is doing on the same PR in real time (force-pushing a fix while someone's mid-review, or replying to a comment on their behalf). Keeping this first version report-only establishes the watch itself as useful before any later change considers letting it act.

*Why `/loop` instead of a bespoke polling mechanism*: the project already has a generic "run a prompt on an interval" skill; building a second, skill-specific polling loop would duplicate that mechanism for no behavioral gain. `pr-watch` only needs to define what a single tick does and when to stop — scheduling is `/loop`'s job.

*Why GitHub-only*: the user asked specifically for GitHub Actions and PR comments. GitLab's equivalent (pipelines + MR comments) would need its own mapping through `providers.json` and is left for a follow-on change rather than guessed at here.

*Alternative considered*: make the watch auto-fix CI failures (e.g., re-run flaky jobs, or push a trivial lint fix). Rejected for this change on the same grounds as the autonomy-level discussion for `start` — auto-proceeding on heuristics is one thing when the "action" is transitioning a ticket you're about to work on yourself; it's a different risk tier when the action is pushing new commits to a PR mid-review. Left as a later option once report-only has been used for a while.

## Risks / Trade-offs

- **[Risk]** Auto-transitioning and auto-branching without confirmation surprises someone who ran `start` just to look at a ticket. → **Mitigation**: `start` is already named as a commitment to begin work, not to browse; `--confirm` is available when that distinction matters for a specific ticket.
- **[Risk]** A flat numeric estimate threshold doesn't account for differing units (points vs. hours) across providers/projects. → **Mitigation**: documented as a simplifying default; listed as an open question rather than a blocker.
- **[Risk]** Letting the subagent perform provider write calls and `git worktree add` autonomously (in the no-gate path) increases the blast radius of a wrong heuristic call. → **Mitigation**: the gate conditions are conservative and already-proven (WIP check is unchanged; scope-width heuristic is reused as-is); the action is always reported after the fact, never silent.
- **[Risk]** Worktrees accumulate on disk with no cleanup path yet. → **Mitigation**: explicitly deferred; tracked in Open Questions so it isn't lost.
- **[Risk]** A recurring `/loop` watch left running on a PR that's abandoned (never merged or closed) polls indefinitely. → **Mitigation**: the user can stop any `/loop` manually; a future change could add a max-tick or max-age cutoff if this proves to be a real problem.
- **[Risk]** Per-PR state files (`.project/pr-watch/<pr-number>.yaml`) are never cleaned up after the watch ends. → **Mitigation**: low cost (one small file per PR); explicitly out of scope for this change, same as worktree cleanup.
- **[Risk]** **BREAKING**: anyone relying on `start` always asking before switching branches gets a worktree instead, in a new sibling directory. → **Mitigation**: called out explicitly in the proposal as a breaking change; `--no-branch` remains available for those who want neither action.

## Migration Plan

No data migration — this is a behavior change to `SKILL.md`'s MODE: start section plus a delta to the `targeted-ticket-start` spec. No new required config fields, so existing `.project/config.yaml` files keep working unchanged. Rollback is reverting the SKILL.md section; no state is persisted that would need un-migrating.

## Open Questions

- Should the estimate threshold become a configurable `.project/config.yaml` field once real usage shows the hardcoded default (`5`) is wrong for a given project's point scale or unit?
- Who owns worktree lifecycle — does `ship` remove the worktree after a successful PR, does `openspec-apply-change` need to `cd` into it, or does cleanup stay manual? This needs its own change once `start`'s worktree behavior has been used for a while.
- Should `next` mode's output (which currently suggests `/project-management start TICK-42`) say anything differently now that `start` acts immediately rather than waiting for a second confirmation?
