## 1. Shared gate logic

- [x] 1.1 Add a "Shared: Start-Mode Pre-Flight Gate" section to `skills/project-management/SKILL.md` defining the three conditions (WIP limit, scope-width signal, estimate threshold) and the combined question format
- [x] 1.2 Document the scope-width signal's reuse against `ticket.title + ticket.description`, and the docs-breadth component's reuse of the Context Fallback Chain's match count instead of a second scan
- [x] 1.3 Document the default estimate threshold (`5`) and that a missing/unset estimate does not contribute to the gate

## 2. Start mode: subagent delegation

- [x] 2.1 Rewrite MODE: start Steps 1–3 (fetch, comment ranking, code refs, linked issues, Context Fallback Chain) as instructions to spawn a fresh subagent with only the ticket reference and resolved config
- [x] 2.2 Specify the subagent's return contract: context block, gate evaluation result + reason, worktree path (or absence), and a one-line action summary when it mutated
- [x] 2.3 Specify that the subagent performs the state transition and worktree creation itself only when the gate does not fire; otherwise it returns without mutating

## 3. Start mode: gate and worktree behavior

- [x] 3.1 Rewrite Step 4 (state transition) to use the combined gate instead of an unconditional "Move to in-progress? [y/n]" prompt
- [x] 3.2 Rewrite Step 5 (branch creation) to create a `git worktree` at `../{repo}-{ticket-id}-{slug}` instead of checking out the branch in place, gated by the same combined question
- [x] 3.3 Collapse the Step 4 and Step 5c prompts into the single combined question, asked once when the gate fires
- [x] 3.4 Add the `--confirm` flag: forces the gate unconditionally for one invocation; confirm it composes correctly with `--no-branch` (confirm still applies to the transition even when branch/worktree is skipped)
- [x] 3.5 Update Step 6 (context block assembly) to include the worktree path when present, and omit it when branch/worktree creation was skipped or declined

## 4. Help text and routing

- [x] 4.1 Update `help start` (Variant B block) to document the new default (auto-proceed unless gated), the three gate conditions, and the `--confirm` flag
- [x] 4.2 Update MODE: start's opening summary line to reflect that it auto-transitions and auto-branches by default

## 5. Ship mode: PR watch offer

- [x] 5.1 Add the post-PR-creation watch offer to MODE: ship Step 6 (GitHub branch only), with the exact prompt text
- [x] 5.2 Document the `/loop` hand-off: what prompt is passed, and that it re-enters `pr-watch` mode for the created PR number

## 6. pr-watch mode

- [x] 6.1 Add a new `MODE: pr-watch` section to `skills/project-management/SKILL.md` covering one tick: fetch CI status + new comments, compare to stored state, report, update state
- [x] 6.2 Define the state file shape and path (`.project/pr-watch/<pr-number>.yaml`: last-seen CI run ID, last-seen comment ID)
- [x] 6.3 Define the merge/close stop condition and how it signals `/loop` to end (vs. scheduling another tick)
- [x] 6.4 Add `pr-watch` to the help index and `help pr-watch` detail block
- [x] 6.5 Document the GitHub-only scope explicitly in the mode's opening line, so it's clear GitLab pipelines aren't covered yet

## 7. Verification

- [x] 7.1 Trace each scenario in `specs/targeted-ticket-start/spec.md` (MODIFIED), `specs/start-mode-autonomy/spec.md`, and `specs/start-mode-worktree-delegation/spec.md` against the rewritten SKILL.md text to confirm every scenario is satisfied by the instructions as written — caught and fixed a docs-breadth wording drift (file-count vs. section-count) in both the spec and SKILL.md during this pass
- [x] 7.2 Manually walk a no-gate ticket (small, no scope-width signal, low/no estimate) through the rewritten Steps 1–5 and confirm it would auto-proceed with exactly one combined summary line and no prompts
- [x] 7.3 Manually walk a gated ticket (large estimate or scope-width hit) through the same steps and confirm exactly one combined question is asked, covering both transition and worktree creation
- [x] 7.4 Trace each scenario in `specs/ship-mode/spec.md` (ADDED) and `specs/pr-watch/spec.md` against the rewritten MODE: ship and new MODE: pr-watch text
- [x] 7.5 Manually walk one full tick sequence: open PR → first tick (no CI result yet, schedules next) → simulated CI failure (reported, state updated, schedules next) → simulated merge (watch ends via ScheduleWakeup stop:true)
- [x] 7.6 Run `openspec validate streamline-start-mode --strict` and confirm it still passes after any edits made during verification
