## Why

vibe_learn bundles two distinct roles — Socratic tutor and wiki maintainer — into a single skill. Users who want a persistent, compounding wiki without the curriculum/tutor layer have no standalone option. Additionally, the wiki half only works with Claude Code; Karpathy's LLM Wiki pattern (which vibe_learn already implements in spirit) explicitly targets multiple providers (Claude Code, Codex/AGENTS.md). A dedicated `vibe_wiki` skill separates these concerns and adds the missing provider-awareness and local-file ingest path.

## What Changes

- **New skill file**: `SKILL.md` for `vibe_wiki` — pure wiki management, no tutor, no curriculum, no progress tracking
- **New `skill.json`**: manifest for the `vibe_wiki` skill with multi-platform compatibility (`claude-code`, `codex`)
- **New `raw/` starter directory**: convention for immutable source files; ingest resolves filename args against this dir
- **Extended ingest command**: argument can be a URL *or* a filename (resolved to `raw/<filename>`); routing is explicit
- **Provider-aware init**: `wiki init` detects or prompts for provider and emits `CLAUDE.md` (Claude Code) or `AGENTS.md` (Codex) as the wiki schema document
- **Query → wiki operation**: explicit `wiki answer` command saves synthesized answers back as wiki pages
- **Shared assets**: `vibe_wiki` reuses vibe_learn's existing node schemas (`assets/schemas/`) and starter files (`index.md`, `log.md`) — no duplication

No changes to existing `vibe_learn` skill files. The two skills are siblings; vibe_learn's wiki logic is unchanged.

## Capabilities

### New Capabilities

- `wiki-init`: Initialise a new wiki — create directory structure, emit provider-specific schema doc (CLAUDE.md or AGENTS.md), copy starter files
- `wiki-ingest`: Ingest a source into the wiki; argument is a URL or a filename looked up in `raw/`; registers result in `sources/`
- `wiki-query`: Answer a question from wiki content; optionally save the answer as a new wiki page
- `wiki-lint`: Health-check the wiki graph (orphans, stubs, broken links, stale claims)
- `provider-routing`: Detect active provider and map operations to correct tool names (Read/WebFetch vs file_search/web_search)

### Modified Capabilities

- `ingest`: Existing vibe_learn URL ingest workflow gains a filename-to-raw/ branch — but this lives in vibe_wiki, not vibe_learn; no change to vibe_learn

## Impact

- New files in this repo: `SKILL.md` (vibe_wiki), `skill.json` (vibe_wiki), `assets/starter/raw/.gitkeep`
- Reuses without modification: `assets/schemas/`, `assets/bases/`, `assets/starter/index.md`, `assets/starter/log.md`
- No changes to existing `SKILL.md` (vibe_learn), `skill.json` (vibe_learn), or any reference docs
- User-facing: new `/vibe_wiki` invocation; existing `/vibe_learn` unchanged
