## ADDED Requirements

### Requirement: Graphdb mode records actions as immutable log nodes
When `wiki.backend: graphdb`, every action that would append an entry to `log.md` in markdown mode (ingest, query-save, lint) SHALL instead create a new `:LogEntry` node with properties `ts` (ISO timestamp), `action` (`ingest` | `query-save` | `lint`), `target` (source id or query text), and `pages_written` (list of node ids affected). `log.md` SHALL NOT be created or written to when `wiki.backend: graphdb`.

Affected files: `SKILL.md` (vibe-wiki), `skills/vibe-wiki/assets/graphdb/`

#### Scenario: Ingest logs a LogEntry node
- **WHEN** an ingest completes in graphdb mode
- **THEN** a new `:LogEntry` node is created with `action: "ingest"`, the source id as `target`, and the list of node ids written as `pages_written`

#### Scenario: Markdown mode is unaffected
- **WHEN** `wiki.backend: markdown` (or unset)
- **THEN** logging continues to append to `log.md` exactly as before; no `:LogEntry` nodes are created

### Requirement: Log nodes are never updated after creation
Once created, a `:LogEntry` node's properties SHALL NOT be modified by any later operation. History is read by querying all `:LogEntry` nodes ordered by `ts`.

Affected files: `skills/vibe-wiki/assets/graphdb/`

#### Scenario: Reading log history
- **WHEN** the user asks to see the wiki's action history in graphdb mode
- **THEN** the skill queries all `:LogEntry` nodes ordered by `ts` ascending and presents them, without modifying any existing entry

#### Scenario: Two actions in the same session
- **WHEN** two log-worthy actions occur in the same session
- **THEN** two separate `:LogEntry` nodes are created; neither overwrites the other
