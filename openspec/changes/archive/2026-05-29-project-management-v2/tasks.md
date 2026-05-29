## 1. Project Type Detection

- [x] 1.1 Add project type question (mobile / web / api / microservices / generic) to init Step 2 in SKILL.md, positioned after provider confirmation
- [x] 1.2 Add conditional stack clarification question per type (React Native/Flutter for mobile; Next.js/Vite for web; REST/GraphQL/gRPC for api; monorepo/separate-repos for microservices) with skip for generic
- [x] 1.3 Add `project_type` and `stack` to the config.yaml example block in SKILL.md Step 5 (Write config)
- [x] 1.4 Add type-specific supplementary label bootstrap table to init Step 7 in SKILL.md (mobile, web, api, microservices label sets alongside canonical state labels)

## 2. Query Normalization Layer

- [x] 2.1 Add "Shared: Query Normalization" section to SKILL.md before the Mode Routing table
- [x] 2.2 Define intent verb mappings in that section: show/list/find/search → list, create/add/new → create, update/move/change → update, close/done/finish → lifecycle, ambiguous → ticket list default
- [x] 2.3 Add filter grammar table to the Query Normalization section: @{name} → assignee, #{id} → ticket, "about {term}" → search_term, "in sprint {n}" → sprint, state keywords, priority keywords, label:{slug}
- [x] 2.4 Update mode routing table to reference the Query Normalization step and add natural query form examples (especially for ticket → list: "show me @alice's tickets", "what's blocked", "find tickets about auth")

## 3. Type-Conditional Docs Scaffold

- [x] 3.1 Replace fixed four-file scaffold logic in docs MODE with type-conditional file selection based on `project_type` from `.project/config.yaml`
- [x] 3.2 Add `docs/api.md` scaffold template to SKILL.md with sections: Endpoint Catalog, Versioning Strategy, Authentication, Rate Limiting, Error Format, Deprecation Policy
- [x] 3.3 Add `docs/services.md` scaffold template to SKILL.md with a service registry table (Name, Port, Health Endpoint, Responsibility) and a `### Service: example-svc` stub section
- [x] 3.4 Add `docs/local-storage.md` scaffold template to SKILL.md with sections: Storage Engine, Data Model, Migration Strategy, Sync Strategy
- [x] 3.5 Add type-conditional tools.md section logic: mobile type gets App Signing & Certificates, Build & Distribution, App Store, OTA Updates sections instead of App Dependencies (Docker)
- [x] 3.6 Update the Context Fallback Chain in SKILL.md Shared section to check `docs/local-storage.md` as the database entity source for mobile projects

## 4. Docs-After-Init Prompt

- [x] 4.1 Add docs scaffold prompt ("Scaffold project docs now? [y/n]") as the final step of init mode in SKILL.md, after label bootstrap and fallback notifications
- [x] 4.2 Add logic: if user answers yes, invoke docs scaffold immediately using the now-configured `project_type`; if no, exit init cleanly

## 5. Type-Specific BDD Pattern Seeds

- [x] 5.1 Add BDD seed pattern library to SKILL.md ticket → new Step 3 (Generate ticket brief): 3 seed patterns each for mobile, web, api, and microservices types; no seeds for generic
- [x] 5.2 Wire seed selection into scenario generation: read `project_type` from `.project/config.yaml` before generating `## Scenarios` section; include matching seeds as generation context

## 6. Multi-Repo Sprint — Next Mode

- [x] 6.1 Update next MODE Step 1 (Load config) in SKILL.md: after reading anchor config, check `context_repos` and read `.project/config.yaml` from each valid sibling path
- [x] 6.2 Update next MODE Step 2 (Fetch tickets) to fan out one MCP call per configured repo using each repo's own `mcp_prefix` and `active_sprint`; merge results with `source_repo` tag
- [x] 6.3 Update next MODE Step 3 (Eliminate ineligible tickets) to operate on merged pool; blockers may be in any repo
- [x] 6.4 Update next MODE Step 5 (Output recommendation) to include source repo path for sibling tickets and cross-repo unblocking reasoning
- [x] 6.5 Add graceful handling: if a sibling has no `.project/config.yaml` or no `active_sprint`, warn and skip that repo; continue with remaining repos

## 7. Multi-Repo Sprint — Status Mode

- [x] 7.1 Update status MODE in SKILL.md: when `context_repos` is non-empty, fetch tickets from each repo using its own provider and active sprint
- [x] 7.2 Add per-repo breakdown display format: one section per repo with state counts, followed by cross-repo totals row
- [x] 7.3 Annotate blocked ticket IDs with source repo in the blocked list (e.g., `TICK-12 (../api-gateway)`)
- [x] 7.4 Keep single-repo format unchanged when `context_repos` is empty or absent

## 8. Verification

- [x] 8.1 Verify init flow presents project type question after provider confirmation and stores `project_type` + `stack` in `.project/config.yaml`
- [x] 8.2 Verify docs scaffold creates correct file set for each project type (mobile: no database.md + local-storage.md; api: +api.md; microservices: no prd.md + services.md)
- [x] 8.3 Verify mobile `docs/tools.md` has signing/store sections and does NOT have App Dependencies (Docker)
- [x] 8.4 Verify `docs/api.md` scaffold contains all 6 required sections
- [x] 8.5 Verify `docs/services.md` scaffold contains the service registry table and a stub service section
- [x] 8.6 Verify label bootstrap creates type-specific labels at init (e.g., `platform:ios` for mobile, `breaking-change` for api)
- [x] 8.7 Verify ticket scenarios for a mobile project use mobile-relevant vocabulary (permission, offline, background)
- [x] 8.8 Verify ticket scenarios for an api project use HTTP/auth/rate-limit vocabulary
- [x] 8.9 Verify query normalization: "show me @alice's blocked tickets" routes to ticket list with assignee + state filters pre-filled
- [x] 8.10 Verify multi-repo status shows per-repo state breakdown when context_repos are configured
- [x] 8.11 Verify next recommendation includes source repo path for tickets from sibling repos
- [x] 8.12 Verify missing sibling config produces a warning line and does not fail the invocation
- [x] 8.13 Verify backward compatibility: existing `.project/config.yaml` without `project_type` behaves identically to `project_type: generic`
- [x] 8.14 Verify `npx skills` still lists `project-management` with correct description after SKILL.md changes
