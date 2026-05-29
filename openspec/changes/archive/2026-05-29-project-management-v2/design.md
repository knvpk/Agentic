## Context

The `project-management` skill v1 treats all projects identically: the same four doc files, the same routing table, and a single-provider single-repo sprint model. In practice, teams use three mutually incompatible mental models depending on project type — mobile apps think in screens and permissions, API services think in endpoints and contracts, microservices teams think in service boundaries and cross-repo coordination. The v1 skill produces generic BDD scenarios and scaffolds files (e.g., `database.md`) that are irrelevant or misleading for half of its users.

Separately, natural-language queries that users type every day ("show me @alice's blocked tickets", "find tickets about auth") have no explicit route in the current skill. Routing works by keyword matching against an imperative-phrase table; query-style input falls through to ambiguous interpretation.

Multi-repo sprint coordination is also unaddressed. Teams running a mobile app, an API backend, and an auth service as separate repos with separate providers (GitHub + Jira) currently have no way to get a unified "what's in sprint 7 across everything" view.

Constraints:
- `.project/config.yaml` is per-repo; no global config file
- Each context repo already carries its own `.project/config.yaml` (established in v1 for context_repos)
- Docs always live locally; no wiki or remote doc integration
- All ticket operations go through MCP — no raw HTTP

## Goals / Non-Goals

**Goals:**
- Make project type a first-class field that drives doc scaffold, label bootstrap, and BDD pattern seeding
- Define an explicit query normalization layer that converts natural language to `{ mode, subMode, filters }` before routing
- Enable multi-repo sprint views by reading each `context_repos` repo's own config at query time
- Keep `.project/config.yaml` schema backward-compatible (new fields optional, default to `generic`)

**Non-Goals:**
- Auto-detecting project type from code structure (single question is cheaper and more accurate)
- Supporting >1 provider per repo (each repo has its own config and its own provider)
- Profile inheritance or template registries for doc scaffolding
- GitHub Projects v2 / GraphQL sprint support (deferred to v3)
- Merging with `issue-explore` (forward-compatible, separate skill in v2)

## Decisions

### D1: `project_type` as a first-class config field, not inferred

**Decision:** Add a required question at init Step 2: "What kind of project is this?" with options `mobile | web | api | microservices | generic`. A conditional follow-up asks for the specific stack (e.g., React Native vs Flutter for mobile). Both stored in `.project/config.yaml` as `project_type` and `stack`.

**Rationale:** Auto-detection from code (e.g., `pubspec.yaml` → Flutter) is brittle — a repo can contain tooling from multiple ecosystems, and silent misdetection is worse than a single question. The question is answered once at init and never asked again.

**Alternative considered:** Detect from filesystem markers. Rejected: ambiguous for polyglot repos and adds complexity for marginal gain.

### D2: Query normalization as an explicit pre-routing layer in SKILL.md

**Decision:** Before dispatching to a mode, the skill runs a normalization step that extracts:
- **Intent verb**: show/list/find/search → list intent; create/add/new → create intent; update/move/change → update intent; close/done/finish → lifecycle intent
- **Filter object**: `@{name}` → assignee, `#{id}` → ticket id, `"about {term}"` → search_term, state keywords, priority keywords, `"in sprint {n}"` → sprint override

The normalized `{ intent, filters }` pair is then routed. This is declared as a named step in SKILL.md, not implicit.

**Rationale:** Without an explicit normalization step, each mode handles natural-language input independently and inconsistently. Declaring the grammar in SKILL.md gives the model a shared vocabulary and gives users documentation of what queries are understood.

**Alternative considered:** Expand the routing table with every natural-language variant. Rejected: combinatorially infeasible; the normalization layer generalizes over unlimited phrase variants.

### D3: Multi-repo sprint via context_repos self-description

**Decision:** `context_repos` entries are directory paths. Each path contains its own `.project/config.yaml` with its own `provider.mcp_prefix`, `active_sprint`, and `capabilities`. When `next` or `status` is invoked, the skill reads each sibling's config and fans out ticket fetches using each repo's own MCP prefix and sprint reference. No sprint info is duplicated in the anchor repo's config.

**Rationale:** Each repo should own its sprint state. The anchor repo only needs to know where siblings are. This handles provider heterogeneity for free — a GitHub repo and a Jira repo in the same `context_repos` list each use their own MCP. Adding a new sibling requires only appending its path to `context_repos` and ensuring it has run init.

**Alternative considered:** Define a top-level `team_sprint` in the anchor config that overrides siblings. Rejected: creates drift — the anchor could declare a sprint name that doesn't match any sibling's active sprint.

### D4: Type-conditional doc scaffold as inline conditional logic, not a profile system

**Decision:** Doc scaffold logic uses if/else on `project_type` from config. The file set and section variants per type are declared inline in SKILL.md. No profile registry, no template inheritance.

File sets by type:
- `mobile`: `prd.md`, `architecture.md`, `local-storage.md`, `tools.md` (signing/store sections, no Docker)
- `web`: `prd.md`, `architecture.md`, `database.md`, `tools.md` (with Docker section)
- `api`: `prd.md`, `architecture.md`, `database.md`, `tools.md`, `api.md`
- `microservices`: `architecture.md`, `services.md`, `tools.md` (no prd.md — product lives in feature repos)
- `generic`: `prd.md`, `architecture.md`, `database.md`, `tools.md` (v1 default, unchanged)

**Rationale:** The number of project types is bounded and stable. Conditional logic in SKILL.md is readable and maintainable without introducing indirection.

**Alternative considered:** Template files per type in a `references/templates/` directory. Rejected: adds file management overhead; conditional inline logic is simpler for a bounded type set.

### D5: Type-specific label bootstrap at init, declared inline

**Decision:** Init Step 7 (state label bootstrap) is extended to also create a type-specific supplementary label set appropriate to the project type. Sets are declared inline in SKILL.md:

| Type | Additional labels bootstrapped |
|------|-------------------------------|
| mobile | `platform:ios`, `platform:android`, `platform:shared`, `crash`, `a11y`, `store-review-blocker` |
| web | `seo`, `performance`, `a11y`, `responsive`, `pwa`, `breaking` |
| api | `breaking-change`, `contract-change`, `deprecation`, `versioning`, `consumer-impact` |
| microservices | `service:{slug}` per service in services.md, `cross-cutting`, `contract-change`, `migration` |
| generic | (no supplementary labels) |

**Rationale:** Type-specific labels are cheap to create and prevent inconsistent ad-hoc labelling later. Creating them at init ensures they exist when the first ticket is created.

### D6: BDD pattern hints as seed prompts, not rigid templates

**Decision:** The ticket content generator receives a set of 2–3 seed BDD patterns as prompt context, keyed on `project_type` from config. These are example patterns that guide Claude's scenario generation, not fill-in-the-blank templates. The seed patterns are declared inline in SKILL.md.

Example seeds by type:
- `mobile`: touch/gesture patterns; permission grant/deny; network condition scenarios; background/foreground lifecycle
- `web`: loading/error/empty state patterns; form validation; browser viewport; auth flow
- `api`: HTTP verb + status code patterns; auth boundary (unauthenticated, expired, insufficient scope); rate limiting; pagination
- `microservices`: service-to-service call patterns; circuit breaker / failure mode; event publishing/consuming; saga compensation

**Rationale:** Seed patterns nudge scenario generation toward type-relevant vocabulary without constraining the output. A rigid template would produce identical boilerplate regardless of the ticket topic; seed hints allow Claude to adapt while still using the right domain language.

## Risks / Trade-offs

- **Backward compatibility of `.project/config.yaml`** → All new fields (`project_type`, `stack`) are optional with `generic` as the default. Existing configs continue to work unchanged.
- **Sibling config missing or malformed** → Multi-repo sprint gracefully warns and skips repos with no `.project/config.yaml` rather than failing the whole invocation.
- **Type-specific label bootstrap on providers without label namespacing (Jira)** → Jira labels are free-text strings; prefix conventions (`platform:ios`) still work, they just aren't first-class namespaces. No structural change needed.
- **Mobile `local-storage.md` vs `database.md` naming** → Renaming creates a small inconsistency with the context fallback chain (which references `docs/database.md`). Mitigation: the fallback chain is updated to check both names.
- **`services.md` for microservices is a new pattern** → No existing model for per-service registries. Risk: the scaffold is underspecified and users fill it with inconsistent data. Mitigation: provide a concrete example row in the scaffold template.

## Migration Plan

1. Update `skills/project-management/SKILL.md` with the query normalization layer, expanded routing table, multi-repo sprint logic, and type-conditional doc scaffold
2. Existing `.project/config.yaml` files without `project_type` treat as `generic` — no migration required
3. Existing `docs/` directories are not modified — type-conditional scaffold only runs when `docs/` is first created
4. New label sets are created on the first `init` or `init --probe` after upgrade

Rollback: revert `SKILL.md` to v1; no remote state is affected (labels already created persist but are harmless).

## Open Questions

- **Q1**: For `microservices` type, should `services.md` list services as a table (name | port | repo | health endpoint) or as individual `### Service: {name}` sections? Lean: table for discoverability + `### Service:` sections for depth. Both in same file.
- **Q2**: Should the docs-after-init prompt be skipped when `project_type: microservices` and no services are defined yet in `services.md`? The scaffold is less useful without a populated service list. Lean: always offer, but note in the prompt that `services.md` can be populated later.
- **Q3**: For the multi-repo status board, should the per-repo breakdown be the default or opt-in via `--by-repo` flag? Lean: default when `context_repos` is non-empty; single-repo view when not configured.
