## 1. my-brain skill

- [x] 1.1 Create `skills/my-brain/SKILL.md` with frontmatter (name, broad description) and the five principles with rule + test question
- [x] 1.2 Verify: frontmatter valid per agentskills.io, description < 1024 chars, `npx skills` lists it

## 2. Global CLAUDE.md

- [x] 2.1 Create `global/CLAUDE.md`: docstring/comment rule, four behavioral guidelines, pointer to `my-brain`
- [x] 2.2 Remove the Principles section from `CLAUDE.md`; delete the file if nothing repo-specific remains
- [x] 2.3 Verify: principles text exists only in `skills/my-brain/SKILL.md`

## 3. Link task

- [x] 3.1 Create `Taskfile.yaml` with `link` task for `global/CLAUDE.md` only (idempotent, refuses to overwrite real files or foreign links)
- [x] 3.2 Verify in a temp `HOME`: fresh create, re-run no-op, real-file refusal

## 4. Wrap-up

- [x] 4.1 Add `my-brain` row to the README skills table
- [x] 4.2 Confirm `git status` shows no changes under `krishna/`
- [ ] 4.3 User step (manual): back up and remove `~/.claude/CLAUDE.md` and `~/CLAUDE.md`, then run `task link`
