## Context

The `project-management` skill has six modes: init, docs, ticket, sprint, next, status. The `next` mode ends with a recommendation plus a two-line manual hint. There is no direct path from "I know which ticket I want to work on" to "get me into it with full project context."

The `issue-explore` skill solves a harder problem: detecting the provider from scratch (CLI/token/env heuristics, 5-step detection). `project-management` already has a configured provider in `.project/config.yaml`, making the start flow significantly simpler.

## Goals / Non-Goals

**Goals:**
- Add a `start <ticket-id>` mode that accepts any ticket reference format and loads the ticket into opsx:explore with full project doc context
- Reuse all existing machinery: Context Fallback Chain, state_mapping, MCP prefix from config
- Update `next` mode output hint to a single `/project-management start <id>` call

**Non-Goals:**
- Re-implementing issue-explore's full provider-detection heuristics (provider is already known)
- Supporting ticket IDs from a different provider than the one configured in `.project/config.yaml`
- Replacing issue-explore; this is a project-context-aware peer

## Decisions

### D1: New top-level mode (`start`) rather than overloading `next`

`next` is pure recommendation — no arguments, fully algorithmic. Overloading it with an optional ID argument conflates two distinct intents. A new `start` mode keeps each mode single-responsibility and matches the pattern of the rest of the skill (each mode name is a verb that stands alone).

**Alternatives considered**: `next TICK-42` as an overloaded form — rejected because it muddies the routing table and breaks the skill description's "algorithmic, no user input" invariant for `next`.

### D2: Reuse Context Fallback Chain verbatim

The same chain used in `ticket new` applies here: prd.md → architecture.md → database.md → tools.md → local src → context_repos. Only relevant sections are included. This gives the exploration session the same project-doc awareness that ticket creation has — no new chain logic needed.

### D3: State transition only for `todo` → `in-progress`, with confirmation

- `todo`: ask once ("Move to in-progress? [y/n]") — intent to start is implied
- `in-progress`: silent no-op — already started
- `backlog`: warn ("This ticket is not in the active sprint. Continue anyway? [y/n]")
- `done`/`in-review`: warn and continue — user may want to explore a completed ticket

**Alternatives considered**: Always ask regardless of state — rejected as noisy for the common case.

### D4: Branch creation is opt-in via the same branching detection as issue-explore

Reuse the gitflow/three-branch/single-branch detection. Present the derived branch name and ask for confirmation before touching git. `--no-branch` flag skips entirely.

### D5: Delegate to opsx:explore (not opsx:ff) as the terminal step

`start` is for exploration before implementation — matches the `issue-explore` pattern. `opsx:ff` is for when the user already knows they want to fast-forward to tasks. After exploration, `opsx:ff` or `opsx:apply` are natural next steps the user can choose.

## Risks / Trade-offs

- **Skill length**: Adding a full new mode section increases SKILL.md size. Mitigated by keeping the mode concise — it reuses existing sections (Context Fallback Chain, state_mapping) by reference.
- **Ticket ID parsing ambiguity**: A bare number like `42` is ambiguous without a project key prefix. Mitigation: if the configured provider is GitHub/GitLab, treat as issue number in the active repo. If Jira, require full key format and tell the user.

## Open Questions

- None blocking implementation. The `--no-branch` flag behavior is inherited directly from issue-explore's Step 5 design.
