## Context

`docs` mode currently scaffolds files with empty section headers and relies on the user to supply all content. There is no guided path for capturing project knowledge. The existing `docs-management` spec covers file creation, section structure, and ticket-context reading — but says nothing about how sections get populated.

The change adds an interactive fill layer on top of the existing scaffold: a structured Q&A flow that fills multiple sections per answer, triggered after scaffold and re-invokable any time.

## Goals / Non-Goals

**Goals:**
- Offer to fill docs immediately after scaffold
- Allow re-filling existing (empty or partial) docs via routing phrases
- Each question fills one or more sections across multiple files
- Keep total question count to 7-10 per project type
- Never overwrite existing content — append only
- Step 3 detects empty sections and asks the targeted question rather than waiting passively

**Non-Goals:**
- Rewriting or reformatting sections that already have content
- Validation of content quality or completeness
- Syncing docs back from the ticket tracker
- Changing any ticket, sprint, bulk, next, start, or status flows

## Decisions

### Decision 1 — Grouped questions, not per-section wizard

A full per-section wizard would produce ~20 questions across 5 files × 4 sections. Drop-off is high by question 10, and context-switching between unrelated questions (NFRs vs. linting tools) is jarring.

Grouped questions solve this: one "tech stack" answer fills `tools.md §Language`, `tools.md §Framework`, `tools.md §Testing`, and `tools.md §Linting & Formatting` simultaneously. The user's mental model is "describe my project" rather than "fill a database form field."

**Alternative considered**: Single free-text dump ("describe your project, I'll distribute it"). Rejected: sections get filled unevenly, gaps are invisible, and users can't tell what landed where.

**Alternative considered**: Per-section sequential wizard. Rejected: ~20 questions, high drop-off, mechanical feel.

### Decision 2 — Question-to-section mapping lives in the skill spec, not config

The mapping (question → one or more (file, section) targets) is deterministic behavioural spec, not user-configurable. It lives as a lookup table in the `docs-interactive-fill` spec. No config schema changes required.

### Decision 3 — Append-only writes with `---` divider

When a section already contains non-whitespace content, new content is appended below a `---` separator. Existing content is never overwritten. This preserves work the user has already done and makes re-fills safe to invoke.

The `---` separator accumulates if the fill is run many times, but in practice the fill flow is run once at setup. Subsequent single-section edits go through Step 3, which is append-only for non-empty sections too.

**Alternative considered**: Overwrite if user confirms. Rejected: data loss risk and extra prompt friction.

### Decision 4 — Fill flow is reachable independently of scaffold

Post-scaffold offer is one entry point, but users may scaffold and skip, or have existing docs/ that are empty. Routing phrases ("fill docs", "fill in the PRD", "populate docs") trigger the fill flow directly — no re-scaffolding.

When invoked via routing, the fill flow reads which files already exist and only asks questions for files that are present. It does not create new files.

### Decision 5 — Step 3 empty-section detection

When the user targets a specific section and that section's body (text between `## Header` and the next `##` or EOF) is empty or whitespace-only, the skill retrieves the targeted question from the question map and asks it rather than waiting passively.

This does not apply to sections with partial content — those are edited conventionally through conversational exchange.

## Risks / Trade-offs

- **Grouped answers require interpretation**: A single "tech stack" answer must be parsed and distributed to 4 sections. If the user gives a vague answer, some sections may remain sparse. Mitigation: show the target sections in the question prompt so the user knows what to include.
- **`---` divider accumulation**: Repeated fills on the same section add multiple separators. Low likelihood in practice (fill is a one-time setup activity). Mitigated by documentation in the spec.
- **Empty-section detection is line-based**: The skill checks whether content between two `##` headers is non-whitespace. If a section contains only HTML comments or placeholder text, it still reads as non-empty. This is acceptable — placeholder text implies the user has begun editing manually.

## Open Questions

None — scope is well-defined and self-contained.
