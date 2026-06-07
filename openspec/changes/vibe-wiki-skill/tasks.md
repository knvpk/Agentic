## 1. Config and Provider Setup

- [x] 1.1 Create `assets/vibe_wiki.config.template.yaml` with keys: `wiki.root`, `provider`, `ingest.*`, `obsidian.enabled`
- [x] 1.2 Create `providers/claude-code.md` — tool name mappings and Claude Code-specific wiki schema fragment
- [x] 1.3 Create `providers/codex.md` — tool name mappings and Codex-specific wiki schema fragment
- [x] 1.4 Create `assets/starter/raw/.gitkeep` to establish the `raw/` directory convention

## 2. Skill Manifest

- [x] 2.1 Create `skill.json` for vibe_wiki with `name`, `version`, `description`, `platforms: ["claude-code", "codex"]`, `tags`, and installer paths [restart-required]
- [x] 2.2 Verify `skill.json` install paths point to shared `assets/schemas/` and `assets/starter/` (no duplication)

## 3. SKILL.md — Startup and Init

- [x] 3.1 Write SKILL.md header: frontmatter (`name`, `version`, `description`, `allowed-tools`), invocation triggers [restart-required]
- [x] 3.2 Write Startup section: read `vibe_wiki.config.yaml`, resolve `SKILL_DIR`, resolve provider, halt with instructions if config missing
- [x] 3.3 Write `wiki init` section: create directory tree, copy starter files (skip existing), compose and write CLAUDE.md or AGENTS.md from provider fragment

## 4. SKILL.md — Ingest

- [x] 4.1 Write ingest argument routing: inspect arg prefix → URL branch (WebFetch/web_search) or filename branch (resolve to `raw/<filename>`)
- [x] 4.2 Write ingest flow: summarise → confirm → map to wiki nodes → confirm placement → save pages → register in `sources/` → append to `log.md`
- [x] 4.3 Add error path: filename not found in `raw/` → list `raw/` contents and stop

## 5. SKILL.md — Query

- [x] 5.1 Write `wiki query` section: read `index.md` → identify relevant pages → read pages → synthesise answer with `[[wikilink]]` citations
- [x] 5.2 Write save-to-wiki prompt: after answer, ask "Save as wiki page? [y/N]"; if yes, propose id + frontmatter → confirm → write page → update `index.md` → append `log.md`
- [x] 5.3 Ensure saved query pages include `sources` frontmatter listing contributing node IDs

## 6. SKILL.md — Lint

- [x] 6.1 Write orphan check: scan all node dirs, build inbound-link map from wikilinks across all pages, report nodes with zero inbound links
- [x] 6.2 Write stub check: flag pages with fewer than 5 lines of body content (excluding frontmatter)
- [x] 6.3 Write index gap check: diff files on disk against `index.md` entries; offer to add missing entries
- [x] 6.4 Write lint log append: write `## [<date>] lint | <N> pages, <N> orphans, <N> stubs, <N> index gaps` to `log.md`

## 7. SKILL.md — Help and Schema Generation

- [x] 7.1 Write `help` / `commands` output block covering: init, ingest, query, lint, help, generate schema
- [x] 7.2 Port `generate schema` command from vibe_learn verbatim (reads `wiki.additional_schemas` config key, writes to `{wiki.root}.schemas/`)

## 8. Verification

- [ ] 8.1 Invoke `/vibe_wiki` in a fresh project, run `wiki init` with `provider: claude-code`, verify CLAUDE.md is emitted with correct tool names
- [ ] 8.2 Run `wiki ingest https://...` — verify summarise → confirm → save → sources/ entry → log.md append
- [ ] 8.3 Run `wiki ingest <filename>` with file present in `raw/` — verify correct routing and save
- [ ] 8.4 Run `wiki ingest <missing>` — verify error message and raw/ listing
- [ ] 8.5 Run `wiki query` and save the answer — verify page written with correct frontmatter and sources
- [ ] 8.6 Run `wiki lint` on a wiki with an orphan and a stub — verify both reported and log.md updated
