## Why

The `.state/` directory is created during `wiki init` but is never read, written, or referenced by any subsequent wiki command (ingest, query, lint, generate schema). It is a tutor-pattern artifact — designed for tracking learner session progress — that was carried into vibe-wiki without being wired up. A wiki's persistent state is the wiki itself (`index.md`, `log.md`, and page files); there is no session-level user state to track.

## What Changes

- Remove `.state/` from the directory tree created by `wiki init` (SKILL.md step I1)

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `wiki-init`: Remove `.state/` from the required directory structure. The spec currently mandates its creation; that requirement is being dropped.

## Impact

- `skills/vibe-wiki/SKILL.md` — one line removed from the I1 directory list
- `openspec/specs/wiki-init/spec.md` — requirement updated to remove `.state/` from the directory list and scenarios
