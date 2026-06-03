## 1. Config Schema — new optional keys

- [x] 1.1 Add `wip_limit` (optional positive integer) to `config.schema.json`
- [x] 1.2 Add `definition_of_done` (optional array of `has_bdd | has_assignee`) to `config.schema.json`
- [x] 1.3 Add `velocity_log` (optional array of `{sprint, points_committed, points_completed}`) to `config.schema.json`
- [x] 1.4 Verify existing configs still validate after schema additions

## 2. Quality Gates — DoD and WIP enforcement

- [x] 2.1 Add DoD gate helper: evaluate `has_bdd` criterion (check description for `## Scenarios`)
- [x] 2.2 Add DoD gate helper: evaluate `has_assignee` criterion
- [x] 2.3 Insert DoD gate into `ticket update → done` flow (after state machine validation, before provider call); warn + confirm; `--force` bypass
- [x] 2.4 Add WIP limit helper: count current `in-progress` tickets in active sprint via provider fetch
- [x] 2.5 Insert WIP limit check into `ticket update → in-progress` flow (after state machine validation, before provider call); warn + confirm
- [x] 2.6 Insert WIP limit check into `start` mode (after user confirms `→ in-progress`, before provider call)

## 3. Agile Metrics — velocity log and sprint health

- [x] 3.1 Add sprint health computation to `status` mode: derive expected_done, actual_done, health category (on-track / at-risk / off-track)
- [x] 3.2 Render health bar line above state breakdown in `status` output
- [x] 3.3 Add WIP count vs. `wip_limit` line to `status` output (skip silently if `wip_limit` absent)
- [x] 3.4 Add `velocity_log` append logic for `sprint close`: tally done-ticket estimates, check for duplicate entry, write to config

## 4. Sprint Ceremonies — plan, review, retro, close

- [x] 4.1 Add `sprint plan` sub-mode: fetch backlog candidates, rank by priority, show DoR flags, interactive selection, add to sprint
- [x] 4.2 Add `sprint review` sub-mode: fetch done tickets, group by label, compute commitment vs. delivered delta, output shipped summary
- [x] 4.3 Add `sprint retro` sub-mode: prompt for three sections, create structured tracker issue with `retro` label (create label if absent), no sprint assignment
- [x] 4.4 Add `sprint close` sub-mode: tally points, append `velocity_log`, close sprint in provider per provider variant (GitHub: close milestone, GitLab CE: clear config only, GitLab EE: close iteration, Jira: complete sprint, Plane: close cycle), clear `active_sprint` from config
- [x] 4.5 Add intent routing for new sub-modes: "plan sprint", "sprint planning", "sprint plan" → plan; "sprint review", "what shipped" → review; "sprint retro", "retrospective", "retro" → retro; "sprint close", "close sprint", "end sprint", "finish sprint" → close

## 5. Standup Mode

- [x] 5.1 Add `standup` mode: fetch active sprint tickets, filter to current user's in-review/done tickets → "What I did"
- [x] 5.2 Run next-ticket scoring algorithm inline → "What I'll work on"
- [x] 5.3 Fetch blocked tickets in active sprint → "Blockers" section
- [x] 5.4 Output in fixed three-section format with proxy-limitation footer note
- [x] 5.5 Add intent routing for standup: "standup", "daily standup", "stand up", "daily" → standup mode

## 6. Backlog Refinement Mode

- [x] 6.1 Add `backlog refine` sub-mode: fetch unestimated backlog/todo tickets sorted by priority
- [x] 6.2 Present each ticket with context (ID, title, truncated description, labels, relationships)
- [x] 6.3 Check DoR per ticket (non-empty description + at least one label); show `⚠ Not ready` with failing criteria
- [x] 6.4 Prompt for story-point estimate; save to provider on entry; skip on `s`/`skip`
- [x] 6.5 Show session summary at end: `Refined: N estimated, N skipped, N remaining`
- [x] 6.6 Add intent routing: "backlog refine", "refine backlog", "estimate tickets", "grooming" → backlog refine

## 7. Skill Frontmatter Update

- [x] 7.1 Update SKILL.md description field to list the two new modes (`standup`, `backlog refine`) and four new sprint sub-modes (`plan`, `review`, `retro`, `close`)
- [x] 7.2 Update SKILL.md Query Normalization table with new intent verbs for all new modes/sub-modes
