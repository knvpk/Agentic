## Context

The `project-management` skill (at `skills/project-management/SKILL.md`) has 10 modes and dozens of sub-commands discoverable only by reading a 2000-line instruction file. The skill's Query Normalization layer currently runs on every input before mode routing. "help" and "?" are not reserved words — they pass through normalization, where "show" maps to "list" and ambiguous input defaults to `ticket → list`. If "help" reaches normalization, it would silently route to `ticket → list`, showing a confusing ticket board instead of help content.

The only additive change needed is:
1. A first-class pre-normalization intercept for help triggers
2. A new `## MODE: help` section in `SKILL.md`

## Goals / Non-Goals

**Goals:**
- Users can type "help" (or "?", "what can you do", "commands") and get a grouped command index
- Users can type "help `<mode>`" (e.g. "help sprint") and get sub-commands + trigger phrases for that mode
- General help includes a one-line config status (provider, active sprint) and an init prompt if unconfigured
- No MCP calls are made by the help mode

**Non-Goals:**
- Interactive tutorial or onboarding wizard
- Changing how any existing mode behaves
- Provider-specific help content
- Help for the init wizard itself (it's a guided Q&A, not a sub-command surface)

## Decisions

### Decision 1: Intercept before Query Normalization

**Choice**: Add a pre-normalization guard — check for help triggers before the normalization step runs.

**Rationale**: Normalization maps "show" → list intent. "help" contains no intent verb and would fall through to the "ambiguous → ticket list" default. Intercepting first keeps normalization clean (no special-casing inside it) and ensures help is always reachable regardless of phrasing.

**Alternative considered**: Add "help" as an intent verb inside normalization. Rejected — this bleeds help-specific logic into the normalization layer, which is shared across all modes.

### Decision 2: Two variants — general and mode-specific

**Choice**: `help` (no arg) → grouped index; `help <mode>` → mode detail.

**Rationale**: General help gives orientation; mode-specific help provides depth on demand. The `<mode>` argument is parsed as the word immediately after "help" in the input.

**Alternative considered**: Always show general help and let the user navigate. Rejected — mode-specific help is the most common need for experienced users who remember the mode but not its sub-commands.

### Decision 3: Config-aware status line in general help

**Choice**: If `.project/config.yaml` exists, append `Current: provider={name} | sprint={active_sprint.name or "none"}` to the general help output. If absent, append `⚠ Not initialized — run: /project-management init`.

**Rationale**: Confirms whether the skill is configured at a glance. Cheap — just a config file read, no MCP call.

**Alternative considered**: Always show the status line regardless. Accepted as-is — config read is trivial.

### Decision 4: Mode-specific help sourced from known SKILL.md structure

**Choice**: The help mode has a hardcoded summary per mode (not generated dynamically from SKILL.md). Each entry includes: one-line description, sub-commands (if any), and two example trigger phrases.

**Rationale**: The SKILL.md structure is stable and the mode list is fixed. Dynamically parsing SKILL.md would add fragile text extraction logic. The help content is short enough to maintain inline.

**Maintenance implication**: When a new mode or sub-mode is added to the skill, the help section must also be updated. This is acceptable — the help section is a deliberate editorial summary, not a mirror.

## Risks / Trade-offs

- **Help content drift** → New modes added to the skill without updating the help section will be invisible to users. Mitigation: note this explicitly in the `## MODE: help` section header as a maintenance note for contributors.
- **Pre-normalization intercept order** → If the mode routing table is read sequentially, the help guard must appear at the very top, before the normalization prose. Mitigation: add it as a dedicated subsection "Pre-routing intercepts" before the Query Normalization section.

## Open Questions

None — the design is fully constrained by the single-file nature of the skill and the requirement to make no MCP calls.
