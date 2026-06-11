## 1. openspec/specs/archive-ticket-sync/spec.md — Replace "Capture this" section

- [ ] 1.1 Replace the existing "Capture this in opsx:explore" section with the new section from the delta spec (full 3-step flow: gate → draft → confirm+post)
- [ ] 1.2 Extend the degradation behaviour table with the four new rows from the delta spec (SDD gate miss, code-first gate miss, ticket fetch fail, gate overridden)
- [ ] 1.3 Verify all existing sections (Signal Sources, Skip Heuristic, Comment Format, Provider Routing, Body Update, Related Ticket Comments) are unchanged

## 2. skills/project-management/SKILL.md — sync → capture sub-mode

- [ ] 2.1 Replace the current Step 1 ("Find active change with linked_issue") with the new Step 0 from the spec (same logic, renamed for clarity)
- [ ] 2.2 Add Step 1 — Gate: project type detection + SDD gate (delta spec directory check) + code-first gate (LLM judge over ticket body vs session) + Override Prompt using AskUserQuestion
- [ ] 2.3 Update Step 2 ("Draft and confirm") to: synthesise across full session (not last exchange); use the delta note format (What changed / Why / Final approach); use minimal format when gate was overridden with no real divergence
- [ ] 2.4 Verify the existing Step 3 (post via provider routing) is unchanged except for the override-flag-aware draft format
- [ ] 2.5 Verify the Guardrails block still applies: never auto-post, always show draft first, never overwrite ticket body, always print on write failure

## 3. Verification

- [ ] 3.1 Trace: SDD project, specs changed → gate passes, full delta draft shown, user confirms, posted
- [ ] 3.2 Trace: SDD project, no specs changed → override prompt shown, user skips → nothing posted
- [ ] 3.3 Trace: SDD project, no specs changed → override prompt shown, user confirms → minimal note posted
- [ ] 3.4 Trace: code-first project, session has divergence → judge returns Yes, full delta draft shown, user confirms, posted
- [ ] 3.5 Trace: code-first project, session has no divergence → judge returns No with reason, override prompt shown, user skips → nothing posted
- [ ] 3.6 Trace: code-first project, ticket fetch fails → judge skipped, proceed to draft with "original context unavailable" note
- [ ] 3.7 Trace: no active change → stops immediately with message
- [ ] 3.8 Trace: active change, no linked_issue → offers notes.md fallback, proceeds on confirmation
