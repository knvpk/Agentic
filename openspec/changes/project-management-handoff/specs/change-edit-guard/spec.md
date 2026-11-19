## ADDED Requirements

### Requirement: Edits on a ticket branch require a linked change
The skill SHALL provide a script `scripts/require-change.sh`, intended for a PreToolUse hook on `Edit`, `Write` and `NotebookEdit`, that blocks the call when the current branch contains a ticket id and no non-archived `openspec/changes/*/.openspec.yaml` has a matching `linked_issue.id`.

#### Scenario: Edit blocked without a change
- **WHEN** the branch is `feature/TICK-42-oauth-login` and no active change has `linked_issue.id: "42"`
- **THEN** the script exits non-zero with a message telling the user to run explore or create a change first

#### Scenario: Edit allowed with a linked change
- **WHEN** the same branch has an active change with `linked_issue.id: "42"`
- **THEN** the script exits zero and the edit proceeds

#### Scenario: Archived changes do not satisfy the guard
- **WHEN** the only matching change is under `openspec/changes/archive/`
- **THEN** the edit is blocked

### Requirement: The guard never blocks artifact writes or non-ticket branches
The guard SHALL allow edits to paths under `openspec/changes/` and SHALL do nothing on branches with no ticket id.

#### Scenario: Writing change artifacts is allowed
- **WHEN** the target path is `openspec/changes/TICK-42-oauth-login/proposal.md` and no change is yet linked
- **THEN** the script exits zero

#### Scenario: Non-ticket branch is unaffected
- **WHEN** the branch is `main` or has no `[A-Z]+-\d+` / numeric ticket id
- **THEN** the script exits zero

### Requirement: Guard installation is opt-in and documented
The skill SHALL document the settings snippet that wires the script as a PreToolUse hook, and SHALL NOT modify user or project settings itself.

#### Scenario: Documented snippet
- **WHEN** a user reads the skill's `start` section
- **THEN** it contains the hook configuration to add, and `start` never writes to settings files
