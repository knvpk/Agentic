## Why

Teams using Claude Code lack a unified, provider-agnostic way to manage project artefacts (PRD, architecture, database docs) and ticket lifecycles within the same AI-assisted workflow. The `project-management` skill closes that gap by connecting structured local documentation to any major issue tracker and generating rich, opsx-ready ticket briefs — so the path from feature idea to implementation is unbroken.

## What Changes

- New skill `skills/project-management/` following the agentskills.io specification
- New `docs/` layer management (prd.md, architecture.md, database.md) — always local markdown
- Provider-agnostic ticket CRUD via MCP-first adapters (GitHub, GitLab, Jira, Plane)
- Runtime capability detection per provider/plan with graceful label-based fallbacks
- Sprint/milestone/cycle management mapped to a canonical model
- All-relationship support: parent/child, blocks/blocked-by, relates-to
- Algorithmic "next ticket" scheduler reading open ticket titles + dependency graph
- Ticket content generation: requirements (SHALL), BDD scenarios, use cases, non-functional constraints, opsx hand-off hint
- Provider capability probing via MCP at `init`; falls back to user prompt when probing is ambiguous

## Capabilities

### New Capabilities

- `skill-frontmatter`: SKILL.md with valid agentskills.io frontmatter, description, compatibility, and mode routing table
- `docs-management`: Create and update `docs/prd.md`, `docs/architecture.md`, `docs/database.md` as structured local markdown
- `provider-adapter`: MCP-first provider abstraction with `references/providers.json` declaring tool contracts, state mappings, plan variants, and fallback strategies per provider
- `capability-detection`: Runtime API probing at init to detect provider plan features (epics, sprints, relationships); label-based fallbacks when native support absent; results cached in `.project/config.yaml`
- `ticket-management`: Create, update, and link tickets in any supported provider with canonical state machine (backlog → todo → in-progress → in-review → done | blocked) and all relationship types
- `ticket-content-generation`: Generate structured ticket briefs — requirements, BDD scenarios, use cases, non-functional constraints, context links from docs, and `/opsx:ff` hand-off hint — as input for the opsx pipeline
- `sprint-management`: Create and manage sprints (GitHub: milestone proxy; GitLab: milestone; Jira: sprint; Plane: cycle) and sprint metadata (labels, milestones)
- `next-ticket-scheduler`: Algorithmic daily ticket recommendation reading open ticket titles, dependency graph, priority, and WIP state; outputs recommendation with plain-English reasoning

### Modified Capabilities

(none)

## Impact

- New directory: `skills/project-management/`
- New files: `SKILL.md`, `references/providers.json`, `references/github.md`, `references/gitlab.md`, `references/jira.md`, `references/plane.md`
- Runtime artefact: `.project/config.yaml` (per-project, gitignored or tracked by choice)
- Runtime artefact: `docs/prd.md`, `docs/architecture.md`, `docs/database.md` (local, git-tracked)
- MCP dependency: one of `mcp__github__`, `mcp__gitlab__`, `mcp__jira__`, `mcp__plane__` must be configured
- No changes to existing skills or OpenSpec schemas
- Forward-compatible with `issue-explore` skill (shared provider pattern, separate registries)
