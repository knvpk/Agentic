## Purpose

Defines the shared manifest format and interactive edit command protocol used by both `bulk` mode and the `ticket new` breakdown flow. The manifest is the mandatory human review step before any MCP ticket creation calls are made.

## ADDED Requirements

### Requirement: Manifest displays candidates in a structured table grouped by epic
The manifest table SHALL group rows by epic (derived from the PRD feature area or architecture component group). Within each epic group, rows SHALL be ordered by ticket type: `scaffold` and `migration` first, then `feature`, `task`, `maintenance`, `spike`. Each row SHALL include: row number, check state (✓/✗), title, type, and epic.

#### Scenario: Manifest table structure is correct
- **WHEN** the manifest is shown
- **THEN** each row contains: row number, check mark (✓ for selected, ✗ for unselected), ticket title, type label, and epic group
- **AND** rows are visually grouped under epic headings

#### Scenario: Scaffold tickets appear before feature tickets in the same epic
- **WHEN** the Auth epic contains a scaffold ticket and two feature tickets
- **THEN** the scaffold ticket appears first within the Auth group
- **AND** the feature tickets appear after it

#### Scenario: Possible duplicate rows are unchecked by default
- **WHEN** a candidate is flagged as a possible duplicate of an existing ticket
- **THEN** its check state shows ✗ and the row title includes "⚠ possible duplicate of #<id>"

---

### Requirement: Skill accepts text edit commands to modify the manifest before creation
After displaying the manifest, the skill SHALL accept the following edit commands in any order. Multiple commands can be provided in a single reply, one per line. The manifest SHALL be re-displayed after any edit command, unless the user issues `create`.

| Command | Syntax | Effect |
|---|---|---|
| skip | `skip <n>` | Uncheck row n |
| keep | `keep only <n>,<n>,...` | Uncheck all rows except listed numbers |
| check | `check <n>` | Check (re-select) row n |
| rename | `rename <n> <new title>` | Update title of row n |
| merge | `merge <n>,<n>` | Combine rows into one (first row title kept, prompt for new title) |
| type | `type <n> <type>` | Change ticket type of row n |
| create | `create` | Finalize and create all checked tickets |

#### Scenario: Skip command unchecks a row
- **WHEN** user sends "skip 6"
- **THEN** row 6 check state changes to ✗
- **AND** the updated manifest is re-displayed

#### Scenario: Rename command updates ticket title
- **WHEN** user sends "rename 3 Bootstrap AuthService and JWT middleware"
- **THEN** row 3 title changes to "Bootstrap AuthService and JWT middleware"
- **AND** the updated manifest is re-displayed

#### Scenario: Merge command combines two rows into one
- **WHEN** user sends "merge 4,5"
- **THEN** the skill combines rows 4 and 5 into a single row, keeping row 4's title by default
- **AND** prompts user to confirm or override the merged title before re-displaying

#### Scenario: Invalid edit command shows help
- **WHEN** user sends an unrecognized command like "delete 3"
- **THEN** the skill outputs: "Unknown command. Valid commands: skip, keep only, check, rename, merge, type, create"
- **AND** the manifest is re-displayed unchanged

---

### Requirement: Create command echoes final selection and asks for confirmation before MCP calls
When the user issues `create`, the skill SHALL display the final list of checked ticket titles and count, then ask for one final confirmation before making any MCP API calls.

#### Scenario: Create command shows final confirmation before API calls
- **WHEN** user sends "create"
- **AND** 9 rows are checked
- **THEN** the skill outputs: "Creating 9 tickets: [list of titles]. Confirm? [y/n]"
- **AND** on `y`, begins calling `create_ticket` MCP tool for each checked row
- **AND** on `n`, returns to the manifest for further editing

#### Scenario: Each ticket creation is acknowledged as it completes
- **WHEN** tickets are being created sequentially
- **THEN** the skill outputs "✓ Created: <title> (#<id>)" for each successful creation
- **AND** "✗ Failed: <title> — <error>" for any that fail, then continues with the rest

---

### Requirement: Manifest header shows source docs and dedup status
The line immediately above the manifest table SHALL state the number of candidates, source doc files, and dedup status.

#### Scenario: Manifest header with successful dedup
- **WHEN** dedup completed successfully
- **THEN** header reads: "Found N ticket candidates from <file list> (dedup: M existing tickets checked)"

#### Scenario: Manifest header with skipped dedup
- **WHEN** dedup was skipped due to MCP failure
- **THEN** header reads: "Found N ticket candidates from <file list> ⚠ Dedup skipped — could not reach tracker"
