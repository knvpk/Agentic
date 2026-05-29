## Why

The `project-management` skill treats all projects identically — the same four doc files, the same routing table, and a single-repo sprint view — but real projects differ fundamentally by type (mobile app, web app, API service, microservices platform). At the same time, natural-language queries that users type every day ("show me @alice's blocked tickets", "what's in sprint 4 across all repos") have no route in the current skill. This change adds project-type awareness throughout the skill and makes the routing layer fluent enough to handle how people actually talk.

## What Changes

- **Project type detection at init**: a new init question asks what kind of project this is (mobile / web / api / microservices / generic), optionally followed by a stack clarification question; result stored as `project_type` in `.project/config.yaml`
- **Type-conditional doc scaffolding**: docs created at first use are selected and structured based on `project_type` — mobile apps skip `database.md` and get signing/store sections in `tools.md`; API projects add `api.md`; microservices projects add `services.md`
- **Docs-after-init prompt**: after init completes, the skill asks "Scaffold project docs? [y/n]" rather than requiring a separate invocation
- **Type-specific label bootstrap**: at init, a label set appropriate to the project type is created alongside the canonical state labels (e.g., `platform:ios`, `platform:android` for mobile; `breaking-change`, `contract-change` for APIs)
- **Query normalization layer**: a pre-routing step extracts intent verb + filter objects (assignee, state, sprint, search term) from natural language before mode dispatch
- **Expanded routing table**: adds natural query forms (`"show me @alice's tickets"`, `"what's blocked"`, `"find tickets about auth"`) alongside the existing imperative forms
- **Multi-repo sprint**: `next` and `status` modes read `.project/config.yaml` from each path in `context_repos`, use each repo's own `mcp_prefix` and `active_sprint`, fan out ticket fetches, and return a merged view tagged by source repo
- **Type-specific BDD pattern hints**: ticket content generator seeds scenario generation with pattern examples appropriate to the project type (HTTP patterns for APIs, touch/permission/lifecycle patterns for mobile)

## Capabilities

### New Capabilities

- `project-type-detection`: Detect and store project type at init via guided questions; drives doc scaffold selection, label bootstrap, and BDD hint seeding throughout the skill
- `query-normalization`: Pre-routing intent extraction layer; parses natural language into `{ mode, subMode, filters }` before mode dispatch; defines the shared filter grammar (assignee, state, sprint, search_term)
- `multi-repo-sprint`: Cross-repo sprint view powered by reading each `context_repos` path's own `.project/config.yaml`; fans out ticket fetches per repo using each repo's declared provider and active sprint; merges and tags results by source repo

### Modified Capabilities

- `capability-detection`: Adds project_type and stack clarification questions at init Step 2; adds docs-scaffold prompt (y/n) after init completes at Step 7; stores `project_type` and `stack` in `.project/config.yaml`
- `docs-management`: Type-conditional file selection and section content at scaffold time; file set and section headers vary by `project_type`; type-specific initial label set bootstrapped for label-dependent providers
- `ticket-content-generation`: Scenario generation seeded with type-specific BDD pattern hints from a per-type pattern library keyed on `project_type`
- `next-ticket-scheduler`: Ticket fetch fans out across all `context_repos` configs before scoring; recommendation output includes source-repo identifier
- `sprint-management`: Status board output gains a source-repo column when `context_repos` are configured; grouped totals shown per repo
- `skill-frontmatter`: Routing table expanded with natural query forms and inline filter examples; references the query-normalization layer for filter extraction

## Impact

- Modified skill: `skills/project-management/SKILL.md` — query normalization layer, expanded routing table, multi-repo sprint logic in `next` and `status` modes
- Modified config schema: `.project/config.yaml` — adds `project_type`, `stack` fields; multi-repo sprint reads sibling configs at query time (no schema change needed)
- New doc templates: type-specific scaffold variants for `docs/api.md`, `docs/services.md`, `docs/local-storage.md`
- Modified doc templates: `docs/tools.md` gains type-conditional sections; `docs/prd.md` and `docs/architecture.md` gain type-specific hints
- Label bootstrap: type-specific label sets added to init Step 7 alongside existing canonical state labels
- No breaking changes to existing `.project/config.yaml` files — `project_type` defaults to `generic` if absent
- No changes to `references/providers.json` or any provider reference files
- Forward-compatible with `issue-explore` skill (separate registries, no shared state)
