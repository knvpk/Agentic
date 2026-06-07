# wiki-ingest

## Purpose

Defines the ingest workflow for the vibe-wiki skill: resolving arguments to URLs or raw files, following the summarise-confirm-map-save-register flow, and enforcing the immutability convention for the `raw/` directory.

## Requirements

### Requirement: Ingest argument resolves to URL or raw file
The `wiki ingest <arg>` command SHALL inspect `<arg>` at invocation time:
- If `<arg>` starts with `http://` or `https://`, it is treated as a URL and fetched via the provider's web tool
- Otherwise it is treated as a filename and resolved to `raw/<arg>` under `wiki.root`

Affected files: `SKILL.md` (vibe_wiki)

#### Scenario: URL argument
- **WHEN** the user runs `wiki ingest https://example.com/article`
- **THEN** the skill fetches the URL via web tool, extracts content, and proceeds to the summarise-map-save flow

#### Scenario: Filename argument resolves to raw/
- **WHEN** the user runs `wiki ingest transformer_paper.pdf` and `raw/transformer_paper.pdf` exists
- **THEN** the skill reads the file from `raw/`, extracts content, and proceeds to the summarise-map-save flow

#### Scenario: Filename not found in raw/
- **WHEN** the user runs `wiki ingest missing_file.md` and `raw/missing_file.md` does not exist
- **THEN** the skill reports the file was not found under `raw/`, lists files currently in `raw/`, and stops

### Requirement: Ingest follows summarise → confirm → map → save → register flow
After loading content (URL or file), the skill SHALL:
1. Summarise the content and list concepts covered
2. Ask for confirmation before mapping or writing anything
3. Map to existing wiki nodes or propose new ones (with user confirmation)
4. Save wiki pages (create or enrich); never overwrite without showing a diff
5. Register the source in `sources/<id>.md` with frontmatter conforming to `assets/schemas/source.json`
6. Append an entry to `log.md`

Affected files: `SKILL.md` (vibe_wiki), `assets/schemas/source.json` (reused, not changed)

#### Scenario: New source, new concept nodes
- **WHEN** content covers concepts with no existing wiki pages
- **THEN** the skill proposes new node IDs, shows where they would sit, waits for confirmation, creates pages, and registers the source

#### Scenario: Existing concept nodes
- **WHEN** content covers concepts with existing pages in `concepts/`
- **THEN** the skill shows the enrichment diff (what would be added), waits for confirmation, appends content, and updates the source registry

#### Scenario: User declines mapping confirmation
- **WHEN** the user says no to the proposed concept mapping
- **THEN** the skill stops; nothing is written to the wiki or source registry

### Requirement: raw/ directory is immutable by convention
The skill SHALL never write to or modify files under `raw/`. It MAY read from `raw/` during ingest. This is a documented convention enforced by instruction, not by filesystem permissions.

Affected files: `SKILL.md` (vibe_wiki) — documented in startup rules and in emitted `CLAUDE.md`/`AGENTS.md`

#### Scenario: Ingest from raw/
- **WHEN** the skill reads a file from `raw/` during ingest
- **THEN** it reads only; the original file in `raw/` remains byte-for-byte unchanged after ingest completes
