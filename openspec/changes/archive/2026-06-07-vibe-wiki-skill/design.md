## Context

vibe_learn ships as a single SKILL.md that fuses a Socratic tutor with a wiki maintainer. The wiki half already implements the pattern Karpathy describes in his LLM Wiki gist: raw sources → LLM-maintained markdown wiki → schema document that tells the LLM how to operate. The gap: the wiki half is Claude Code-only, has no concept of an immutable `raw/` sources directory, and has no standalone entry point for users who only want wiki management.

`vibe_wiki` is a new sibling skill. It extracts and extends the wiki-maintenance half without modifying vibe_learn.

## Goals / Non-Goals

**Goals:**
- Standalone wiki skill with no tutor or curriculum dependencies
- Multi-provider: works with Claude Code (`CLAUDE.md`) and Codex (`AGENTS.md`)
- `raw/` directory convention for local file ingestion alongside URL ingestion
- Ingest argument resolves: `http(s)://` → WebFetch/web_search; filename → `raw/<filename>`
- `wiki answer` saves synthesized query responses back as wiki pages
- Reuses vibe_learn's 11 node-type schemas and Obsidian-compatible structure

**Non-Goals:**
- Modifying vibe_learn in any way
- Embedding infrastructure or vector search (index.md + grep is sufficient at target scale)
- A runtime server or CLI binary
- Curriculum, progress tracking, or Socratic teaching

## Decisions

### Decision 1: Sibling skill, not extraction

**Choice**: `vibe_wiki` is a new independent skill that coexists with `vibe_learn`.

**Rationale**: Modifying vibe_learn risks breaking existing users. Extraction (making vibe_learn delegate to vibe_wiki) is a later migration if desired. A sibling costs one duplicated startup routine; the benefit is zero regression risk.

**Alternatives considered**:
- *vibe_learn delegates to vibe_wiki internally* — cleaner long-term, but requires vibe_learn changes and a migration path. Deferred.
- *vibe_wiki as a mode flag in vibe_learn* — conflates two distinct skill contracts into one file. Rejected.

### Decision 2: Provider detection via config key

**Choice**: `vibe_wiki.config.yaml` includes a `provider` key (`claude-code` | `codex`). `wiki init` reads it and emits the appropriate schema doc.

**Rationale**: Provider can't be reliably autodetected at skill-invocation time. A config key is explicit and survives session restarts. Emitting `CLAUDE.md` or `AGENTS.md` once at init time means every subsequent session just reads the file — no repeated detection logic.

**Alternatives considered**:
- *Detect by which tools respond* — unreliable; both providers may be available in hybrid setups.
- *Single `WIKI.md` schema doc for all providers* — simpler but loses provider-specific tool name accuracy. Rejected.

### Decision 3: Ingest argument routing

**Choice**: Ingest command inspects the argument string prefix:
- Starts with `http://` or `https://` → fetch via provider's web tool
- Otherwise → treat as filename, look up `raw/<filename>`; error if not found

**Rationale**: Simple, unambiguous, no config needed. Users drop files in `raw/` and pass the filename. This mirrors Karpathy's raw-layer convention exactly.

### Decision 4: Asset reuse without copying

**Choice**: `vibe_wiki`'s `skill.json` installer points to the same `assets/schemas/` and `assets/starter/` directories as vibe_learn. No duplication.

**Rationale**: Schema definitions are domain-neutral (concept, source, author, etc.) — they belong to neither skill specifically. If a user installs both skills, they share one asset tree.

**Risk**: If schemas evolve differently for each skill in future, this coupling becomes a problem. Acceptable at v1.

### Decision 5: Query-to-wiki is opt-in per invocation

**Choice**: `wiki answer <question>` asks the question, presents the answer, then prompts: "Save this as a wiki page? [y/N]". No auto-save.

**Rationale**: Not every query produces page-worthy content. Forcing confirmation matches vibe_learn's ingest confirmation pattern and prevents wiki clutter.

## Risks / Trade-offs

- **Schema drift**: vibe_wiki reuses vibe_learn schemas. If vibe_learn schemas change incompatibly, vibe_wiki users' wikis may break. → Mitigation: schemas are versioned via `$schema` field; vibe_wiki pins to `vibe_learn/schema/v1`.
- **Provider tool-name accuracy**: Codex tool names may change as the platform evolves. → Mitigation: provider-specific schema fragment is a separate file (`providers/codex.md`) — easy to update without touching SKILL.md.
- **index.md scalability**: At ~100+ sources the index-scan approach slows. → Mitigation: Karpathy's gist explicitly calls this out and recommends `qmd` as a future add-on. Not in scope for v1; noted in SKILL.md as an optional upgrade.

## Migration Plan

No migration needed. New files only:
1. `SKILL.md` (vibe_wiki skill definition)
2. `skill.json` (vibe_wiki manifest)
3. `providers/claude-code.md`, `providers/codex.md` (schema fragments)
4. `assets/starter/raw/.gitkeep` (raw sources dir convention)

Existing vibe_learn files untouched. Users install vibe_wiki independently via `npx skills add knvpk/VibeWiki`.

## Open Questions

- Should `wiki init` also generate a `vibe_wiki.config.yaml` template, or ask interactively? (Lean toward template, consistent with vibe_learn.)
- Is `wiki answer` the right command name, or `wiki query`? (`wiki query` is more consistent with the operations vocabulary.)
