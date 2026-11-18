## Purpose
Defines how `start` mode delegates ticket fetch/enrichment to a spawned subagent and creates branches as git worktrees rather than in-place checkout switches, keeping the main thread's context limited to the assembled result.

## Requirements

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
When branch creation is not suppressed by `--no-branch`, the skill SHALL create the branch according to `start.worktree` in `.project/config.yaml`. When `start.worktree` is `true` or absent, the skill SHALL create the branch via `git worktree add`, in a sibling directory named from the repo and ticket, rather than switching branches in the current checkout. When `start.worktree` is `false`, the skill SHALL create the branch in place with `git checkout -b {branch} {base}` in the current checkout.

#### Scenario: Worktree path derived from repo and ticket
- **WHEN** TICK-42's branch is `feature/TICK-42-oauth-login` and `start.worktree` is absent
- **THEN** the worktree is created at a sibling path such as `../{repo}-TICK-42-oauth-login`, leaving the current checkout's branch untouched

#### Scenario: worktree false creates the branch in place
- **WHEN** `start.worktree: false` and TICK-42's branch is `feature/TICK-42-oauth-login`
- **THEN** the skill runs `git checkout -b feature/TICK-42-oauth-login {base}` in the current checkout and creates no worktree

#### Scenario: --no-branch skips worktree creation entirely
- **WHEN** user passes `--no-branch`, regardless of `start.worktree`
- **THEN** no worktree or branch is created, and the main checkout is left untouched

### Requirement: Worktree path is carried forward in the context block
The assembled context block passed to `opsx:explore` SHALL include the worktree path when one was created, or indicate its absence when branch/worktree creation was skipped or declined.

#### Scenario: Context block includes worktree path
- **WHEN** a worktree was created for TICK-42
- **THEN** the context block's repository section includes the worktree path alongside the branch name and base branch

#### Scenario: Context block omits worktree path when skipped
- **WHEN** `--no-branch` was passed or the user declined branch/worktree creation at the gate
- **THEN** the context block's repository section has no worktree path entry

### Requirement: Init asks whether to use worktrees and stores the answer
Init SHALL ask `Create a separate git worktree for each ticket? [Y/n]` with a hint naming untracked files, running dev servers, and submodules, and SHALL write the answer to `start.worktree`. A config without `start.worktree` SHALL be treated as `true` without re-asking.

#### Scenario: Answer n stored
- **WHEN** the user answers `n` at init
- **THEN** `.project/config.yaml` contains `start: { worktree: false }`

#### Scenario: Missing key defaults to true
- **WHEN** `start` runs on a config with no `start.worktree`
- **THEN** the worktree path is used and the user is not asked

### Requirement: In-place mode omits the worktree path from the context block
When `start.worktree` is `false` and the branch is created, the context block SHALL include the branch name and base branch and SHALL omit the worktree path line.

#### Scenario: No Worktree line in place mode
- **WHEN** a branch was created in place for TICK-42
- **THEN** the context block's repository section has no worktree path entry
