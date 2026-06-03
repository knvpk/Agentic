## Purpose
Defines the help mode for the project-management skill, providing a grouped command index and mode-specific sub-command reference. Help is intercepted before Query Normalization runs.

## Requirements

### Requirement: Skill provides a help mode that lists all available commands
The skill SHALL expose a `help` mode that is reachable before Query Normalization runs. When invoked with no argument, it SHALL output a grouped command index covering all modes, a config status line, and an init prompt if the project is not configured.

#### Scenario: General help output
- **WHEN** user says "help", "?", "what can you do", "commands", or "list commands"
- **THEN** skill outputs a grouped table of all modes (SETUP, TICKETS, SPRINTS, DAILY WORKFLOW categories)
- **AND** skill appends a one-line config status if `.project/config.yaml` exists

#### Scenario: Config status shown when initialized
- **WHEN** `.project/config.yaml` is present and `help` is invoked
- **THEN** output includes `Current: provider={name} | sprint={active_sprint.name or "none"}`

#### Scenario: Init prompt shown when not initialized
- **WHEN** `.project/config.yaml` is absent and `help` is invoked
- **THEN** output includes `⚠ Not initialized — run: /project-management init`

#### Scenario: Help requires no MCP calls
- **WHEN** help mode runs
- **THEN** no provider MCP tools are called

### Requirement: Skill provides mode-specific help when a mode name is given
The skill SHALL accept `help <mode>` and output sub-commands, trigger phrases, and at least one example for the named mode.

#### Scenario: Mode-specific help for sprint
- **WHEN** user says "help sprint"
- **THEN** output lists sprint sub-modes (plan, review, retro, close, create, milestone, labels) with one-line descriptions and example trigger phrases

#### Scenario: Mode-specific help for ticket
- **WHEN** user says "help ticket"
- **THEN** output lists ticket sub-modes (new, update, link, list) with one-line descriptions and example trigger phrases

#### Scenario: Mode-specific help for unknown mode name
- **WHEN** user says "help <unrecognised-name>"
- **THEN** skill outputs `Unknown mode: <name>. Valid modes: init, docs, ticket, sprint, next, start, status, standup, backlog, bulk`

#### Scenario: Mode-specific help requires no MCP calls
- **WHEN** help <mode> runs
- **THEN** no provider MCP tools are called

### Requirement: Help trigger phrases are intercepted before Query Normalization
The skill SHALL check for help triggers before running Query Normalization. Help triggers SHALL NOT pass through the normalization step.

#### Scenario: "help" does not route to ticket list
- **WHEN** user says "help"
- **THEN** skill routes to help mode, not to `ticket → list`

#### Scenario: "?" does not route to ticket list
- **WHEN** user says "?"
- **THEN** skill routes to help mode, not to `ticket → list`
