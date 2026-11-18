## ADDED Requirements

### Requirement: PR body includes an Evidence section and no session URL line
The PR body SHALL consist of the one-sentence summary, the `Closes` line when a ticket ID is known, and an `## Evidence` section produced per the `ship-evidence` capability. The hard-coded session URL line SHALL NOT be included.

#### Scenario: PR body contains Evidence
- **WHEN** `ship` creates a PR
- **THEN** the body contains an `## Evidence` section, even when it only reads `No evidence captured: {reason}`

#### Scenario: Session URL absent
- **WHEN** `ship` creates a PR
- **THEN** the body does not contain a `claude.ai/code/session` line

### Requirement: Confirmation step shows the evidence plan
Step 4 SHALL display the resolved evidence plan beneath the proposed commit and before `Proceed?`, so the user can abort before images or links are pushed.

#### Scenario: Aborting after seeing the plan
- **WHEN** the user answers `n` after the evidence plan is shown
- **THEN** nothing is committed, pushed, or committed to `pr-evidence`
