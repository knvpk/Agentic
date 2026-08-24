## Why

`vibe-wiki` stores every node as a markdown file with relationships expressed as untyped `[[wikilink]]` strings tucked inside frontmatter arrays. This has two costs: relationships have no schema (a link's meaning is implied only by the field name it lives in, and reciprocal links — e.g. `source.author` / `author.sources` — can silently drift out of sync since nothing enforces both sides), and every lint/query operation is a full-file scan against `index.md`. FalkorDB is already provisioned in `docker_services` (`falkordb-server` + `falkordb-browser`) and gives typed, directed, property-bearing edges natively via Cypher. Making the storage backend configurable lets a wiki opt into a real graph model without disturbing existing markdown-based wikis.

## What Changes

- Add `wiki.backend` config key (`markdown` | `graphdb`) to `vibe-wiki.yaml`. Default remains `markdown` — **no behavior change for existing wikis**.
- **BREAKING** (graphdb mode only): when `wiki.backend: graphdb`, the wiki is stored entirely in FalkorDB — no `.md` files, no `index.md`, no Obsidian compatibility. Node type = Cypher label; frontmatter fields = node properties; body headings (`## Key Takeaways`, etc.) = array-valued node properties.
- Add a relationship-schema layer (`assets/schemas/relationships/*.json`) declaring, per edge type: source/target labels, directionality, and properties. Properties are marked `x-fill: inferred` or `x-fill: user-supplied` — user-supplied properties MUST be prompted for individually during ingest before the mapping plan can be confirmed; they are never inferred from source content.
- Symmetric relationships (e.g. `RELATED_TO`) are written once in canonical order (alphabetical by id) and always queried undirected (`-[:TYPE]-`), instead of duplicated on both nodes as today's markdown model does.
- Add a bundled adapter script (`assets/graphdb/`) that the agent shells out to (JSON in, parameterized `GRAPH.QUERY` out) for all node/edge writes in graphdb mode — hand-built Cypher string interpolation is not permitted, since ingested web content is untrusted input.
- Replace `log.md` with immutable `:LogEntry` nodes (`ts`, `action`, `target`, ...) in graphdb mode — write-once, ordered by `ts`, never updated. `log.md` is unchanged in markdown mode.
- `wiki lint`'s orphan/stub/index-gap checks get graphdb-native equivalents (Cypher queries instead of file scans); the index-gap check does not apply in graphdb mode since there is no `index.md`.
- `wiki query`'s relevance step gets a graphdb-native equivalent (property/full-text match via Cypher instead of reading `index.md`).

## Capabilities

### New Capabilities
- `wiki-backend-config`: the `wiki.backend` config key, FalkorDB connection settings, and startup branching that selects which instruction set (markdown vs. graphdb) the rest of the skill follows.
- `wiki-relationship-schema`: schema files defining typed, directed, property-bearing relationships between node types, including the inferred vs. user-supplied property fill rule.
- `wiki-graphdb-storage`: the graphdb-mode read/write operations (node upsert, edge upsert, query) performed via the bundled adapter script instead of file I/O.
- `wiki-audit-log`: immutable `:LogEntry` node model used in graphdb mode in place of `log.md`.

### Modified Capabilities
- `wiki-init`: branches on `wiki.backend` — graphdb mode connects to FalkorDB and verifies/creates indexes instead of creating the markdown directory tree.
- `wiki-ingest`: node/edge creation, edge-property prompting, source registration, and logging steps branch by backend.
- `wiki-lint`: orphan/stub checks branch by backend; index-gap check is markdown-only.
- `wiki-query`: relevance lookup (index.md scan vs. Cypher match) branches by backend.

## Impact

- `skills/vibe-wiki/SKILL.md` — startup (S1-S5) and all four command sections gain backend branches.
- `skills/vibe-wiki/assets/vibe-wiki.template.yaml` — new `wiki.backend` and `wiki.graphdb.*` (host, port, password env var, graph name) keys.
- `skills/vibe-wiki/assets/schemas/relationships/` — new directory, one schema file per edge type.
- `skills/vibe-wiki/assets/graphdb/` — new adapter script asset for safe parameterized Cypher.
- Depends on `docker_services/docker/falkor_db` (`falkordb-server`, already scaffolded) being reachable when `wiki.backend: graphdb` is selected; no changes needed to that service definition.
- Obsidian compatibility (`obsidian.enabled` config) is meaningless in graphdb mode — no `.md` files are produced.
