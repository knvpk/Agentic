## ADDED Requirements

### Requirement: Skill evaluates a single combined gate before transitioning or branching
Before transitioning a ticket to `in-progress` or creating its branch/worktree, the skill SHALL evaluate three conditions: WIP limit would be exceeded, the scope-width signal fires against the ticket's title+description, or the ticket's estimate exceeds the configured threshold (default `5`). If ANY condition is true, the skill SHALL ask one combined question before proceeding. If NONE is true, the skill SHALL proceed automatically and report what it did.

#### Scenario: No condition true — auto-proceed
- **WHEN** none of the three conditions are true for a fetched ticket
- **THEN** skill transitions the ticket and creates its worktree without asking, then reports both actions in one summary line

#### Scenario: Scope-width signal alone fires the gate
- **WHEN** the ticket's title+description trips the conjunction, plural-area, or docs-breadth scope-width signal (reused from `ticket-breakdown-detection`)
- **THEN** the gate fires and the skill asks the combined confirmation question, naming "this ticket looks broad in scope" as the reason

#### Scenario: Estimate above threshold fires the gate
- **WHEN** the ticket's estimate field is set to a numeric value greater than `5`
- **THEN** the gate fires and the skill asks the combined confirmation question, naming "this ticket's estimate is large" as the reason

#### Scenario: Missing estimate does not fire the gate by itself
- **WHEN** the ticket has no estimate set (null, empty, or zero)
- **THEN** the missing-estimate condition does NOT contribute to the gate — the gate only fires if WIP or scope-width independently trigger it

#### Scenario: Multiple conditions true — reasons combined in the prompt
- **WHEN** both the WIP limit would be exceeded and the scope-width signal fires
- **THEN** the skill asks one combined question naming both reasons, not two separate prompts

### Requirement: Docs-breadth signal reuses the Context Fallback Chain's match count
The docs-breadth component of the scope-width signal SHALL be derived from the number of distinct (file, section) matches already produced by the Context Fallback Chain for the ticket's topic, rather than running a second independent relevance scan.

#### Scenario: Three or more chain matches trigger docs-breadth
- **WHEN** the Context Fallback Chain matches three or more distinct (file, section) pairs for the ticket's topic — whether spread across files or concentrated in one
- **THEN** the docs-breadth signal is considered true for gate evaluation, with no additional scan performed

#### Scenario: Fewer than three chain matches do not trigger docs-breadth
- **WHEN** the Context Fallback Chain matches only one or two (file, section) pairs
- **THEN** the docs-breadth signal is false, though the other two scope-width signals (conjunction, plural-area) are still evaluated independently against the ticket text

### Requirement: --confirm flag forces the gate unconditionally
Passing `--confirm` on a `start` invocation SHALL force the combined gate to fire regardless of the three conditions, reproducing the always-ask behavior for that single invocation only.

#### Scenario: --confirm overrides a would-be auto-proceed
- **WHEN** none of the three gate conditions are true, but the user passed `--confirm`
- **THEN** the skill still asks the combined confirmation question before transitioning or creating the branch/worktree

#### Scenario: --confirm is not persisted
- **WHEN** a `--confirm` invocation completes
- **THEN** the next `start` invocation without `--confirm` evaluates the gate normally — no state is remembered across invocations
