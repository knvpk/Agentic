## Why

When `docs` mode scaffolds project documentation, it creates files containing only empty section headers — no content, no questions asked. Users who invoke `docs` expecting to capture their project knowledge are left with stub files they must manually fill, and there is no guided path to populate any doc file interactively. The same passivity applies when editing: the skill waits for the user to supply content rather than asking targeted questions per section.

## What Changes

- **New fill flow** triggered after scaffolding and via explicit routing phrases ("fill docs", "populate docs", "fill in the PRD/tools/etc.")
- **Smart grouped questions** (~7-10 per project type) where each answer fills one or more sections across multiple files simultaneously, rather than one-question-per-section wizard fatigue
- **Step 3 empty-section behaviour**: when a user targets a specific section that is currently empty, the skill asks the targeted question for that section rather than waiting passively for content
- **Append-only writes**: when a section already contains content and the skill fills or edits it, new content is appended below a `---` divider — existing content is never overwritten
- **Broader routing**: all doc files (`prd.md`, `architecture.md`, `database.md`, `tools.md`, `api.md`, `services.md`, `local-storage.md`) are equally reachable by the fill flow, not just `tools.md` and `api.md`

## Capabilities

### New Capabilities

- `docs-interactive-fill`: The grouped Q&A fill flow — question-to-section mapping per project type, fill routing, append behaviour, skip/done flow control, and post-fill summary

### Modified Capabilities

- `docs-management`: Add requirement for interactive fill offer after scaffold (Step 2b); add requirement that Step 3 asks targeted question when target section is empty; extend routing table with fill-intent phrases

## Impact

- `skills/project-management/SKILL.md`: MODE: docs block (Steps 2 and 3), Mode Routing table
- No new files, no breaking changes to existing ticket/sprint/bulk flows
- No config schema changes
