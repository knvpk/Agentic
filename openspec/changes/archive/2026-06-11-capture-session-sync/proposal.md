## Why

Tickets are created with initial context — requirements, approach, scope. By the time implementation finishes, the reality has often diverged: approach changed, scope shifted, a decision was made that wasn't in the original ticket. The current `sync → capture` posts only the most recent exchange, which misses the full arc of what changed.

The result: tickets become stale and lose their value as living documentation of intent.

## What Changes

- **`sync → capture` gate** — before drafting, check whether anything meaningful changed. For SDD projects (has `openspec/` or `spec-kit`), the gate is a spec diff. For code-first projects, the gate is an LLM judgment over the session: did this session surface decisions that diverge from the ticket's original context?
- **User override** — if the gate says "nothing changed", ask the user before skipping. They can force a capture.
- **Whole-session delta** — the draft captures the full arc of the session (decisions, scope shifts, approach changes), not just the last exchange. Framed as a delta: what was originally intended vs. what actually happened and why.

## Capabilities

### Modified Capabilities

- `archive-ticket-sync`: Extends the "Capture this in opsx:explore" section with the project-type-aware gate, LLM divergence judge, user override, and whole-session delta draft format.

## Impact

- `openspec/specs/archive-ticket-sync/spec.md` — extended "Capture this" section
- `skills/project-management/SKILL.md` — `sync → capture` sub-mode updated to match new spec
