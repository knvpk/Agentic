## Why

The `project-management` skill has grown across three distinct workflow phases that have different invocation frequency, different coupling surfaces, and different cognitive load. Keeping them in one 1,200-line SKILL.md means the full skill is loaded into context every time a user asks "what should I work on next" — a lightweight read operation that doesn't need init logic, MCP setup wizard text, or doc scaffolding templates. More importantly, the three phases have different *owners*: setup runs once per project, core ticket work runs many times per sprint, and the daily workflow (`next → start → explore`) runs every morning. Splitting by phase makes each skill smaller, faster to load, easier to update without risking regressions in the others, and clearer about what it does.

## What Changes

The single `skills/project-management/SKILL.md` is split into three co-located skills, each sharing the existing `references/` folder:

### Skill 1 — `project-management-setup` (new file)

Modes moved: **init**, **docs**

Handles the one-time configuration phase: provider detection, MCP setup wizard, capability probing, canonical state label bootstrap, type-specific label bootstrap, and doc scaffolding. After a project is initialised this skill is rarely invoked again. Moving it out reduces the size of the two frequently-used skills and isolates all MCP setup wizard text and doc template content.

### Skill 2 — `project-management` (trimmed in place)

Modes retained: **ticket**, **sprint**, **bulk**

The core ticket lifecycle — creating, updating, linking, listing tickets, managing sprints and milestones, and generating full backlogs from docs. These three modes share the most logic (canonical state machine, context fallback chain, manifest review, scope-width detection, relationship types) and must stay together. This skill is the largest after the split but is now free of the ~250 lines of setup and scaffolding content.

### Skill 3 — `project-management-workflow` (new file)

Modes moved: **next**, **start**, **status**

The daily rhythm: algorithmic ticket recommendation from the dependency graph, starting a ticket (fetch → enrich → transition → branch → explore), and reading the sprint board. These modes are read-heavy and mostly non-mutating. They share a natural pipeline (`next` recommends, `start` loads). This skill is the thinnest of the three and its `start` mode is the primary bridge into `opsx:explore`.

### Shared logic — `references/shared.md` (new file)

Cross-skill logic extracted to a single reference file that all three skills include:

- Canonical State Machine
- Relationship Types
- Context Fallback Chain
- Scope-Width Detection Signals
- Manifest Review format (table, edit commands, create confirmation)
- Query Normalization (intent verbs + filter grammar)

This mirrors the existing `references/providers.json` pattern — shared contracts live in `references/`, skills reference them by name. No duplication across skill files.

## Capabilities

### New Capabilities

- `shared-reference-layer`: Extracts cross-skill logic (state machine, context fallback, manifest review, scope-width detection, query normalization, relationship types) into `references/shared.md`; all three skills declare a dependency on it in their frontmatter

### Modified Capabilities

- `capability-detection` → moves to `project-management-setup`
- `docs-management` → moves to `project-management-setup`
- `ticket-content-generation` → stays in `project-management`
- `sprint-management` → stays in `project-management`
- `bulk-backlog-generation` → stays in `project-management`
- `next-ticket-scheduler` → moves to `project-management-workflow`
- `start-mode` → moves to `project-management-workflow`
- `sprint-status-view` → moves to `project-management-workflow`

### Routing Entrypoints After Split

| User invokes | Skill loaded |
|---|---|
| `/project-management init` | `project-management-setup` |
| `/project-management docs` | `project-management-setup` |
| `/project-management ticket ...` | `project-management` |
| `/project-management sprint ...` | `project-management` |
| `/project-management bulk` | `project-management` |
| `/project-management next` | `project-management-workflow` |
| `/project-management start TICK-42` | `project-management-workflow` |
| `/project-management status` | `project-management-workflow` |

## Impact

- New file: `skills/project-management/SKILL.md` (trimmed — ticket, sprint, bulk only)
- New file: `skills/project-management-setup/SKILL.md` (init, docs)
- New file: `skills/project-management-workflow/SKILL.md` (next, start, status)
- New file: `skills/project-management/references/shared.md` (extracted shared logic)
- No changes to `references/providers.json`
- No changes to `.project/config.yaml` schema
- No changes to the ticket brief format or manifest format
- No breaking changes for existing configured projects
- Approximate size reduction in core skill: ~40% (removing setup + workflow modes + shared sections now in reference)
