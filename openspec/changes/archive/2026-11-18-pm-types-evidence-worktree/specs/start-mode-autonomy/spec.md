## MODIFIED Requirements

### Requirement: Skill evaluates a single combined gate before transitioning or branching
Before transitioning a ticket to `in-progress` or creating its branch/worktree, the skill SHALL evaluate four conditions: WIP limit would be exceeded, the scope-width signal fires against the ticket's title+description, the ticket's estimate exceeds the configured threshold (default `5`), or `start.worktree` is `false` and the working tree has uncommitted changes. If ANY condition is true, the skill SHALL ask one combined question before proceeding. If NONE is true, the skill SHALL proceed automatically and report what it did.

#### Scenario: No condition true — auto-proceed
- **WHEN** none of the four conditions are true for a fetched ticket
- **THEN** skill transitions the ticket and creates its branch or worktree without asking, then reports both actions in one summary line

#### Scenario: Scope-width signal alone fires the gate
- **WHEN** the ticket's title+description trips the conjunction, plural-area, or docs-breadth scope-width signal
- **THEN** the gate fires and the skill asks the combined confirmation question, naming "this ticket looks broad in scope" as the reason

#### Scenario: Estimate above threshold fires the gate
- **WHEN** the ticket's estimate field is set to a numeric value greater than `5`
- **THEN** the gate fires and the skill asks the combined confirmation question, naming "this ticket's estimate is large" as the reason

#### Scenario: Missing estimate does not fire the gate by itself
- **WHEN** the ticket has no estimate set (null, empty, or zero)
- **THEN** the missing-estimate condition does NOT contribute to the gate — the gate only fires if another condition independently triggers it

#### Scenario: Dirty tree in in-place mode fires the gate
- **WHEN** `start.worktree` is `false` and `git status --porcelain` is non-empty
- **THEN** the gate fires and the question names "uncommitted changes would carry onto the new branch" as the reason

#### Scenario: Dirty tree is irrelevant in worktree mode
- **WHEN** `start.worktree` is `true` or absent and the working tree has uncommitted changes
- **THEN** the dirty-tree condition does NOT contribute to the gate

#### Scenario: Multiple conditions true — reasons combined in the prompt
- **WHEN** both the WIP limit would be exceeded and the dirty-tree condition is true
- **THEN** the skill asks one combined question naming both reasons, not two separate prompts
