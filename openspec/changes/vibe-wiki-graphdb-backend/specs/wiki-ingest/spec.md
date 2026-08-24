## MODIFIED Requirements

### Requirement: Ingest follows summarise → confirm → map → save → register flow
After loading content (URL or file), the skill SHALL:
1. Summarise the content and list concepts covered
2. Ask for confirmation before mapping or writing anything
3. Map to existing wiki nodes or propose new ones (with user confirmation), including proposed typed relationships (edges) between nodes per `wiki-relationship-schema`
4. For any proposed edge with a `user-supplied` property, prompt the user individually for that property's value before the mapping plan can be confirmed
5. Save wiki pages (create or enrich) and relationships:
   - **markdown backend**: write/enrich `.md` files; never overwrite without showing a diff
   - **graphdb backend**: upsert nodes and edges via the bundled adapter (`wiki-graphdb-storage`); never construct Cypher by hand
6. Register the source:
   - **markdown backend**: create `sources/<id>.md` conforming to `assets/schemas/source.json`
   - **graphdb backend**: upsert a `Source` node with the same fields as properties
7. Record the action:
   - **markdown backend**: append an entry to `log.md`
   - **graphdb backend**: create a `:LogEntry` node per `wiki-audit-log`

Affected files: `SKILL.md` (vibe-wiki), `assets/schemas/source.json` (reused, not changed), `assets/schemas/relationships/*.json`

#### Scenario: New source, new concept nodes, markdown backend
- **WHEN** `wiki.backend: markdown` and content covers concepts with no existing wiki pages
- **THEN** the skill proposes new node IDs, shows where they would sit, waits for confirmation, creates pages, and registers the source in `sources/`

#### Scenario: New source, new concept nodes, graphdb backend
- **WHEN** `wiki.backend: graphdb` and content covers concepts with no existing nodes
- **THEN** the skill proposes new node ids and the edges that would connect them to the source, waits for confirmation (including any user-supplied edge properties), upserts the nodes and edges via the adapter, and creates a `:LogEntry`

#### Scenario: Existing concept nodes
- **WHEN** content covers concepts with existing pages/nodes
- **THEN** the skill shows the enrichment diff (what would be added), waits for confirmation, and applies it via the active backend's write path

#### Scenario: New edge with a user-supplied property
- **WHEN** the proposed mapping includes a new edge whose schema declares a `user-supplied` property (e.g. `confidence` on `COVERS`)
- **THEN** the skill prompts for that property's value before presenting the final mapping-plan confirmation, and does not create the edge until a value is given

#### Scenario: User declines mapping confirmation
- **WHEN** the user says no to the proposed concept/edge mapping
- **THEN** the skill stops; nothing is written to the wiki (files or graph) or source registry
