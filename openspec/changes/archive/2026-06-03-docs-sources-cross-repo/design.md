## Context

The `project-management` skill's Context Fallback Chain reads docs from `docs/` in the current repo only. In multi-repo architectures (e.g. a frontend repo + a backend repo), the frontend's tickets and bulk generation have no visibility into the backend's architecture, database schema, or PRD.

The solution: let `.project/config.yaml` declare sibling repos via `docs_sources`, and auto-discover them from `.gitmodules`. The skill reads docs from all resolved sources and labels content by origin.

## Goals / Non-Goals

**Goals:**
- `docs_sources` config key accepts an array of `{path, url?, exclude?}` objects
- Git submodules with a `docs/` folder are auto-discovered and merged with `docs_sources`
- `exclude: true` on any entry (explicit or auto-discovered) suppresses that source
- Resolution: read from disk if path exists; fall back to GitHub MCP fetch using `url` if path is missing
- All cross-repo docs content is labelled `[from: <repo-name>]` in ticket context
- `pm init` detects submodules and prompts once; confirmed entries written to `docs_sources`
- Read-only: skill never writes to any `docs_sources` path

**Non-Goals:**
- Writing docs to sibling repos
- Syncing or caching remote docs locally
- Multi-level transitive discovery (sibling's siblings)
- Non-GitHub remotes for MCP fallback (GitHub MCP only for now)

## Decisions

### D1 — Config shape: array of objects, not strings

**Decision**: `docs_sources` is an array of objects with `path` (required), `url` (optional), and `exclude` (optional boolean).

```yaml
docs_sources:
  - path: ../backend
    url: https://github.com/knvpk/backend
  - path: vendor/ui-lib
    exclude: true
```

**Rationale**: A plain string array cannot express exclusion or carry a URL override. An object per entry keeps all information for a source co-located. `exclude: true` works for both explicit suppression and overriding an auto-discovered submodule without duplicating the entry.

**Alternative considered**: Separate `docs_sources_exclude` top-level key. Rejected — splits related information across two keys; an array of objects is more cohesive.

### D2 — Submodule auto-discovery reads `.gitmodules` at runtime

**Decision**: On every docs-reading operation, parse `.gitmodules` to get `{path, url}` for each submodule. Merge with `docs_sources`. Any path already in `docs_sources` (with or without `exclude`) takes precedence over the auto-discovered entry.

**Rationale**: `.gitmodules` already encodes both path and remote URL — no config duplication needed. Runtime parsing means newly added submodules are picked up without re-running `pm init`.

**Merge / deduplication rule**: if the same `path` appears in both `docs_sources` and `.gitmodules`, the `docs_sources` entry wins entirely (its `url`, `exclude`, etc. override the auto-discovered values).

### D3 — Fallback resolution order: disk first, then GitHub MCP

**Decision**: For each resolved source:
1. Check if `path` exists on disk and has a `docs/` folder → read all `.md` files from it
2. If path missing or has no `docs/`: if `url` is present, parse `owner/repo` from it and fetch `docs/` file listing via GitHub MCP `get_file_contents`
3. If neither: emit `⚠ <name>: path missing, no url — skipped`

**URL parsing**: accept both `https://github.com/org/repo` and `git@github.com:org/repo.git`; normalize to `org/repo` for MCP calls.

### D4 — Context Fallback Chain insertion point: step 5

**Decision**: Insert `docs_sources` resolution at step 5, after local `docs/` files and before local repo source files.

```
1. docs/prd.md
2. docs/architecture.md
3. docs/database.md / docs/local-storage.md
4. docs/tools.md
5. docs_sources docs/   ← NEW
6. local repo files (src/, lib/, config)
7. context_repos
8. warn
```

**Rationale**: Structured project docs (both local and sibling) are higher signal than source code. Sibling docs belong adjacent to local docs, not after raw source files.

### D5 — Labelling: `[from: <folder-name>]`

**Decision**: Every snippet drawn from a `docs_sources` entry is prefixed with `[from: <folder-name>]` where `folder-name` is the last path segment (e.g. `../backend` → `backend`).

**Rationale**: Ticket context must be attributable. Engineers need to know whether an architecture constraint came from the current repo or a sibling.

### D6 — `pm init` submodule prompt: ask once, write to config

**Decision**: During `pm init`, if `.gitmodules` is found, list detected submodules and ask: *"Found submodules: [list]. Include their docs/ as doc sources? [all / select / none]"*. Write confirmed entries to `docs_sources` in `.project/config.yaml`. Auto-sets `url` from `.gitmodules`.

**Rationale**: Explicit opt-in at init time keeps the config as the authoritative record. Runtime auto-discovery still runs for submodules added after init.

## Risks / Trade-offs

**[Risk] Submodule not initialized (path empty on disk)** → Mitigated by D3: URL fallback via GitHub MCP handles un-initialized submodules.

**[Risk] Irrelevant submodule docs pollute ticket context** → Mitigated by D2 deduplication and `exclude: true`; also by the existing relevance filter (only sections matching the ticket topic are included).

**[Risk] Private repo MCP fetch fails silently** → Skill emits a warning when MCP fetch returns no results; user can investigate.

**[Risk] `url` field not provided and path missing** → Skill skips with a clear warning (D3 step 3).
