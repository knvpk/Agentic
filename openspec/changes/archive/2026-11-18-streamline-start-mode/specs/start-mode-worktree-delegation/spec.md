## ADDED Requirements

### Requirement: Ticket fetch and enrichment run in a spawned subagent
The skill SHALL spawn a fresh, non-context-inheriting subagent to perform ticket fetch, comment ranking, code cross-reference scanning, linked-issue lookup, and Context Fallback Chain resolution. The subagent SHALL return only the assembled context block, the gate evaluation result, and (when applicable) the worktree path to the main thread — not the intermediate tool-call trace.

#### Scenario: Main thread receives only the bounded result
- **WHEN** start mode is invoked for TICK-42
- **THEN** the fetch, ranking, scanning, and doc-context steps run inside a spawned subagent, and the main thread's visible output is limited to the subagent's returned context block and summary

#### Scenario: Subagent has no access to prior conversation
- **WHEN** the subagent is spawned for a ticket fetch
- **THEN** it is given only the ticket reference and the resolved `.project/config.yaml` values it needs — not the user's prior conversation history

### Requirement: Subagent performs mutations only when the gate does not fire
When the combined gate (see `start-mode-autonomy`) evaluates to "no condition true," the subagent SHALL also perform the state transition call and the worktree/branch creation itself before returning. When the gate fires, the subagent SHALL perform no mutation and SHALL return the proposed action and gate reason for the main thread to confirm with the user.

#### Scenario: No-gate path mutates inside the subagent
- **WHEN** the gate does not fire for TICK-42
- **THEN** the spawned subagent calls `update_ticket` and creates the worktree itself, returning the completed summary to the main thread

#### Scenario: Gated path defers mutation to the main thread
- **WHEN** the gate fires for TICK-42
- **THEN** the subagent returns without calling `update_ticket` or creating any worktree, and the main thread asks the user before performing either action

### Requirement: Branch creation is always a git worktree, never a checkout-in-place switch
When branch creation is not suppressed by `--no-branch`, the skill SHALL create the branch via `git worktree add`, in a sibling directory named from the repo and ticket, rather than switching branches in the current checkout.

#### Scenario: Worktree path derived from repo and ticket
- **WHEN** TICK-42's branch is `feature/TICK-42-oauth-login`
- **THEN** the worktree is created at a sibling path such as `../{repo}-TICK-42-oauth-login`, leaving the current checkout's branch untouched

#### Scenario: --no-branch skips worktree creation entirely
- **WHEN** user passes `--no-branch`
- **THEN** no worktree or branch is created, and the main checkout is left untouched — same as before this change

### Requirement: Worktree path is carried forward in the context block
The assembled context block passed to `opsx:explore` SHALL include the worktree path when one was created, or indicate its absence when branch/worktree creation was skipped or declined.

#### Scenario: Context block includes worktree path
- **WHEN** a worktree was created for TICK-42
- **THEN** the context block's repository section includes the worktree path alongside the branch name and base branch

#### Scenario: Context block omits worktree path when skipped
- **WHEN** `--no-branch` was passed or the user declined branch/worktree creation at the gate
- **THEN** the context block's repository section has no worktree path entry
