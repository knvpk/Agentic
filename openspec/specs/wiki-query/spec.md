# wiki-query

## Purpose

Defines the query workflow for the vibe-wiki skill: searching wiki content, synthesising cited answers, optionally saving answers as new wiki pages, and ensuring traceable source references.

## Requirements

### Requirement: Wiki query answers from wiki content with citations
The `wiki query <question>` command SHALL search `index.md` to find relevant pages, read those pages, and synthesise an answer with inline citations to the wiki nodes consulted. The answer SHALL reference node IDs using wikilinks (`[[id]]`).

Affected files: `SKILL.md` (vibe_wiki)

#### Scenario: Question answered from existing wiki pages
- **WHEN** the user runs `wiki query "How does attention work?"`
- **THEN** the skill reads `index.md`, identifies relevant concept pages, reads them, synthesises an answer, and cites each node used (e.g., `[[attention_mechanism]]`, `[[transformer_architecture]]`)

#### Scenario: Question not covered by wiki
- **WHEN** no relevant pages exist in the wiki for the question
- **THEN** the skill reports which concepts are missing and offers to ingest a source or create a stub page

### Requirement: Query answer can be saved as a wiki page
After presenting an answer, the skill SHALL ask: "Save this as a wiki page? [y/N]". If the user confirms, the skill SHALL save the answer as a new node under the most relevant collection (defaulting to `concepts/`) with appropriate frontmatter.

Affected files: `SKILL.md` (vibe_wiki)

#### Scenario: User saves a query answer
- **WHEN** the skill presents an answer and the user confirms saving
- **THEN** the skill proposes an `id` (snake_case from the question), shows the full frontmatter, waits for confirmation, writes `concepts/<id>/<id>.md`, updates `index.md`, and appends to `log.md`

#### Scenario: User declines saving
- **WHEN** the skill asks to save and the user says no
- **THEN** nothing is written; the answer remains only in conversation history

### Requirement: Query answers reference sources traceably
Any wiki page created from a query answer SHALL include a `sources` frontmatter field listing the wiki node IDs that contributed to the answer, formatted as `[[wikilinks]]`.

Affected files: `SKILL.md` (vibe_wiki), `assets/schemas/concept.json` (reused, not changed)

#### Scenario: Saved query page has source trail
- **WHEN** a query answer page is saved
- **THEN** its frontmatter `sources` field lists every `[[node_id]]` that was read to produce the answer
