## Why

The project-management skill manages sprints and tickets but has no ceremony support, no quality gates, and no feedback-loop metrics. Teams using it have no way to run sprint planning, review, retrospectives, or standups through the skill, and no signal on whether a sprint is on track or velocity is improving.

## What Changes

- **New mode `standup`**: daily standup helper — what I did, what's next, what's blocking me
- **New mode `backlog`** with sub-mode `refine`: walk unestimated / un-BDD'd backlog tickets, prompt for story points and acceptance criteria (DoR gate)
- **New sub-mode `sprint plan`**: show DoR-checked backlog candidates ranked by priority, select tickets to pull into the sprint (no capacity math)
- **New sub-mode `sprint review`**: generate shipped summary from done tickets, show commitment vs. delivered delta
- **New sub-mode `sprint retro`**: prompt for went-well / to-improve / action-items, create structured retro ticket in the tracker
- **New sub-mode `sprint close`**: tally completed story points, append to `velocity_log` in config, mark sprint done in provider, clear `active_sprint`
- **Enhanced `status` mode**: add sprint health percentage, on-track/at-risk/off-track signal, text burndown (points remaining per day), WIP count vs. limit
- **DoD gate on `ticket update → done`**: check configured `definition_of_done` criteria before allowing transition; warn, overridable with `--force`
- **WIP limit check on `ticket update → in-progress` and `start`**: warn when `wip_limit` is exceeded
- **New config keys**: `wip_limit`, `definition_of_done`, `velocity_log`

## Capabilities

### New Capabilities

- `sprint-ceremonies`: sprint plan, review, retro, and close sub-modes with structured outputs and tracker integration
- `standup`: daily standup mode sourcing yesterday's transitions, next-ticket recommendation, and current blockers
- `backlog-refinement`: backlog refine mode walking unestimated tickets for story-point and DoR review
- `agile-metrics`: velocity log, sprint health signal, burndown display, commitment-vs-delivered tracking
- `agile-quality-gates`: Definition of Done enforcement on `→ done` transition, WIP limit enforcement on `→ in-progress`

### Modified Capabilities

- `sprint-management`: adds `plan`, `review`, `retro`, `close` sub-modes; `close` writes `velocity_log`
- `ticket-management`: `update → done` gains DoD gate; `update → in-progress` gains WIP limit check
- `targeted-ticket-start`: `start` mode gains WIP limit check before transitioning ticket to in-progress
- `config-schema`: new keys `wip_limit`, `definition_of_done`, `velocity_log`

## Impact

- `skills/project-management/SKILL.md`: new modes, sub-modes, guards in existing state transitions
- `.project/config.yaml`: three new optional keys (`wip_limit`, `definition_of_done`, `velocity_log`)
- All supported providers (GitHub, GitLab CE/EE, Jira, Plane): retro and review create tracker issues; sprint close marks sprint done via provider-native mechanism
- No breaking changes — all new gates warn by default and are overridable; new config keys are optional
