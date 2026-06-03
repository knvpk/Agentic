## ADDED Requirements

### Requirement: standup mode reports what the current user did by showing their in-review and done tickets in the active sprint
The skill SHALL fetch all tickets in the active sprint assigned to the current user (resolved from provider identity), filter to those in `in-review` or `done` state, and display them as "What I did". This is a proxy for recently completed work. The output footer SHALL note that this reflects current state, not literal yesterday's activity.

#### Scenario: In-review and done tickets listed under what I did
- **WHEN** user invokes `standup` and has 2 in-review and 1 done ticket in the active sprint
- **THEN** output lists all 3 under `## What I did`

#### Scenario: No completed work shows clear message
- **WHEN** user has no in-review or done tickets in the active sprint
- **THEN** output shows `## What I did\n(nothing in-review or done yet this sprint)`

#### Scenario: Output footer notes proxy limitation
- **WHEN** any standup output is produced
- **THEN** footer reads `Note: "what I did" reflects current ticket states, not a timestamped activity log`

### Requirement: standup mode shows what the current user will work on next using the next-ticket algorithm
The skill SHALL run the same next-ticket scoring algorithm used by `next` mode (WIP continuation → priority → unblocks-others → estimate) and display the top recommendation as "What I'll work on".

#### Scenario: Next ticket recommendation shown under what I'll work on
- **WHEN** an eligible ticket exists in the active sprint
- **THEN** output includes `## What I'll work on` with the recommended ticket ID, title, and one-line reasoning

#### Scenario: No eligible tickets produces a clear message
- **WHEN** all in-sprint tickets are blocked or done
- **THEN** output shows `## What I'll work on\n(no eligible tickets — sprint may be complete)`

### Requirement: standup mode lists current blockers from the active sprint
The skill SHALL fetch all tickets in `blocked` state in the active sprint and display them as "Blockers", including the blocking reason if available from the ticket body.

#### Scenario: Blocked tickets listed with reason
- **WHEN** TICK-42 is blocked with reason "waiting on infra access"
- **THEN** standup shows `TICK-42 — Add OAuth login (blocked: waiting on infra access)`

#### Scenario: No blockers shows clear message
- **WHEN** no in-sprint tickets are in blocked state
- **THEN** output shows `## Blockers\n(none)`

### Requirement: standup mode requires no user input during invocation
The standup output SHALL be fully derived from ticket state. The skill SHALL NOT prompt for input. If `active_sprint` is absent, it SHALL output a single error and exit.

#### Scenario: Invocation requires no user interaction
- **WHEN** user runs `/project-management standup`
- **THEN** skill outputs the three sections without any prompts

#### Scenario: Missing active sprint produces an error
- **WHEN** `active_sprint` is absent from `.project/config.yaml`
- **THEN** skill outputs `No active sprint — run sprint create first` and exits

### Requirement: standup output follows a fixed three-section format
The skill SHALL output sections in this order: `## What I did`, `## What I'll work on`, `## Blockers`. Each section SHALL be separated by a blank line.

#### Scenario: Output sections always appear in fixed order
- **WHEN** standup runs successfully
- **THEN** sections appear as: What I did → What I'll work on → Blockers, regardless of content
