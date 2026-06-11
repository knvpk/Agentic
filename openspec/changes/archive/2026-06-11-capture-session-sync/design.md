## Context

The `sync → capture` flow currently extracts a conclusion from "the most recent exchange" and posts it to the linked ticket. This is too narrow: it misses decisions made earlier in the session and provides no mechanism to avoid noise posts when nothing meaningful happened.

The needed upgrade has three parts:
1. A gate that decides whether capture is worth doing
2. An LLM judge for code-first projects (spec diff is the gate for SDD)
3. A draft format that captures the full session delta, not a single moment

## Goals / Non-Goals

**Goals:**
- For SDD projects: only capture when spec files changed
- For code-first projects: only capture when LLM judge detects meaningful divergence from ticket's original context
- Both cases: user can override a "nothing changed" gate with explicit confirmation
- Draft covers the full session arc (decisions, scope shifts, changed approach), framed as a delta from original ticket context
- Preserve all existing degradation behaviour (no `linked_issue`, no active change, tracker write fails)

**Non-Goals:**
- Changing the archive flow (`sync → archive`) — that already uses spec diff + git diff + thread
- Auto-posting without confirmation — always show draft and require user confirmation
- Modifying the `notes.md` fallback path

## Decisions

### D1 — Project type detection: presence of `openspec/` or `spec-kit/` directory

**Decision**: A project is SDD if `openspec/` or `spec-kit/` exists at the repo root. Otherwise code-first.

**Rationale**: Already consistent with `project-type-detection` spec. No new heuristic needed.

### D2 — SDD gate: spec diff against main specs

**Decision**: For SDD projects, gate on whether any delta spec file exists at `openspec/changes/<name>/specs/`. If the directory exists and contains at least one `.md` file, specs changed — proceed. If absent or empty, skip (with user override prompt).

**Rationale**: Delta specs are the SDD signal for "the contract changed". Their presence is unambiguous.

**Alternative considered**: Diff individual spec files. Rejected as over-engineered — the delta spec directory is already the canonical "things changed here" signal.

### D3 — Code-first gate: LLM judge over session vs ticket body

**Decision**: For code-first projects, fetch the ticket body (using the provider read tool) and ask: "Does this session contain decisions, scope changes, or approach shifts that differ from the original ticket context?" If yes → proceed. If no → prompt user with override option.

**Rationale**: File-level diffs are too noisy (a whitespace fix isn't a decision). LLM judgment over session conversation is the right signal for "did something meaningful change in how we're building this?"

**Input to judge**:
- Ticket body (original context)
- Session conversation (current context window)

**Judge output**: Yes/No + one-sentence reason (used in the override prompt to the user).

### D4 — User override: always offer escape hatch when gate says no

**Decision**: When either gate says "nothing meaningful changed", show the judge's reason and ask:
> "Nothing significant looks different from the original ticket. Capture anyway?"
Options: `Yes, capture it` | `Skip`

**Rationale**: The user knows things the judge doesn't. The gate should reduce noise, not block intentional captures.

### D5 — Draft format: delta note, not transcript summary

**Decision**: The draft is structured as a delta from the original ticket, not a freeform summary:

```markdown
**Session update — <change-name>**

**What changed from the original plan:**
<bullet list of divergences>

**Why:**
<brief reasoning from session>

**Final approach:**
<what was actually decided>
```

If nothing diverged but user forced capture: omit the "What changed" section, just post a brief note.

**Rationale**: Tickets benefit from structured deltas, not narrative summaries. A reader can scan "what changed / why / final approach" without reading the whole comment.

### D6 — Session scope: full context window, not last exchange

**Decision**: When drafting, synthesise across the entire current session, not just the most recent exchange.

**Rationale**: Decisions accumulate across a session. The last exchange is often wrap-up; the meaningful divergence may have happened earlier.

## Risks / Trade-offs

**[Risk] LLM judge produces false positives** → The draft always requires user confirmation before posting. False positives just mean one extra "Skip" click.

**[Risk] LLM judge produces false negatives** → The override prompt catches this. User can always force capture.

**[Risk] Ticket body unavailable** (provider read fails) → Degrade gracefully: skip the judge, proceed as if gate passed, note in draft that original context wasn't available.

**[Risk] Code-first project with no `linked_issue`** → Existing degradation path applies: offer `notes.md` fallback.
