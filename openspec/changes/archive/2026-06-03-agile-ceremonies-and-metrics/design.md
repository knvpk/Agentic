## Context

The project-management skill (`skills/project-management/SKILL.md`, ~72KB) provides sprint management, backlog generation, ticket CRUD, and a daily next-ticket recommendation. It supports GitHub, GitLab CE/EE, Jira, and Plane via a provider-adapter pattern. Sprint metadata lives in `.project/config.yaml`; provider capability flags are declared in `references/providers.json`.

Current gaps: no ceremony modes (planning, review, retrospective, standup), no feedback-loop metrics (velocity history, sprint health), no quality enforcement (Definition of Done, WIP limits), no backlog estimation tooling.

All provider write operations follow the established GitLab Write Path Resolution pattern (MCP → glab → REST). New write operations in this change follow the same chain.

## Goals / Non-Goals

**Goals:**
- Add `sprint plan`, `sprint review`, `sprint retro`, `sprint close` sub-modes
- Add a `standup` mode for daily updates
- Add a `backlog refine` mode for estimation and DoR review
- Add velocity tracking (story points completed per sprint) via `velocity_log` in config
- Enhance `status` with sprint health signal and projected burndown indicator
- Add DoD enforcement on `ticket update → done`
- Add WIP limit check on `ticket update → in-progress` and `start`
- Add three optional config keys: `wip_limit`, `definition_of_done`, `velocity_log`

**Non-Goals:**
- Capacity planning (no person-hour × velocity = sprint capacity math)
- True per-day burndown chart (requires daily data collection)
- Linked PR as a DoD criterion (too provider-specific for v1)
- Team-level velocity aggregation

## Decisions

### 1. velocity_log lives in `.project/config.yaml`

Alternatives considered:
- **pm-meta issue**: cross-repo accessible but requires active pm-meta (only guaranteed on GitLab CE) and an extra API call per sprint close.
- **Separate `.project/velocity.json`**: clean separation but adds a file to manage and read.

Decision: append to `velocity_log` array in `.project/config.yaml`. Consistent with `active_sprint` storage. Multi-repo `status` already reads sibling configs, so velocity history is accessible without extra infrastructure.

### 2. Burndown is projected (single-point), not historical (per-day)

True burndown needs daily story-point snapshots — requiring a background daemon. The skill runs on-demand.

Decision: compute a single projected progress indicator per `status` invocation:
```
expected_done = (days_elapsed / sprint_days_total) × total_committed_points
actual_done   = sum of estimates on done tickets
health        = on-track (≥90% of expected) | at-risk (70–89%) | off-track (<70%)
```
Display: `Sprint health: ▓▓▓▓░░░░ 12/21 pts (57%) · AT-RISK — 5 days left`

### 3. DoD gate is warn-and-confirm with `--force` bypass

Hard-blocking breaks hotfix workflows. Decision: when `definition_of_done` is set in config, the skill checks criteria, lists unmet ones, then asks `Close anyway? [y/n]`. `--force` skips the prompt. State machine is unchanged — tickets can still reach `done`.

Supported v1 criteria: `has_bdd` (description contains at least one `## Scenarios` block), `has_assignee` (ticket has an assignee).

### 4. WIP limit is warn-and-confirm, not a hard block

Same rationale as DoD. Decision: when `wip_limit` is set and in-progress count would exceed it, warn with current count and limit, ask `Continue? [y/n]`. No separate `--force` flag needed.

### 5. Retro creates a tracker issue, not a local file

Local files are hard to share and not tracked in sprint context. Decision: `sprint retro` creates a tracker issue with a fixed three-section template (went-well / to-improve / action-items). The issue is created in the backlog (no sprint assignment) with a `retro` label.

### 6. Standup "what I did" uses current in-review/done proxy

Fetching per-ticket activity history requires N+1 API calls and is not uniformly available across providers. Decision: "what I did" = tickets assigned to current user currently in `in-review` or `done` state in the active sprint. Zero extra API calls beyond the sprint ticket fetch already done.

## Risks / Trade-offs

- **Story points not always set** → health and velocity show `N/A`. Mitigated: warn if capacity is empty at `sprint create` time (non-blocking).
- **Sprint close idempotency** → running `sprint close` twice duplicates a `velocity_log` entry. Mitigation: check for existing entry with matching sprint label/id before appending.
- **Provider sprint-close variance** → GitHub closes milestone, GitLab CE clears config only, GitLab EE closes iteration, Jira completes sprint, Plane closes cycle. Each path follows the existing provider capability matrix.
- **Retro issue noise** → a retro ticket per sprint may clutter backlog. Accepted trade-off; users can triage or use a `retro` label filter.
- **Standup accuracy** → tickets moved back from done to todo after completion won't appear. Known limitation; standup output footer notes this.

## Migration Plan

All changes are additive. No existing behaviour changes:
1. New modes and sub-modes added to `SKILL.md` — existing modes untouched.
2. DoD and WIP guards are no-ops when the config keys are absent.
3. `config.schema.json` gains three new optional properties — existing configs validate without change.

Rollback: revert `SKILL.md`; configs with new keys are harmless to the previous skill version.

## Open Questions

- Should `sprint plan` auto-derive the sprint start date from `sprint_length_days`, or always ask? (Assumption: auto-derive from today, user can override.)
- Should `velocity_log` entries include ticket IDs or aggregated points only? (Assumption: aggregated only — ticket IDs would bloat config for long-running projects.)
