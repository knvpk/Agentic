## 1. Mode Routing

- [x] 1.1 Add fill-intent routing phrases to Mode Routing table: "fill docs", "fill in docs", "populate docs", "fill in the {file}" → docs mode
- [x] 1.2 Clarify routing note: fill-intent phrases skip scaffold check and jump directly to Interactive Fill Flow for existing files

## 2. Step 2b — Post-Scaffold Fill Offer

- [x] 2.1 After Step 2 scaffold writes any new files, output `Created: {file list}. Fill them in now? [y/n]`
- [x] 2.2 On `y`: invoke the Interactive Fill Flow (Step 2b hands off to the new flow)
- [x] 2.3 On `n`: exit docs mode cleanly with no further output

## 3. Interactive Fill Flow — New Section

- [x] 3.1 Add `### Interactive Fill Flow` section to MODE: docs in SKILL.md
- [x] 3.2 Define core question set (5 questions) with target section mapping table (as specified in docs-interactive-fill spec)
- [x] 3.3 Define conditional questions block: per-project_type questions with target section mapping
- [x] 3.4 Define optional questions block: 4 questions prefixed with `(optional — press Enter to skip)`
- [x] 3.5 Add `done` early-exit: user types "done" at any prompt → skip to post-fill summary
- [x] 3.6 Add answer-to-section distribution rule: each answer is parsed and written to its mapped (file, section) targets; tech stack answer is split across 4 tools.md sections
- [x] 3.7 Add Docker answer hook: after writing to `tools.md §App Dependencies (Docker)`, run the existing docker-modular-stack catalog check
- [x] 3.8 Add append rule: if target section is non-empty (contains non-whitespace text), append `\n\n---\n\n{new content}` after existing content; if empty, write directly
- [x] 3.9 Add post-fill summary: grouped by file, list each section written (omit skipped sections)
- [x] 3.10 Add fill-via-routing path: when invoked via routing phrase (not post-scaffold), check which files in `docs/` already exist; only ask questions targeting those files; do not create new files

## 4. Step 3 — Empty-Section Detection

- [x] 4.1 Extend Step 3 instruction: after identifying the target section, check whether its body is empty or whitespace-only
- [x] 4.2 If section is empty: retrieve the targeted question from the fill flow question map for that (file, section) pair and ask it
- [x] 4.3 Write the answer using the append rule (append if non-empty after answer is supplied, direct write if still empty)
- [x] 4.4 If section is non-empty: proceed with existing conversational edit behaviour (no change)

## 5. Verification

- [x] 5.1 Trace through first-time scaffold flow: confirm fill offer appears after files are created
- [x] 5.2 Trace through "fill docs" routing: confirm no new files are created, only existing sections filled
- [x] 5.3 Trace through "fill in the PRD" routing: confirm only prd.md questions are asked
- [x] 5.4 Trace through Step 3 with empty section: confirm targeted question is asked
- [x] 5.5 Trace through Step 3 with non-empty section: confirm no question is asked, edit proceeds normally
- [x] 5.6 Verify append rule: if §Overview already has content and fill is re-run, existing content is preserved and new content follows `---`
- [x] 5.7 Verify Docker answer triggers docker-modular-stack suggestion when matching service is listed
