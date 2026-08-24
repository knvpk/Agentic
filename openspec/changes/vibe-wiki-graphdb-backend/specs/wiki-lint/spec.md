## MODIFIED Requirements

### Requirement: Lint checks for orphan pages
`wiki lint` SHALL identify nodes with no inbound relationship from any other node:
- **markdown backend**: scan all pages for `[[wikilink]]` references and identify pages with zero inbound links, as before
- **graphdb backend**: run a Cypher query identifying nodes with no incoming edges of any type

In both backends, the skill SHALL list orphan node IDs and suggest either linking them from a parent node or deleting them.

Affected files: `SKILL.md` (vibe-wiki)

#### Scenario: Orphan pages found, markdown backend
- **WHEN** `wiki.backend: markdown` and lint runs and one or more pages have no inbound links
- **THEN** the skill reports each orphan with its path and asks if the user wants to link or remove each one

#### Scenario: Orphan nodes found, graphdb backend
- **WHEN** `wiki.backend: graphdb` and lint runs and the orphan query returns one or more nodes
- **THEN** the skill reports each orphan node's id and label and asks if the user wants to link or remove each one

#### Scenario: No orphans
- **WHEN** every node has at least one inbound relationship (link or edge)
- **THEN** lint reports "No orphans found" for this check, regardless of backend

### Requirement: Lint checks for stub pages
`wiki lint` SHALL identify under-developed nodes:
- **markdown backend**: pages under a threshold line count (default: 5 lines of body content excluding frontmatter), as before
- **graphdb backend**: nodes whose combined body-section array properties (per `wiki-graphdb-storage`) hold fewer than 5 total entries

Affected files: `SKILL.md` (vibe-wiki)

#### Scenario: Stub pages found, markdown backend
- **WHEN** `wiki.backend: markdown` and lint runs and one or more pages have fewer than 5 lines of body content
- **THEN** the skill lists each stub and offers to enrich it or ingest a source for it

#### Scenario: Stub nodes found, graphdb backend
- **WHEN** `wiki.backend: graphdb` and lint runs and one or more nodes have fewer than 5 total entries across their body-section array properties
- **THEN** the skill lists each stub node and offers to enrich it or ingest a source for it

### Requirement: Lint checks for missing index entries
`wiki lint` compares node pages against an index:
- **markdown backend**: compare all files under `wiki.root` node directories against entries in `index.md`; any page not listed SHALL be flagged and the missing entry offered for addition, as before
- **graphdb backend**: this check does not apply — there is no `index.md` in graphdb mode — and SHALL be skipped

Affected files: `SKILL.md` (vibe-wiki)

#### Scenario: Page missing from index, markdown backend
- **WHEN** `wiki.backend: markdown` and a wiki page exists on disk but has no entry in `index.md`
- **THEN** lint flags it, shows the proposed `index.md` entry, and asks the user to confirm adding it

#### Scenario: Lint runs in graphdb mode
- **WHEN** `wiki.backend: graphdb` and lint runs
- **THEN** the index-gap check is skipped entirely and the summary reports it as not applicable, rather than as zero gaps found

### Requirement: Lint records a summary after each run
After each lint run, the skill SHALL record a timestamped summary listing counts: pages/nodes checked, orphans found, stubs found, index gaps found (or "not applicable" in graphdb mode).
- **markdown backend**: append the summary to `log.md`, as before
- **graphdb backend**: create a `:LogEntry` node per `wiki-audit-log` with `action: "lint"` and the counts in its properties

Affected files: `SKILL.md` (vibe-wiki)

#### Scenario: Lint completes, markdown backend
- **WHEN** `wiki.backend: markdown` and lint finishes all checks
- **THEN** an entry is appended to `log.md` in the format `## [<date>] lint | <N> pages, <N> orphans, <N> stubs, <N> index gaps`

#### Scenario: Lint completes, graphdb backend
- **WHEN** `wiki.backend: graphdb` and lint finishes all checks
- **THEN** a `:LogEntry` node is created with `action: "lint"` and properties recording nodes checked, orphans, and stubs (index gaps recorded as not applicable)
