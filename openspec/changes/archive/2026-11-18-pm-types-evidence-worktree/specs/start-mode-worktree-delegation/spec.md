## MODIFIED Requirements

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

## ADDED Requirements

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
