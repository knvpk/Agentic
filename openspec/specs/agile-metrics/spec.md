## Purpose
Defines how the skill computes and displays sprint health signals and velocity metrics to give teams real-time visibility into sprint progress.

## Requirements

### Requirement: Sprint health signal is computed and displayed in status mode
On each `status` invocation, when an active sprint exists and at least one in-sprint ticket has a story-point estimate, the skill SHALL compute sprint health using a projected burndown formula and display a one-line health bar. Health categories: `ON-TRACK` (actual_done ≥ 90% of expected_done), `AT-RISK` (70–89%), `OFF-TRACK` (<70%). When no tickets have estimates the skill SHALL display `Sprint health: N/A (no estimates)`.

```
expected_done = (days_elapsed / sprint_days_total) × total_committed_points
actual_done   = sum of estimates on tickets in done state
```

#### Scenario: On-track sprint shows health bar
- **WHEN** sprint is 50% through time and 55% of points are done
- **THEN** status shows `Sprint health: ▓▓▓▓▓░░░░░ 11/20 pts (55%) · ON-TRACK — 7 days left`

#### Scenario: At-risk sprint shows warning
- **WHEN** sprint is 60% through time and only 45% of points are done
- **THEN** status shows `Sprint health: ▓▓▓▓░░░░░░ 9/20 pts (45%) · AT-RISK — 5 days left`

#### Scenario: Off-track sprint shows alert
- **WHEN** sprint is 80% through time and only 30% of points are done
- **THEN** status shows `Sprint health: ▓▓▓░░░░░░░ 6/20 pts (30%) · OFF-TRACK — 3 days left`

#### Scenario: Health bar not shown when estimates absent
- **WHEN** no in-sprint tickets have story-point estimates
- **THEN** status shows `Sprint health: N/A (no estimates)` instead of the bar

#### Scenario: Health signal appears above the state breakdown
- **WHEN** status is invoked
- **THEN** the sprint health line appears before the `backlog / todo / in-progress / in-review / done / blocked` breakdown

### Requirement: status mode shows WIP count relative to wip_limit when configured
When `wip_limit` is set in config, the status output SHALL include a WIP line showing current in-progress count vs. the limit. If the limit is at or exceeded, it SHALL be flagged.

#### Scenario: WIP within limit shown normally
- **WHEN** wip_limit is 3 and 2 tickets are in-progress
- **THEN** status shows `WIP: 2/3`

#### Scenario: WIP at or over limit shown as warning
- **WHEN** wip_limit is 3 and 3 or more tickets are in-progress
- **THEN** status shows `WIP: 3/3 ⚠ limit reached`

### Requirement: velocity_log entries are immutable once written
Each `velocity_log` entry written by `sprint close` SHALL be treated as an append-only record. If `sprint close` detects an existing entry for the same sprint identifier (`label_name` for CE, `id` for standard), it SHALL skip the write and warn the user.

#### Scenario: Duplicate sprint close skips velocity_log write
- **WHEN** `sprint close` is invoked for `sprint::2025-W23` and an entry with that sprint already exists in `velocity_log`
- **THEN** skill outputs `⚠ velocity_log already has an entry for sprint::2025-W23 — skipping duplicate` and does not modify config

#### Scenario: New sprint appends cleanly
- **WHEN** `sprint close` is invoked and no existing entry matches
- **THEN** the new entry is appended and config is saved

### Requirement: velocity_log entry records sprint identifier, committed points, and completed points
Each entry in `velocity_log` SHALL have the shape `{ sprint: <string>, points_committed: <number|null>, points_completed: <number> }`. `points_committed` SHALL be `null` when the sprint was created without a capacity value.

#### Scenario: velocity_log entry has all three fields
- **WHEN** a sprint with capacity 21 is closed with 18 points done
- **THEN** the new entry is `{ sprint: "sprint::2025-W23", points_committed: 21, points_completed: 18 }`

#### Scenario: velocity_log entry has null committed when capacity was unset
- **WHEN** a sprint was created without a capacity value and is now closed with 13 points done
- **THEN** the new entry is `{ sprint: "sprint::2025-W23", points_committed: null, points_completed: 13 }`
