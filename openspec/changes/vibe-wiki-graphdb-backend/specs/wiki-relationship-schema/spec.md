## ADDED Requirements

### Requirement: Relationship types are defined by schema files
Each typed relationship SHALL have a corresponding schema file under `assets/schemas/relationships/{edge_type}.json` declaring `source_label`, `target_label`, `directed`, and (optionally) `properties`. Edge types with no metadata SHALL NOT require a schema file and MAY be created bare. Before creating any typed relationship, the skill SHALL read the matching schema file (if one exists) to know which node types are valid endpoints and which properties to populate.

Affected files: `skills/vibe-wiki/assets/schemas/relationships/` (new directory)

#### Scenario: Relationship type with a schema file
- **WHEN** the skill creates a `COVERS` relationship and `assets/schemas/relationships/covers.json` exists
- **THEN** the skill validates that the source node's label matches `source_label` and the target node's label matches `target_label` before creating the edge, and populates only properties defined in the schema

#### Scenario: Relationship type with no schema file
- **WHEN** the skill creates a relationship type with no matching file under `assets/schemas/relationships/`
- **THEN** the skill creates the edge with no properties

#### Scenario: Endpoint label mismatch
- **WHEN** the skill attempts to create a relationship whose source or target node label does not match the schema's declared `source_label`/`target_label`
- **THEN** the skill reports the mismatch and does not create the edge

### Requirement: Relationship properties declare an inferred or user-supplied fill mode
Each property in a relationship schema SHALL declare `x-fill: inferred` or `x-fill: user-supplied`. Properties marked `inferred` SHALL be populated by the agent from ingest content and surfaced in the mapping-plan summary for confirmation. Properties marked `user-supplied` SHALL NEVER be inferred — the skill SHALL prompt the user individually for each such property, for each new edge, before the overall mapping plan can be confirmed.

Affected files: `skills/vibe-wiki/assets/schemas/relationships/*.json`, `SKILL.md` (vibe-wiki)

#### Scenario: Inferred property
- **WHEN** a new edge is proposed with a property marked `x-fill: inferred`
- **THEN** the skill fills the property from ingest content and shows the filled value in the mapping-plan summary without a separate prompt

#### Scenario: User-supplied property
- **WHEN** a new edge is proposed with a property marked `x-fill: user-supplied`
- **THEN** the skill prompts the user for that property's value before the mapping plan can be confirmed, and does not proceed to the overall confirmation step until every user-supplied property on every new edge has a value

#### Scenario: Multiple new edges with user-supplied properties in one ingest
- **WHEN** an ingest proposes more than one new edge that each carry a user-supplied property
- **THEN** the skill collects all such prompts before presenting the final mapping-plan confirmation, rather than interleaving them with unrelated steps

### Requirement: Symmetric relationships are written once and queried undirected
Relationship types marked symmetric in their schema (`directed: false`) SHALL be created exactly once per node pair, with source and target ordered by id (ascending) to produce a canonical direction. All reads of a symmetric relationship type SHALL use an undirected match pattern.

Affected files: `skills/vibe-wiki/assets/schemas/relationships/*.json`, `SKILL.md` (vibe-wiki)

#### Scenario: New symmetric edge between two nodes
- **WHEN** the skill creates a `RELATED_TO` edge between nodes with ids `self_attention` and `transformer_architecture`
- **THEN** the edge is created once, from `self_attention` to `transformer_architecture` (alphabetically first as source), regardless of which node initiated the relationship

#### Scenario: Symmetric edge already exists in the other order
- **WHEN** the skill would create a symmetric edge but one already exists between the same two nodes (in either direction)
- **THEN** the skill does not create a duplicate edge

#### Scenario: Reading a symmetric relationship
- **WHEN** the skill queries a node's `RELATED_TO` relationships
- **THEN** it matches the edge regardless of which node is stored as source and which as target
