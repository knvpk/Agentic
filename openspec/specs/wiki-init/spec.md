# wiki-init

## Purpose

Defines the initialisation workflow for the vibe-wiki skill: creating the directory structure, emitting a provider schema document, and generating a config template when none exists.

## Requirements

### Requirement: Wiki initialisation creates directory structure
On `wiki init`, the skill SHALL create the full wiki directory tree under `wiki.root` as defined in `vibe_wiki.config.yaml`: `concepts/`, `sources/`, `authors/`, `tools/`, `workflows/`, `terms/`, `raw/`. It SHALL copy starter files (`index.md`, `log.md`) if they do not already exist. It SHALL NOT overwrite existing files.

Affected files: `SKILL.md` (vibe_wiki), `assets/starter/raw/.gitkeep`

#### Scenario: First-time init on empty directory
- **WHEN** the user runs `wiki init` and `wiki.root` is empty or does not exist
- **THEN** the skill creates all subdirectories (`concepts/`, `sources/`, `authors/`, `tools/`, `workflows/`, `terms/`, `raw/`), copies `index.md` and `log.md` from `assets/starter/`, and confirms each directory created

#### Scenario: Init on partially-existing wiki
- **WHEN** the user runs `wiki init` and some directories already exist
- **THEN** the skill creates only missing directories and files, skips existing ones with a note, and does not overwrite any content

### Requirement: Wiki init emits provider-specific schema document
On `wiki init`, the skill SHALL read the `provider` key from `vibe_wiki.config.yaml` and emit the appropriate schema document — `CLAUDE.md` for `claude-code`, `AGENTS.md` for `codex` — in `wiki.root`. The schema document SHALL include: wiki structure conventions, node types, ingest workflow, query workflow, and lint workflow. It SHALL reference provider-correct tool names.

Affected files: `SKILL.md` (vibe_wiki), `providers/claude-code.md`, `providers/codex.md`

#### Scenario: Claude Code provider
- **WHEN** `provider: claude-code` is set and user runs `wiki init`
- **THEN** `CLAUDE.md` is written to `wiki.root` using the `providers/claude-code.md` fragment; tool names reference `Read`, `Write`, `WebFetch`, `Glob`

#### Scenario: Codex provider
- **WHEN** `provider: codex` is set and user runs `wiki init`
- **THEN** `AGENTS.md` is written to `wiki.root` using the `providers/codex.md` fragment; tool names reference `file_search`, `web_search`, `code_interpreter`

#### Scenario: Missing provider key
- **WHEN** `provider` key is absent from `vibe_wiki.config.yaml`
- **THEN** the skill asks the user to choose a provider before proceeding, saves the choice to config, then continues

### Requirement: Wiki init generates config template if absent
If `vibe_wiki.config.yaml` does not exist in the project root, the skill SHALL copy `assets/vibe_wiki.config.template.yaml` and prompt the user to edit it before continuing.

Affected files: `SKILL.md` (vibe_wiki), `assets/vibe_wiki.config.template.yaml` (new)

#### Scenario: No config file present
- **WHEN** the user runs `wiki init` and `vibe_wiki.config.yaml` is not found
- **THEN** the skill copies the template, prints the path, and stops with instructions to edit and re-run
