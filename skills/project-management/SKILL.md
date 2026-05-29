---
name: project-management
description: >
  Provider-agnostic project management skill. Manages local project docs (docs/prd.md,
  docs/architecture.md, docs/database.md, docs/tools.md) and connects to any supported
  issue tracker (GitHub, GitLab, Jira, Plane) via MCP. Seven modes: init (configure
  provider, probe plan capabilities), docs (scaffold and edit project docs; suggests
  docker-modular-stack for Docker dependencies), ticket (create rich opsx-ready ticket
  briefs with requirements, BDD scenarios, use cases; CRUD; all relationship types;
  canonical lifecycle), sprint (manage sprints/milestones/cycles and labels), next
  (algorithmic daily ticket recommendation from dependency graph and priority), start
  (fetch a specific ticket by ID, enrich with project doc context, transition state,
  create branch, invoke opsx:explore), status (sprint board grouped by canonical state).
  Context for tickets is relevance-filtered from docs and falls back to local repo files
  or configured sibling repos.
compatibility: >
  Requires one MCP server configured: mcp__github__, mcp__gitlab__, mcp__jira__, or
  mcp__plane__. Run /project-management init before first use.
---

# project-management

## Shared: Query Normalization

Before routing to a mode, extract **intent** and **filters** from the user's input. Use the normalized output to determine mode, sub-mode, and pre-filled filters.

### Intent verbs

| Input contains | Intent | Default route |
|---------------|--------|---------------|
| show, list, find, search | list | ticket → list |
| create, add, new | create | ticket → new |
| update, move, change, set | update | ticket → update |
| close, done, finish, mark, complete | lifecycle | ticket → update (state) |
| *(ambiguous / no match)* | list | ticket → list |

### Filter grammar

| Pattern in input | Filter key | Example |
|-----------------|-----------|---------|
| `@{name}` | assignee | `@alice` → `assignee: "alice"` |
| `#{id}` or `TICK-{n}` | ticket | `#42` → `ticket: "42"` |
| `"about {term}"` | search_term | `"about auth"` → `search_term: "auth"` |
| `"in sprint {n}"` | sprint | `"in sprint 4"` → `sprint: "Sprint 4"` |
| canonical state name | state | `"blocked"` → `state: "blocked"` |
| `"high priority"`, `"critical"`, `"low priority"` | priority | `"high priority"` → `priority: "high"` |
| `"label:{slug}"` | label | `"label:backend"` → `label: "backend"` |

Filters compose: `"show me @alice's blocked high-priority tickets in sprint 4"` → `{ assignee: "alice", state: "blocked", priority: "high", sprint: "Sprint 4" }`.

---

## Mode Routing

Run Query Normalization first, then route:

| User says | Mode |
|-----------|------|
| "init", "set up project", "configure provider", "init --probe" | **init** |
| "update the PRD", "add to architecture", "edit database doc", "scaffold docs", "update tools" | **docs** |
| "create a ticket", "new issue", "add task" | **ticket → new** |
| "update TICK-42", "move TICK-42 to in-review", "close TICK-5" | **ticket → update** |
| "link TICK-42 to TICK-10", "blocks", "relates to" | **ticket → link** |
| "list tickets", "show tickets", "find tickets about auth" | **ticket → list** |
| "show me @alice's tickets", "what's blocked", "search for login tickets" | **ticket → list** |
| "new sprint", "start sprint", "add to sprint", "remove from sprint", "create label", "sprint status" | **sprint** |
| "create milestone", "new milestone", "release milestone", "assign milestone", "list milestones", "close milestone" | **sprint → milestone** |
| "what should I work on", "next ticket", "what's next", "suggest a task" | **next** |
| "start TICK-42", "work on TICK-42", "begin TICK-42", "let's work on #42", "start {any ticket id or URL}" | **start** |
| "show board", "sprint board", "show progress", "what's in flight" | **status** |

---

## Shared: Canonical State Machine

Valid states and transitions:

```
backlog → todo → in-progress → in-review → done
                     ↕
                  blocked  (requires: reason, optional blocking ticket ref)
```

Reject any transition not following this path. Always validate before dispatching to provider.
Translate using `state_mapping` from `references/providers.json` for the active provider.

---

## Shared: Relationship Types

| Type | Native? | Fallback |
|------|---------|---------|
| parent/child | Provider-dependent | label `epic:{slug}` + description note |
| blocks/blocked-by | Provider-dependent | Comment `Blocks: #{id}` / `Blocked by: #{id}` |
| relates-to | Provider-dependent | Label `relates:#{id}` (bidirectional) |

Always check `capabilities` in `.project/config.yaml` before using native API. If capability is false, use fallback strategy from `references/providers.json`.

---

## Shared: Context Fallback Chain

When generating ticket context, follow this chain — stop at first hit, only include **relevant** pieces:

```
1. docs/prd.md            → find sections matching the ticket topic by keyword
                             (skip if project_type: microservices — no prd.md in that type)
2. docs/architecture.md   → find components matching the ticket topic
3. docs/database.md       → find entities/tables matching the ticket topic
   docs/local-storage.md  → use instead of database.md when project_type: mobile
4. docs/tools.md          → find tools relevant to the ticket topic
5. local repo files       → search src/, lib/, config files by filename + content proximity
6. context_repos          → if set in .project/config.yaml, search those repo paths
7. warn                   → "No relevant context found — Context section may be incomplete"
```

Never dump an entire docs file. Only include sections/paragraphs where the topic appears.

---

## MODE: init

### Step 1 — Read or create `.project/config.yaml`

If `.project/config.yaml` exists and `--probe` flag is NOT set, read it and skip to Step 5.

### Step 2 — Provider selection

**a. Try to detect from git remote:**
```
git remote get-url origin  →  match against providers.json hostname_patterns
```

**b. If detected**, confirm with user:
```
Detected provider: GitHub (from git remote origin)
Is this correct? [y / n — pick a different provider]
```

**c. If not detected or user says no**, present a selection:
```
Which provider will this project use?
  1. GitHub
  2. GitLab
  3. Jira
  4. Plane
```

Store: `provider.name`, `provider.mcp_prefix`.

### Step 2b — Project type and stack

Ask:
```
What kind of project is this?
  1. Mobile app  (iOS / Android / React Native / Flutter)
  2. Web app     (SPA / SSR / PWA)
  3. API service (REST / GraphQL / gRPC)
  4. Microservices  (multiple services — this is the coordination repo)
  5. Generic / full-stack
```

Store as `project_type`: `mobile` | `web` | `api` | `microservices` | `generic`.

**Conditional follow-up** — ask only the matching clarification, skip for generic:

| project_type | Question | Options | Stored as `stack` |
|---|---|---|---|
| mobile | Cross-platform or native? | react-native, flutter, native, other | e.g. `react-native` |
| web | Framework? | nextjs, nuxt, remix, vite-spa, other | e.g. `nextjs` |
| api | Protocol? | rest, graphql, grpc, mixed | e.g. `rest` |
| microservices | Repo structure? | separate-repos, monorepo | e.g. `separate-repos` |
| generic | *(skip)* | — | *(omit from config)* |

### Step 3 — ToolSearch probe (Signal 1) + MCP setup wizard

Use ToolSearch to verify the MCP server is reachable:
```
ToolSearch("mcp__{provider}__")
```

**If tools found** → MCP is configured, continue to Step 4.

**If no tools found** → launch setup wizard:

**Step A — Resolve endpoint URL**

All four providers have official hosted HTTP MCPs. Present the default and offer a self-hosted override:

```
{Provider} MCP is not configured.

Official endpoint: {mcp_setup.default_url}
  docs: {mcp_setup.docs}

Use the default or a self-hosted instance?
  1. Default  ({mcp_setup.default_url})
  2. Self-hosted  ({mcp_setup.self_hosted_url_pattern or note})
```

- **Plane + Default**: URL is fixed `https://mcp.plane.so/http/api-key/mcp` — ask for API key → pass as `--header "x-api-key={key}"`
- **Plane + Self-hosted**: ask for instance base URL → use `{base_url}/http/api-key/mcp` with same header
- **GitHub/GitLab/Jira + Default**: use `default_url` as-is
- **GitHub/GitLab/Jira + Self-hosted**: ask for instance URL, build URL from `self_hosted_url_pattern`

**Step B — Resolve auth method**

Read `mcp_setup.auth_methods`. If only one → use it. If multiple → ask:

```
How should the MCP authenticate?
  1. OAuth  — browser flow, recommended  (GitHub / GitLab / Jira)
  2. PAT / API token  — for automation or CI
```

| Provider | OAuth command | Token command |
|----------|--------------|---------------|
| GitHub | `claude mcp add github -t http --url {url}` | append `--header "Authorization=Bearer {token}"` |
| GitLab | `claude mcp add gitlab --transport http {url}` | OAuth only |
| Jira | `claude mcp add jira --transport http {url}` | append `--header "Authorization=Basic {base64}"` |
| Plane | `claude mcp add plane --transport http {url} --header "x-api-key={key}"` | API key in header |

For **OAuth**: run the install command → output: "Open Claude and type `/mcp` to complete OAuth browser flow."
For **PAT/token**: collect token (masked) → run install command with `--header` → no browser step needed.
For **Plane**: URL is fixed (`https://mcp.plane.so/http/api-key/mcp`) — collect API key → pass as `--header "x-api-key={key}"`.

For Jira API token: generate base64 → `echo -n "{email}:{token}" | base64` → embed in header.

Then:

```
Does your MCP server manage authentication centrally (SSO/service account)?
  1. Yes — server handles auth, no token needed from me
  2. No  — I need to provide credentials
```

**If server manages auth (option 1):**
- Skip all `required_env` marked `skip_if_server_manages_auth: true`
- Still collect any env vars NOT marked as skippable (e.g. `PLANE_WORKSPACE_SLUG`, `PLANE_PROJECT_ID`)

**If client provides credentials (option 2):**
- For each `required_env`: check if already in environment
  - Found → "Found {name} in environment ✓"
  - Not found → ask user (mask input) → append `export {name}="{value}"` to `~/.zshrc`

Then run (always project-scoped — each project may use a different provider or workspace):
```
claude mcp add {provider} --scope project --transport http {url}
```

Output:
```
✓ MCP registered: {provider} → {url}
✓ Credentials configured.
```

Store URL in `.project/config.yaml`:
```yaml
provider:
  name: github
  mcp_url: https://mcp.company.com/github
  mcp_prefix: mcp__github__
```

Since HTTP transport takes effect immediately (no local process restart needed), continue directly to Step 4.

If **user cancels** → print `references/{provider}.md` setup section and stop.

### Step 4 — API probe (Signal 2)

For each feature, call a safe read endpoint. Map result to capability flag:

| Feature | Probe tool suffix | 200 → | 403/error → | tool missing → |
|---------|-------------------|--------|-------------|----------------|
| epics | `list_modules` / `list_epics` | true | false | ask user |
| sprints | `list_cycles` / `list_milestones` / `list_boards` | true | false | ask user |
| relationships | `list_issue_relations` / `list_issue_links` | true | false | ask user |
| sub_issues | `list_issues` | true | false | assume true |

When asking the user (ambiguous probe):
> "Couldn't determine whether your {Provider} workspace supports {feature}. Is it available on your plan? [y/n]"

### Step 5 — Write `.project/config.yaml`

```yaml
provider:
  name: plane
  mcp_prefix: mcp__plane__
  capabilities:
    epics: false
    sprints: true
    relationships: true
    sub_issues: true
  probed_at: 2026-05-28T10:00:00Z   # ISO-8601

project_type: api      # mobile | web | api | microservices | generic
stack: rest            # omit for generic; values: react-native, flutter, nextjs, nuxt, rest, graphql, grpc, separate-repos, monorepo

# Optional: sibling repo paths — each must have its own .project/config.yaml
# Used for cross-repo context fallback AND unified multi-repo sprint views
# context_repos:
#   - ../mobile-app
#   - ../auth-service
```

### Step 6 — Jira extra: board selection

If provider is jira and `sprints: true`, call `list_boards`, present a selection list, store `board_id` in config.

### Step 7 — Bootstrap state labels (label-dependent providers)

For providers where states are simulated via labels (GitHub, GitLab, and any provider
whose `state_mapping` uses `"label"` fields), create the canonical state labels now if
they do not already exist. Call `create_label` for each missing label:

| Label | Colour | Purpose |
|-------|--------|---------|
| `todo` | `#e4e669` | canonical todo state |
| `in-progress` | `#0075ca` | canonical in-progress state |
| `in-review` | `#7057ff` | canonical in-review state |
| `blocked` | `#d93f0b` | canonical blocked state |

Skip this step only for **Jira** — Jira labels are free-text strings attached directly to issues; no `create_label` call is needed or supported. For **Plane**, check `state_mapping` entries: create labels only for entries that contain a `label` field (`in-review` and `blocked`); skip entries that use `state_name` only.
Output: `✓ State labels created` or `✓ State labels already present`.

**Type-specific supplementary labels** — after canonical state labels, also create the following if `project_type` is set and provider supports `create_label` (skip for Jira free-text):

| project_type | Additional labels | Colours |
|---|---|---|
| mobile | `platform:ios`, `platform:android`, `platform:shared`, `crash`, `a11y`, `store-review-blocker` | `#0075ca`, `#28a745`, `#6f42c1`, `#d93f0b`, `#0052cc`, `#b60205` |
| web | `seo`, `performance`, `a11y`, `responsive`, `pwa`, `breaking` | `#0075ca`, `#e4e669`, `#0052cc`, `#7057ff`, `#28a745`, `#d93f0b` |
| api | `breaking-change`, `contract-change`, `deprecation`, `versioning`, `consumer-impact` | `#d93f0b`, `#b60205`, `#e4e669`, `#0075ca`, `#7057ff` |
| microservices | `cross-cutting`, `contract-change`, `migration` | `#7057ff`, `#b60205`, `#e4e669` |
| generic | *(none)* | — |

Output: `✓ Type labels created` or `✓ Type labels already present` (skip silently for generic).

### Step 8 — Notify active fallbacks

For each capability that is false, print one line:
```
⚠  Epics not available on this plan — using label epic:{slug} fallback
⚠  Sprints not available — using milestone proxy
```

### Step 9 — Offer docs scaffold

After all steps complete, ask:
```
Scaffold project docs now? [y/n]
```

- **y** → immediately invoke the docs scaffold flow (MODE: docs Step 1–2) using the `project_type` just configured; create only the type-appropriate files
- **n** → exit init cleanly; docs can be scaffolded later via `/project-management docs`

---

## MODE: docs

### Step 1 — Ensure docs/ exists

If `docs/` directory does not exist, create it and scaffold the type-appropriate files (see Step 2).
If it exists, skip scaffolding and go to Step 3.

### Step 2 — Scaffold files (first time only, type-conditional)

Read `project_type` from `.project/config.yaml`. If absent, treat as `generic`.

**File set by project type:**

| project_type | Files created |
|---|---|
| mobile | prd.md, architecture.md, local-storage.md, tools.md (mobile variant) |
| web | prd.md, architecture.md, database.md, tools.md |
| api | prd.md, architecture.md, database.md, tools.md, api.md |
| microservices | architecture.md, services.md, tools.md |
| generic | prd.md, architecture.md, database.md, tools.md |

Create each file only if it doesn't already exist:

**docs/prd.md** *(mobile, web, api, generic)*
```markdown
## Overview

## Features

## Non-Functional Requirements

## Requirements

## Scenarios
```

**docs/architecture.md** *(all types)*
```markdown
## Overview

## Components

## Data Flow

## Architecture Decisions
```

**docs/database.md** *(web, api, generic)*
```markdown
## Overview

## Entities

## Relationships

## Schema Notes
```

**docs/local-storage.md** *(mobile only — replaces database.md)*
```markdown
## Storage Engine

## Data Model

## Migration Strategy

## Sync Strategy
```

**docs/api.md** *(api, microservices)*
```markdown
## Endpoint Catalog

## Versioning Strategy

## Authentication

## Rate Limiting

## Error Format

## Deprecation Policy
```

**docs/services.md** *(microservices only)*
```markdown
## Service Registry

| Name | Port | Health Endpoint | Responsibility |
|------|------|----------------|----------------|
| example-svc | 8001 | /health | Brief description |

## Services

### Service: example-svc

**Responsibility**: What this service owns.

**Upstream dependencies**: services or external APIs this service calls.

**Downstream consumers**: services that call this service.

**Data ownership**: entities/tables owned by this service.
```

**docs/tools.md** *(generic, web, api, microservices variant)*
```markdown
## Language

## Framework

## CI/CD

## Command Runner

## Dev Environment

## Testing

## App Dependencies (Docker)

## Linting & Formatting
```

**docs/tools.md** *(mobile variant — replaces App Dependencies section)*
```markdown
## Language

## Framework

## CI/CD

## Command Runner

## Dev Environment

## Testing

## App Signing & Certificates

## Build & Distribution

## App Store

## OTA Updates

## Linting & Formatting
```

### Step 3 — Edit the relevant section

Identify which file and section the user wants to update. Edit that section only; do not touch other sections.

### Step 4 — docker-modular-stack suggestion

After any edit to `docs/tools.md § App Dependencies (Docker)`, check whether any listed service name matches the docker-modular-stack catalog:

```
Catalog: postgres, clickhouse, valkey, redis, minio, neo4j, falkor_db, chroma,
         grafana, tempo, otel-collector, langfuse, phoenix, hyperdx,
         mailpit, mailslurper, authentik, oryd, graphiti, litellm, hasura,
         kestra, hermes, archon, paperclip, tensorzero, mission_control,
         prefect, ollama, webui, inspector, coredns, traefik, kong
```

If any match found, output:
```
💡 postgres, valkey, authentik are available in docker-modular-stack.
   Run /docker-modular-stack to scaffold these services.
```

---

## MODE: ticket

Detect sub-mode from user intent: **new** | **update** | **link** | **list** | **lifecycle**

---

### Sub-mode: ticket new

#### Step 1 — Collect input

Minimum required: ticket title. Ask for at minimum one label or sprint assignment if not provided.

#### Step 2 — Read context (relevance-filtered)

Follow the **Context Fallback Chain** defined in Shared section above. Collect only relevant pieces. Build a `context_refs` list.

#### Step 3 — Generate ticket brief

**BDD seed patterns** — read `project_type` from `.project/config.yaml` and use the matching seeds as vocabulary context when generating `## Scenarios`. Seeds guide language and structure; generated scenarios must still address the specific ticket topic, not copy seeds verbatim. Skip seeds for `generic` or absent `project_type`.

| project_type | Seed patterns (use as vocabulary guidance) |
|---|---|
| mobile | `GIVEN user has denied camera permission / WHEN feature requires camera access / THEN app shows permission rationale and graceful fallback`; `GIVEN device switches network mid-operation / WHEN transfer is in progress / THEN app resumes via offline queue without data loss`; `GIVEN app is backgrounded during long operation / WHEN user returns to foreground / THEN session and operation state are restored` |
| web | `GIVEN API call is in-flight / WHEN component renders / THEN skeleton loader shown, not blank screen`; `GIVEN user submits form with invalid input / WHEN validation runs / THEN inline errors appear and submit stays disabled`; `GIVEN mobile viewport (375px) / WHEN page loads / THEN layout adapts to single-column with accessible touch targets` |
| api | `GIVEN authenticated user with scope=read:orders / WHEN GET /orders?status=pending / THEN 200 with paginated list and X-Total-Count header`; `GIVEN request without Authorization header / WHEN POST /payments / THEN 401 with WWW-Authenticate challenge`; `GIVEN 51st request in a 60-second window (limit=50/min) / WHEN rate limiter evaluates / THEN 429 Too Many Requests with Retry-After header` |
| microservices | `GIVEN orders-svc calls inventory-svc.reserveStock() / WHEN inventory-svc returns 503 three times / THEN circuit breaker trips, order stays in PENDING`; `GIVEN payment-svc publishes order.paid event / WHEN notifications-svc is down / THEN event persists in DLQ and is delivered after recovery`; `GIVEN payment succeeds but order creation fails / WHEN saga compensates / THEN payment is refunded and no order record persists` |

Produce the full ticket body with these sections:

```markdown
## Summary
{one-paragraph description derived from user input and prd.md context}

## Context
{context_refs — one line per source, e.g.:}
> Derived from docs/prd.md §Features — Token Refresh
> Component: AuthService (docs/architecture.md §Components)
> Entity: sessions (docs/database.md §Entities)
> Stack: authentik (docs/tools.md §App Dependencies)
> See: src/auth/token_service.py

## Requirements
- The system SHALL {requirement 1}
- The system SHALL {requirement 2}
{minimum 2 SHALL statements}

## Scenarios
{generate one GIVEN/WHEN/THEN block per distinct behaviour — use ticket topic and project_type seed patterns below as vocabulary guidance}

GIVEN {precondition}
WHEN {action}
THEN {expected outcome}

GIVEN {precondition 2}
WHEN {action 2}
THEN {outcome 2}
{one block per distinct behaviour}

## Use Cases
### UC-1: {name}
**Actor**: {actor}
**Precondition**: {precondition}
**Flow**:
1. {step}
2. {step}
**Postcondition**: {postcondition}

## Non-Functional
{relevant NFRs from docs/prd.md §Non-Functional Requirements, plus any from user}

## OpenSpec Hint
`/opsx:ff {ticket title}` using this ticket as context
```

#### Step 4 — Validate and create

Validate canonical state (default: `backlog`). Resolve MCP tool from `tool_contracts.create_ticket`. Call with the generated brief as the body field.

---

### Sub-mode: ticket update

Ask which field(s) to update: title, description, state, labels, assignee, sprint.

For **state changes**: validate against canonical machine → translate to provider state via `state_mapping` → call `update_ticket`. For `blocked`: prompt for reason + optional blocking ticket ref.

---

### Sub-mode: ticket link

Ask for: source ticket, relationship type (parent/child | blocks | relates-to), target ticket.

1. Read `capabilities` from config. If native supported → call `create_relation` with correct type.
2. If not supported → apply fallback strategy from `providers.json`:
   - `comment` strategy: add comment to the target ticket
   - `label` strategy:
     a. Derive the label name (e.g. `epic:auth-system` from epic title "Auth System")
     b. Call `list_labels` to check if the label already exists in the provider
     c. If NOT found → call `create_label` first (colour `#e99695` for epics, `#c5def5` for relates)
     d. Call `add_label` to attach it to the ticket
     e. Add a description note on the child ticket: "Part of epic: {Epic Title}"
3. Notify user which mode is active.

Relates-to is always bidirectional: apply to both tickets.

**Epic label lifecycle:**
- Epic labels are created on-demand (not at init) because epic names are unknown upfront.
- When the last child ticket is closed and the epic label has no remaining open issues, notify:
  `"💡 epic:auth-system has no open tickets — consider closing this epic."`
- Slug derivation: lowercase, replace spaces with `-`, strip special chars.
  e.g. "Auth System v2" → `epic:auth-system-v2`

---

### Sub-mode: ticket list

Accept canonical state filter. Translate to provider query syntax via `state_mapping`. Call `list_tickets`.

---

## MODE: sprint

### Step 1 — Detect sub-mode: create | add | remove | labels | status | milestone

### Sub-mode: sprint create

Map to provider mechanism via `providers.json`:
- GitHub / GitLab → `create_milestone` (name, due date)
- Jira → `create_sprint` (name, startDate, endDate, originBoardId from config)
- Plane → `create_cycle` (name, start_date, end_date)

Store active sprint reference in `.project/config.yaml`:
```yaml
active_sprint:
  id: "12"
  name: "Sprint 4"
```

### Sub-mode: sprint add / remove

Resolve sprint ID from config. Call `add_issue_to_sprint` / remove equivalent.

### Sub-mode: labels

- **create**: call `create_label` tool with name and colour
- **list**: call `list_labels`
- **assign**: call `add_label` / `update_ticket` with label field

### Sub-mode: milestone

**Milestone vs Sprint:** Sprint = time-boxed iteration ("Sprint 4"). Milestone = release/delivery target ("v1.0", "Beta"). A ticket can have both.

Detect operation: **create | assign | list | close**

**create** — collect: name (e.g. "v1.0"), description, due date.
Read `capabilities.milestones` from config:
- `true` → call `milestone_contracts.create` from `providers.json`
- `false` (Plane) → activate label fallback: create label `milestone:{slug}`, notify user

**assign** — attach a ticket to a milestone.
- Native: call `milestone_contracts.assign` (update issue with milestone field / fixVersions)
- Fallback: add label `milestone:{slug}` to the ticket

**list** — call `milestone_contracts.list`. Display name, due date, open/closed ticket counts.
For Plane fallback: search issues by `milestone:*` label prefix.

**close** — mark milestone as closed/released.
- Native: call `milestone_contracts.close` with `state: closed` / `released: true`
- Fallback: rename label to `milestone:{slug}-released` (signals closure)
- Before closing: warn if milestone still has open tickets

| Provider | Milestone mechanism | Native? |
|----------|---------------------|---------|
| GitHub   | GitHub Milestone (`v1.0` naming) | ✓ |
| GitLab   | GitLab Milestone (`v1.0` naming) | ✓ |
| Jira     | Fix Version | ✓ |
| Plane    | Label `milestone:{slug}` | ✗ (fallback) |

**Naming convention for GitHub/GitLab** (both use milestones for sprints too):
- Sprints: `Sprint N` or `YYYY-WW` (week-based)
- Milestones: `vX.Y.Z` or plain release name (`Beta`, `Q3 Launch`)

### Sub-mode: status

**Single-repo** (no `context_repos` configured): fetch all active sprint tickets using the anchor's provider. Group by canonical state. Display unchanged v1 format:

```
Sprint 4 — 12 tickets
──────────────────────────────────────────
backlog      2   TICK-50, TICK-51
todo         3   TICK-42, TICK-43, TICK-44
in-progress  2   TICK-38, TICK-39
in-review    1   TICK-35
blocked      1   TICK-41  (blocked by TICK-33)
done         3   TICK-30, TICK-31, TICK-32
```

**Multi-repo** (when `context_repos` is non-empty): apply the same sibling config resolution as `next` MODE Step 1. For each repo with a valid config + active sprint, fetch tickets using that repo's `mcp_prefix`. Display per-repo breakdown followed by cross-repo totals:

```
Sprint 4  —  across 3 repos  —  28 tickets total
──────────────────────────────────────────────────────────
[./]             backlog 1  todo 2  in-progress 1  done 3
[../mobile-app/] backlog 0  todo 3  in-progress 2  done 2
[../api-gateway/]backlog 2  todo 1  in-progress 1  done 4
──────────────────────────────────────────────────────────
TOTALS           backlog 3  todo 6  in-progress 4  done 9

blocked:
  TICK-41 (./)             →  blocked by TICK-33 (in-progress)
  TICK-12 (../api-gateway/)→  blocked by TICK-8  (in-review)
```

Repos with no `active_sprint` are listed as: `[../service-name/] — no active sprint`.

---

## MODE: next

### Step 1 — Load config and resolve repo set

Read `.project/config.yaml`. If no `active_sprint` is set on the anchor repo, tell the user to create or activate a sprint first.

**Multi-repo expansion**: if `context_repos` is non-empty, read `.project/config.yaml` from each listed path. For each sibling:
- If the file is missing → emit `⚠ {path} has no .project/config.yaml — skipped` and continue.
- If `active_sprint` is absent → emit `⚠ {path} has no active sprint — skipped` and continue.
- Otherwise → record `{ path, mcp_prefix, active_sprint, capabilities }` for use in Step 2.

### Step 2 — Fetch open in-sprint tickets

For each repo in the set (anchor + valid siblings), call `list_tickets` filtered to that repo's `active_sprint` + state != done, using that repo's own `mcp_prefix`. Collect: id, title, description, canonical_state, priority, estimate, blocked_by relationships. Tag each ticket with `source_repo` (relative path, `"."` for anchor).

Merge all results into a single candidate pool.

### Step 3 — Eliminate ineligible tickets

For each ticket with `blocked_by` entries: check if ALL blockers are in `done` state. Blockers may be in any repo in the merged pool — search by ticket ID across all source repos. If any blocker is non-done → remove this ticket from the candidate pool.

### Step 4 — Score remaining candidates

Rank in this order:

1. **WIP continuation** — tickets already `in-progress` (rank first)
2. **Priority** — critical > high > medium > low
3. **Unblocks-others count** — count how many open tickets in the merged pool list this ticket in their `blocked_by`. Higher = rank higher.
4. **Estimate** — if estimates present, prefer smaller (fits in a day)

### Step 5 — Output recommendation

Single-repo (no context_repos):
```
Next ticket: TICK-42 — Auth token refresh
Priority: high | Sprint: Sprint 4 | Estimate: 3h

Reason: High priority, no open dependencies, unblocks 3 other tickets
        (TICK-45, TICK-46, TICK-47).

Ready to start? /project-management start TICK-42
```

Multi-repo (when ticket comes from a sibling repo):
```
Next ticket: TICK-17 (../api-gateway/) — Rate limit middleware
Priority: high | Sprint: Sprint 4 | Estimate: 2h

Reason: High priority, no open dependencies, unblocks 2 tickets (../mobile-app/).

Ready to start? /project-management start TICK-17
```

### Step 6 — Empty candidate pool

```
No eligible tickets in the active sprint.

Blocked tickets:
  TICK-41 (.)              →  blocked by TICK-33 (in-progress)
  TICK-12 (../api-gateway) →  blocked by TICK-8 (in-review)

Consider: resolve blockers, add tickets to the sprint, or create new tickets.
```

---

## MODE: start

Accept a ticket reference and load it for exploration with full project doc context. Accepts `--no-branch` flag to skip branch creation.

### Step 1 — Parse ticket reference

Detect the input form and normalise to `(ticket_id, is_url)`:

| Input form | Example | Action |
|---|---|---|
| Full URL | `https://github.com/org/repo/issues/42` | Extract issue number from path |
| Key format | `PROJ-42` | Use as-is |
| Hash format | `#42` | Strip `#`, treat as bare number |
| Bare number | `42` | Use as numeric issue ID |

**Jira bare-number guard**: if `config.provider.name == "jira"` and input is a bare number, ask:
> "Jira requires a full key format. What is your project key prefix? (e.g. `PROJ`)"
Reconstruct as `PREFIX-<number>` and continue.

### Step 2 — Fetch ticket

Read `.project/config.yaml` for `provider.mcp_prefix`. No provider detection needed — the project is already configured.

Emit `Fetching <id>…` before the call.

Call the get-ticket tool from `tool_contracts.get_ticket` in `references/providers.json` using `{mcp_prefix}`. Collect: id, title, description, state (raw), labels, assignees, sprint membership, priority, issue_type.

Emit `✓ Loaded: "<title>"` on success.

### Step 3 — Project doc context (Context Fallback Chain)

Follow the **Context Fallback Chain** defined in the Shared section above — identical logic to `ticket new`. Filter to sections relevant to the ticket's title and description topic. Build a `context_refs` list.

If all chain steps miss, emit:
```
⚠ No relevant context found — Context section may be incomplete.
```

### Step 4 — State transition

Reverse-map the raw provider state to canonical state via `state_mapping`:

| Canonical state | Action |
|---|---|
| `todo` | Ask: "Move TICK-<id> to in-progress? [y/n]" → on Y call `update_ticket` translating via `state_mapping` |
| `in-progress` | Silent no-op — already started |
| `backlog` | Warn: "TICK-<id> is in backlog and not assigned to the active sprint. Continue anyway? [y/n]" |
| `in-review` or `done` | Warn: "TICK-<id> is already `<state>` — continuing in exploration mode." |
| `blocked` | Warn: "TICK-<id> is blocked. Note the blocker before exploring." |

### Step 5 — Branch creation

> **Skip this step entirely if `--no-branch` was passed.** Set `BRANCH_SKIPPED=true` and go to Step 6.

#### Step 5a — Detect branching strategy

Run `git branch -a --format=%(refname:short)` and infer from topology:

| Branch topology | Strategy | Base branch |
|---|---|---|
| `develop` + `release` + `hotfix` present | gitflow | `develop` |
| `develop` or `dev` + `release` | gitflow-lite | `develop` |
| `develop`, `dev`, or `development` only | three-branch | detected dev branch |
| `release/*` branches, no develop | trunk-release | `main`/`master` |
| No develop branch | single-branch | `main`/`master` |

Tell the user: "Detected [strategy] — branching from `[base_branch]`."

#### Step 5b — Derive branch name slug

Apply this prompt to yourself:

```
Issue title:       {ticket.title}
Issue description: {ticket.description[:300] if present, else "(none)"}

Rules:
1. Output ONLY the slug — no explanation, no quotes.
2. 2–4 lowercase words joined by hyphens.
3. Choose the most identifying domain/technical words.
4. One optional short action verb (fix, add, migrate) only when meaningful.
5. Omit filler words (the, a, an, is, to, for, in, on, with, of, and…).

Slug:
```

Determine branch prefix from `issue_type`:
- `bug` → `bug/` (or `hotfix/` for gitflow strategies)
- `feature`, `task`, `story`, or unknown → `feature/`
- `hotfix` → `hotfix/`

Compose: `{prefix}{ticket.id}-{slug}` (e.g. `feature/PROJ-42-oauth-login`)

#### Step 5c — Confirm and create

Ask:
```
Ready to create branch:
  [BRANCH_NAME]  (from [BASE_BRANCH])
Create it now? [Y/n] — or type a different name to override.
```

- **Y** or Enter: run `git checkout [BASE_BRANCH] && git pull origin [BASE_BRANCH] && git checkout -b [BRANCH_NAME]`
- **Custom name**: sanitize (`re.sub(r'[^a-z0-9/._-]', '-', name.lower()).strip('-')`) and create with that name
- **n**: tell user "Skipping branch creation — continuing in exploration mode." Set `BRANCH_SKIPPED=true`.

### Step 6 — Assemble context block

Build the context block:

```
=== [provider] Ticket: [id] ===
URL:        [ticket.url if available]
Title:      [ticket.title]
State:      [canonical_state]
Type:       [ticket.issue_type]
Labels:     [ticket.labels joined by ", "]
Priority:   [ticket.priority]
Assignees:  [ticket.assignees joined by ", "]

--- Description ---
[ticket.description, up to 3000 chars]

--- Project Context ---
[context_refs from Step 3, one block per matched source, e.g.:]
> Derived from docs/prd.md §Features — Token Refresh
> Component: AuthService (docs/architecture.md §Components)
> Entity: sessions (docs/database.md §Entities)
> See: src/auth/token_service.py

=== Code Repository ===
Branch:   [git rev-parse --abbrev-ref HEAD]
Remote:   [git remote get-url origin]

Recent commits:
[git log --oneline -5]
```

If `BRANCH_SKIPPED` is false, append:
```
Branch:   [BRANCH_NAME]  (from [BASE_BRANCH])
```

### Step 7 — Invoke opsx:explore

#### Step 7a — Detect opsx:explore

Scan the `system-reminder` skills list for `opsx:explore`. If present, invoke it with the context block assembled in Step 6 and this prompt:

```
I want to explore the implementation for this ticket before starting work:

<context block>

Let's think through: requirements, ambiguities, edge cases, and which parts of the codebase are likely involved.
```

#### Step 7b — Fallback if opsx:explore not loaded

Present the context block directly to the user, then offer:

```
No spec skill loaded — context above is ready.

What would you like to do?
  1. Find files in this repo likely affected by this ticket
  2. List open questions, ambiguities, and edge cases
  3. Summarise what needs to be implemented
  4. Check for related branches or PRs
  5. Start implementing now

Reply with a number, or ask anything about the ticket.
```

Wait for the user's reply and act on it directly.

---

## Init flag: --probe

When `init --probe` is invoked, ignore any cached `.project/config.yaml` and re-run Steps 2–7 of init mode. Overwrite the config file with fresh results.

## Lazy re-probe on 403

If any MCP call returns an unexpected 403 mid-session:
1. Re-run the API probe (Step 4 of init) for that specific feature only.
2. Update `config.yaml` with the new flag.
3. Retry the operation using the fallback strategy.
4. Notify: "⚠ {Feature} support not available — switched to {fallback} fallback."
