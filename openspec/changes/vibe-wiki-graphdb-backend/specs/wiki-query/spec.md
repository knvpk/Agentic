## MODIFIED Requirements

### Requirement: Wiki query answers from wiki content with citations
The `wiki query <question>` command SHALL find relevant nodes, read/collect their content, and synthesise an answer with inline citations to the nodes consulted:
- **markdown backend**: search `index.md` to find relevant pages, read those pages, cite with `[[id]]` wikilinks, as before
- **graphdb backend**: run a Cypher property/full-text match against node properties to find relevant nodes, read their properties, cite with node ids

Affected files: `SKILL.md` (vibe-wiki)

#### Scenario: Question answered from existing wiki pages, markdown backend
- **WHEN** `wiki.backend: markdown` and the user runs `wiki query "How does attention work?"`
- **THEN** the skill reads `index.md`, identifies relevant concept pages, reads them, synthesises an answer, and cites each node used (e.g., `[[attention_mechanism]]`, `[[transformer_architecture]]`)

#### Scenario: Question answered from existing nodes, graphdb backend
- **WHEN** `wiki.backend: graphdb` and the user runs `wiki query "How does attention work?"`
- **THEN** the skill runs a property/full-text match against node properties to find relevant nodes, reads their properties, synthesises an answer, and cites each node id used

#### Scenario: Question not covered by wiki
- **WHEN** no relevant pages/nodes exist for the question, regardless of backend
- **THEN** the skill reports which concepts are missing and offers to ingest a source or create a stub node

### Requirement: Query answer can be saved as a wiki node
After presenting an answer, the skill SHALL ask: "Save this as a wiki page? [y/N]". If the user confirms:
- **markdown backend**: save the answer as a new node under the most relevant collection (defaulting to `concepts/`) with appropriate frontmatter, as before
- **graphdb backend**: upsert a new `Concept` node via the adapter with the same properties, and create edges to every node consulted (see "Query answers reference sources traceably" below)

Affected files: `SKILL.md` (vibe-wiki)

#### Scenario: User saves a query answer, markdown backend
- **WHEN** `wiki.backend: markdown`, the skill presents an answer, and the user confirms saving
- **THEN** the skill proposes an `id` (snake_case from the question), shows the full frontmatter, waits for confirmation, writes `concepts/<id>/<id>.md`, updates `index.md`, and appends to `log.md`

#### Scenario: User saves a query answer, graphdb backend
- **WHEN** `wiki.backend: graphdb`, the skill presents an answer, and the user confirms saving
- **THEN** the skill proposes an `id`, shows the full property set, waits for confirmation, upserts a `Concept` node via the adapter, creates edges to every consulted node, and creates a `:LogEntry`

#### Scenario: User declines saving
- **WHEN** the skill asks to save and the user says no
- **THEN** nothing is written to the wiki (files or graph); the answer remains only in conversation history

### Requirement: Query answers reference sources traceably
Any node created from a query answer SHALL record which nodes contributed to the answer:
- **markdown backend**: a `sources` frontmatter field listing the wiki node IDs, formatted as `[[wikilinks]]`, as before
- **graphdb backend**: an edge (per the relationship schema for the relevant node types, e.g. `INFORMED_BY`) from the new node to each node that contributed to the answer

Affected files: `SKILL.md` (vibe-wiki), `assets/schemas/concept.json` (reused, not changed), `assets/schemas/relationships/*.json`

#### Scenario: Saved query page has source trail, markdown backend
- **WHEN** `wiki.backend: markdown` and a query answer page is saved
- **THEN** its frontmatter `sources` field lists every `[[node_id]]` that was read to produce the answer

#### Scenario: Saved query node has source trail, graphdb backend
- **WHEN** `wiki.backend: graphdb` and a query answer node is saved
- **THEN** an edge is created from the new node to every node that was read to produce the answer, using the relationship type declared for that node-type pair
