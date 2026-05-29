## Purpose
Defines how the skill validates `.project/config.yaml` against `config.schema.json` during `init` and `init --probe` flows, including error surfacing, drift reporting, and the yaml-language-server schema comment written into every generated config file.

## Requirements

### Requirement: init validates assembled config before writing (Step 4.5)
After the API probe (Step 4) and before writing `.project/config.yaml` (Step 5), the `init` mode SHALL assemble the full config object in memory and validate it against `config.schema.json`. If validation fails, the skill SHALL surface all field-level errors and SHALL NOT write the file.

#### Scenario: Valid assembled config proceeds to write
- **WHEN** all collected values produce a config object that passes schema validation
- **THEN** the skill writes `.project/config.yaml` and continues to Step 5

#### Scenario: Invalid assembled config is not written
- **WHEN** the assembled config object has a missing required field or unknown key
- **THEN** the skill outputs each violation (field name + reason) and halts before writing

#### Scenario: Multiple violations are reported together
- **WHEN** the assembled config has two or more schema violations
- **THEN** all violations are listed in a single error block, not sequentially one-at-a-time

### Requirement: init --probe validates existing config before re-probing (Step 1b)
When `init --probe` is invoked, after reading the existing `.project/config.yaml` (Step 1), the skill SHALL validate the file against `config.schema.json` and report any violations before proceeding with the re-probe. Violations are reported but do NOT halt the probe — the probe proceeds regardless to correct the config.

#### Scenario: Drift is reported before probe continues
- **WHEN** the existing config is missing `sprint_convention` (a required GitLab CE field)
- **THEN** the skill outputs `⚠ sprint_convention missing — will re-probe` and continues to Step 2

#### Scenario: Valid existing config produces no drift report
- **WHEN** the existing config passes schema validation
- **THEN** no drift lines are emitted and the probe continues silently

#### Scenario: Unknown key in existing config is flagged as drift
- **WHEN** the existing config contains an unrecognised key (e.g. `old_field: true`)
- **THEN** the skill outputs `⚠ old_field is not a recognised config field — will be removed on re-write`

### Requirement: init writes a yaml-language-server schema comment into every generated config
Every `.project/config.yaml` written by `init` SHALL begin with the comment:
```
# yaml-language-server: $schema=../skills/project-management/references/config.schema.json
```
The relative path SHALL resolve from the `.project/` directory to the schema file.

#### Scenario: Generated config starts with schema comment
- **WHEN** `init` writes `.project/config.yaml`
- **THEN** line 1 of the file is `# yaml-language-server: $schema=../skills/project-management/references/config.schema.json`

#### Scenario: Schema comment enables editor autocomplete
- **WHEN** a developer opens `.project/config.yaml` in VS Code with the YAML extension
- **THEN** the editor offers autocomplete for valid keys and flags unknown keys inline
