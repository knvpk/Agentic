## ADDED Requirements

### Requirement: Wiki config declares a storage backend
`vibe-wiki.yaml` SHALL support a `wiki.backend` key with allowed values `markdown` and `graphdb`. When the key is absent, the skill SHALL default to `markdown`, preserving existing behavior for wikis created before this capability existed.

Affected files: `SKILL.md` (vibe-wiki), `assets/vibe-wiki.template.yaml`

#### Scenario: Backend key absent defaults to markdown
- **WHEN** `vibe-wiki.yaml` has no `wiki.backend` key
- **THEN** the skill operates exactly as it did before this capability — markdown files, `index.md`, `log.md` — with no behavior change

#### Scenario: Backend explicitly set to graphdb
- **WHEN** `vibe-wiki.yaml` sets `wiki.backend: graphdb`
- **THEN** the skill follows the graphdb-mode instruction set for every command (init, ingest, query, lint) for the remainder of the session

#### Scenario: Invalid backend value
- **WHEN** `wiki.backend` is set to a value other than `markdown` or `graphdb`
- **THEN** the skill reports the invalid value and the two allowed options, and stops before executing any command

### Requirement: Graphdb backend requires connection config
When `wiki.backend: graphdb`, `vibe-wiki.yaml` SHALL provide a `wiki.graphdb` block with `host`, `port`, `password_env` (name of an environment variable holding the FalkorDB password), and `graph_name`. The skill SHALL read the password from the named environment variable at runtime and SHALL NOT accept a literal password value in `vibe-wiki.yaml`.

Affected files: `SKILL.md` (vibe-wiki), `assets/vibe-wiki.template.yaml`

#### Scenario: Complete graphdb config
- **WHEN** `wiki.backend: graphdb` and `wiki.graphdb` includes `host`, `port`, `password_env`, and `graph_name`
- **THEN** the skill connects to FalkorDB using those values, reading the password from the named environment variable

#### Scenario: Missing graphdb config block
- **WHEN** `wiki.backend: graphdb` but `wiki.graphdb` is absent or missing a required key
- **THEN** the skill reports which key is missing and stops before executing any command

#### Scenario: Literal password in config is rejected
- **WHEN** `wiki.graphdb` contains a `password` key with a literal value instead of `password_env`
- **THEN** the skill reports that passwords must be supplied via an environment variable, not committed to config, and stops

### Requirement: Startup verifies graphdb connectivity before proceeding
When `wiki.backend: graphdb`, the skill's startup routine SHALL verify the FalkorDB connection is reachable before dispatching to any command. On failure, it SHALL report the connection error and point to the backing service rather than proceeding into a partial or confusing command failure.

Affected files: `SKILL.md` (vibe-wiki)

#### Scenario: FalkorDB reachable
- **WHEN** startup runs with `wiki.backend: graphdb` and the configured host/port responds
- **THEN** the skill proceeds to dispatch the requested command

#### Scenario: FalkorDB unreachable
- **WHEN** startup runs with `wiki.backend: graphdb` and the connection fails
- **THEN** the skill reports the failure, names the configured host/port, and stops without attempting the requested command
