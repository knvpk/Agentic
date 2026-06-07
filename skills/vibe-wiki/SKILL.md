---
name: vibe-wiki
version: 1.0.0
description: >
  Build and maintain a persistent, compounding wiki from URLs and local files. Commands: wiki
  init, wiki ingest, wiki query, wiki lint, wiki help, wiki generate schema.
compatibility: >
  Requires vibe-wiki.yaml in the project root. Run `wiki init` to set up a new wiki.
triggers:
  - /vibe-wiki
  - wiki init
  - wiki ingest
  - wiki query
  - wiki lint
  - wiki help
  - wiki generate schema
---

# vibe-wiki

Ingest sources, query accumulated knowledge, keep the graph healthy.

Read the user's command and jump to the matching section:

| Command | Section |
|---------|---------|
| `wiki init` | [Init](#wiki-init) |
| `wiki ingest <url-or-filename>` | [Ingest](#wiki-ingest) |
| `wiki query <question>` | [Query](#wiki-query) |
| `wiki lint` | [Lint](#wiki-lint) |
| `wiki help` / `wiki commands` | [Help](#wiki-help) |
| `wiki generate schema` | [Generate Schema](#wiki-generate-schema) |

---

## Startup

Run this routine at the start of every session before executing any wiki command.

### S1 — Locate config

Look for `vibe-wiki.yaml` in the project root (working directory).

**If not found:**
> `vibe-wiki.yaml` not found.
> Copy `{SKILL_DIR}/assets/vibe-wiki.template.yaml` to the project root as `vibe-wiki.yaml`, edit the `wiki.root` key, then re-invoke.

Stop. Do not proceed further.

**If found:** read it and continue.

### S2 — Resolve SKILL_DIR

`SKILL_DIR` is the directory containing this SKILL.md file (the skill's installation directory). All paths like `{SKILL_DIR}/assets/...` are resolved relative to it.

### S3 — Resolve wiki.root

Read `wiki.root` from config. This is the path to the wiki directory (relative to the project root). Resolve it to an absolute path. This is `WIKI_ROOT` for all subsequent operations.

### S4 — Load schemas

The skill ships two layers of schema for each node type, both under `{SKILL_DIR}/assets/schemas/`:

| Layer | Path pattern | Purpose |
|-------|-------------|---------|
| Frontmatter | `{type}.json` | Defines the required and optional YAML frontmatter fields for every page of that type |
| Body | `content/{type}.json` | Defines the expected Markdown heading sections and what to put in each |

Built-in types: `concept`, `source`, `author`, `tool`, `workflow`, `term`, `idea`.

**Rule: before creating or enriching any wiki page, read the matching `{type}.json` to know which frontmatter fields to include, and `content/{type}.json` to know how to structure the body.** Never invent fields or sections not listed in the schemas.

### S5 — Dispatch command

Proceed to the section matching the user's command.

---

## Wiki Init

Create a new wiki or complete a partially-initialised one.

### I1 — Create directory tree

Create the following directories under `WIKI_ROOT`. Skip any that already exist and note which were skipped:

```
{WIKI_ROOT}/
  concepts/
  sources/
  authors/
  tools/
  workflows/
  terms/
  ideas/
  unorganized/
  raw/
```

Report each directory: "Created: concepts/" or "Exists (skipped): concepts/".

### I2 — Copy starter files

Copy from `{SKILL_DIR}/assets/starter/`:

| Source | Destination | Behaviour |
|--------|-------------|-----------|
| `index.md` | `{WIKI_ROOT}/index.md` | Copy only if destination does not exist |
| `log.md` | `{WIKI_ROOT}/log.md` | Copy only if destination does not exist |

Report each: "Copied: index.md" or "Exists (skipped): index.md".

**Never overwrite existing content.**

### I3 — Confirm

```
wiki init complete
  Wiki root:           {WIKI_ROOT}
  Directories created: N
  Files copied:        N
```

---

## Wiki Ingest

Add a new source to the wiki. Usage: `wiki ingest <url-or-filename>`

### G1 — Resolve argument

Inspect `<arg>`:

- Starts with `http://` or `https://` → **URL branch** (G2)
- Otherwise → **filename branch** (G3)

### G2 — URL branch: fetch content

Fetch the URL and extract the main text content. If the fetch fails, report the error and stop.

### G3 — Filename branch: load from raw/

Check whether `{WIKI_ROOT}/raw/<arg>` exists.

**If not found:**
> File not found: `raw/<arg>`
> Files currently in `raw/`:
> {list contents of WIKI_ROOT/raw/}

Stop. Do not write anything.

**If found:** read the file content. (Do not modify the file — `raw/` is immutable by convention.)

### G4 — Summarise and confirm

Summarise the loaded content:
1. One-paragraph summary of what the source covers
2. Bulleted list of key concepts, topics, or entities identified

Show to the user and ask:
> Proceed with ingesting this source into the wiki? [y/N]

If no: stop, write nothing.

### G5 — Map to wiki nodes

For each concept, topic, or entity identified:
1. Check `{WIKI_ROOT}/index.md` for an existing page with a matching id or title
2. For existing pages: propose enrichment (what content would be added)
3. For new entities: determine which built-in type fits — `concept`, `source`, `author`, `tool`, `workflow`, `term`, `idea`
4. For entities that don't cleanly fit any built-in type, pick one of two options and present it to the user:
   - **Suggest a new schema**: describe the new node type, its key fields, and offer to create a schema file for it (user can then add that directory to `wiki.additional_schemas` and run `wiki generate schema`)
   - **Unorganized node**: place the data in `{WIKI_ROOT}/unorganized/{id}/{id}.md` as freeform Markdown with a minimal frontmatter (`id`, `name`, `raw_type: <what it appears to be>`) — no schema enforced; can be reclassified later

Present the full mapping plan, flagging anything unresolved:
```
Proposed mapping for "<source title>":
  Mapped to built-in types:
    - concepts/attention_mechanism/ (new)
    - concepts/transformer_architecture/ (new)
    - authors/vaswani_et_al/ (new)
  Enrichments:
    - concepts/neural_network/ — add 2 paragraphs on scaling
  Unresolved (no matching type):
    - "Benchmark results table" → suggest new schema 'benchmark' OR place in unorganized/
    - "License terms" → suggest new schema 'legal' OR place in unorganized/
```

For each unresolved item, ask the user:
> "Benchmark results table" doesn't fit a built-in type.
> (a) Suggest a new schema  (b) Place in unorganized/  (c) Skip

If the user chooses (a): describe the proposed schema (`id`, `title`, key fields) and offer to write the schema file. Do not write it without confirmation.

Ask for overall confirmation before writing anything:
> Confirm this mapping? [y/N] (or type changes)

If no: stop, write nothing.

### G6 — Save pages

For each **typed page** (built-in or custom schema):

1. Read `{SKILL_DIR}/assets/schemas/{type}.json` — populate all `required` fields; include relevant optional fields based on the content.
2. Read `{SKILL_DIR}/assets/schemas/content/{type}.json` (if it exists) — structure the body using the defined heading sections; only include sections that have meaningful content.
3. Create `{WIKI_ROOT}/{type}/{id}/{id}.md` with the generated frontmatter and body.

For each **unorganized page** (user chose option b in G5):

Create `{WIKI_ROOT}/unorganized/{id}/{id}.md` with minimal frontmatter:
```yaml
---
id: {id}
name: {human-readable name}
raw_type: {what the entity appears to be}
sources: ["[[{source_id}]]"]
---
```
Followed by the raw extracted content as freeform Markdown. No schema enforced. Note in the body: `> Unclassified — reclassify with wiki ingest or promote to a typed page when a schema exists.`

For each enrichment: read the existing page, show the diff of what will be appended under which body section, ask for per-page confirmation, then append.

**Never overwrite a page without showing the diff and getting confirmation. Never add frontmatter fields or body sections not defined in the schema for typed pages.**

### G7 — Register source

Read `{SKILL_DIR}/assets/schemas/source.json` and `{SKILL_DIR}/assets/schemas/content/source.json`.

Create `{WIKI_ROOT}/sources/{source_id}/{source_id}.md` with frontmatter and body structured according to those schemas.

Key source fields: `id`, `type` (article/paper/video/book/docs/talk/other), `title`, `url` or `filename`, `date_ingested`, `concepts`, `author`, `tags`.

Update `{WIKI_ROOT}/index.md`: add an entry under `## Sources` for `[[{source_id}]]`.

### G8 — Append to log

Append to `{WIKI_ROOT}/log.md`:

```
## [{today}] ingest | {source_id} — {title}
Pages written: {list of ids}
```

### G9 — Confirm

```
Ingest complete
  Source:    {source_id}
  New pages: N
  Enriched:  N
```

---

## Wiki Query

Answer a question from wiki content. Usage: `wiki query <question>`

### Q1 — Read index

Read `{WIKI_ROOT}/index.md`. Identify all page entries relevant to `<question>` by matching concepts, terms, and keywords.

**If no relevant pages found:**
> No wiki pages found covering: "{question}"
> Missing concepts: {list}
> Options:
>   1. Run `wiki ingest <url>` to add a source covering these concepts
>   2. Run `wiki ingest <filename>` if you have a source in raw/
>   3. Create a stub page and enrich it later

Stop.

### Q2 — Read relevant pages

Read each relevant page. Collect the content and note each page's id.

### Q3 — Synthesise answer

Produce a clear, accurate answer to `<question>` based solely on the wiki content read. Every claim must cite the wiki node it came from using `[[wikilink]]` notation.

Example: "Attention allows the model to weight input positions differently [[attention_mechanism]]. This is the core of the Transformer architecture [[transformer_architecture]]."

Present the answer to the user.

### Q4 — Offer to save

After presenting the answer, ask:
> Save this as a wiki page? [y/N]

If no: done. Nothing is written.

### Q5 — Save query answer as wiki page

Derive an id from the question (snake_case, max 5 words).

Read `{SKILL_DIR}/assets/schemas/concept.json` and `{SKILL_DIR}/assets/schemas/content/concept.json`. Generate frontmatter covering all required fields and the body using the defined sections. The `sources` field must list every `[[node_id]]` that was read to produce the answer.

Show the proposed frontmatter and body outline to the user and ask:
> Confirm this id and frontmatter? [y/N] (or suggest changes)

If confirmed: write `{WIKI_ROOT}/concepts/{id}/{id}.md`.

### Q6 — Update index and log

Update `{WIKI_ROOT}/index.md`: add `- [[{id}]] — {one-line description}` under `## Concepts`.

Append to `{WIKI_ROOT}/log.md`:
```
## [{today}] query-save | {id} — {question}
Sources consulted: {list of node ids}
```

---

## Wiki Lint

Health-check the wiki graph. Usage: `wiki lint`

### L1 — Orphan check

1. Enumerate all `*.md` files under `{WIKI_ROOT}` node directories (`concepts/`, `sources/`, `authors/`, `tools/`, `workflows/`, `terms/`, `ideas/`, `unorganized/`). Build the full set of page ids.
2. Scan all pages for `[[wikilink]]` references. Build an inbound-link map: `id → set of ids that link to it`.
3. Identify pages with zero inbound links (orphans).

**If orphans found:**
```
Orphan pages (no inbound links):
  - concepts/orphan_concept/orphan_concept.md
  - terms/unused_term/unused_term.md

Options for each: link from a parent page, or delete.
```
Ask the user what to do for each orphan.

**If no orphans:** report "No orphans found."

### L2 — Stub check

For each page enumerated in L1:
1. Read the file
2. Strip the YAML frontmatter block (everything between `---` markers at the top)
3. Count non-empty body lines

Flag pages with fewer than 5 body lines as stubs.

**If stubs found:**
```
Stub pages (fewer than 5 body lines):
  - concepts/sparse_concept/sparse_concept.md (2 lines)
  - tools/empty_tool/empty_tool.md (1 line)

Options: enrich manually or run `wiki ingest` targeting these concepts.
```

**If no stubs:** report "No stubs found."

### L3 — Index gap check

1. Read `{WIKI_ROOT}/index.md`. Extract all `[[wikilink]]` entries.
2. Compare against the full set of page ids from L1.
3. Identify pages on disk that have no entry in `index.md`.

**If gaps found:**
```
Pages missing from index.md:
  - [[new_concept]] (concepts/new_concept/new_concept.md)

Proposed index.md entries:
  Under ## Concepts:
    - [[new_concept]] — <one-line description from page title>

Add these entries? [y/N]
```

If yes: update `index.md` with the proposed entries.

### L4 — Append lint log

Append to `{WIKI_ROOT}/log.md`:

```
## [{today}] lint | {N} pages, {N} orphans, {N} stubs, {N} index gaps
```

### L5 — Lint summary

```
Lint complete
  Pages checked:  N
  Orphans:        N
  Stubs:          N
  Index gaps:     N
```

---

## Wiki Help

Print the command reference. Usage: `wiki help` or `wiki commands`

```
vibe-wiki commands
──────────────────────────────────────────────────────

wiki init
  Initialise a new wiki. Creates directory structure and copies starter
  files (index.md, log.md) to wiki.root. Requires vibe-wiki.yaml.

wiki ingest <url-or-filename>
  Ingest a source into the wiki. <url-or-filename> can be:
    https://example.com/article  — fetched from the web
    transformer_paper.pdf        — resolved to raw/<filename>
  Flow: summarise → confirm → map to nodes → confirm → save → register.

wiki query <question>
  Answer a question from wiki content. Reads index.md, finds relevant
  pages, synthesises an answer with [[wikilink]] citations. Optionally
  saves the answer as a new wiki page.

wiki lint
  Health-check the wiki graph:
    • Orphan pages (no inbound wikilinks)
    • Stub pages (fewer than 5 body lines)
    • Pages missing from index.md
  Appends a summary entry to log.md.

wiki generate schema
  Loads custom node-type schemas into the session. Reads
  wiki.additional_schemas from vibe-wiki.yaml — each entry is a
  directory of *.json schema files defining frontmatter and body
  sections for custom node types.

wiki help | wiki commands
  Show this command reference.

──────────────────────────────────────────────────────
Config: vibe-wiki.yaml (project root)
```

---

## Wiki Generate Schema

Generate custom schema files for additional node types. Usage: `wiki generate schema`

### GS1 — Read config

Read `wiki.additional_schemas` from `vibe-wiki.yaml`. Each entry is a path to a directory containing pre-written `*.json` schema files. These schemas follow the same structure as the built-in schemas in `{SKILL_DIR}/assets/schemas/` — they define the frontmatter fields and body sections for custom node types.

If the key is absent or empty:
> No additional schemas configured. Add directory paths under `wiki.additional_schemas` in vibe-wiki.yaml.

Stop.

### GS2 — Load custom schemas

For each directory path in `wiki.additional_schemas`:

1. Resolve the path (relative to the project root)
2. Read each `*.json` file in that directory
3. Make those schemas available for this session — when a user asks to create a page of a custom type, use the matching schema to know which frontmatter fields to populate and which body sections to include

### GS3 — Confirm

```
Custom schemas loaded
  Types available: {list of schema ids}
```
