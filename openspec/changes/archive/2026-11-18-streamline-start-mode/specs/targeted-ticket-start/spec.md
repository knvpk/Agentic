## MODIFIED Requirements

### Requirement: start mode transitions a todo ticket to in-progress with user confirmation
The skill SHALL transition a fetched ticket in `todo` or `backlog` state to `in-progress` automatically, without prompting, unless the combined pre-flight gate (WIP limit, scope-width signal, or estimate threshold — see `start-mode-autonomy`) fires, or the `--confirm` flag was passed. When the gate fires, the skill SHALL ask once, combining the transition decision and the branch/worktree decision into a single question, before performing either. The transition SHALL use `state_mapping` from the active provider config.

#### Scenario: todo ticket transitions automatically when no gate fires
- **WHEN** ticket state is `todo` and none of the gate conditions fire
- **THEN** skill transitions the ticket to `in-progress` without prompting, and reports `✓ TICK-42 → in-progress` as part of the combined summary

#### Scenario: backlog ticket transitions automatically when no gate fires
- **WHEN** ticket state is `backlog` and none of the gate conditions fire
- **THEN** skill transitions the ticket to `in-progress` without prompting, and reports the transition as part of the combined summary

#### Scenario: gated ticket asks a single combined question
- **WHEN** ticket state is `todo` or `backlog` and the gate fires for any reason
- **THEN** skill asks once: `"TICK-42 looks {reason} — transition to in-progress and create its branch anyway? [y/n]"`, covering both the transition and the branch/worktree step

#### Scenario: gated transition declined — continues without state change
- **WHEN** the gate fires and user answers `n`
- **THEN** skill outputs `Transition cancelled — continuing in exploration mode (ticket stays in current state).` and proceeds without any state change or branch/worktree creation

#### Scenario: --confirm flag forces the gate every time
- **WHEN** user runs `/project-management start TICK-42 --confirm`
- **THEN** the combined gate question is asked regardless of WIP, scope-width, or estimate — reproducing the pre-change always-ask behavior for this invocation only

#### Scenario: in-progress ticket requires no prompt and no gate evaluation
- **WHEN** ticket state is already `in-progress`
- **THEN** skill skips the state transition and the gate check entirely, and continues directly to branch/worktree handling

### Requirement: start mode optionally creates a branch using the detected branching strategy
The skill SHALL create a git worktree — not a branch switch in the current checkout — using the same gitflow/three-branch/single-branch base-branch detection logic as before. Worktree creation SHALL happen automatically, without prompting, unless the combined pre-flight gate fires or `--confirm` was passed. Passing `--no-branch` SHALL skip both branch and worktree creation entirely, regardless of gate state.

#### Scenario: Branch name derived from ticket title
- **WHEN** ticket title is "Add OAuth login support"
- **THEN** derived branch name is of the form `feature/PROJ-42-oauth-login-support`

#### Scenario: Worktree created automatically when no gate fires
- **WHEN** no gate condition fires for TICK-42
- **THEN** skill runs `git worktree add ../{repo}-TICK-42-{slug} -b feature/TICK-42-{slug} {base}` without prompting, and includes the worktree path in the combined summary

#### Scenario: Worktree creation included in the single combined gate question
- **WHEN** the gate fires and the user confirms with `y`
- **THEN** skill performs both the state transition and the worktree creation in response to that one confirmation — no second prompt for the branch step

#### Scenario: --no-branch skips both branch and worktree creation
- **WHEN** user invokes `/project-management start TICK-42 --no-branch`
- **THEN** no branch or worktree is created, regardless of gate state, and skill proceeds directly without either

#### Scenario: --confirm flag applies to the worktree step too
- **WHEN** user runs `start TICK-42 --confirm`
- **THEN** the combined gate question, covering both transition and worktree creation, is asked even if no risk heuristic would otherwise fire

### Requirement: start mode applies the WIP limit check before transitioning the ticket to in-progress
The WIP limit check SHALL be one of three inputs to the single combined pre-flight gate defined in `start-mode-autonomy`, evaluated before any prompt is shown or any action is taken — not after an initial confirmation as before. If the WIP limit would be exceeded, the combined gate fires and the user is asked once before either the transition or the worktree/branch creation happens.

#### Scenario: WIP limit alone is sufficient to fire the combined gate
- **WHEN** wip_limit would be exceeded for TICK-42, and neither the scope-width signal nor the estimate threshold applies
- **THEN** the combined gate still fires, and the user is asked the single combined question before any transition or worktree creation

#### Scenario: WIP check skipped when ticket is already in-progress
- **WHEN** ticket fetched by start mode is already in `in-progress` state
- **THEN** no WIP check is performed as part of gate evaluation, since no new in-progress slot is being consumed

#### Scenario: WIP check skipped when wip_limit is absent
- **WHEN** `.project/config.yaml` has no `wip_limit` key
- **THEN** the WIP condition contributes nothing to the gate evaluation — the gate may still fire from scope-width or estimate threshold

#### Scenario: start mode with --no-branch still evaluates the WIP condition for the transition
- **WHEN** user runs `start TICK-42 --no-branch` and wip_limit would be exceeded
- **THEN** the gate still fires for the transition decision — `--no-branch` only suppresses branch/worktree creation, not the transition gate
