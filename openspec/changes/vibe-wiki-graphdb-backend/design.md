## Context

`vibe-wiki` is pure SKILL.md instructions — an LLM agent following prose, not code calling a storage interface. Today that prose always means "read/write a markdown file." Nodes are typed via paired JSON Schema files (`{type}.json` for frontmatter, `content/{type}.json` for body headings); built-in types are `concept`, `source`, `author`, `tool`, `workflow`, `term`, `idea`. Relationships are untyped `[[wikilink]]` strings inside frontmatter arrays — the field name (`related_concepts`, `sources`, `expertise`, ...) implies the semantics, and reciprocal fields (`source.author` / `author.sources`) are independently maintained with nothing enforcing agreement. `index.md` is a hand-maintained flat index; `wiki lint` and `wiki query` both work by scanning every file.

FalkorDB (`docker_services/docker/falkor_db/service.yaml`) is already running as `falkordb-server` (Redis protocol, Cypher via `GRAPH.QUERY`, password-gated via `REDIS_ARGS: --requirepass`) plus `falkordb-browser` for human browsing. This design makes the wiki's backend a config choice between the existing markdown model and a full FalkorDB-backed graph model.

## Goals / Non-Goals

**Goals:**
- `wiki.backend: markdown | graphdb` config key; `markdown` is the default and existing wikis are unaffected.
- In `graphdb` mode, nodes and relationships are both typed: node type → Cypher label, relationship type → Cypher relationship type with its own schema (source/target labels, properties).
- Relationship properties are supported, with an explicit inferred-vs-user-supplied fill rule per property.
- All Cypher execution goes through a bundled adapter script — no agent-authored Cypher string built via bash interpolation of ingested content.
- `wiki lint` and `wiki query` get graphdb-native equivalents rather than falling back to file scans.

**Non-Goals:**
- Migrating an existing markdown wiki into graphdb (or vice versa). Switching `wiki.backend` applies to new writes going forward only; no `wiki migrate` command in this change.
- Semantic/vector search. Graphdb-mode relevance lookup is still lexical (FalkorDB full-text/property match), same limitation the markdown model already has via `index.md` + grep — this change does not improve retrieval quality, only its substrate.
- Dual-write / keeping markdown and graphdb in sync simultaneously. A wiki is one backend or the other, per its config.
- Obsidian compatibility in graphdb mode — no `.md` files are produced, so `obsidian.enabled` has no effect when `wiki.backend: graphdb`.

## Decisions

### Decision 1: Backend selection is a startup branch, not a code abstraction
**Choice**: `SKILL.md`'s startup routine (S1-S5) reads `wiki.backend` after loading config and, for the remainder of the session, follows one of two parallel instruction sets per command section (markdown vs. graphdb). There is no shared "storage interface" abstraction, because there is no code layer — everything is prose an LLM interprets.
**Rationale**: This matches how `wiki generate schema` already works (config key → load a different instruction fragment). It keeps the two modes legible as separate reasoning paths instead of forcing artificial code-style abstraction onto markdown instructions.
**Alternatives considered**: A single unified instruction set with inline conditionals at every step — rejected, it would make `SKILL.md` far harder to follow and error-prone for the agent to execute correctly mid-command.

### Decision 2: Node mapping is mechanical
**Choice**: node type → Cypher label; frontmatter scalar/array fields → node properties of the same name; each body heading (`## Key Takeaways`) → an array-valued property (slugified: `key_takeaways`). The existing `{type}.json` / `content/{type}.json` schema pair is reused unchanged to know which properties to set — no new node schema format.
**Rationale**: Body sections are already structured bullet lists with explicit append/no-duplicate semantics, not free prose — they map to array properties with no loss of structure.

### Decision 3: Relationships get their own schema layer
**Choice**: `assets/schemas/relationships/{edge_type}.json` declares `source_label`, `target_label`, `directed`, and `properties`. Each property is marked `x-fill: inferred` (agent fills from context, shown in the mapping-plan summary) or `x-fill: user-supplied` (agent MUST prompt for it individually before the plan can be confirmed — never inferred). Edge types with no metadata don't need a schema file at all; they're created bare.
**Rationale**: A bare wikilink string has nowhere to hold a property. Making the ingest-time relationship representation an object (`{target, ...props}`) instead of a string is required before any edge property can exist, independent of backend — but it's only exercised in graphdb mode in this change.
**Alternatives considered**: Inferring all edge properties automatically — rejected per explicit requirement: properties like confidence/weight/role are judgment calls, not extractable facts, so silent inference would produce unreliable graph data.

### Decision 4: Symmetric relationships are written once, queried undirected
**Choice**: For relationship types that are conceptually bidirectional (e.g. `RELATED_TO`), the edge is created once, in canonical order (source/target ordered alphabetically by id), and always matched with an undirected pattern (`-[:RELATED_TO]-`) rather than an arrow.
**Rationale**: Avoids ever creating both `A→B` and `B→A` for the same relationship — the exact "two records disagree" failure mode the current markdown model has with reciprocal fields, just reintroduced in the graph if not addressed explicitly.

### Decision 5: Cypher execution goes through a bundled adapter, never hand-built strings
**Choice**: `assets/graphdb/` ships a small script (JSON on stdin → parameterized `GRAPH.QUERY` via a real Redis/FalkorDB client) that the agent invokes via Bash for every node/edge write and read. `SKILL.md`'s graphdb-mode instructions say "pipe this JSON to the script," never "construct this Cypher string."
**Rationale**: `redis-cli` alone gives string concatenation, not parameter binding. Ingest pulls in untrusted content (arbitrary URLs, PDFs) — an agent interpolating that content into a Cypher string by hand is a real injection surface (e.g. a page containing `'}) DETACH DELETE n //`). A parameterized adapter removes the class of bug entirely rather than relying on the agent to escape correctly every time.
**Alternatives considered**: Agent-authored Cypher with careful escaping instructions in `SKILL.md` — rejected, escaping correctness can't be relied on across every ingest, and the failure mode (data loss / corruption) is too severe.

### Decision 6: Audit log becomes immutable, timestamp-ordered nodes
**Choice**: `log.md` is replaced in graphdb mode by `:LogEntry` nodes (`ts`, `action`, `target`, `pages_written`, ...), created once and never updated, ordered at query time via `ORDER BY ts`. `log.md` is unchanged in markdown mode.
**Rationale**: The only property `log.md` needs is chronological, human/agent-readable history. A single agent executing operations sequentially doesn't need clock-skew-proof ordering, so a `ts` property is sufficient — an explicit linked-list chain (`-[:NEXT]->`) would add write complexity (find-the-tail on every entry) for no benefit at this scale.

### Decision 7: `wiki lint` and `wiki query` get graphdb-native equivalents
**Choice**: Orphan check → nodes with no matching incoming/outgoing edges via Cypher. Stub check → a property-length threshold on body-section properties instead of counting markdown body lines. Index-gap check → dropped entirely in graphdb mode (no `index.md` exists to have gaps against). `wiki query`'s relevance lookup → Cypher property/full-text match against node properties instead of reading and keyword-matching `index.md`.
**Rationale**: Porting the markdown-era checks verbatim (e.g. re-deriving something `index.md`-shaped) would forfeit the actual benefit of the graph model, which is that these become native queries instead of full-file scans.

## Risks / Trade-offs

- **FalkorDB unavailability** → `wiki init`/every subsequent command fails outright when `wiki.backend: graphdb` and the server is unreachable. Mitigation: fail fast at startup (S1-equivalent) with a clear error pointing at `docker_services/docker/falkor_db`, rather than a partial/confusing failure mid-command.
- **Adapter script becomes a single point of correctness** for all graphdb writes → Mitigation: keep it deliberately small (upsert-node, upsert-edge, query) and parameter-bound; it's infrastructure, not business logic, so it shouldn't need frequent changes.
- **No migration path** → a wiki started in one backend can't move to the other without manual work. Mitigation: explicitly scoped out (see Non-Goals); acceptable because `wiki.backend` is expected to be a project-start decision, not something toggled mid-project.
- **Loss of git-diffability and Obsidian compatibility in graphdb mode** → Mitigation: `falkordb-browser` (already running alongside `falkordb-server`) covers the human-browsing use case; accepted as a real trade-off of choosing graphdb mode, not something this design tries to paper over.
- **Retrieval quality unchanged** → graphdb mode does not make `wiki query` smarter, only its lookup mechanism different (Cypher match vs. file scan). Both remain lexical. Documented so it isn't mistaken for a semantic-search upgrade.

## Migration Plan

No migration needed for existing wikis — `wiki.backend` defaults to `markdown`, which is byte-for-byte the current behavior. Adopting `graphdb` mode is only available to wikis run through `wiki init` with `wiki.backend: graphdb` already set (fresh wiki, or a project not yet initialized); there is no rollback concern because the two modes never share state.

## Open Questions

- Exact set of built-in relationship schema files to ship on day one — the mapping table discussed (`RELATED_TO`, `COVERS`, `WROTE`, `DEFINES`, `EXPERT_IN`) covers the fields visible on `concept`/`source`/`author`; `tool`, `workflow`, `term`, and `idea` schemas haven't been audited yet for their own implicit relationship fields. To be finalized in specs.
- Whether `wiki migrate` is worth a future follow-up change once graphdb mode has real usage, or whether backend choice staying permanent-at-init is fine long-term.
