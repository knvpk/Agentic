## 1. Config Schema — `docs_sources` key

- [ ] 1.1 Add `docs_sources` to the config schema documentation in SKILL.md — array of objects with `path` (string, required), `url` (string, optional), `exclude` (boolean, optional)
- [ ] 1.2 Add a config example block showing both a plain entry with `url` and an `exclude: true` entry

## 2. Shared: `docs_sources` Resolution Logic

- [ ] 2.1 Add a "Resolve docs sources" shared procedure to SKILL.md:
  - Read `docs_sources` from `.project/config.yaml` (default to empty array if absent)
  - Parse `.gitmodules` if present: extract `{path, url}` for each submodule
  - Merge: for each submodule entry, if its `path` already appears in `docs_sources`, skip the auto-discovered entry; otherwise append it
  - Filter out any entry where `exclude: true`
- [ ] 2.2 Add URL normalization rule: accept `https://github.com/org/repo`, `https://github.com/org/repo.git`, and `git@github.com:org/repo.git`; all normalize to `org/repo` for MCP calls
- [ ] 2.3 Add per-source read logic:
  - If `path` exists on disk with a `docs/` subfolder → read all `.md` files from `path/docs/`
  - Else if `url` present → use GitHub MCP `get_file_contents` to list and fetch `docs/*.md`
  - Else → emit `⚠ <folder-name>: path missing, no url — skipped`
- [ ] 2.4 Add labelling rule: prefix every retrieved snippet with `[from: <last-path-segment>]`

## 3. Context Fallback Chain — Insert Step 5

- [ ] 3.1 Update the Context Fallback Chain in SKILL.md — insert step 5 between local `docs/tools.md` (step 4) and local repo files (current step 5):
  ```
  5. docs_sources docs/  → run Resolve docs sources; for each resolved source,
                           find sections matching the ticket topic by keyword;
                           label each snippet [from: <name>]
  ```
- [ ] 3.2 Renumber the existing steps 5–7 to 6–8

## 4. `pm init` — Submodule Detection Step

- [ ] 4.1 Add a submodule detection step to `pm init` (after provider config, before docs scaffold offer):
  - Check if `.gitmodules` exists in the repo root
  - If found, list submodule paths and ask: *"Found submodules: [list]. Include their docs/ as doc sources? [all / select / none]"*
  - For `all`: write all submodules to `docs_sources` with their `url` from `.gitmodules`
  - For `select`: prompt per submodule with `[y/n]`; write confirmed ones
  - For `none`: skip; user can add manually later
- [ ] 4.2 Write confirmed entries to `.project/config.yaml` under `docs_sources`

## 5. `pm docs` — Cross-Repo Awareness

- [ ] 5.1 In `pm docs` (scaffold and fill modes), after listing local docs files, add a note showing which `docs_sources` are active: `Doc sources: backend (disk), design-system (remote)`
- [ ] 5.2 Ensure the skill never attempts to scaffold or write files in any `docs_sources` path

## 6. `pm bulk` — Multi-Source Doc Read

- [ ] 6.1 In `pm bulk`, after reading local `docs/` files, run Resolve docs sources and read all available docs from each source
- [ ] 6.2 Label each section in the ticket generation manifest with its source: `[local]` or `[from: <name>]`

## 7. Verification

- [ ] 7.1 Trace: frontend repo with `.gitmodules` pointing to backend, backend has `docs/architecture.md`; run `pm ticket "user login"` — confirm `[from: backend]` architecture section appears in context
- [ ] 7.2 Trace: same setup with `exclude: true` on backend entry in `docs_sources` — confirm backend docs are NOT included
- [ ] 7.3 Trace: submodule path not initialized on disk but `url` present — confirm MCP fetch is attempted and snippet is labelled correctly
- [ ] 7.4 Trace: submodule with no `docs/` folder — confirm it is silently skipped with no error
- [ ] 7.5 Trace: `pm init` with `.gitmodules` present — confirm prompt appears and selected entries are written to config
