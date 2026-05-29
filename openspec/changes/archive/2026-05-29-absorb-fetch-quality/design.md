## Context

`project-management start` (MODE: start, Steps 2–7 in `skills/project-management/SKILL.md`) currently calls `get_ticket` via MCP and collects a small set of fields: `id`, `title`, `description`, `state`, `labels`, `assignees`, `sprint`, `priority`, `issue_type`. It then runs the Context Fallback Chain over project docs and assembles a context block for `opsx:explore`.

`issue-explore` (Steps 3, 3b, 4 in `skills/issue-explore/SKILL.md`) has four additional fetch-quality features built up over time:
1. **Comment ranking** — scores and trims comments on high-volume issues
2. **Linked issue fetching** — fetches related issues when description is thin
3. **Custom provider fields** — renders `Sprint`, `Story Points`, `Epic`, etc.
4. **Code cross-reference scanning** — extracts MR/PR URLs, branch names, commit SHAs from body + comments

These features exist in `issue-explore` but not in `pm start`, creating a quality gap when users move from ad-hoc issue exploration to the configured-project workflow. The goal is to port these four behaviors into `pm start` without touching `issue-explore` itself.

## Goals / Non-Goals

**Goals:**
- Port comment ranking/trimming into pm start Step 2 — identical algorithm, same thresholds (> 10 comments, top 7 + last 3, same scorer weights)
- Port linked issue fetching into pm start Step 2 — same trigger condition (description < 150 chars, empty, or cross-refs only)
- Port custom provider fields rendering into pm start Step 6 context block — render all non-null custom fields from the ticket MCP response
- Port code cross-reference scanning into pm start Step 2 — same regex patterns, same 10-ref cap, add `--- Code References in Issue ---` section to context block
- Update `openspec/specs/targeted-ticket-start/spec.md` to cover these behaviors as requirements

**Non-Goals:**
- Modifying `issue-explore` in any way — it continues as-is for zero-config use
- Merging or replacing `issue-explore` — this change narrows the quality gap, deprecation is a separate decision
- Adding `/tmp/` file intermediaries to pm start — the skill reasons directly from MCP response, no file normalization step
- Porting `issue-explore`'s provider detection machinery — pm start already knows its provider from config

## Decisions

### D1: Port logic inline rather than extracting a shared subroutine

**Decision**: Duplicate the comment-ranking algorithm and cross-reference scanner directly into pm start's SKILL.md rather than extracting a shared library or referencing issue-explore.

**Rationale**: Both skills are LLM-executed prompt specifications, not imported code. There is no runtime module system. The "shared subroutine" pattern in skills means copying the prose + pseudocode block into the target skill — which is effectively duplication. The tradeoff is: duplication vs. tight coupling. Skills should be self-contained; importing from another skill creates a hidden dependency. If issue-explore's algorithm evolves, pm start should be updated deliberately, not automatically.

**Alternative considered**: Reference `references/` files from issue-explore in pm start — rejected because cross-skill file references aren't supported by the skills specification, and would make pm start fail if issue-explore is removed.

---

### D2: Skip `/tmp/` intermediate files — work directly from MCP response

**Decision**: In pm start, run comment ranking and cross-ref scanning in-memory as part of Step 2, rather than writing `/tmp/ii_normalized.json` as issue-explore does.

**Rationale**: issue-explore uses `/tmp/` files because it fetches via three different paths (CLI, MCP, API token) and needs a stable handoff format between steps. pm start always fetches via a single known MCP tool, so the intermediate file adds complexity without value. Keeping pm start's data flow as a single annotated object is simpler.

---

### D3: Linked issue fetching uses the provider's `list_issue_relations` or equivalent, not a raw fetch

**Decision**: Use whatever MCP tool is available in `tool_contracts.get_linked_issues` (or equivalent listed in `providers.json`) — if no such tool exists for the provider, skip silently with a note.

**Rationale**: pm start operates through MCP only (no CLI or API-token path). Not all providers expose linked issues via MCP. Silent skip is better than an error that blocks the entire flow.

---

### D4: Custom fields rendered from the MCP ticket response, no schema normalization

**Decision**: Render any non-null, non-standard fields returned by the MCP `get_ticket` response as-is in a `--- Provider Fields ---` section. No mapping or normalization to a canonical schema.

**Rationale**: The set of custom fields varies by provider plan and workspace configuration. Attempting to normalize them (e.g., always calling the sprint field "sprint") is premature — render what the API returns with its original key names. The user knows their workspace's terminology.

## Risks / Trade-offs

- **Risk: comment ranking logic diverges between the two skills over time** → Mitigation: the spec delta for `targeted-ticket-start` locks in the algorithm as a testable requirement; future changes to issue-explore's scorer should be evaluated for backport
- **Risk: `list_issue_relations` MCP tool absent for some providers** → Mitigation: D3 specifies silent skip — the flow is not blocked, just the linked-issues section is omitted; user sees no error
- **Risk: custom fields section bloats context for providers that return many metadata fields** → Mitigation: render only non-null fields; if the section exceeds a reasonable size (> 20 fields), cap and note "and N more" — but this is a minor concern in practice

## Open Questions

- Should the code cross-reference section in pm start use the same `CODE_REFS` variable name as issue-explore for consistency, or a different label given that pm start doesn't use the `CODE_*` naming convention? (Recommend: use section header `--- Code References in Issue ---` and the variable name `ticket_code_refs` internally to avoid confusion with issue-explore's globals)
