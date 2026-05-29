## Context

The `project-management` skill has seven modes (`init`, `docs`, `ticket`, `sprint`, `next`, `start`, `status`). After `init` and `docs` are complete, users have a populated `docs/` folder but must create tickets individually via `ticket new`. There is no path from a complete requirements doc set to a full backlog.

The `ticket new` sub-mode always produces exactly one ticket regardless of input breadth. There is no detection of scope-wide inputs that represent multiple discrete tickets.

The skill reads docs/ for context during single-ticket creation but has never used docs/ as the *source* of ticket candidates.

Constraints:
- The skill is a single `SKILL.md` file — all logic is expressed as instructions to the model, not imperative code.
- All ticket creation must go through existing MCP tool contracts (`tool_contracts.create_ticket`) in `references/providers.json`.
- The manifest review step must work in a text-only conversational interface (no interactive checkboxes).

## Goals / Non-Goals

**Goals:**
- New `bulk` top-level mode that reads all `docs/` files and produces a complete candidate ticket manifest.
- Ticket type taxonomy (feature, task, scaffold, migration, maintenance, spike) mapped from doc source sections.
- Dependency ordering in the manifest (scaffold/migration tickets ordered before feature tickets they enable).
- Interactive manifest review with text edit commands (skip, rename, merge, type, create).
- Deduplication of candidates against existing tracker tickets before presenting the manifest.
- Intelligent scope-width detection in `ticket new` that proposes a breakdown when scope is broad.
- Post-create sprint assignment and epic label creation offers.

**Non-Goals:**
- Generating or editing docs/ content (that is `docs` mode).
- AI-written functional requirements from scratch — the skill reads existing docs, not invents them.
- Bulk operations on existing tickets (bulk state change, bulk assignment) — out of scope for this change.
- Multi-repo bulk creation — bulk operates on the anchor repo only; multi-repo is a future concern.
- Fully automated creation with no human review step — the manifest review is mandatory.

## Decisions

### Decision 1: `bulk` as a top-level mode, not a flag on `ticket`

**Chosen**: New `bulk` entry in the mode routing table; dedicated `## MODE: bulk` section in SKILL.md.

**Alternatives considered**:
- `ticket bulk` sub-mode: inconsistent with the scope — `ticket` sub-modes operate on one ticket; bulk is a workflow.
- `init --generate-tickets` flag: ties bulk generation to project setup; users need to re-run it independently mid-project.

**Rationale**: The flow (read docs → generate manifest → review → create → assign sprint) is a distinct multi-step workflow that doesn't fit the single-ticket CRUD pattern of `ticket` mode.

---

### Decision 2: Manifest as mandatory intermediate state

**Chosen**: Bulk always presents a manifest table for review before any MCP create calls. No `--force` or `--auto` flag in v1.

**Alternatives considered**:
- Auto-create with post-hoc list: creates tickets immediately, shows what was created. Risky — deleting wrongly-created tickets is harder than not creating them.
- Optional review flag: `bulk --review` to enable the manifest. Makes the dangerous path the default.

**Rationale**: Ticket creation in external trackers is hard to reverse at scale. The 30 seconds of manifest review prevents creating 20 poorly-scoped tickets that must be manually deleted.

---

### Decision 3: Section-to-ticket-type mapping drives decomposition

**Chosen**: Each doc file section maps to a specific ticket type. The mapping is declarative (defined in the skill) and applied mechanically before any AI generation.

| Doc file | Section | Ticket type |
|---|---|---|
| `prd.md` | §Features | `feature` |
| `prd.md` | §NFR | `maintenance` |
| `prd.md` | §Scenarios | Supplement existing feature tickets (not standalone) |
| `architecture.md` | §Components | `scaffold` |
| `architecture.md` | §Data Flow | `task` |
| `architecture.md` | §Decisions (TBD) | `spike` |
| `database.md` / `local-storage.md` | §Entities | `migration` |
| `api.md` | §Endpoints | `task` |
| `tools.md` | §CI/CD, §Testing, §Dev Env | `maintenance` |
| `tools.md` | §App Dependencies | `maintenance` (cross-ref docker-modular-stack) |
| `services.md` | Each service entry | `scaffold` |

**Rationale**: Deterministic type assignment reduces variance in manifest quality. The manifest edit command `type <n> <type>` allows human correction.

---

### Decision 4: Scope-width heuristic for `ticket new` breakdown detection

**Chosen**: Three independent signals are checked. Any one signal being true triggers the breakdown offer.

| Signal | Threshold |
|---|---|
| Conjunction in input | Input contains "and" linking two domain nouns, or a comma-separated list of ≥2 items |
| Plural domain area | Input matches a known area word (auth, users, payments, notifications, settings) without a specific action verb |
| Docs match breadth | Quick relevance scan finds ≥3 distinct doc sections matching the topic |

If triggered, the skill asks: "I see enough scope here for multiple tickets — propose a breakdown? [y/n]". On `y`, drop into mini-bulk flow (same manifest format, narrowed to the matching doc sections). On `n`, proceed with single ticket as today.

**Rationale**: Three independent signals with OR logic catches both explicit ("auth and profile") and implicit ("auth system") broad inputs without over-triggering on focused inputs like "refresh token on 401 response".

---

### Decision 5: Deduplication via semantic title comparison against existing tickets

**Chosen**: Before presenting the manifest, list open tickets in the active sprint (and backlog if available). For each candidate, check if any existing ticket title is a close match (>80% word overlap or identical key terms). Flag matches in the manifest with `⚠ possible duplicate of #<id>`.

**Alternatives considered**:
- Skip dedup entirely: fast, but causes duplicates when bulk is re-run.
- Exact-match only: misses "Set up AuthService" vs "Bootstrap AuthService".

**Rationale**: Semantic match at 80% word overlap is cheap (no embeddings needed for title-level comparison) and catches obvious duplicates without false-positive rates that would annoy users.

---

### Decision 6: Dependency ordering in manifest

**Chosen**: The manifest is sorted so that `scaffold` and `migration` tickets appear before `feature` and `task` tickets that reference the same component/entity. The skill infers this by matching component/entity names from architecture.md/database.md to the feature descriptions.

The manifest includes a `Blocks` column (hidden by default, shown only when dependencies exist) displaying `→ #<row>` links between manifest rows.

**Rationale**: Creating tickets in dependency order makes the manifest immediately usable as a sprint plan — developers can pick up tickets in display order without manually figuring out what blocks what.

## Risks / Trade-offs

**Risk: Decomposition granularity is wrong (too many or too few tickets)**
→ Mitigation: Manifest review is mandatory. Users can merge rows (too granular) or split via rename + duplicate (too coarse). Future: configurable granularity hint (`--granularity coarse|fine`).

**Risk: Dedup list_tickets call adds latency before manifest appears**
→ Mitigation: Emit "Scanning existing tickets for duplicates…" progress line. If the MCP call fails or times out, skip dedup silently and note "⚠ Dedup skipped — could not reach tracker" in the manifest header.

**Risk: docs/ sections have inconsistent structure across projects**
→ Mitigation: The section-to-type mapping uses fuzzy section header matching (case-insensitive prefix). If a section doesn't match any known pattern, it is ignored (not added to the manifest). Users will notice missing candidates and can add them via `ticket new`.

**Risk: `ticket new` breakdown detection over-triggers on normal inputs**
→ Mitigation: The heuristic requires a signal to be clearly present — the word "and" alone does not trigger (requires two domain nouns). Plural area words only trigger without a specific action verb. False positives are safe: the user just says `n` and proceeds as today.

**Risk: Manifest edit commands are text-only and error-prone**
→ Mitigation: Invalid commands produce a help line listing valid commands. The `create` command echoes the final checked-ticket list before making any MCP calls and asks for confirmation.

## Open Questions

- **Granularity of PRD §Scenarios**: Should GIVEN/WHEN/THEN blocks in prd.md §Scenarios produce standalone tickets or only supplement feature tickets? Current decision: supplement only. Revisit if users report missing scenario-driven tickets.
- **`--from` flag for external spec files**: Not in v1. Users can paste content into docs/ first, then run `bulk`. A `--from` flag can be added as a follow-on.
- **Bulk re-run strategy**: If `bulk` is run a second time mid-project, dedup handles obvious overlaps but newly added doc sections will generate new candidates. No special "incremental" mode in v1 — the full manifest is regenerated each time and dedup filters out already-created tickets.
