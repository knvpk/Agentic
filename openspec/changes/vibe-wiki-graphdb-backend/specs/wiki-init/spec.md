## MODIFIED Requirements

### Requirement: Wiki initialisation creates directory structure or connects to graphdb
On `wiki init`, the skill SHALL branch on `wiki.backend`:
- **markdown** (default): create the full wiki directory tree under `wiki.root` as defined in `vibe-wiki.yaml`: `concepts/`, `sources/`, `authors/`, `tools/`, `workflows/`, `terms/`, `ideas/`, `unorganized/`, `raw/`. Copy starter files (`index.md`, `log.md`) if they do not already exist. Never overwrite existing files.
- **graphdb**: create only `raw/` (the local ingestion staging directory, unaffected by backend choice). Do not create per-type directories, `index.md`, or `log.md`. Instead, verify the FalkorDB connection (see `wiki-backend-config`) and ensure any required indexes exist on the configured graph.

Affected files: `SKILL.md` (vibe-wiki), `assets/starter/raw/.gitkeep`

#### Scenario: First-time init on empty directory, markdown backend
- **WHEN** the user runs `wiki init`, `wiki.backend` is `markdown` (or unset), and `wiki.root` is empty or does not exist
- **THEN** the skill creates all subdirectories (`concepts/`, `sources/`, `authors/`, `tools/`, `workflows/`, `terms/`, `ideas/`, `unorganized/`, `raw/`), copies `index.md` and `log.md` from `assets/starter/`, and confirms each directory created

#### Scenario: Init on partially-existing markdown wiki
- **WHEN** the user runs `wiki init` with `wiki.backend: markdown` and some directories already exist
- **THEN** the skill creates only missing directories and files, skips existing ones with a note, and does not overwrite any content

#### Scenario: First-time init, graphdb backend
- **WHEN** the user runs `wiki init` and `wiki.backend: graphdb`
- **THEN** the skill creates `raw/` if absent, connects to the configured FalkorDB instance, ensures required indexes exist, and reports readiness — it does not create `concepts/`, `sources/`, `index.md`, or `log.md`

#### Scenario: Init on graphdb backend with FalkorDB unreachable
- **WHEN** the user runs `wiki init` with `wiki.backend: graphdb` and the configured FalkorDB instance is unreachable
- **THEN** the skill reports the connection failure and stops without creating `raw/` or reporting readiness
