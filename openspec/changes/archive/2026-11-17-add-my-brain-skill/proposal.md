## Why

The user's working principles are scattered: `agentic/CLAUDE.md` has three, `krishna/CLAUDE.md` has a different four, and `~/.claude/CLAUDE.md` plus `~/CLAUDE.md` are Ruflo-generated boilerplate that nobody wrote by hand. None of it is versioned in a place meant for reuse. Consolidating into one skill and one git-tracked global CLAUDE.md makes the rules reproducible, reviewable, and portable.

## What Changes

- Add skill `my-brain` holding the five principles (everything as code, decoupled, structured, scalable, measured), each with a test question.
- Add `global/CLAUDE.md`: docstring/comment rule, the four behavioral guidelines, and a pointer to `my-brain`. It is symlinked to `~/.claude/CLAUDE.md`.
- Add a `Taskfile.yaml` with `task link` that symlinks `global/CLAUDE.md` into `~/.claude`, refusing to overwrite real files. Skills are not linked; they are installed with `npx skills add`.
- Remove the Principles section from `agentic/CLAUDE.md`; delete the file if nothing repo-specific remains.
- Add `my-brain` to the README skills table.
- `krishna/` is not touched.
- Deleting the Ruflo-generated `~/CLAUDE.md` and the Ruflo block in `~/.claude/CLAUDE.md` is done by the user, not by this change.

## Capabilities

### New Capabilities
- `my-brain-skill`: the `my-brain` skill — frontmatter, broad trigger description, the five principles with test questions.
- `global-claude-config`: the git-tracked global CLAUDE.md, its content rules, and the `task link` mechanism that symlinks it (and skills) into `~/.claude`.

### Modified Capabilities

(none)

## Impact

- New: `skills/my-brain/SKILL.md`, `global/CLAUDE.md`, `Taskfile.yaml`.
- Edited: `CLAUDE.md` (principles removed), `README.md`.
- Machine state: `~/.claude/CLAUDE.md` becomes a symlink (after the user backs up the existing file).
- No dependencies added; `go-task` is already in the flake dev shell.
