## Why

The `project-management` skill reads `docs/` only from the current repo. When a frontend and backend live in separate repos, the frontend's tickets are generated without awareness of the backend's `docs/prd.md`, `docs/architecture.md`, `docs/database.md`, etc. This causes tickets to miss critical context about the API contracts, data models, and architecture they depend on.

## What Changes

- **`docs_sources` config key** — new array of `{path, url, exclude}` objects in `.project/config.yaml`; each entry points to a sibling repo whose `docs/` should be consulted
- **Git submodule auto-discovery** — on every docs-reading operation the skill reads `.gitmodules` and auto-includes any submodule that has a `docs/` folder, merging with explicit `docs_sources` entries and honoring `exclude: true`
- **Context Fallback Chain** — `docs_sources` entries (both explicit and auto-discovered) are inserted at step 5, after local `docs/` and before local repo files
- **`pm init`** — detects `.gitmodules` at setup time, asks which submodules to include, and writes confirmed entries to `docs_sources`
- **`pm docs` / `pm bulk`** — reads docs from all resolved sources, labels each snippet with its origin repo name
- **Read-only** — the skill never writes to a `docs_sources` path; all cross-repo access is read-only

## Capabilities

### New Capabilities

- `docs-sources-cross-repo`: Skill resolves docs from sibling repos declared in `docs_sources` or auto-discovered from `.gitmodules`; content is labelled by source and used in ticket context, bulk generation, and docs mode

### Modified Capabilities

- `project-type-detection`: `pm init` gains a submodule detection step that prompts the user to confirm which submodules to include as doc sources
- `ticket-content-generation`: Context Fallback Chain gains a new step 5 for `docs_sources` resolution
- `bulk-ticket-generation`: Bulk mode reads docs from all resolved sources

## Impact

- `skills/project-management/SKILL.md` — `pm init`, `pm docs`, `pm bulk`, Context Fallback Chain, config schema docs
- `openspec/specs/docs-sources-cross-repo/spec.md` — new spec
