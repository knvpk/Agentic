---
name: project-management
description: >
  Provider-agnostic project management skill. Manages local project docs (docs/prd.md,
  docs/architecture.md, docs/database.md, docs/tools.md) and connects to any supported
  issue tracker (GitHub, GitLab, Jira, Plane) via MCP. Six modes: init (configure
  provider, probe plan capabilities), docs (scaffold and edit project docs; suggests
  docker-modular-stack for Docker dependencies), ticket (create rich opsx-ready ticket
  briefs with requirements, BDD scenarios, use cases; CRUD; all relationship types;
  canonical lifecycle), sprint (manage sprints/milestones/cycles and labels), next
  (algorithmic daily ticket recommendation from dependency graph and priority), status
  (sprint board grouped by canonical state). Context for tickets is relevance-filtered
  from docs and falls back to local repo files or configured sibling repos.
compatibility: >
  Requires one MCP server configured: mcp__github__, mcp__gitlab__, mcp__jira__, or
  mcp__plane__. Run /project-management init before first use.
---

# project-management

## Mode Routing

Read the user's intent and pick one mode:

| User says | Mode |
|-----------|------|
| "init", "set up project", "configure provider", "init --probe" | **init** |
| "update the PRD", "add to architecture", "edit database doc", "scaffold docs", "update tools" | **docs** |
| "create a ticket", "new issue", "update ticket", "link tickets", "list tickets", "close ticket", "ticket status" | **ticket** |
| "new sprint", "start sprint", "add to sprint", "remove from sprint", "create label", "sprint status" | **sprint** |
| "create milestone", "new milestone", "release milestone", "assign milestone", "list milestones", "close milestone" | **sprint → milestone** |
| "what should I work on", "next ticket", "what's next", "suggest a task" | **next** |
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
1. docs/prd.md        → find sections matching the ticket topic by keyword
2. docs/architecture.md → find components matching the ticket topic
3. docs/database.md   → find entities/tables matching the ticket topic
4. docs/tools.md      → find tools relevant to the ticket topic
5. local repo files   → search src/, lib/, config files by filename + content proximity
6. context_repos      → if set in .project/config.yaml, search those repo paths
7. warn               → "No relevant context found — Context section may be incomplete"
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

# Optional: list sibling repo paths for cross-repo context fallback
# context_repos:
#   - ../backend
#   - ../shared-lib
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

### Step 8 — Notify active fallbacks

For each capability that is false, print one line:
```
⚠  Epics not available on this plan — using label epic:{slug} fallback
⚠  Sprints not available — using milestone proxy
```

---

## MODE: docs

### Step 1 — Ensure docs/ exists

If `docs/` directory does not exist, create it and scaffold all four files (see Step 2).
If it exists, skip scaffolding and go to Step 3.

### Step 2 — Scaffold files (first time only)

Create each file only if it doesn't already exist:

**docs/prd.md**
```markdown
## Overview

## Features

## Non-Functional Requirements

## Requirements

## Scenarios
```

**docs/architecture.md**
```markdown
## Overview

## Components

## Data Flow

## Architecture Decisions
```

**docs/database.md**
```markdown
## Overview

## Entities

## Relationships

## Schema Notes
```

**docs/tools.md**
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

Fetch all active sprint tickets. Group by canonical state (reverse-map provider states). Display:

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

---

## MODE: next

### Step 1 — Load config and active sprint

Read `.project/config.yaml`. If no `active_sprint` is set, tell the user to create or activate a sprint first.

### Step 2 — Fetch open in-sprint tickets (single call)

Call `list_tickets` filtered to active sprint + state != done. Collect: id, title, description, canonical_state, priority, estimate, blocked_by relationships.

### Step 3 — Eliminate ineligible tickets

For each ticket with `blocked_by` entries: check if ALL blockers are in `done` state. If any blocker is non-done → remove this ticket from the candidate pool.

### Step 4 — Score remaining candidates

Rank in this order:

1. **WIP continuation** — tickets already `in-progress` (rank first)
2. **Priority** — critical > high > medium > low
3. **Unblocks-others count** — count how many other open tickets list this ticket in their `blocked_by`. Higher = rank higher.
4. **Estimate** — if estimates present, prefer smaller (fits in a day)

### Step 5 — Output recommendation

```
Next ticket: TICK-42 — Auth token refresh
Priority: high | Sprint: Sprint 4 | Estimate: 3h

Reason: High priority, no open dependencies, unblocks 3 other tickets
        (TICK-45, TICK-46, TICK-47).

To start: /project-management ticket update TICK-42 --state in-progress
Ready to spec? /opsx:ff auth token refresh using this ticket as context
```

### Step 6 — Empty candidate pool

```
No eligible tickets in the active sprint.

Blocked tickets:
  TICK-41  →  blocked by TICK-33 (in-progress)
  TICK-44  →  blocked by TICK-38 (in-review)

Consider: resolve blockers, add tickets to the sprint, or create new tickets.
```

---

## Init flag: --probe

When `init --probe` is invoked, ignore any cached `.project/config.yaml` and re-run Steps 2–7 of init mode. Overwrite the config file with fresh results.

## Lazy re-probe on 403

If any MCP call returns an unexpected 403 mid-session:
1. Re-run the API probe (Step 4 of init) for that specific feature only.
2. Update `config.yaml` with the new flag.
3. Retry the operation using the fallback strategy.
4. Notify: "⚠ {Feature} support not available — switched to {fallback} fallback."
