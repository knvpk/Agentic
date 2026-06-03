## Why

The `project-management` skill has 10 modes and dozens of sub-commands, but no help surface — there is no way to discover what the skill can do without reading a 2000-line SKILL.md. New users have no onboarding entry point, and experienced users cannot quickly recall trigger phrases or sub-modes without guessing.

## What Changes

- Add a `help` mode to the `project-management` skill
- Route "help", "help `<mode>`", "?", "what can you do", "commands", and "list commands" to the new mode
- `help` (no argument) outputs a grouped command index with a live config status line
- `help <mode>` outputs sub-commands, trigger phrases, and examples for the named mode
- Guard for uninitialized state: if `.project/config.yaml` is absent, append a prompt to run `init`

## Capabilities

### New Capabilities

- `pm-help-command`: Help mode for the project-management skill — command index, mode-specific detail, and config status display

### Modified Capabilities

- `query-normalization`: The "help" / "?" triggers must be caught **before** normalization (normalization maps "show" → list; "help" must not be swallowed by that layer)

## Impact

- `skills/project-management/SKILL.md` — two additive edits: one row in the Mode Routing table, one new `## MODE: help` section
- No existing modes are modified
- No provider MCP calls required by the help mode
- No config changes
