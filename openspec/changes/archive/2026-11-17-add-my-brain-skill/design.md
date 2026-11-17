## Context

Global instructions currently live as plain files in `~/.claude/` and `~/`, outside git. The repo already installs skills with `npx skills add`, and `~/.claude/skills/` already uses symlinks for some skills. The repo's `CLAUDE.md` would be loaded twice inside this repo if `~/.claude/CLAUDE.md` pointed at it.

## Goals / Non-Goals

**Goals:**
- One git-tracked source for global Claude rules and principles.
- Reproducible setup on a new machine with one command.
- Principles usable as review lenses, not just statements.

**Non-Goals:**
- Editing `krishna/`.
- Removing Ruflo hooks/MCP wiring from Claude settings.
- Carrying over the old "run tests after changes" rule.

## Decisions

1. **Dedicated `global/CLAUDE.md`, not the repo-root `CLAUDE.md`.** Linking the root file would load it twice in this repo and mix global rules with repo rules. Alternative rejected: Option A (link root).
2. **Principles in a skill, constraints in CLAUDE.md.** The docstring rule constrains every output so it must be always loaded. Principles are design lenses, so description-based loading is acceptable, backed by a one-line pointer in CLAUDE.md.
3. **Each principle carries a test question** (e.g. "Could another project reuse this without edits?"). Makes the skill applicable during review.
4. **`task link` via Taskfile, CLAUDE.md only.** Skills are installed with `npx skills add`, so linking them would duplicate that and clash with existing links. Matches the user's `taskfile-conventions`; `go-task` is already in the dev shell. Script is idempotent: if the target is already the correct symlink, do nothing; if it is a real file or a different link, stop with an error. No `--force`.
5. **Behavioral guidelines stay in `global/CLAUDE.md`.** They govern Claude's behavior, not design, and must be always loaded.
6. **Wide trigger description** for `my-brain`: any design, coding, review, scaffolding of code, config or infra. A narrow description would mean it never loads.

## Risks / Trade-offs

- [Skill may not load] → CLAUDE.md pointer line names the skill explicitly.
- [Existing `~/.claude/CLAUDE.md` is a real file] → `task link` refuses and tells the user to back it up and remove it first.
- [Rules in one place drift from `krishna/CLAUDE.md`] → accepted; krishna is out of scope and can point at the skill later.
