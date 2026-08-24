## ADDED Requirements

### Requirement: All graphdb reads and writes go through the bundled adapter
When `wiki.backend: graphdb`, every node/edge create, update, or query operation SHALL be performed by invoking the bundled adapter script under `assets/graphdb/` (JSON input, parameterized `GRAPH.QUERY` execution against a real FalkorDB client) via Bash. The skill SHALL NOT construct Cypher query strings by interpolating ingest content directly into a shell command.

Affected files: `skills/vibe-wiki/assets/graphdb/` (new), `SKILL.md` (vibe-wiki)

#### Scenario: Node write in graphdb mode
- **WHEN** the skill needs to create or update a node while `wiki.backend: graphdb`
- **THEN** it invokes the adapter script with a JSON payload describing the label and properties, rather than building a Cypher string itself

#### Scenario: Ingest content containing Cypher-significant characters
- **WHEN** ingested content contains characters that would be significant if interpolated into a Cypher string (quotes, comment markers, statement separators)
- **THEN** those characters are passed as data through the adapter's parameterized query and have no effect on query structure

### Requirement: Node upsert maps node schema to Cypher label and properties
The adapter SHALL create or update a node using the node's type as the Cypher label, and the node's frontmatter fields plus body-section headings (slugified to property names, e.g. `## Key Takeaways` → `key_takeaways`) as node properties, per the existing `assets/schemas/{type}.json` and `assets/schemas/content/{type}.json` pair.

Affected files: `skills/vibe-wiki/assets/graphdb/`

#### Scenario: New concept node
- **WHEN** the skill creates a new `concept` node with frontmatter fields and body sections populated per `concept.json`/`content/concept.json`
- **THEN** the resulting graph node has label `Concept`, frontmatter fields as scalar/array properties, and each body heading as an array-valued property

#### Scenario: Enriching an existing node's body section
- **WHEN** the skill appends a new bullet to an existing node's `## Key Takeaways` section
- **THEN** the adapter appends to the `key_takeaways` array property without duplicating existing entries

### Requirement: Edge upsert maps relationship schema to Cypher relationship
The adapter SHALL create or update an edge using the relationship type's schema (see relationship-schema capability) to determine the Cypher relationship type, source/target node match, directionality, and properties.

Affected files: `skills/vibe-wiki/assets/graphdb/`

#### Scenario: Edge with properties
- **WHEN** the skill creates a `COVERS` edge with a `confidence` property supplied by the user
- **THEN** the adapter creates `(:Source)-[:COVERS {confidence: <value>}]->(:Concept)` with the property bound as a query parameter
