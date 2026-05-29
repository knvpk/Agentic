## Context

The `project-management` skill currently maps GitLab sprints to GitLab milestones — the same API used for release targets (v1.0, Beta). This is an existing shortcut in `providers.json` where `sprint_proxy: milestone` and `sprint: "create_milestone"` are set identically for both CE and EE variants.

GitLab CE self-hosted does not have native iterations (sprints). Iterations are a GitLab Premium/Ultimate feature. The correct CE-native primitive for time-bounded grouping is scoped labels (`sprint::*`), which have mutual-exclusion semantics — assigning `sprint::2025-W25` automatically removes `sprint::2025-W23` from the same issue.

The existing `SKILL.md` sprint mode and `providers.json` both need to be updated. No new dependencies are introduced — this uses the existing GitLab MCP tool contracts (`create_label`, `list_labels`, `create_issue`, `get_issue`).

## Goals / Non-Goals

**Goals:**
- Sprints on GitLab CE use scoped labels (`sprint::*`), milestones remain exclusively for release targets
- Edition auto-detected at `pm init` via iterations API probe; no manual configuration needed
- Sprint naming convention chosen once at init, stored in config, applied consistently
- Sprint metadata (dates, goal) stored in a GitLab issue in a designated `pm-meta` project; accessible from any repo via MCP without git cloning
- Minimal change surface: only `SKILL.md` sprint/init logic and `providers.json` GitLab CE entry

**Non-Goals:**
- GitLab EE/Premium sprint behavior is unchanged (native iterations remain the preferred path)
- GitHub sprint behavior is unchanged
- Multi-repo sprint views (`status` mode) are not redesigned in this change
- Migrating existing milestone-based sprint data for users who already used the old behavior

## Decisions

### Decision 1: Scoped labels as the CE sprint primitive

**Chosen**: `sprint::` scoped labels (e.g. `sprint::2025-W23`)

**Alternatives considered**:
- Custom milestones with a naming prefix (`[Sprint] Sprint 4`) — rejected because milestones are the thing we're trying to protect from pollution; a naming convention doesn't enforce the semantic contract
- A config file in the repo (`.gitlab/sprints.json`) — rejected because file-based metadata is git-level only; other repos cannot read it without cloning

**Why scoped labels**: GitLab CE supports scoped labels natively. The `::` separator enforces mutual exclusion within a scope — assigning `sprint::2025-W25` automatically removes `sprint::2025-W23`. This is precisely the constraint sprints need (an issue belongs to exactly one sprint at a time). Labels are queryable via API, filterable in the GitLab board UI, and inheritable at group level.

### Decision 2: Sprint metadata in a dedicated GitLab issue

**Chosen**: One GitLab issue per sprint in a `pm-meta` project; label description holds the issue URL

**Alternatives considered**:
- Label description only (store dates as structured text in the 255-char description field) — rejected because capacity, goals, and retrospective notes don't fit; the description is already used for the issue URL FK
- Wiki page per sprint — rejected because wiki pages require a different API and aren't easily machine-parseable or linkable from label descriptions

**Why dedicated issue**: A GitLab issue is a first-class platform object. Its URL is stable, accessible via `mcp__gitlab__get_issue` from any repo regardless of which git repo you're working in, and supports structured body content plus free-form comments for retrospectives. The label description stores only the URL (`https://gitlab.example.com/group/pm-meta/-/issues/42`) — under 255 chars, leaving the issue body for full metadata.

### Decision 3: Group-level labels for cross-repo sprint visibility

**Chosen**: Create sprint labels at the GitLab group level (`POST /groups/:id/labels`)

**Alternatives considered**:
- Project-level labels only — requires creating the same `sprint::*` label in each project separately; they'd be distinct objects
- Sync script on sprint creation — adds external tooling complexity

**Why group-level**: GitLab CE supports group-level labels that are automatically inherited by all projects in the group. One `sprint::2025-W23` label created at group level appears in every project under the group. The skill creates sprint labels at group scope; `pm init` detects the group from the git remote.

### Decision 4: Edition detection via iterations API probe

**Chosen**: Call `list_iterations` (or equivalent) on the group; 404/403 → CE; 200 → EE Premium

**Why**: This is the most reliable signal. The `/api/v4/metadata` endpoint doesn't expose edition. Parsing version strings is fragile. The iterations endpoint exists in Premium/Ultimate and is absent (404) or forbidden (403) in CE. A single safe probe call settles the question permanently at init time.

### Decision 5: Four sprint naming conventions, chosen at init

**Chosen**: `sequential` (1, 2, 3), `year-week` (2025-W23), `year-month-week` (2025-06-W3), `quarterly` (Q2-2025-S1) — default `year-week`

**Why four options**: Teams differ. A small startup might prefer sequential simplicity; enterprise teams may plan by calendar week or quarter. The convention is stored in config and enforced on every sprint label created thereafter — it must not change after the first sprint is created (label names are immutable without migration).

## Risks / Trade-offs

- **Convention lock-in** → Mitigation: warn at init that the convention cannot easily be changed after sprints are created; document a migration procedure in references/gitlab.md
- **Group-level label API requires group access** → Mitigation: if the MCP token lacks group-level write access, fall back to project-level labels with a warning; note the cross-repo limitation
- **pm-meta project must exist before sprint creation** → Mitigation: `pm init` creates it automatically if absent (via `mcp__gitlab__create_project`); if creation fails (permissions), fall back to using a dedicated issue in the current project
- **Existing CE users with milestone-based sprints** → No migration; old milestone data is untouched; new sprints use labels going forward. Users must manually close old milestone "sprints" and re-create via the new flow

## Migration Plan

No data migration required. The change is additive:
1. `providers.json` GitLab CE entry gains new fields; existing fields retained for backward-compat reading
2. `SKILL.md` logic branches on `config.sprint_proxy`; projects without the new field continue using milestone behavior (old behavior preserved until `pm init --probe` is re-run)
3. Re-running `pm init --probe` on an existing project re-detects edition and writes `sprint_proxy: label` for CE — at that point new sprint creates use labels, old milestones remain as-is

## Open Questions

- Should the `pm-meta` project be created automatically at init, or prompt the user to create it manually? (Current decision: auto-create via MCP if the user has project creation rights; prompt if not)
- Should the skill sync sprint labels to sibling repos' project-level label lists, or rely on group-level inheritance? (Current decision: group-level only; project-level sync is deferred)
