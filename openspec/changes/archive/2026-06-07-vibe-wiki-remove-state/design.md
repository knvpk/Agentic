## Context

The vibe-wiki skill creates `.state/` in `wiki init` (SKILL.md, step I1) but no command ever reads from or writes to it. The `wiki-init` spec currently mandates `.state/` as part of the required directory tree.

## Goals / Non-Goals

**Goals:**
- Remove `.state/` from the `wiki init` directory tree
- Update the `wiki-init` spec to reflect the removal

**Non-Goals:**
- Introducing a replacement state mechanism
- Modifying any other wiki command behaviour
- Migrating or cleaning up existing `.state/` directories in user wikis

## Decisions

**Remove without replacement** — There is no code path that populates or reads `.state/`. Keeping it as an "extension point" adds confusion without value; any future need can add the directory when that feature is actually implemented.

**Spec update is required** — The `wiki-init` spec explicitly names `.state/` in a SHALL requirement and in scenario step descriptions. The spec must be updated to stay accurate; leaving it inconsistent with the skill would cause the next spec-driven implementation pass to re-add the directory.

## Risks / Trade-offs

- **Existing user wikis** — Users who have already run `wiki init` will have a `.state/` directory sitting unused. This change does not touch those; the directory just stops being recreated on fresh inits. No data loss, no breakage.

## Open Questions

_(none)_
