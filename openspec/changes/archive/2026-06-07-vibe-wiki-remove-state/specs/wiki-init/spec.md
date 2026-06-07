## MODIFIED Requirements

### Requirement: Wiki initialisation creates directory structure
On `wiki init`, the skill SHALL create the full wiki directory tree under `wiki.root` as defined in `vibe_wiki.config.yaml`: `concepts/`, `sources/`, `authors/`, `tools/`, `workflows/`, `terms/`, `raw/`. It SHALL copy starter files (`index.md`, `log.md`) if they do not already exist. It SHALL NOT overwrite existing files.

Affected files: `SKILL.md` (vibe_wiki), `assets/starter/raw/.gitkeep`

#### Scenario: First-time init on empty directory
- **WHEN** the user runs `wiki init` and `wiki.root` is empty or does not exist
- **THEN** the skill creates all subdirectories (`concepts/`, `sources/`, `authors/`, `tools/`, `workflows/`, `terms/`, `raw/`), copies `index.md` and `log.md` from `assets/starter/`, and confirms each directory created

#### Scenario: Init on partially-existing wiki
- **WHEN** the user runs `wiki init` and some directories already exist
- **THEN** the skill creates only missing directories and files, skips existing ones with a note, and does not overwrite any content
