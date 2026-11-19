## ADDED Requirements

### Requirement: start creates the change shell before invoking explore
After the pre-flight gate resolves and the branch or worktree exists, `start` SHALL create an OpenSpec change named `<ticket-id>-<slug>` and write `linked_issue` (provider, project_ref, id, url) and `base_ref` (HEAD sha) into its `.openspec.yaml` before invoking `opsx:explore`. The `archive-ticket-sync` `linked_issue` schema is unchanged.

#### Scenario: Change exists before explore begins
- **WHEN** `start TICK-42` completes the gate and branch creation
- **THEN** `openspec/changes/TICK-42-<slug>/.openspec.yaml` exists with `linked_issue.id: "42"` and `base_ref` set, and only then is `opsx:explore` invoked

#### Scenario: Gate declined still creates the change shell
- **WHEN** the user answers `n` to the pre-flight gate
- **THEN** the change shell is still created (without branch/worktree), so exploration is anchored to the ticket

#### Scenario: Existing change for the ticket is reused
- **WHEN** `start TICK-42` runs and a non-archived change with `linked_issue.id: "42"` already exists
- **THEN** no second change is created and the existing change is resumed

### Requirement: Explore invoked from start ends with a structured verdict
The prompt `start` sends to `opsx:explore` SHALL require the session to end by writing a `## Verdict` block (`ready` or `needs-input`) and an `## Assumptions` section to the change's `design.md`. When the verdict is `needs-input`, it SHALL also write an `## Open Questions` section.

#### Scenario: Ready verdict
- **WHEN** explore concludes with no blocking questions
- **THEN** `design.md` contains `## Verdict` with `ready` and any non-blocking uncertainty listed under `## Assumptions`

#### Scenario: Missing verdict is re-prompted once
- **WHEN** the explore session ends and `design.md` has no `## Verdict`
- **THEN** `start` re-prompts for the verdict once and does not proceed to implementation until one exists

### Requirement: A question is blocking only if its answer changes scope, design, or a spec scenario
The skill SHALL define a question as blocking only when its answer would change scope, design, or a spec scenario. All other uncertainty SHALL be recorded as an explicit assumption rather than an open question.

#### Scenario: Non-blocking uncertainty becomes an assumption
- **WHEN** explore is unsure about a detail whose answer would not alter scope, design, or any scenario
- **THEN** it is written under `## Assumptions` and the verdict may still be `ready`

#### Scenario: Scope-changing unknown is blocking
- **WHEN** explore cannot tell whether the ticket includes a second user role, which would add scenarios
- **THEN** it is listed under `## Open Questions` and the verdict is `needs-input`

### Requirement: needs-input stops the ticket and is resumable
On a `needs-input` verdict, the skill SHALL stop the ticket's pipeline, post the blocking questions as one comment on the ticket via the provider write path, and set `status: awaiting-answers` in the change's `.openspec.yaml`. Re-running `start <ticket>` SHALL resume from that state.

#### Scenario: Stop with questions recorded
- **WHEN** the verdict is `needs-input`
- **THEN** the questions are in `design.md`, one ticket comment contains only the blocking questions, `.openspec.yaml` has `status: awaiting-answers`, and no implementation begins

#### Scenario: Resume after answers
- **WHEN** the user re-runs `start TICK-42` and the matching change has `status: awaiting-answers`
- **THEN** the skill performs no second state transition or branch creation, folds the user's or ticket's new answers into `design.md`, re-evaluates the verdict, and clears `awaiting-answers` when it becomes `ready`
