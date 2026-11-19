---
name: project-management
description: >
  Provider-agnostic project management skill. Manages local project docs (docs/prd.md,
  docs/architecture.md, docs/database.md, docs/tools.md) and connects to any supported
  issue tracker (GitHub, GitLab, Jira, Plane) via MCP. Ten modes: init (configure
  provider, probe plan capabilities), docs (scaffold and edit project docs; suggests
  docker-modular-stack for Docker dependencies), bulk (generate a full backlog from docs/
  — reads all docs files, produces typed dependency-ordered ticket manifest, deduplicates
  against existing tickets, human review then creates in one pass), ticket (create rich
  opsx-ready ticket briefs with requirements, BDD scenarios, use cases; CRUD; all
  relationship types; canonical lifecycle; intelligent scope-width detection proposes
  breakdown into multiple tickets when input covers broad scope), sprint (manage
  sprints/milestones/cycles and labels; agile ceremonies: plan, review, retro, close),
  next (algorithmic daily ticket recommendation from dependency graph and priority),
  start (fetch a specific ticket by ID, enrich with project doc context, transition state
  with WIP limit check, create branch, invoke opsx:explore), status (sprint board with
  health signal and burndown grouped by canonical state), standup (daily standup: what I
  did / what's next / blockers), backlog (refine unestimated tickets with DoR check and
  story-point prompts). Quality gates: Definition of Done enforcement on ticket close,
  WIP limit enforcement on in-progress transitions. Context for tickets is
  relevance-filtered from docs and falls back to local repo files or configured sibling
  repos.
compatibility: >
  Requires one MCP server configured: mcp__github__, mcp__gitlab__, mcp__jira__, or
  mcp__plane__. Run /project-management init before first use.
---

# project-management

## Pre-routing Intercepts

Check these triggers **before** running Query Normalization. Route directly to the named mode — do not run intent extraction or filter grammar parsing on these inputs.

| Trigger | Route |
|---------|-------|
| `help`, `?`, `what can you do`, `commands`, `list commands` | **help** (Variant A — general index) |
| `help <word>` (single word after "help") | **help** (Variant B — mode detail) |

---

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
| "help", "help `<mode>`", "?", "what can you do", "commands", "list commands" | **help** |
| "init", "set up project", "configure provider", "init --probe" | **init** |
| "update the PRD", "add to architecture", "edit database doc", "scaffold docs", "update tools" | **docs** |
| "fill docs", "fill in docs", "populate docs", "fill in the {file}" | **docs** *(fill-intent — skip scaffold check, go to Interactive Fill Flow for existing files)* |
| "create a ticket", "new issue", "add task" | **ticket → new** |
| "update TICK-42", "move TICK-42 to in-review", "close TICK-5" | **ticket → update** |
| "link TICK-42 to TICK-10", "blocks", "relates to" | **ticket → link** |
| "list tickets", "show tickets", "find tickets about auth" | **ticket → list** |
| "show me @alice's tickets", "what's blocked", "search for login tickets" | **ticket → list** |
| "new sprint", "start sprint", "add to sprint", "remove from sprint", "create label", "sprint status" | **sprint** |
| "sprint plan", "plan sprint", "sprint planning" | **sprint → plan** |
| "sprint review", "review sprint", "what shipped" | **sprint → review** |
| "sprint retro", "retrospective", "retro" | **sprint → retro** |
| "sprint close", "close sprint", "end sprint", "finish sprint" | **sprint → close** |
| "create milestone", "new milestone", "release milestone", "assign milestone", "list milestones", "close milestone" | **sprint → milestone** |
| "what should I work on", "next ticket", "what's next", "suggest a task" | **next** |
| "start TICK-42", "work on TICK-42", "begin TICK-42", "let's work on #42", "start {any ticket id or URL}" | **start** |
| "show board", "sprint board", "show progress", "what's in flight" | **status** |
| "standup", "daily standup", "stand up", "daily" | **standup** |
| "backlog refine", "refine backlog", "estimate tickets", "grooming", "backlog grooming" | **backlog → refine** |
| "bulk", "generate tickets", "create tickets from docs", "populate backlog", "generate backlog" | **bulk** |
| "sync ticket", "post to ticket", "update ticket", "archive sync", "sync issue", "capture this", "capture" | **sync** |
| "ship", "ship my changes", "commit and pr", "commit and create pr", "push and pr", "commit all changes" | **ship** |
| "watch PR #42", "pr-watch 42", "watch this PR" | **pr-watch** |
| "release notes", "release this", "generate release notes" | **release-notes** |
| "release notes for uat", "release candidate" | **release-notes** (UAT framing) |
| "release notes for prod", "release to production", "release notes for production" | **release-notes** (PROD framing) |

---

## MODE: help

> Maintenance note: when adding a new mode or sub-mode, update Variant A's command index and the corresponding Variant B block below.

### Variant A — general help (no argument)

Triggered by: `help`, `?`, `what can you do`, `commands`, `list commands`

Output this command index:

```
project-management — available commands

SETUP
  init         Configure provider (GitHub, GitLab, Jira, Plane) and probe capabilities
  docs         Scaffold and fill project docs (prd, architecture, database, tools…)

TICKETS
  ticket new   Create a rich ticket with BDD scenarios and use cases
  ticket list  List / search tickets by state, assignee, label, sprint
  ticket update Update state, labels, assignee, or sprint for a ticket
  ticket link  Link tickets: parent/child, blocks/blocked-by, relates-to
  bulk         Generate a full backlog from docs/ folder

SPRINTS
  sprint plan     Pick tickets for the sprint from backlog candidates
  sprint review   What shipped this sprint (grouped by label)
  sprint retro    Record retrospective; creates a retro issue
  sprint close    End sprint, log velocity, clear active sprint
  sprint milestone Create / assign / list / close release milestones
  sprint labels   Create or list state and epic labels

DAILY WORKFLOW
  next      Algorithmic recommendation: best ticket to work on now
  start     Load a ticket, create its branch, invoke explore mode
  standup   Daily standup: what I did / what's next / blockers
  status    Sprint board grouped by canonical state with health signal
  backlog   Refine unestimated backlog tickets (story points + DoR check)
  sync      Post archive summary or explore conclusion to linked ticket
  ship      Commit all changes, push, and open a PR in one command
  pr-watch  One watch tick: GitHub Actions status + new PR comments, report-only
  release-notes  Generate release notes from git tags (prev-tag → current-tag)

Type: help <mode>  for details. Example: help sprint
```

After the index, append a status line:
- **`.project/config.yaml` exists** → `Current: provider={provider.name} | sprint={active_sprint.name or "none"}`
- **`.project/config.yaml` absent** → `⚠ Not initialized — run: /project-management init`

No MCP calls are made by this mode.

---

### Variant B — mode-specific help (`help <mode>`)

Extract the single word after "help". Match against the list below and output the block. No MCP calls are made.

**`help init`**
```
init — configure the project management provider

  Detects provider from git remote, probes API capabilities, writes .project/config.yaml.
  Offers to scaffold docs/ on completion.

  Flags:
    (none)      First-time setup
    --probe     Re-detect capabilities (use after plan changes or MCP updates)

  Examples:
    "set up project"
    "init --probe"
```

**`help docs`**
```
docs — scaffold and fill project documentation

  Creates docs/ files (prd.md, architecture.md, database.md, tools.md) appropriate
  for your project type. Interactive fill-in flow asks questions and writes answers
  to the correct sections.

  Sub-flows:
    scaffold   Create empty docs files for your project type
    fill       Interactive Q&A to populate sections in existing docs
    edit       Update a specific section in an existing doc

  Examples:
    "scaffold docs"
    "fill in the PRD"
```

**`help ticket`**
```
ticket — create, update, link, and list tickets

  Sub-modes:
    new     Create a rich ticket with BDD scenarios, requirements, and use cases
    update  Change state, labels, assignee, or sprint
    link    Link two tickets: parent/child, blocks/blocked-by, relates-to
    list    List or search tickets by state, assignee, label, sprint, or keyword

  Examples:
    "create a ticket for JWT refresh"
    "show me @alice's blocked tickets"
```

**`help sprint`**
```
sprint — manage sprints, ceremonies, and milestones

  Sub-modes:
    create    Start a new sprint (label-based on GitLab CE)
    plan      Pick tickets for the sprint from ranked backlog candidates
    review    What shipped this sprint, grouped by label
    retro     Record retrospective (creates a retro issue in the tracker)
    close     End sprint, log velocity, clear active sprint from config
    milestone Create / assign / list / close release milestones (v1.0, Beta…)
    labels    Create or list state and epic labels

  Examples:
    "sprint plan"
    "sprint close"
```

**`help next`**
```
next — recommend the best ticket to work on right now

  Scores open in-sprint tickets by: WIP continuation → priority → unblocks-others
  count → estimate size. Eliminates tickets whose blockers are not yet done.
  Works across multiple repos when context_repos is configured.

  Examples:
    "what should I work on"
    "next ticket"
```

**`help start`**
```
start — load a ticket, auto-start it, and open explore mode

  Fetches ticket by ID or URL, enriches with project doc context. By default,
  transitions it to in-progress and creates its branch as an isolated git worktree
  automatically — no confirmation — then opens explore mode. Set
  `start.worktree: false` in .project/config.yaml to branch in place with
  `git checkout -b` instead. Pauses once, with a single combined question, only
  when: the WIP limit would be exceeded, the ticket looks broad in scope (reused
  ticket-breakdown heuristic), its estimate is larger than 5, or (in-place mode)
  the working tree has uncommitted changes.

  Also creates the OpenSpec change for the ticket (linked to it) before explore,
  and explore must end with a verdict. `needs-input` stops here: the blocking
  questions are posted to the ticket and recorded in design.md, and re-running
  `start` on the same ticket resumes once they are answered.

  Flags:
    --no-branch   Skip branch/worktree creation; continue in exploration mode only
    --confirm     Force the combined confirmation every time, even if nothing
                  would otherwise trigger it

  Examples:
    "start TICK-42"
    "work on #38"
    "start TICK-42 --confirm"
```

**`help status`**
```
status — sprint board with health signal

  Fetches all active-sprint tickets, groups by canonical state, and shows a sprint
  health bar (% of committed points done), WIP count, and blocked ticket list.
  Works across multiple repos when context_repos is configured.

  Examples:
    "show board"
    "what's in flight"
```

**`help standup`**
```
standup — daily standup output

  Produces three sections: what I did (in-review / done tickets assigned to me),
  what I'll work on next (top scorer from the next algorithm), and blockers.

  Examples:
    "standup"
    "daily standup"
```

**`help backlog`**
```
backlog — refine unestimated tickets

  Walks unestimated backlog/todo tickets one at a time. Shows Definition of Ready
  check per ticket and prompts for a story-point estimate. Saves estimates to the
  tracker directly.

  Examples:
    "refine backlog"
    "estimate tickets"
```

**`help bulk`**
```
bulk — generate a full backlog from docs/

  Reads all applicable docs/ files, maps sections to typed ticket candidates
  (feature, scaffold, migration, maintenance, spike), deduplicates against existing
  tracker tickets, presents a manifest for human review, then creates all approved
  tickets in one pass.

  Examples:
    "generate tickets from docs"
    "populate backlog"
```

**`help sync`**
```
sync — post archive summary or explore conclusion to linked ticket

  Two sub-modes:
    sync archive [change-name]  Gather spec diff + git diff + session thread for an
                                archived change and post a summary comment to its
                                linked issue. Run after opsx:archive completes.
    sync capture                Post the current explore conclusion to the linked
                                ticket. Use during an explore session when a decision
                                crystallises.

  Requires linked_issue in openspec/changes/.openspec.yaml (written by `start` mode).
  Degrades gracefully when no linked issue is stored or tracker write fails.

  Examples:
    "sync ticket"
    "post to ticket"
    "capture this"
    "sync archive my-change"
```

**`help ship`**
```
ship — commit, push, and create a PR in one command

  Stages all changes, generates a conventional commit message from the diff,
  confirms with you, commits, pushes, and creates a PR.

  Enriches the commit with a ticket ID parsed from the branch name or
  current_ticket in .project/config.yaml (if set).

  Works without .project/config.yaml — auto-detects provider from git remote.
  Skips PR creation for Jira and Plane (commit + push only).

  The PR body ends with an Evidence section. Its kind follows project_type
  (web/mobile/bi → screenshots, qa → report link, api → OpenAPI diff as
  markdown, cli/library/ai/generic → transcript); tools, spec path and start
  command are auto-detected and shown at confirmation. Screenshots are hosted on
  an orphan `pr-evidence` branch (GitHub only). Override anything under
  `ship.evidence` in .project/config.yaml; `extra` strings are appended verbatim.

  After a successful GitHub PR, offers to start a recurring pr-watch via /loop.

  Options at confirmation:
    y        proceed
    e        edit the commit message
    n        abort — nothing is committed

  Examples:
    "ship"
    "commit and pr"
    "commit all changes"
```

**`help pr-watch`**
```
pr-watch — watch a GitHub PR's CI and comments, report-only

  One tick: checks the PR's state (stops the watch if merged/closed), fetches
  GitHub Actions run status for the head commit, and any new PR comments since
  the last tick. Reports findings — never pushes a fix or replies on your behalf.
  Persists last-seen run/comment IDs in .project/pr-watch/<pr-number>.yaml.
  Scheduling across ticks is handled by /loop, not by this mode. GitHub only.

  Examples:
    "watch PR #42"
    "pr-watch 42"
```

**`help release-notes`**
```
release-notes — generate release notes from git tags

  Diffs current tag against the previous semver tag, extracts resolved tracker
  tickets, groups by label, and publishes to GitLab Release or docs/release_notes/.

  Must be run while on a git tag (e.g. after `git checkout v1.2.0`).

  Optional qualifiers:
    (none)       neutral framing — "Release v1.2.0"
    for uat      candidate framing — "Release Candidate v1.2.0"
    for prod     production framing — "Released v1.2.0 to production"

  Examples:
    "release notes"
    "release notes for uat"
    "release notes for prod"
```

**Unknown mode fallback**

If the word after "help" does not match any known mode name, output:
```
Unknown mode: <name>. Valid modes: init, docs, ticket, sprint, next, start, status, standup, backlog, bulk, sync, ship, pr-watch, release-notes
```

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

## Shared: Provider Write Path Resolution

For any operation that mutates an issue (state change, label add/remove, sprint label, milestone assign), resolve the tool suffix from `tool_contracts` in `providers.json` (e.g. `update_ticket`) and call `mcp__{provider}__{suffix}`. If the MCP server isn't configured or the call fails because no write path is available, tell the user to configure it — see `mcp_setup` in `providers.json` for the install command and auth method — rather than guessing at an alternative.

**Lazy project ID fetch for GitLab (if needed)**

If provider is GitLab and `gitlab_project_id` is absent from `.project/config.yaml`, resolve it via the GitLab MCP tool that reads a project by path (e.g. `get_project`), using `{gitlab_group}/{repo_name}` parsed from the git remote. Store the numeric `id` as `gitlab_project_id` in config.

**Label-delta helper (for label-based writes)**

When the write involves label changes (state transitions, sprint assignment):
1. Fetch the issue's current labels via the provider's get-ticket MCP tool
2. Identify the state label to remove: any label whose value matches a `state_mapping[*].label` entry in `providers.json`
3. Compute `add_labels` and `remove_labels` as the delta; preserve all other labels
4. Call `mcp__gitlab__update_issue` with `state_event` (if the state changed) plus `add_labels` and `remove_labels`

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
5. docs_sources docs/     → run Resolve Docs Sources; for each resolved source, find
                             sections matching the ticket topic by keyword;
                             label each snippet [from: <folder-name>]
6. local repo files       → search src/, lib/, config files by filename + content proximity
7. context_repos          → if set in .project/config.yaml, search those repo paths
8. warn                   → "No relevant context found — Context section may be incomplete"
```

Never dump an entire docs file. Only include sections/paragraphs where the topic appears.

---

## Shared: Resolve Docs Sources

Call this procedure whenever a mode needs to read docs from sibling repos (ticket context, bulk generation, docs mode display).

### Step 1 — Collect entries

1. Read `docs_sources` from `.project/config.yaml` (treat as empty array if absent).
2. Parse `.gitmodules` from the repo root if it exists. For each submodule block, extract `path` and `url`. These become auto-discovered entries.
3. Merge: if an auto-discovered entry's `path` already appears in `docs_sources` (with or without `exclude`), skip the auto-discovered entry — the explicit entry wins entirely.
4. Filter: remove any entry where `exclude: true`.

Result: a list of `{path, url?}` objects to read from.

### Step 2 — URL normalization

When a `url` value is needed for MCP calls, normalize it to `owner/repo`:
- `https://github.com/org/repo` → `org/repo`
- `https://github.com/org/repo.git` → `org/repo`
- `git@github.com:org/repo.git` → `org/repo`

### Step 3 — Read each source

For each entry in the resolved list:

1. **Path exists on disk and has a `docs/` subfolder** → read all `.md` files from `<path>/docs/`
2. **Path missing or no `docs/` on disk, and `url` is present** → normalize URL to `owner/repo`; use GitHub MCP `get_file_contents` on the `docs/` path to retrieve the directory listing, then fetch each `.md` file individually
3. **Path missing and no `url`** → emit `⚠ <folder-name>: path missing, no url — skipped` and continue

Where `<folder-name>` is the last path segment of `path` (e.g. `../backend` → `backend`).

### Step 4 — Label all content

Prefix every snippet retrieved from a docs source with `[from: <folder-name>]` so its origin is clear in ticket context and bulk manifests.

---

## Shared: Scope-Width Detection Signals

Used by `ticket new` to decide whether a single-ticket request describes broad scope that warrants a breakdown offer. Evaluate the three signals below. If **any one** is true, offer a breakdown before proceeding with single-ticket creation.

### Signal 1 — Conjunction
Input contains `"and"` linking two distinct domain nouns, **or** a comma-separated list of ≥2 domain items.
- Triggers: `"auth and profile management"`, `"login, logout, and token refresh"`
- Does NOT trigger: `"retry logic and error handling for the auth endpoint"` — this is one concern, not two distinct domain nouns

### Signal 2 — Plural area word (without specific action verb)
Input contains one of the known **domain area words** but does NOT also contain a **specific action verb**.

**Known domain area words**: `auth`, `authentication`, `users`, `payments`, `notifications`, `settings`, `admin`, `administration`, `reporting`, `reports`, `search`, `onboarding`

**Specific action verbs that suppress the signal**: `create`, `delete`, `remove`, `update`, `refresh`, `fetch`, `get`, `display`, `show`, `render`, `add`, `reset`, `validate`, `send`, `handle`

- Triggers: `"create a ticket for the auth system"`, `"auth features"`, `"user management"` (no specific action)
- Does NOT trigger: `"refresh the auth token"`, `"fetch user profile"` — specific action verb present

### Signal 3 — Docs breadth
Run a quick relevance scan across all `docs/` files. If ≥3 **distinct doc sections** (across any combination of files) match the input topic, the signal is true.

- Triggers: topic "authentication" matches prd.md §Features, architecture.md §Components, database.md §Entities, and api.md §Endpoints (4 sections across 4 files)
- Does NOT trigger: topic matches only prd.md §Features and architecture.md §Components (2 sections)

### Breakdown offer prompt (when any signal triggers)
```
I see enough scope here for multiple tickets — propose a breakdown? [y/n]
```
- **y** → run decomposition scoped to doc sections matching the input topic; present manifest using the **Shared: Manifest Review** format
- **n** → proceed with normal single-ticket creation using the original input unchanged

---

## Shared: Start-Mode Pre-Flight Gate

Used by `start` mode to decide whether to transition a ticket to `in-progress` and create its branch/worktree automatically, or pause once for a combined confirmation. Replaces two separate prompts (transition, then branch) with a single gate evaluated before either action.

### Gate conditions

Evaluate all four; the gate fires if **any** is true:

| Condition | Check |
|---|---|
| WIP limit | Run steps 1–3 of the **Shared: WIP Limit Check** (read `wip_limit`, fetch in-progress count, compare) to get a boolean "would exceed" result. Do not show that check's own `Continue? [y/n]` prompt here — this gate's combined question supersedes it. |
| Scope-width signal | Evaluate the **Shared: Scope-Width Detection Signals** (conjunction, plural-area-without-verb, docs-breadth) against `ticket.title + " " + ticket.description`, instead of raw user input. For the docs-breadth signal specifically, do NOT run a second relevance scan — reuse the match count already produced by the Context Fallback Chain (start mode's fetch-and-prepare step): ≥3 distinct (file, section) matches counts as true. |
| Large estimate | Ticket's estimate field is set to a numeric value greater than `5`. A missing, empty, or zero estimate does NOT fire this condition — it simply contributes nothing to the gate. |
| Dirty tree (in-place mode) | `start.worktree` is `false` **and** `git status --porcelain` is non-empty. Does NOT apply when `start.worktree` is `true` or absent — a worktree never touches the current checkout. |

Passing `--confirm` on the `start` invocation forces the gate to fire unconditionally, regardless of the four conditions above, for that single invocation only. It is not persisted — the next invocation without `--confirm` evaluates the gate normally.

### Gate outcome

- **No condition true** (and no `--confirm`): proceed automatically — perform the state transition and branch/worktree creation, then report both in one combined summary line. No question is asked.
- **Any condition true** (or `--confirm` passed): ask once, combining the transition and branch/worktree decision:
  ```
  TICK-42 looks {reason} — transition to in-progress and create its branch anyway? [y/n]
  ```
  Where `{reason}` names whichever condition(s) fired — e.g. "like it's at the WIP limit", "broad in scope", "like its estimate is large", "like uncommitted changes would carry onto the new branch" — joined with "and" when more than one fires.
  - **y** → perform both the transition and the branch/worktree creation
  - **n** → output `Transition cancelled — continuing in exploration mode (ticket stays in current state).` and skip both actions

This gate has no effect on tickets already in `in-progress`, `in-review`, `done`, or `blocked` — those states keep start mode's existing state-specific messaging (see Step 2, below) instead of gate evaluation.

---

## Shared: Manifest Review

Used by both `bulk` mode and `ticket new` breakdown flow. This is the mandatory human review step — no MCP ticket creation calls are made until `create` is confirmed.

### Manifest table format

Display candidates grouped by epic. Within each epic group, order by type: `scaffold` and `migration` first, then `feature`, `task`, `maintenance`, `spike`.

```
Found N ticket candidates from <file list> (dedup: M existing tickets checked)

┌────┬──┬────────────────────────────────────────┬────────────┬──────────┐
│ #  │✓ │ Title                                  │ Type       │ Epic     │
├────┼──┼────────────────────────────────────────┼────────────┼──────────┤
│  1 │✓ │ Set up AuthService (scaffold)          │ scaffold   │ Auth     │
│  2 │✓ │ Create sessions table                  │ migration  │ Auth     │
│  3 │✓ │ Auth token silent refresh              │ feature    │ Auth     │
│  4 │✓ │ Logout across all devices              │ feature    │ Auth     │
│  5 │✗ │ Admin revoke all sessions ⚠ dup #12   │ feature    │ Auth     │
├────┼──┼────────────────────────────────────────┼────────────┼──────────┤
│  6 │✓ │ Set up GitHub Actions CI pipeline      │ maintenance│ DevOps   │
└────┴──┴────────────────────────────────────────┴────────────┴──────────┘

Edit commands: skip <n> | keep only <n,n,...> | check <n> | rename <n> <title>
               merge <n,n> | type <n> <type> | create
```

### Edit commands

| Command | Syntax | Effect |
|---|---|---|
| skip | `skip <n>` | Uncheck row n (set to ✗) |
| keep only | `keep only <n>,<n>,...` | Uncheck all rows except the listed numbers |
| check | `check <n>` | Re-check row n (set to ✓) |
| rename | `rename <n> <new title>` | Update the title of row n |
| merge | `merge <n>,<n>` | Combine two rows — prompt user to confirm or override merged title, then collapse to one row |
| type | `type <n> <type>` | Change ticket type of row n (valid: feature, task, scaffold, migration, maintenance, spike) |
| create | `create` | Finalize — show confirmation, then create all ✓ tickets |

After any edit command (except `create`), re-display the full updated manifest.

For invalid commands, output:
```
Unknown command. Valid commands: skip, keep only, check, rename, merge, type, create
```
Then re-display the manifest unchanged.

### Create confirmation step

When `create` is issued:
1. Echo the final checked ticket list and count:
   ```
   Creating 8 tickets:
     1. Set up AuthService (scaffold)
     2. Create sessions table
     ...
   Confirm? [y/n]
   ```
2. On `y` → begin MCP creation calls sequentially. For each:
   - Success: `✓ Created: <title> (#<id>)`
   - Failure: `✗ Failed: <title> — <error>` (continue with remaining tickets regardless)
3. On `n` → return to manifest for further editing.

---

## MODE: init

### Step 1 — Read or create `.project/config.yaml`

If `.project/config.yaml` exists and `--probe` flag is NOT set, read it and skip to Step 5.

### Step 1b — Validate existing config before re-probe (`--probe` only)

When `--probe` is set and the file exists, validate it against `references/config.schema.json` before proceeding. Report each violation as a drift warning — these are informational; the probe continues regardless to correct the config.

```
⚠ sprint_convention missing — will re-probe
⚠ old_field is not a recognised config field — will be removed on re-write
⚠ gitlab_edition: must be ce or ee-premium, got: community — will re-probe
```

Format: `⚠ <field> <reason> — will re-probe` for missing/invalid fields; `⚠ <key> is not a recognised config field — will be removed on re-write` for unknown keys. After printing all drift lines, continue to Step 2.

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
  5. QA          (a dedicated test-automation repo)
  6. AI / ML     (LLM app, RAG, agent, model training)
  7. BI / analytics  (dashboards, metrics, dbt)
  8. CLI tool
  9. Library / SDK
  10. Generic / full-stack
```

Store as `project_type`: `mobile` | `web` | `api` | `microservices` | `qa` | `ai` | `bi` | `cli` | `library` | `generic`.

**Conditional follow-up** — ask only the matching clarification, skip for generic:

| project_type | Question | Options | Stored as `stack` |
|---|---|---|---|
| mobile | Cross-platform or native? | react-native, flutter, native, other | e.g. `react-native` |
| web | Framework? | nextjs, nuxt, remix, vite-spa, other | e.g. `nextjs` |
| api | Protocol? | rest, graphql, grpc, mixed | e.g. `rest` |
| microservices | Repo structure? | separate-repos, monorepo | e.g. `separate-repos` |
| qa | Test tool? | playwright, cypress, pytest, k6, other | e.g. `playwright` |
| ai | Shape? | llm-app, rag, agent, ml-training, other | e.g. `rag` |
| bi | Tooling? | dbt, metabase, superset, looker, powerbi, other | e.g. `dbt` |
| cli | Language? | python, go, node, rust, other | e.g. `go` |
| library | Language? | python, typescript, go, rust, other | e.g. `typescript` |
| generic | *(skip)* | — | *(omit from config)* |

**Worktree preference** — ask once, for every project type:
```
Create a separate git worktree for each ticket? [Y/n]
  (choose n if the app needs untracked files, a running dev server, or the repo uses submodules)
```

Store the answer as `start.worktree` (`Y` → `true`, `n` → `false`). A config with no `start.worktree` is treated as `true` and is never re-asked.

### Step 3 — Confirm provider access

Run `ToolSearch` for the provider's MCP prefix (`provider.mcp_prefix`, e.g. `mcp__gitlab__`) to confirm its MCP server is configured and at least one tool resolves.

- **Found** → `✓ {Provider} MCP server reachable`
- **Not found** → tell the user to configure it — see `mcp_setup` in `providers.json` for the install command and auth method for this provider — then stop until they've done so.

Store in `.project/config.yaml`:
```yaml
provider:
  name: gitlab
```

### Step 3b — GitLab-specific setup (GitLab only)

Skip this step entirely if `provider.name != "gitlab"`.

**Group detection**

Run `git remote get-url origin` and parse the group path:
- HTTPS: `https://gitlab.example.com/{group}/{repo}.git` → group = first path segment after host
- SSH: `git@gitlab.example.com:{group}/{repo}.git` → group = segment before the last `/`

If group detected, confirm: `"Detected GitLab group: {group}. Is this correct? [y/n]"` — on `n`, ask for manual entry.
If not detected, ask: `"Enter your GitLab group path (e.g. mycompany):"`

Store as `gitlab_group` in `.project/config.yaml`.

**Edition detection**

Call the GitLab MCP iterations tool (`gitlab_extras.edition_probe.tool` in `providers.json`, i.e. `mcp__gitlab__list_iterations`) scoped to `gitlab_group`:
- Succeeds (returns a list, even empty) → `gitlab_edition: ee-premium`, `sprint_proxy: iteration`
- Fails with not-found/forbidden, or the tool isn't available → `gitlab_edition: ce`, `sprint_proxy: label`, `sprint_label_scope: sprint`
- Ambiguous → ask: `"Could not detect GitLab edition. Is your instance EE Premium or Ultimate? [y/n]"`
  - `y` → `gitlab_edition: ee-premium`, `sprint_proxy: iteration`
  - `n` → `gitlab_edition: ce`, `sprint_proxy: label`, `sprint_label_scope: sprint`

Store results in `.project/config.yaml`.

**Sprint naming convention (CE only)**

If `gitlab_edition == "ce"`:

First, if this is a re-probe (`init --probe`), check for existing sprint labels:
- Call the GitLab MCP list-labels tool (`mcp__gitlab__list_labels`) filtered to the `sprint::` prefix
- If labels found AND the stored `sprint_convention` differs from what the user is about to select → after selection, output:
  ```
  ⚠ Sprint labels already exist using {old_convention} convention — changing requires
    manually relabelling existing sprints. Confirm change? [y/n]
  ```
  On `n`: keep existing `sprint_convention`, skip writing.

Ask:
```
Which sprint naming convention?
  1. Sequential          sprint::1, sprint::2  (simplest)
  2. Year-Week (ISO)     sprint::2025-W23      (recommended)
  3. Year-Month-Week     sprint::2025-06-W3
  4. Quarterly           sprint::Q2-2025-S1
```
Store choice as `sprint_convention: sequential | year-week | year-month-week | quarterly`.
Output: `⚠ Convention cannot be changed after the first sprint is created without relabelling existing sprints.`

**Project ID capture (all GitLab editions)**

Parse the repo name from the git remote (segment after the last `/` in the path, minus `.git` suffix). Construct full project path: `{gitlab_group}/{repo_name}`.

Call the GitLab MCP project-lookup tool for that path:
- Found → read the numeric `id` field; store `gitlab_project_id: <id>` in `.project/config.yaml`
- Not found / tool unavailable → skip silently; `gitlab_project_id` will be fetched lazily on first write operation

**pm-meta project setup (CE only)**

If `gitlab_edition == "ce"`:
1. Compute target path: `{gitlab_group}/pm-meta`
2. Call the GitLab MCP project-lookup tool for that path:
   - Found → project exists; store `pm_meta_project: {gitlab_group}/pm-meta`
   - Not found → call the GitLab MCP create-project tool with `name: pm-meta`, `namespace_id: {group_id}`:
     - Success → store `pm_meta_project: {gitlab_group}/pm-meta`
     - Permission denied → store `pm_meta_project: {current_project_path}`; output `⚠ Could not create pm-meta project — sprint metadata will be stored in the current project`

### Step 4 — Capability probe

For each feature (epics, sprints, relationships, sub_issues), call the MCP tool named in `probe_endpoints` for the current provider (`providers.json`). Map the result to a capability flag:

- Tool call succeeds → `true`
- Tool call fails with a not-found/forbidden/plan-restriction error → `false`
- `probe_endpoints` entry is `null`, or the result is ambiguous → ask user

For **GitLab**: use `gitlab_edition` from Step 3b to select `plan_variants.ce` or `plan_variants.ee-premium` from `providers.json` instead of probing sprint capability separately. The edition detection in Step 3b IS the sprint probe for GitLab.

When asking the user (ambiguous probe):
> "Couldn't determine whether your {Provider} workspace supports {feature}. Is it available on your plan? [y/n]"

**Plane extra — state UUID resolution**

If `provider.name == "plane"`, call `mcp__plane__list_states`. For each returned state, reverse-map its `name` against `state_mapping` `state_name` values to find the matching canonical state. Build a map and store in `.project/config.yaml`:

```yaml
plane_state_ids:
  backlog: "<uuid-of-Backlog-state>"
  todo: "<uuid-of-Unstarted-state>"
  in-progress: "<uuid-of-In Progress-state>"
  in-review: "<uuid-of-in-review-label-state>"
  done: "<uuid-of-Done-state>"
```

If a canonical state has no matching Plane state name, leave its value as `null` and warn:
```
⚠ Could not map canonical state '<state>' to a Plane state — check your project's state configuration in Plane.
```

Output: `✓ Plane state IDs resolved` or list any unmapped states.

### Step 4.5 — Validate assembled config

Assemble the full config object in memory from all values collected in Steps 2–4. Validate it against `references/config.schema.json`.

**If validation fails:**
```
✗ Config validation failed — not writing .project/config.yaml

  • provider.name: must be one of github, gitlab, jira, plane
  • gitlab_edition: required when provider.name is gitlab
  {one line per violation}

Fix the issues above and re-run init.
```
Do NOT write the file. Stop here.

**If validation passes:** continue to Step 5.

### Step 5 — Write `.project/config.yaml`

Write `.project/config.yaml` conforming to `references/config.schema.json`. Begin the file with the schema comment so editors can provide autocomplete and inline validation:

```yaml
# yaml-language-server: $schema=../skills/project-management/references/config.schema.json
```

All valid fields and their constraints are defined in `references/config.schema.json`. Refer to it as the authoritative field list.

**`docs_sources`** — optional array of sibling repo doc sources. Each entry is an object:

| Field | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Relative path to the sibling repo (e.g. `../backend`) |
| `url` | string | no | Git remote or GitHub URL (e.g. `https://github.com/org/repo`). Used as fallback when `path` is not present on disk. |
| `exclude` | boolean | no | Set `true` to suppress a path auto-discovered from `.gitmodules` |

```yaml
docs_sources:
  - path: ../backend
    url: https://github.com/knvpk/backend
  - path: vendor/ui-lib
    exclude: true   # auto-discovered submodule — suppress it
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
| qa | `flaky`, `coverage-gap`, `regression`, `test-data`, `env` | `#e4e669`, `#0075ca`, `#d93f0b`, `#7057ff`, `#28a745` |
| ai | `prompt`, `eval`, `model`, `guardrail`, `cost`, `latency` | `#0075ca`, `#28a745`, `#7057ff`, `#b60205`, `#e4e669`, `#d93f0b` |
| bi | `metric-definition`, `data-quality`, `dashboard`, `source` | `#0075ca`, `#b60205`, `#28a745`, `#7057ff` |
| cli | `breaking-change`, `ux`, `flags`, `exit-codes`, `completion`, `packaging`, `cross-platform` | `#d93f0b`, `#28a745`, `#0075ca`, `#b60205`, `#7057ff`, `#e4e669`, `#0052cc` |
| library | `semver`, `breaking-change`, `deprecation`, `docs-gap` | `#0075ca`, `#d93f0b`, `#e4e669`, `#7057ff` |
| generic | *(none)* | — |

Output: `✓ Type labels created` or `✓ Type labels already present` (skip silently for generic).

### Step 8 — Notify active fallbacks

For each capability that is false, print one line:
```
⚠  Epics not available on this plan — using label epic:{slug} fallback
⚠  Sprints not available — using milestone proxy
```

**GitLab CE exception**: do NOT print the sprint proxy warning above. Instead print:
```
ℹ  GitLab CE — sprints use scoped labels (sprint::*). Convention: {sprint_convention}. Metadata: {pm_meta_project}.
```

**Plane exception**: if `plane_state_ids` has any `null` entries, print:
```
⚠  Some canonical states could not be mapped to Plane states — state transitions for those states will use MCP only.
```

### Step 9 — Detect sibling repo doc sources

Check if `.gitmodules` exists in the repo root.

**If `.gitmodules` is absent** → skip this step.

**If `.gitmodules` is present**:
1. Parse every submodule block to extract `path` and `url`.
2. Filter out any submodule whose `path` is already present in the existing `docs_sources` array — only prompt for new ones. If all submodules are already configured, skip the prompt entirely.
3. Present the remaining list and ask:
   ```
   Found submodules: [vendor/backend, vendor/design-system]
   Include their docs/ as doc sources? [all / select / none]
   ```
4. **all** → write all submodules to `docs_sources` in `.project/config.yaml`, each as `{path, url}` using the URL from `.gitmodules`
5. **select** → prompt `[y/n]` for each submodule; write confirmed entries only
6. **none** → skip; user can add `docs_sources` manually later

Only write entries for submodules the user confirmed. Do not overwrite any existing `docs_sources` entries.

### Step 10 — Offer docs scaffold

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

Run Resolve Docs Sources. If any sources resolved, display:
```
Doc sources: backend (disk), design-system (remote)
```
Use `(disk)` when the path exists locally, `(remote)` when the path was missing and MCP fallback will be used. This is informational only — the skill never scaffolds or writes files to any docs_sources path.

### Step 2 — Scaffold files (first time only, type-conditional)

Read `project_type` from `.project/config.yaml`. If absent, treat as `generic`.

**File set by project type:**

| project_type | Files created |
|---|---|
| mobile | prd.md, architecture.md, local-storage.md, tools.md (mobile variant) |
| web | prd.md, architecture.md, database.md, tools.md |
| api | prd.md, architecture.md, database.md, tools.md, api.md |
| microservices | architecture.md, services.md, tools.md |
| qa, ai, cli, library | prd.md, architecture.md, tools.md |
| bi | prd.md, architecture.md, database.md, tools.md |
| generic | prd.md, architecture.md, database.md, tools.md |

Create each file only if it doesn't already exist:

**docs/prd.md** *(mobile, web, api, qa, ai, bi, cli, library, generic)*
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

**docs/database.md** *(web, api, bi, generic)*
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

**docs/tools.md** *(generic, web, api, microservices, qa, ai, bi, cli, library variant)*
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

### Step 2b — Offer interactive fill (after scaffold)

After Step 2 writes any new files, output:
```
Created: {file list}. Fill them in now? [y/n]
```

- **y** → immediately run the **Interactive Fill Flow** below
- **n** → exit docs mode cleanly; fill can be invoked any time via fill-intent routing phrases

---

### Interactive Fill Flow

Used by Step 2b (post-scaffold) and by fill-intent routing phrases ("fill docs", "fill in docs", "populate docs", "fill in the {file}").

**When invoked via routing phrase** (not post-scaffold): read which files in `docs/` currently exist. Ask only questions whose target sections live in those files. Do not create new files.

Run Resolve Docs Sources. If any sources resolved, display:
```
Doc sources: backend (disk), design-system (remote)
```

At any question, the user may type `done` to skip all remaining questions and go directly to Step E (post-fill summary).

#### Step A — Core questions (all project types)

Ask each question in order. Show target sections after the question label so the user knows what to include.

| # | Question | Target sections |
|---|----------|-----------------|
| 1 | "What does this project do? (2-3 sentences)" | `prd.md §Overview` |
| 2 | "What are the main features? (one per line — I'll format as bullet points)" | `prd.md §Features` |
| 3 | "What is the tech stack? Include language, framework, testing framework, and linter/formatter." | `tools.md §Language`, `tools.md §Framework`, `tools.md §Testing`, `tools.md §Linting & Formatting` |
| 4 | "What are the main components or services?" | `architecture.md §Components` |
| 5 | "How does data flow through the system? (e.g. client → API → DB)" | `architecture.md §Data Flow` |

#### Step B — Conditional questions (by project_type)

Read `project_type` from `.project/config.yaml` (treat as `generic` if absent), then ask only the matching question(s):

| project_type | Question | Target sections |
|---|---|---|
| web, api, bi, generic | "What database(s) do you use, and what are the main entities/tables?" | `database.md §Overview`, `database.md §Entities` |
| api | "How is the API authenticated and versioned? (e.g. Bearer token, URI versioning)" | `api.md §Authentication`, `api.md §Versioning Strategy` |
| microservices | "List your services with their responsibilities (name: description, one per line)" | `services.md §Service Registry` |
| mobile | "What local storage engine do you use, and how does data sync with the backend?" | `local-storage.md §Storage Engine`, `local-storage.md §Sync Strategy` |
| library | "What is the public API surface and versioning policy?" | `architecture.md §Components`, `architecture.md §Architecture Decisions` |
| ai | "Which models/providers are used and how are outputs evaluated?" | `architecture.md §Components`, `architecture.md §Architecture Decisions` |
| cli | "What commands and flags form the public interface, and what is the output contract (stdout, stderr, exit codes)?" | `architecture.md §Components` |
| qa | "What is under test, and which tools and environments are used?" | `architecture.md §Components`, `tools.md` |

#### Step C — Optional questions

Each is prefixed with `(optional — press Enter to skip)`. If the user presses Enter with no input, skip to the next question.

| Question | Target sections |
|---|---|
| "(optional — press Enter to skip) Any non-functional requirements? (performance, security, compliance)" | `prd.md §Non-Functional Requirements` |
| "(optional — press Enter to skip) What CI/CD, command runner, and dev environment do you use?" | `tools.md §CI/CD`, `tools.md §Command Runner`, `tools.md §Dev Environment` |
| "(optional — press Enter to skip) Any Docker app dependencies? (e.g. postgres, redis, valkey)" | `tools.md §App Dependencies (Docker)` |
| "(optional — press Enter to skip) Any key architecture decisions already made?" | `architecture.md §Architecture Decisions` |

#### Step D — Write answers to target sections

For each question that received an answer:

1. **Parse the answer** to extract content for each target section:
   - **Tech stack answer** (Q3): split by comma or newline; assign each part to the most appropriate section (language token → `§Language`, framework token → `§Framework`, test-framework token → `§Testing`, linter/formatter token → `§Linting & Formatting`)
   - **Features answer** (Q2): format each line as a `- item` bullet
   - **Services answer** (microservices Q): format as table rows added to the `§Service Registry` table
   - **CI/CD + tools answer** (optional Q2): split by comma or newline; assign each part to `§CI/CD`, `§Command Runner`, or `§Dev Environment` based on keywords
   - **All other answers**: write as prose

2. **Apply append rule** — for each target (file, section):
   - Section body is **empty or whitespace-only** → write content directly
   - Section body has **non-whitespace content** → append `\n\n---\n\n{new content}` after the existing content; do not modify anything before the separator

3. **Docker hook** — after writing to `tools.md §App Dependencies (Docker)`, run the docker-modular-stack catalog check (Step 4 logic).

#### Step E — Post-fill summary

After all questions are processed, output a summary grouped by file listing only sections that were actually written:

```
✓ docs/prd.md          — Overview, Features
✓ docs/architecture.md — Components, Data Flow
✓ docs/tools.md        — Language, Framework, Testing, CI/CD
✓ docs/database.md     — Overview, Entities
```

Omit any file where no sections were written. Omit skipped or unanswered questions from the list.

---

### Step 3 — Edit the relevant section

Identify which file and section the user wants to update.

**Empty section detection**: Before editing, check whether the target section's body — the text between its `## Header` line and the next `##` heading (or end of file) — is empty or contains only whitespace.

- **If empty** → retrieve the targeted question from the fill flow question map (Steps A–C of the Interactive Fill Flow above) for that (file, section) pair and ask it. Write the answer using the append rule (Step D). This prevents passive waiting when the user targets a blank section.
- **If non-empty** → edit that section using the user's stated changes, using the append rule. Do not ask a fill question. Do not touch other sections.

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

## MODE: backlog

### Sub-mode: backlog refine

Walk unestimated backlog/todo tickets one at a time to add story-point estimates and check Definition of Ready.

**Step 1 — Fetch unestimated tickets**

Fetch all tickets in `backlog` or `todo` state. Filter to those with no story-point estimate (null, empty, or zero). Sort by priority (high → medium → low → unset). If none found:
```
All backlog tickets are estimated — nothing to refine.
```

**Step 2 — Walk tickets**

For each ticket, display context then prompt for estimate:

```
────────────────────────────────────────────
[1/5] TICK-55  (high)
────────────────────────────────────────────
{ticket description, truncated to 200 chars}…
Labels: backend, auth
Blocks: TICK-60

⚠ Not ready: no description    ← only if DoR fails

Estimate in story points (or "s" to skip):
> _
```

DoR check per ticket:
- `has_description`: ticket description is non-empty
- `has_labels`: ticket has at least one label

Show `⚠ Not ready: {failing criteria}` only when DoR fails. The estimate prompt always appears regardless of DoR status.

**Step 3 — Save estimate**

On a numeric entry: call `update_ticket` with the estimate field value. On `s` or `skip`: record as skipped, do not call the provider.

After saving, advance to the next unestimated ticket automatically.

**Step 4 — Session summary**

After all tickets are presented:
```
Refined: 3 estimated, 1 skipped, 0 remaining.
```

---

## MODE: bulk

Generate a full backlog from the project's `docs/` folder. Reads all applicable doc files, produces a typed dependency-ordered manifest of ticket candidates, deduplicates against existing tracker tickets, then creates all approved tickets in one pass.

### Step 1 — Read all applicable docs/ files

Read `project_type` from `.project/config.yaml`. Read every doc file that exists in `docs/` and is applicable to the project type (same file set as `docs` mode scaffold). Silently skip any file that does not exist.

| project_type | Doc files to read |
|---|---|
| mobile | prd.md, architecture.md, local-storage.md, tools.md |
| web | prd.md, architecture.md, database.md, tools.md |
| api | prd.md, architecture.md, database.md, api.md, tools.md |
| microservices | architecture.md, services.md, tools.md |
| qa, ai, cli, library | prd.md, architecture.md, tools.md |
| bi | prd.md, architecture.md, database.md, tools.md |
| generic | prd.md, architecture.md, database.md, tools.md |

Collect all file paths that were successfully read. These become the `source_files` list shown in the manifest header.

**Cross-repo docs**: run Resolve Docs Sources. For each resolved source, read all `.md` files from its `docs/`. Append them to the file set used for section mapping in Step 2, labelling each section `[from: <folder-name>]`. Append resolved source paths to `source_files` (e.g. `backend/docs/architecture.md [from: backend]`).

### Step 2 — Map doc sections to ticket candidates

Apply the section-to-ticket-type mapping below. Use case-insensitive prefix matching on section header text. Sections that do not match any known prefix are ignored.

| Doc file | Section header prefix | Ticket type | Candidate title pattern |
|---|---|---|---|
| `prd.md` | `Features` | `feature` | One candidate per distinct feature entry |
| `prd.md` | `Non-Functional`, `NFR` | `maintenance` | One candidate per distinct NFR |
| `architecture.md` | `Components` | `scaffold` | "Set up {Component name}" |
| `architecture.md` | `Data Flow` | `task` | One candidate per data flow entry |
| `architecture.md` | `Decisions` | `spike` | Only entries containing "TBD", "evaluate", or "?" — "Spike: {decision}" |
| `database.md` / `local-storage.md` | `Entities`, `Data Model` | `migration` | "Create {entity} table/schema" |
| `api.md` | `Endpoint` | `task` | One candidate per endpoint group |
| `tools.md` | `CI/CD` | `maintenance` | "Set up CI/CD pipeline" |
| `tools.md` | `Testing` | `maintenance` | "Set up test harness" |
| `tools.md` | `Dev Environment` | `maintenance` | "Set up local dev environment" |
| `tools.md` | `App Dependencies` | `maintenance` | One candidate per listed service |
| `services.md` | `### Service:` | `scaffold` | "Scaffold {service name} service" |

For `prd.md §Features`, generate one `feature` candidate per distinct bullet point, heading, or named feature description. Do not split a single feature bullet into multiple candidates.

For `prd.md §Scenarios` (GIVEN/WHEN/THEN blocks), use them to supplement the feature tickets they relate to (add to context) rather than generating standalone candidates.

### Step 3 — Deduplicate against existing tracker tickets

Emit: `Scanning existing tickets for duplicates…`

Call `list_tickets` using the active provider MCP tool. If the call succeeds:
- For each candidate, check if any existing open ticket title has >80% word overlap with the candidate title (case-insensitive, ignore filler words: the, a, an, is, to, for, in, on, with, of, and, or)
- Matches: set candidate `checked = false` and append `⚠ possible duplicate of #<id>` to the title
- Non-matches: set candidate `checked = true`

If `list_tickets` fails or times out:
- Set all candidates `checked = true`
- Record: dedup_status = `"⚠ Dedup skipped — could not reach tracker"`

### Step 4 — Sort candidates by dependency order

Order candidates within each epic group as follows:
1. `scaffold` tickets first
2. `migration` tickets second
3. `feature`, `task`, `maintenance`, `spike` tickets after

For cross-epic ordering, scaffold/migration tickets that share a component or entity name with a feature/task ticket are output before that feature/task ticket, with an implicit blocking relationship noted in the manifest `Blocks` indicator (shown only when a relationship exists).

To infer relationships: match component names from `architecture.md §Components` and entity names from `database.md §Entities` against the descriptions of feature/task candidates. If the component/entity name appears in the feature candidate title or description → infer a dependency.

### Step 5 — Build manifest header

Compose the one-line header:
- Successful dedup: `Found N ticket candidates from <file1>, <file2>, ... (dedup: M existing tickets checked)`
- Skipped dedup: `Found N ticket candidates from <file1>, <file2>, ... ⚠ Dedup skipped — could not reach tracker`

### Step 6 — Display manifest and await edit commands

Display the manifest header followed by the manifest table using the format defined in **Shared: Manifest Review**. Await edit commands.

When `create` is confirmed, proceed to Step 7.

### Step 7 — Generate ticket bodies and create

For each checked ticket row, generate the full ticket body using the existing body generation logic (Summary, Context, Requirements, Scenarios, Use Cases, Non-Functional, OpenSpec Hint). Use the manifest row's **title**, **type**, and **source doc section** as the primary input (in place of conversational description). The `## Context` block MUST include:

```
> Derived from <doc file> §<section>
```

as the first reference line, followed by any additional context from the fallback chain.

Call `create_ticket` for each ticket using the generated body. Acknowledge each result:
- Success: `✓ Created: <title> (#<id>)`
- Failure: `✗ Failed: <title> — <error>` (continue with remaining tickets)

### Step 8 — Post-create offers

After all create calls complete:

**Sprint assignment offer** (only if `active_sprint` is set in `.project/config.yaml`):
```
Add all N created tickets to Sprint {name}? [y/n]
```
On `y`: for each successfully created ticket —
- **GitLab CE (`sprint_proxy == "label"`)**: use **Shared: Provider Write Path Resolution** to add `active_sprint.label_name` to the issue's labels
- **All other providers**: call the sprint assignment MCP tool with the sprint ID

**Epic label offer** (only if manifest had ≥2 distinct epic groups):
```
Create epic labels for {Epic1}, {Epic2}, {Epic3}? [y/n]
```
On `y`:
1. Derive slug for each epic: lowercase, spaces → hyphens, strip special chars (e.g. "Auth System" → `epic:auth-system`)
2. Call `list_labels` to check which epic labels already exist
3. Call `create_label` for any missing epic labels (colour `#e99695`)
4. Call `add_label` to attach each epic label to the relevant tickets in that group

---

## MODE: ticket

Detect sub-mode from user intent: **new** | **update** | **link** | **list** | **lifecycle**

---

### Sub-mode: ticket new

#### Step 0 — Scope-width check (breakdown detection)

Before collecting any input, evaluate the user's message against the three signals defined in **Shared: Scope-Width Detection Signals**.

If any signal is true:
- Offer: `"I see enough scope here for multiple tickets — propose a breakdown? [y/n]"`
- **y** → run decomposition scoped to the doc sections matching the input topic; present the **Shared: Manifest Review** table; stop the single-ticket flow (the manifest handles creation from here)
- **n** → continue to Step 1 as normal, treating the original input as a single ticket request

If no signal is true, skip this step entirely and proceed to Step 1.

#### Step 1 — Collect input

Minimum required: ticket title. Ask for at minimum one label or sprint assignment if not provided.

#### Step 2 — Read context (relevance-filtered)

Follow the **Context Fallback Chain** defined in Shared section above. Collect only relevant pieces. Build a `context_refs` list.

#### Step 3 — Generate ticket brief

> **Note on entry points**: This body generation step is invoked from three places:
> 1. Direct `ticket new` conversational input (standard path — use the user's description as the primary input)
> 2. `bulk` mode manifest creation — use the manifest row's **title**, **type**, and **source doc section** as the primary input instead of a conversational description
> 3. `ticket new` breakdown manifest creation — same as bulk mode, scoped to matching doc sections
>
> For manifest-sourced tickets (paths 2 and 3), the `## Context` block MUST begin with:
> `> Derived from <doc file> §<section name>` as the first reference line, before any other fallback chain results.

**BDD seed patterns** — read `project_type` from `.project/config.yaml` and use the matching seeds as vocabulary context when generating `## Scenarios`. Seeds guide language and structure; generated scenarios must still address the specific ticket topic, not copy seeds verbatim. Skip seeds for `generic` or absent `project_type`.

| project_type | Seed patterns (use as vocabulary guidance) |
|---|---|
| mobile | `GIVEN user has denied camera permission / WHEN feature requires camera access / THEN app shows permission rationale and graceful fallback`; `GIVEN device switches network mid-operation / WHEN transfer is in progress / THEN app resumes via offline queue without data loss`; `GIVEN app is backgrounded during long operation / WHEN user returns to foreground / THEN session and operation state are restored` |
| web | `GIVEN API call is in-flight / WHEN component renders / THEN skeleton loader shown, not blank screen`; `GIVEN user submits form with invalid input / WHEN validation runs / THEN inline errors appear and submit stays disabled`; `GIVEN mobile viewport (375px) / WHEN page loads / THEN layout adapts to single-column with accessible touch targets` |
| api | `GIVEN authenticated user with scope=read:orders / WHEN GET /orders?status=pending / THEN 200 with paginated list and X-Total-Count header`; `GIVEN request without Authorization header / WHEN POST /payments / THEN 401 with WWW-Authenticate challenge`; `GIVEN 51st request in a 60-second window (limit=50/min) / WHEN rate limiter evaluates / THEN 429 Too Many Requests with Retry-After header` |
| microservices | `GIVEN orders-svc calls inventory-svc.reserveStock() / WHEN inventory-svc returns 503 three times / THEN circuit breaker trips, order stays in PENDING`; `GIVEN payment-svc publishes order.paid event / WHEN notifications-svc is down / THEN event persists in DLQ and is delivered after recovery`; `GIVEN payment succeeds but order creation fails / WHEN saga compensates / THEN payment is refunded and no order record persists` |
| qa | `GIVEN a clean environment / WHEN the suite runs / THEN all tests pass without retries`; `GIVEN a flaky test / WHEN it fails intermittently / THEN it is quarantined with a linked ticket` |
| ai | `GIVEN a prompt with retrieved context / WHEN the model answers / THEN the answer is grounded in the context and cites its source`; `GIVEN an unsafe input / WHEN the guardrail evaluates / THEN the request is refused with an explanation`; `GIVEN the eval set / WHEN run on the change / THEN the score is at or above the threshold` |
| bi | `GIVEN a metric definition / WHEN the dashboard loads / THEN the value equals the source-of-truth query`; `GIVEN a stale source / WHEN data is older than its freshness limit / THEN the dashboard flags it` |
| cli | `GIVEN an unknown flag / WHEN the command runs / THEN usage is printed to stderr and the exit code is 2`; `GIVEN stdin is piped / WHEN run non-interactively / THEN no prompt appears and input is consumed`; `GIVEN --json / WHEN the command succeeds / THEN stdout is valid JSON and logs go to stderr` |
| library | `GIVEN a consumer calls a deprecated function / WHEN executed / THEN a deprecation warning names the replacement`; `GIVEN a minor release / WHEN a consumer upgrades / THEN existing public calls behave unchanged` |

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

For **state changes**: validate against canonical machine → translate to provider state via `state_mapping`.

#### Shared: DoD Gate (→ done transitions)

Run this gate **after** state machine validation and **before** the provider call, only when transitioning to `done`.

1. Read `definition_of_done` from `.project/config.yaml`. If absent or empty — skip gate entirely.
2. For each criterion, evaluate:
   - `has_bdd`: ticket description contains at least one `## Scenarios` section (case-insensitive match on `## scenarios` or `## Scenarios`).
   - `has_assignee`: ticket has at least one assignee.
3. If all criteria pass — proceed silently.
4. If any criterion fails AND `--force` flag was NOT passed:
   ```
   ⚠ DoD unmet:
     - has_assignee: no assignee set
   Close anyway? [y/n]
   ```
   On `n` → output `Transition cancelled` and stop. On `y` → proceed with the provider call.
5. If `--force` was passed → skip the confirmation prompt, proceed directly.

#### Shared: WIP Limit Check (→ in-progress transitions)

Run this check **after** state machine validation and **before** the provider call, only when transitioning to `in-progress`.

1. Read `wip_limit` from `.project/config.yaml`. If absent — skip check entirely.
2. Fetch count of tickets currently in `in-progress` state in the active sprint (single MCP list call filtered by state).
3. If count is **below** `wip_limit` — proceed silently.
4. If count is **at or above** `wip_limit`:
   ```
   ⚠ WIP limit is {wip_limit} — you have {count} ticket(s) in-progress.
   Continue? [y/n]
   ```
   On `n` → output `Transition cancelled` and stop. On `y` → proceed with the provider call.

- **GitHub, Jira, Plane**: call `update_ticket` directly.
- **GitLab**: use **Shared: Provider Write Path Resolution** + label-delta helper to apply the transition. For `blocked`: prompt for reason + optional blocking ticket ref before calling the resolved write path.

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

### Step 1 — Detect sub-mode: create | add | remove | plan | review | retro | close | labels | status | milestone

| Input contains | Sub-mode |
|---|---|
| "plan sprint", "sprint planning", "sprint plan" | **plan** |
| "sprint review", "review sprint", "what shipped" | **review** |
| "sprint retro", "retrospective", "retro" | **retro** |
| "sprint close", "close sprint", "end sprint", "finish sprint" | **close** |

### Sub-mode: sprint create

Read `sprint_proxy` from `.project/config.yaml`.

**If `sprint_proxy == "label"` (GitLab CE)** → follow the CE Label Sprint Flow below.

**Otherwise**, map to provider mechanism via `providers.json`:
- GitHub → `create_milestone` (name, due date)
- GitLab EE → native iteration API
- Jira → `create_sprint` (name, startDate, endDate, originBoardId from config)
- Plane → `create_cycle` (name, start_date, end_date)

Store active sprint reference in `.project/config.yaml`:
```yaml
active_sprint:
  id: "12"
  name: "Sprint 4"
```

#### CE Label Sprint Flow (GitLab CE — `sprint_proxy: label` only)

**Step 1 — Derive label name from convention**

Read `sprint_convention` from config:

| Convention | Input needed | Label name derived |
|---|---|---|
| `sequential` | None — auto-increment | Call `mcp__gitlab__list_labels` with `search=sprint::`, find max N, use `sprint::{N+1}` |
| `year-week` | Start date (or today) | `sprint::{YYYY}-W{WW}` (ISO week number, zero-padded) |
| `year-month-week` | Start date (or today) | `sprint::{YYYY}-{MM}-W{w}` (week of month, 1-indexed) |
| `quarterly` | Quarter, year, sprint-in-quarter | `sprint::Q{q}-{YYYY}-S{n}` |

**Step 2 — Collect sprint metadata**

Prompt for:
- Start date (default: next Monday from today's date)
- End date (default: start + `sprint_length_days` from config, default 14)
- Goal (optional free text)
- Capacity in story points (optional)

**Step 3 — Create sprint metadata issue**

Call `mcp__gitlab__create_issue`:
- `project`: value of `pm_meta_project` from config
- `title`: `[Sprint] {label_value} | {start} – {end}`
- `description`:
```
<!-- pm:start -->
start: {start}
end: {end}
goal: {goal or ""}
capacity: {capacity or ""}
status: active
convention: {sprint_convention}
<!-- pm:end -->

## Goal
{goal or "(none)"}
```
Store the returned issue URL as `meta_issue_url`.

**Step 4 — Create group-level sprint label**

Call `mcp__gitlab__create_label` scoped to the group (`gitlab_group` from config):
- `name`: `sprint::{label_value}`
- `color`: cycle through `#3CB371`, `#4169E1`, `#9370DB`, `#FF8C00` based on sprint index mod 4
- `description`: `{meta_issue_url}`

**Step 5 — Write active sprint to config**

Store in `.project/config.yaml`:
```yaml
active_sprint:
  label_name: "sprint::2025-W23"
  meta_issue_url: "https://gitlab.example.com/group/pm-meta/-/issues/42"
  start: "2025-06-02"
  end: "2025-06-13"
```
Output: `✓ Sprint {label_value} created ({start} – {end})`

### Sub-mode: sprint plan

Guard: if no `active_sprint` in config → output `No active sprint — run sprint create first` and stop.

**Step 1 — Fetch backlog candidates**

Fetch all tickets in `backlog` or `todo` state that are NOT already assigned to the active sprint. Collect: id, title, priority, estimate, labels, description.

**Step 2 — Rank by priority**

Sort: critical → high → medium → low → unset.

**Step 3 — Check Definition of Ready per ticket**

A ticket passes DoR if it has a non-empty description AND at least one label. Flag failing tickets with `⚠ not ready`.

**Step 4 — Present candidate list**

```
Sprint Plan — {sprint_id}
Backlog candidates (ranked by priority):

  #  ID        Priority  Est  DoR       Title
  1  TICK-55   high      5    ✓         Add OAuth scopes
  2  TICK-60   high      3    ⚠ no desc Rate limit middleware
  3  TICK-48   medium    2    ✓         Fix session timeout
  4  TICK-62   medium    —    ⚠ no lbl  Update README
  5  TICK-71   low       1    ✓         Refactor config loader

Enter ticket numbers to add (comma-separated), or "done" to finish:
```

**Step 5 — Add selected tickets to sprint**

For each selected number: call the sprint-add flow (same as `sprint add`). Report each addition.

Output summary:
```
Added to {sprint_id}: TICK-55, TICK-48, TICK-71
```

---

### Sub-mode: sprint review

Guard: if no `active_sprint` in config → output `No active sprint` and stop.

**Step 1 — Fetch done tickets**

Fetch all tickets in `done` state assigned to the active sprint. Collect: id, title, labels, estimate, assignees.

**Step 2 — Group by label**

Group tickets by their first non-state label (if any). Tickets with no labels go into an "Unlabelled" group.

**Step 3 — Compute commitment vs. delivered**

Commitment = total in-sprint ticket count at sprint start. Derive from total tickets currently in the sprint (done + not-done). Delivered = count of done tickets.

**Step 4 — Output shipped summary**

```
Sprint Review — {sprint_id}
──────────────────────────────────────
Delivered: {done_count}/{total_count} tickets ({pct}%)
Points shipped: {sum of done estimates or "N/A"}

backend (3 tickets):
  TICK-30  Auth token refresh
  TICK-31  Session expiry fix
  TICK-32  Rate limit endpoint

frontend (2 tickets):
  TICK-35  Login form validation
  TICK-36  Error toast component

Unlabelled (1 ticket):
  TICK-38  Update CHANGELOG
──────────────────────────────────────
{done_count} shipped, {not_done_count} carried over.
```

---

### Sub-mode: sprint retro

Guard: if no `active_sprint` in config → output `No active sprint` and stop.

**Step 1 — Prompt for three sections**

```
Sprint Retro — {sprint_id}

What went well? (free text, Enter to finish):
> _

What should we improve? (free text, Enter to finish):
> _

Action items? (one per line, empty line to finish):
> _
```

**Step 2 — Ensure retro label exists**

Call `list_labels`. If no `retro` label found, create it with colour `#fbca04`.

**Step 3 — Create retro issue**

Create a tracker issue (no sprint assignment):
- **Title**: `Retro: {sprint_id}`
- **Labels**: `retro`
- **Body**:
```
## Went Well
{went_well or "(none)"}

## To Improve
{to_improve or "(none)"}

## Action Items
{action_items formatted as a checklist, or "(none)"}
```

Output: `✓ Retro issue created: {issue_url}`

---

### Sub-mode: sprint add / remove

Read `sprint_proxy` from config.

**GitLab CE (`sprint_proxy == "label"`)**: apply or remove the sprint scoped label on the issue using **Shared: Provider Write Path Resolution**:
- **add**: resolve the write path, then apply `add_labels: active_sprint.label_name` (fetch current labels first to avoid overwriting others)
- **remove**: resolve the write path, then apply `remove_labels: active_sprint.label_name`

**All other providers**: resolve sprint ID from `active_sprint.id` in config. Call `add_issue_to_sprint` / remove equivalent.

### Sub-mode: sprint close

**Step 1 — Tally completed points**

Fetch all done-state tickets in the active sprint. Sum their `estimate` fields (skip tickets with no estimate). Store as `points_completed`.

Read `capacity` from the pm-meta issue description (GitLab CE) or from `active_sprint` metadata. Store as `points_committed` (null if absent).

**Step 2 — Idempotency check**

Read `velocity_log` from `.project/config.yaml`. Derive `sprint_id`:
- GitLab CE: `active_sprint.label_name`
- All others: `active_sprint.id` (coerced to string) or `active_sprint.name`

If an entry with matching `sprint` already exists in `velocity_log`:
```
⚠ velocity_log already has an entry for {sprint_id} — skipping duplicate.
```
Skip Step 3 and continue to Step 4.

**Step 3 — Append to velocity_log**

Append to `velocity_log` in `.project/config.yaml`:
```yaml
- sprint: "{sprint_id}"
  points_committed: {points_committed or null}
  points_completed: {points_completed}
```

**Step 4 — Close sprint in provider**

| Provider | Action |
|---|---|
| GitHub | Call `mcp__github__update_milestone` with `state: closed` using `active_sprint.id` |
| GitLab EE | Call native iteration close tool |
| GitLab CE | No provider API — output `ℹ GitLab CE label-based sprints have no close API — config cleared` |
| Jira | Call complete-sprint MCP tool with `active_sprint.id` |
| Plane | Call `mcp__plane__close_cycle` with `active_sprint.id` |

**Step 5 — Clear active sprint from config**

Remove `active_sprint` key from `.project/config.yaml`.

Output:
```
✓ Sprint {sprint_id} closed.
  Committed: {points_committed or "N/A"} pts  |  Completed: {points_completed} pts
  velocity_log updated. Next: run sprint create to start a new sprint.
```

### Sub-mode: labels

- **create**: call `create_label` tool with name and colour
- **list**: call `list_labels`
- **assign**: call `add_label` / `update_ticket` with label field

### Sub-mode: milestone

**Milestone vs Sprint:** Sprint = time-boxed iteration ("Sprint 4"). Milestone = release/delivery target ("v1.0", "Beta"). A ticket can have both.

Detect operation: **create | assign | list | close**

**create** — collect: name (e.g. "v1.0"), description, due date.

**GitLab CE guard**: if `sprint_proxy == "label"` and the name matches any sprint convention pattern — `Sprint \d+`, `\d{4}-W\d{2}`, `\d{4}-\d{2}-W\d`, `Q\d-\d{4}-S\d+` — reject and output:
```
For GitLab CE, sprints use scoped labels (sprint::*). Use sprint create instead.
Milestones are for release targets only (e.g. v1.0, Beta, Q3 Launch).
```
Do not call any milestone API on rejection.

Read `capabilities.milestones` from config:
- `true` → call `milestone_contracts.create` from `providers.json`
- `false` (Plane) → activate label fallback: create label `milestone:{slug}`, notify user

**assign** — attach a ticket to a milestone.
- **GitHub, Jira, Plane**: call `milestone_contracts.assign` (update issue with milestone field / fixVersions)
- **GitLab**: use **Shared: Provider Write Path Resolution** to set the `milestone_id` field on the issue
- Fallback (Plane, unsupported milestone): add label `milestone:{slug}` to the ticket

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

**Naming convention for milestones**: `vX.Y.Z` or plain release name (`Beta`, `Q3 Launch`). For GitHub, milestones also serve as sprint proxies (`Sprint N`). For GitLab CE, sprints use scoped labels — not milestones.

### Sub-mode: status

**Ticket fetch**: use `active_sprint.label_name` as the label filter for GitLab CE repos (`sprint_proxy: label`); use milestone/sprint ID for all other providers.

#### Sprint Health & WIP (shown before state breakdown)

After fetching tickets, compute and display two lines above the state breakdown:

**Sprint health** — requires estimates on at least one ticket and `active_sprint.start` + `active_sprint.end` in config:

```
expected_done = (days_elapsed / sprint_days_total) × total_committed_points
actual_done   = sum of estimate fields on done-state tickets
```

| actual_done / expected_done | Category |
|---|---|
| ≥ 90% | ON-TRACK |
| 70–89% | AT-RISK |
| < 70% | OFF-TRACK |

```
Sprint health: ▓▓▓▓░░░░ 12/21 pts (57%) · AT-RISK — 5 days left
```

- `▓` blocks = floor((actual_done / total_committed_points) × 8), `░` = remaining up to 8
- `total_committed_points` = sum of all in-sprint ticket estimates (regardless of state)
- `days_left` = `active_sprint.end` − today (in calendar days)
- If no ticket has an estimate: `Sprint health: N/A (no estimates)`
- If `active_sprint.start` or `active_sprint.end` absent: omit health line silently

**WIP display** — only when `wip_limit` is set in config:

```
WIP: 2/3
```

If count ≥ `wip_limit`: `WIP: 3/3 ⚠ limit reached`

**Single-repo** (no `context_repos` configured): fetch all active sprint tickets using the anchor's provider. Group by canonical state. Display:

```
Sprint 4 — 12 tickets
Sprint health: ▓▓▓▓░░░░ 12/21 pts (57%) · AT-RISK — 5 days left
WIP: 2/3
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

## MODE: standup

Guard: if no `active_sprint` in config → output `No active sprint — run sprint create first` and stop.

### Step 1 — Fetch active sprint tickets

Fetch all tickets in the active sprint (same filter as `status` mode). Collect: id, title, canonical_state, assignees, blocked_by.

Derive `current_user` from provider identity (GitHub: `mcp__github__get_authenticated_user`; GitLab: `mcp__gitlab__get_user`; Jira/Plane: read from config or ask once).

### Step 2 — What I did

Filter to tickets assigned to `current_user` with canonical state `in-review` or `done`.

### Step 3 — What I'll work on

Run the same scoring algorithm as **MODE: next** (Steps 3–5) over the full sprint ticket set. Output the top recommendation with one-line reasoning.

### Step 4 — Blockers

Filter all in-sprint tickets (any assignee) with canonical state `blocked`. Extract the blocking reason from the ticket body (look for `Blocked by:` or `blocked:` pattern in the description).

### Step 5 — Output

```
## What I did
  TICK-35  Login form validation  (in-review)
  TICK-32  Auth token refresh     (done)

## What I'll work on
  TICK-42 — Rate limit middleware
  High priority, no open dependencies, unblocks 2 tickets.
  Ready to start? /project-management start TICK-42

## Blockers
  TICK-41  Session timeout fix  (blocked: waiting on infra access)

---
Note: "What I did" reflects current ticket states, not a timestamped activity log.
```

If a section has no items, show `(none)` under the heading. Always output all three sections in this order.

---

## MODE: next

### Step 1 — Load config and resolve repo set

Read `.project/config.yaml`. If no `active_sprint` is set on the anchor repo, tell the user to create or activate a sprint first.

**Multi-repo expansion**: if `context_repos` is non-empty, read `.project/config.yaml` from each listed path. For each sibling:
- If the file is missing → emit `⚠ {path} has no .project/config.yaml — skipped` and continue.
- If `active_sprint` is absent → emit `⚠ {path} has no active sprint — skipped` and continue.
- Otherwise → record `{ path, mcp_prefix, active_sprint, capabilities }` for use in Step 2.

### Step 2 — Fetch open in-sprint tickets

For each repo in the set (anchor + valid siblings), call `list_tickets` filtered to that repo's `active_sprint` + state != done, using that repo's own `mcp_prefix`.

**GitLab CE filter**: if `sprint_proxy == "label"`, filter by `labels: {active_sprint.label_name}` (e.g. `labels: sprint::2025-W23`) instead of `milestone: {active_sprint.id}`.
**All other providers**: filter by milestone ID or sprint ID as before.

Collect: id, title, description, canonical_state, priority, estimate, blocked_by relationships. Tag each ticket with `source_repo` (relative path, `"."` for anchor).

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

Accept a ticket reference and load it for exploration with full project doc context. By default, transitions the ticket to `in-progress` and creates its branch/worktree automatically, reporting what it did — it pauses for confirmation only when the **Shared: Start-Mode Pre-Flight Gate** fires. Accepts `--no-branch` to skip branch/worktree creation entirely, and `--confirm` to force the gate every time (restoring the always-ask behaviour for that one invocation).

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

### Step 2 — Spawn fetch-and-prepare subagent

Spawn a fresh subagent — not a context-inheriting fork, since this task needs only the ticket reference and resolved config, not the prior conversation — to fetch and enrich the ticket, evaluate the pre-flight gate, and (when the gate does not fire) perform the transition and branch/worktree creation itself. This keeps the fetch/enrichment tool-call noise out of the main thread; only the subagent's bounded result below returns here.

**Inputs given to the subagent**: `ticket_id`, `is_url`, `provider.mcp_prefix`, `state_mapping`, `context_repos`, `docs_sources`, `wip_limit`, the `branching` config block, and the `--no-branch` / `--confirm` flags as passed by the user. No prior conversation history is passed.

**What the subagent does, in order:**

##### Step 2a — Fetch ticket

Read `.project/config.yaml` for `provider.mcp_prefix`. No provider detection needed — the project is already configured.

Emit `Fetching <id>…` before the call.

Call the get-ticket tool from `tool_contracts.get_ticket` in `references/providers.json` using `{mcp_prefix}`. Collect: id, title, description, state (raw), labels, assignees, sprint membership, priority, issue_type, estimate, and all additional fields returned by the MCP response.

Emit `✓ Loaded: "<title>"` on success.

#### Step 2b — Rank and trim comments

If the ticket has more than 10 comments, score each and keep only the most relevant:

```python
import re

comments = ticket.get("comments") or []
if len(comments) > 10:
    author    = ticket.get("author", "")
    assignees = set(ticket.get("assignees") or [])
    code_re   = re.compile(
        r'https?://\S+/-/(?:merge_requests|pull)/\d+'
        r'|`[^`]{4,}`'
        r'|(?:branch|commit|pr|mr)\b',
        re.IGNORECASE)
    bot_re    = re.compile(r'\[bot\]|^(github-actions|dependabot|renovate)$', re.IGNORECASE)

    def score(c):
        s = 0
        if c.get("author") == author:           s += 3
        if c.get("author") in assignees:        s += 3
        if bot_re.search(c.get("author", "")):  s -= 5
        if code_re.search(c.get("body", "")):   s += 2
        if len(c.get("body", "")) > 100:        s += 1
        return s

    ranked  = sorted(comments, key=score, reverse=True)
    recents = comments[-3:]
    top     = [c for c in ranked if c not in recents][:7]
    merged  = top + recents
    seen = set(); priority_comments = []
    for c in merged:
        cid = c.get("id") or c.get("body", "")[:40]
        if cid not in seen: seen.add(cid); priority_comments.append(c)
    comments_total = len(comments)
    comments_shown = len(priority_comments)
else:
    priority_comments = comments
    comments_total = comments_shown = len(comments)
```

Carry `priority_comments`, `comments_total`, and `comments_shown` forward for the context block (Step 4).

#### Step 2c — Collect custom provider fields

After the `get_ticket` call, collect all fields returned by the MCP response that are NOT in the standard set (`id`, `title`, `description`, `state`, `labels`, `assignees`, `sprint`, `priority`, `issue_type`, `url`, `author`, `comments`). Filter to non-null, non-empty values only. Store as `custom_fields` (key-value dict).

If no custom fields are present, set `custom_fields = {}`.

Carry `custom_fields` forward for the context block (Step 4).

#### Step 2d — Scan for code cross-references

Scan `ticket.description` and all comment bodies for code references:

```python
import re

full_text = (ticket.get("description") or "") + "\n" + \
            "\n".join(c.get("body", "") for c in (ticket.get("comments") or []))

refs = []
refs += re.findall(r'https?://\S+/-/merge_requests/\d+', full_text)
refs += re.findall(r'https?://github\.com/\S+/pull/\d+', full_text)
refs += re.findall(r'(?:branch[:\s]+|`)([\w./-]{4,80})(?:`|)', full_text, re.IGNORECASE)
refs += re.findall(r'(?<!\w)([0-9a-f]{7,40})(?!\w)', full_text)

seen = set(); ticket_code_refs = []
for r in refs:
    if r not in seen: seen.add(r); ticket_code_refs.append(r)
ticket_code_refs = ticket_code_refs[:10]
```

Carry `ticket_code_refs` forward for the context block (Step 4).

#### Step 2e — Fetch linked issues (thin description only)

Check if the description is insufficient: fewer than 150 characters, empty, or contains only cross-reference links with no prose.

```python
import re
desc = (ticket.get("description") or "").strip()
cross_ref_only = bool(re.search(r'^[\s\S]*$', desc)) and not re.search(r'[a-z]{5,}', desc)
thin = len(desc) < 150 or not desc or cross_ref_only
```

If `thin` is true: look up `tool_contracts.list_issue_relations` (or equivalent) for the active provider in `references/providers.json`. If the tool exists in the current MCP context, call it with the ticket ID. Normalize results to a list of `{id, state, title}` objects and store as `linked_issues`.

If the tool does not exist for the provider, or the call fails for any reason: set `linked_issues = []` and continue — no error shown.

If `thin` is false: set `linked_issues = []` and skip the MCP call.

Carry `linked_issues` forward for the context block (Step 4).

#### Step 2f — Project doc context (Context Fallback Chain)

Follow the **Context Fallback Chain** defined in the Shared section above — identical logic to `ticket new`. Filter to sections relevant to the ticket's title and description topic. Build a `context_refs` list, and separately count the number of **distinct (file, section) matches** found — carry this forward as `docs_breadth_match_count` for the gate (Step 2g). A match is one matched section in one doc file; three sections matched within a single file counts the same as one section each in three files.

If all chain steps miss, emit:
```
⚠ No relevant context found — Context section may be incomplete.
```
and set `docs_breadth_match_count = 0`.

#### Step 2g — Evaluate the pre-flight gate

Run **Shared: Start-Mode Pre-Flight Gate** using this ticket's `estimate`, `title`, `description`, the WIP check inputs (`wip_limit` from config, in-progress count from a `list_tickets` call), `docs_breadth_match_count` from Step 2f for the docs-breadth component, and `start.worktree` from config plus `git status --porcelain` for the dirty-tree condition. If `--confirm` was passed, treat the gate as fired regardless of the four conditions.

Store the result as `gate_fired` (boolean) and, when true, `gate_reason` (the condition name(s) that fired, joined with "and").

#### Step 2h — Transition and branch/worktree creation

**If `gate_fired` is false**: perform the transition and branch/worktree creation now, using the logic below, then compose `action_summary` (e.g. `✓ TICK-42 → in-progress, worktree created at ../repo-TICK-42-oauth-login (branch feature/TICK-42-oauth-login from main)`) and return it along with the context fields collected in Steps 2a–2f.

**If `gate_fired` is true**: perform no mutation. Determine (without executing) what the transition and branch/worktree creation *would* do — the target state, the branch name (Step 2h-ii below), and the base branch — and return this as `proposed_action`, along with `gate_fired: true`, `gate_reason`, and the context fields from Steps 2a–2f. Control returns to the main thread (Step 3) to ask the user before anything below actually runs.

**(i) State transition.** Reverse-map the raw provider state via `state_mapping`:

| Canonical state | Action |
|---|---|
| `todo` or `backlog` | call `update_ticket` via the provider-specific path below |
| `in-progress` | no-op — already started |
| `in-review` or `done` | no transition; note "TICK-<id> is already `<state>`" in `action_summary` / `proposed_action` |
| `blocked` | no transition; note "TICK-<id> is blocked" in `action_summary` / `proposed_action` |

Provider-specific transition call:
- **GitHub, Jira, Plane**: use **Shared: Provider Write Path Resolution** to call `update_ticket` with the translated state from `state_mapping`.
- **GitLab**: use **Shared: Provider Write Path Resolution** + label-delta helper to add the new state label and remove the previous state label.

**(ii) Branch/worktree creation.** Skip this entirely if `--no-branch` was passed — set `BRANCH_SKIPPED=true` and omit it from `action_summary` / `proposed_action`.

*Resume guard*: if a non-archived change with `linked_issue.id` equal to this ticket's id already exists (see Step 3b), or `git worktree list` / `git branch --list "*{ticket.id}-*"` shows a branch or worktree for this ticket, this is a resume — create nothing, set `BRANCH_SKIPPED=true`, report the existing branch/worktree in `action_summary` (`↻ resuming TICK-42 on existing branch …`), and skip the numeric-suffix retry below.

*Detect branching strategy*: read `branching` from `.project/config.yaml` first —

| `branching.strategy` | Base branch for feature work |
|---|---|
| `single` | `branching.main` (default: `main`) |
| `multi` | `branching.develop` (default: `develop`) |

If `branching` is absent, fall back to git topology auto-detection via `git branch -a --format=%(refname:short)`:

| Branch topology | Strategy | Base branch |
|---|---|---|
| `develop` + `release` + `hotfix` present | gitflow | `develop` |
| `develop` or `dev` + `release` | gitflow-lite | `develop` |
| `develop`, `dev`, or `development` only | three-branch | detected dev branch |
| `release/*` branches, no develop | trunk-release | `main`/`master` |
| No develop branch | single-branch | `main`/`master` |

*Derive branch name slug*: apply this prompt to yourself:

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

Determine branch prefix from `issue_type`: `bug` → `bug/` (or `hotfix/` for gitflow strategies); `feature`, `task`, `story`, or unknown → `feature/`; `hotfix` → `hotfix/`.

Compose `BRANCH_NAME = {prefix}{ticket.id}-{slug}` (e.g. `feature/PROJ-42-oauth-login`) and `BASE_BRANCH` from the detection above.

*Create the branch* (only when `gate_fired` is false, i.e. this is actually executing, not just proposing). Read `start.worktree` from `.project/config.yaml`; absent means `true`.

- **`start.worktree` is `true` or absent** — create a worktree: let `repo_name` be the current directory's basename. Run:
  ```
  git worktree add ../{repo_name}-{ticket.id}-{slug} -b {BRANCH_NAME} {BASE_BRANCH}
  ```
  Set `WORKTREE_PATH` to the created path.
- **`start.worktree` is `false`** — create the branch in place in the current checkout:
  ```
  git checkout -b {BRANCH_NAME} {BASE_BRANCH}
  ```
  Leave `WORKTREE_PATH` unset. A dirty working tree has already been surfaced by the gate, so no extra check runs here.

`--no-branch` takes precedence over `start.worktree`. On worktree failure (path or branch name collision), append a numeric suffix (`-2`, `-3`, ...) to the directory name and retry once; if it still fails — or if the in-place `git checkout -b` fails — report the git error, leave the ticket's state transition result unaffected, and set `BRANCH_SKIPPED=true`.

### Step 3 — Resolve the gate

- **`gate_fired: false`** — print the subagent's `action_summary` and continue to Step 4. Nothing is asked.
- **`gate_fired: true`** — ask the combined question from **Shared: Start-Mode Pre-Flight Gate**, using `gate_reason` and `proposed_action`:
  ```
  TICK-42 looks {gate_reason} — transition to in-progress and create its branch anyway? [y/n]
  ```
  - **y** — perform the transition and branch/worktree creation now, directly in the main thread, using the same logic as Step 2h(i)/(ii) above. Continue to Step 4.
  - **n** — output `Transition cancelled — continuing in exploration mode (ticket stays in current state).`, set `BRANCH_SKIPPED=true`, and continue to Step 4 with no transition performed.

### Step 3b — Create or resume the change shell

The handoff to explore is a file on disk. Before Step 5, make sure an OpenSpec change exists for this ticket. Run these commands inside `WORKTREE_PATH` when a worktree was created, otherwise in the current checkout.

1. Look for a non-archived change whose `openspec/changes/*/.openspec.yaml` has `linked_issue.id` equal to this ticket's id.
2. **Found** — reuse it; never create a second change for the same ticket. If its `.openspec.yaml` has `status: awaiting-answers`, this is a resume: set `RESUMING=true` and skip to Step 5c.
3. **Not found** — run `openspec new change "{ticket.id}-{slug}"` (same slug as the branch name), then write into its `.openspec.yaml`:
   ```yaml
   linked_issue:
     provider: <provider from config>
     project_ref: <project path or key from config>
     id: "<ticket id>"
     url: <ticket URL>
   base_ref: <output of: git rev-parse HEAD>
   ```

This runs whether or not the gate was declined or `--no-branch` was passed — exploration is always anchored to the ticket. If `openspec` is not installed, emit `⚠ openspec CLI not found — cannot create the change shell` and continue to Step 5b.

On a resume, Step 2h's transition and branch/worktree creation must not run a second time: the subagent reports `already in-progress` and the existing worktree, and Step 3 prints that without mutating anything.

### Step 4 — Assemble context block

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

--- Comments [if comments_total > comments_shown: "(comments_shown of comments_total shown — ranked by relevance)"] ---
[priority_comments, each as "[author]: body"]

--- Linked Issues ---
[linked_issues if non-empty, each as "  ID [state] title" — omit this section entirely if linked_issues is empty]

--- Provider Fields ---
[custom_fields key-value pairs, each as "  key: value" — omit this section entirely if custom_fields is empty]

--- Code References in Issue ---
[ticket_code_refs, one per line — or "(none found)" if list is empty]

--- Project Context ---
[context_refs from Step 2f, one block per matched source, e.g.:]
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
Branch:    [BRANCH_NAME]  (from [BASE_BRANCH])
Worktree:  [WORKTREE_PATH]
```

If the branch was created in place (`start.worktree: false`), `WORKTREE_PATH` is unset: append only the `Branch:` line and omit the `Worktree:` line.

If `BRANCH_SKIPPED` is true (because `--no-branch` was passed, or the gate was declined, or branch creation failed), omit both lines entirely.

### Step 5 — Invoke opsx:explore

#### Step 5a — Detect opsx:explore

Scan the `system-reminder` skills list for `opsx:explore`. If present, invoke it with the context block assembled in Step 4 and this prompt (the change from Step 3b is `<change-name>`):

```
I want to explore the implementation for this ticket before starting work:

<context block>

Ticket context for linked issue tracking:
  provider: <provider name from config>
  project_ref: <project path or key from config>
  id: "<ticket id>"
  url: <ticket URL>

The OpenSpec change `<change-name>` already exists for this ticket. Explore the
requirements, ambiguities, edge cases, and which parts of the codebase are likely
involved. Do NOT edit application code in this session.

You MUST finish by writing these sections into openspec/changes/<change-name>/design.md:
  ## Verdict        — exactly `ready` or `needs-input`
  ## Assumptions    — every uncertainty that does not need an answer to proceed
  ## Open Questions — only when the verdict is `needs-input`

A question is blocking (→ `needs-input`) ONLY if its answer would change scope,
design, or a spec scenario. Everything else is an assumption, not a question.
```

Also scan `system-reminder` for `archive-ticket-sync`. If present, note to the user:
> "Ticket context stored. After implementation, run `/archive-ticket-sync` to post a summary to #<id> when you archive."

Continue to Step 5c.

#### Step 5b — Fallback if opsx:explore not loaded

Present the context block directly to the user, then offer:

```
No spec skill loaded — context above is ready.

What would you like to do?
  1. Find files in this repo likely affected by this ticket
  2. List open questions, ambiguities, and edge cases
  3. Summarise what needs to be implemented
  4. Check for related branches or PRs
  5. Create a change for this ticket (artifacts first, then implement)

Reply with a number, or ask anything about the ticket.
```

Wait for the user's reply and act on it directly. Option 5 creates the change artifacts (proposal, specs, design, tasks) before any application code is touched; never offer to implement without a change. Option 2 output is recorded in the change's `design.md` as `## Open Questions` / `## Assumptions`, and Step 5c then applies.

#### Step 5c — Resolve the verdict

Read `openspec/changes/<change-name>/design.md` (in `WORKTREE_PATH` when set).

- **On resume** (`RESUMING=true`): fold new answers into `design.md` first — from the user's reply in this session, plus any ticket comments newer than the `awaiting-answers` comment — moving each answered item out of `## Open Questions` into `## Assumptions` (or into the design/spec text it affects). Then re-evaluate: still-blocking questions remain → `needs-input`; none → `ready`.
- **No `## Verdict` section**: re-prompt once — `Write the ## Verdict section (ready | needs-input) to design.md before continuing.` If it is still missing, treat as `needs-input` with the open question `Explore ended without a verdict`.
- **`ready`** — if `.openspec.yaml` has `status: awaiting-answers`, remove it. Tell the user:
  > "Explore complete — verdict: ready. Next: `/opsx:ff` (or `/opsx:continue`) to create the remaining artifacts."
- **`needs-input`** — stop this ticket's pipeline, in this order:
  1. Post **one** comment on the ticket via **Shared: Provider Write Path Resolution**, containing only the blocking questions from `## Open Questions`.
  2. Set `status: awaiting-answers` in the change's `.openspec.yaml`.
  3. Emit `⏸ TICK-42 needs input — N question(s) posted to the ticket and recorded in openspec/changes/<change-name>/design.md. Re-run /project-management start TICK-42 once answered.`
  4. Do not begin implementation or create further artifacts.

#### Edit guard (optional hook)

`start` never writes settings. To make "no edits without a change" harness-enforced, add this to `.claude/settings.json` (or `settings.local.json`):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|NotebookEdit",
        "hooks": [
          { "type": "command", "command": "bash skills/project-management/scripts/require-change.sh" }
        ]
      }
    ]
  }
}
```

The script blocks an edit when the current branch carries a ticket id and no non-archived change has a matching `linked_issue.id`. It always allows paths under `openspec/changes/` and branches with no ticket id.

---

## Init flag: --probe

When `init --probe` is invoked, ignore any cached `.project/config.yaml` and re-run Steps 2–7 of init mode. Overwrite the config file with fresh results.

## Lazy re-probe on 403

If any MCP call returns an unexpected 403 mid-session:
1. Re-run the API probe (Step 4 of init) for that specific feature only.
2. Update `config.yaml` with the new flag.
3. Retry the operation using the fallback strategy.
4. Notify: "⚠ {Feature} support not available — switched to {fallback} fallback."

---

## MODE: sync

Post a change summary or explore conclusion to the linked issue tracker ticket.

Two sub-modes: **archive** (post-archive summary) and **capture** (mid-session conclusion).

### Sub-mode routing

| Input | Sub-mode |
|-------|----------|
| "sync archive", "post to ticket", "update ticket", "archive sync", "sync issue" | **sync → archive** |
| "capture this", "capture", "post this decision", "save this to ticket" | **sync → capture** |

If input is just "sync" with no qualifier, check context: if `opsx:archive` was just run → archive sub-mode; if inside an explore session → capture sub-mode; otherwise ask.

---

### sync → archive

Run after `opsx:archive` completes to post a change summary to the linked ticket.

**Input**: optional change name. If omitted, look for the most recently modified directory under `openspec/changes/archive/` (by `created` date in `.openspec.yaml`). If still ambiguous, ask.

#### Step 1 — Read linked_issue

Read `openspec/changes/archive/<YYYY-MM-DD-name>/.openspec.yaml`.

If `linked_issue` is absent: output `No linked issue found — skipping ticket sync.` and stop.

Extract:
```yaml
linked_issue:
  provider: gitlab|github|jira|plane
  project_ref: org/repo
  id: "42"
  url: https://...
base_ref: <sha>   # optional
```

#### Step 2 — Gather signals (run in parallel)

**Spec signal**

Check `openspec/changes/archive/<YYYY-MM-DD-name>/specs/`. If none: `spec_signal = []`.

For each delta spec found:
- Read `openspec/changes/archive/<YYYY-MM-DD-name>/specs/<capability>/spec.md`
- Read `openspec/specs/<capability>/spec.md` (may not exist for new capabilities)
- Extract as bullets: new requirements, modified requirements, new/removed capabilities

**Git signal**

Determine anchor:
1. `base_ref` from `.openspec.yaml` → `git diff <base_ref>..HEAD --stat`
2. Fallback → `git diff $(git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null)..HEAD --stat`

Extract: top 10 changed files by lines (skip binaries), total `N files, X insertions, Y deletions`.

**Thread signal**

Scan current conversation for:
- Decisions: "we decided", "going with", "ruled out", "won't", "confirmed"
- Scope changes: "out of scope", "added to scope", "scope changed"
- Ticket refs: `#N`, `PROJ-N`, full issue URLs — collect as `related_refs` (exclude primary `id`)

#### Step 3 — Skip heuristic

Skip if ALL are true:
- Spec signal empty or formatting-only changes
- Git signal touches only `.md` files or is empty
- Thread signal has no decisions or scope changes

Output: `No substantive changes detected — skipping ticket comment.` and stop.

#### Step 4 — Synthesise draft

```markdown
## Change `<name>` archived

**Specs:** <spec diff bullets, or "no delta specs">
**Code:** <top changed files with +/- counts, or "no code changes detected">
**Decisions:** <thread conclusions as bullets, or "none recorded this session">
```

#### Step 5 — Confirm and post

Show draft. Use **AskUserQuestion**:
> "Post this summary to <provider> issue #<id>?"

Options: `Post it` | `Edit first` | `Skip`

If `Edit first`: show as plain text, accept edits, re-confirm.

**Provider routing:**

| Provider | Write tool |
|----------|-----------|
| GitHub | `mcp__github__add_issue_comment(owner, repo, issue_number, body)` split from `project_ref` |
| GitLab | `mcp__gitlab__create_note(project_id, issue_iid, body)` |
| Jira | Jira MCP comment tool from `tool_contracts` in `references/providers.json` |
| Plane | Plane MCP comment tool from `tool_contracts` in `references/providers.json` |

On write failure: print comment text to terminal with `⚠ Could not write to tracker — copy and post manually.`

#### Step 6 — Acceptance criteria offer

If spec signal contains new requirements, ask separately:
> "Append these new acceptance criteria to the ticket body?"

Options: `Yes, append` | `Skip`

If yes: fetch current ticket body via provider read tool, append (do NOT overwrite):
```markdown
## Acceptance Criteria (from <change-name>)

<new requirements from spec diff>
```
Write back via provider update tool. On failure: print section to terminal.

#### Step 7 — Related tickets offer

If `related_refs` non-empty (different from primary `id`):
- Show: `Signals also mention: <list>`
- **AskUserQuestion** (multi-select): `Comment on any of these too?`
- For each selected: post `Related change \`<name>\` was archived. See <primary issue URL> for details.`

---

### sync → capture

Post a session delta to the linked ticket — capturing what changed from the original plan, why, and what was decided. Only captures when something meaningful changed.

**Input**: triggered by "capture this", "capture", "sync capture", or "post this decision".

#### Step 0 — Resolve active change and linked_issue

Scan `openspec/changes/` (excluding `archive/`) for `.openspec.yaml` files. Pick the most recently created (by `created` field).

- If no active change: output `No active change found — nothing to capture.` and stop.
- If active change has no `linked_issue`: offer to write to `openspec/changes/<name>/notes.md` instead (append, create if absent). Proceed to Step 2 with notes.md as target.
- If active change has `linked_issue`: proceed to Step 1.

#### Step 1 — Gate: did anything meaningful change?

**Detect project type**: SDD project if `openspec/` or `spec-kit/` exists at repo root. Otherwise code-first.

**SDD gate — spec diff**: Check for delta specs at `openspec/changes/<name>/specs/`.
- Directory exists and contains at least one `.md` file → proceed to Step 2.
- Directory absent or empty → go to Override Prompt.

**Code-first gate — LLM divergence judge**: Fetch linked ticket body via provider read tool. If fetch fails, skip judge and proceed to Step 2 with a note that original context was unavailable.

Judge over the ticket body (original intent) and the full current session conversation:
> "Does this session contain decisions, scope changes, or approach shifts that differ meaningfully from the original ticket context?"

Output: Yes/No + one-sentence reason.
- Divergence detected → proceed to Step 2.
- No divergence detected → go to Override Prompt.

**Override Prompt**: Use **AskUserQuestion**:
> "Nothing significant looks different from the original ticket: `<judge reason>`. Capture anyway?"

Options: `Yes, capture it` | `Skip`
- `Yes`: proceed to Step 2 with gate-overridden flag.
- `Skip`: stop silently.

#### Step 2 — Draft delta note

Synthesise across the **full current session** (not just the last exchange).

```markdown
**Session update — <change-name>**

**What changed from the original plan:**
- <bullet: divergence 1>
- <bullet: divergence 2>

**Why:**
<brief reasoning drawn from session>

**Final approach:**
<what was decided>
```

If gate was overridden and nothing genuinely diverged, use minimal format:
```markdown
**Session note — <change-name>**

<brief summary of session conclusion>
```

#### Step 3 — Post

Show preview. Use **AskUserQuestion**:
> "Post this to <provider> #<id>?"

Options: `Post it` | `Edit first` | `Skip`

On `Edit first`: show draft as editable text, re-confirm.

Use same provider routing table as sync → archive.

On success: `✓ Posted to #<id>.`
On failure: print draft with `⚠ Could not post — copy above to post manually.`

---

### Guardrails

- Never auto-post without user confirmation — always show draft first
- Never overwrite ticket body — append only; require explicit `Yes, append` confirmation
- Related ticket comments require confirmation — never auto-post
- If all write paths fail, always print comment text to terminal
- `base_ref` diff is preferred over `merge-base` heuristic
- Skip heuristic: avoid noise comments on trivial/mechanical changes

---

## MODE: ship

Stage all changes, generate a conventional commit message, confirm, commit, push, and create a PR. Works standalone with no config; enriched when `.project/config.yaml` or a linked ticket is available.

### Step 0 — Pre-flight checks

1. Run `git status --porcelain`. If output is empty → emit `Nothing to commit — working tree clean` and stop.
2. Run `git branch --show-current`. If output is empty (detached HEAD) → emit `✗ Detached HEAD — cannot push. Checkout a branch first.` and stop.

Store: `current_branch`.

### Step 1 — Ticket ID resolution

1. Parse `current_branch` for pattern `[A-Z]+-\d+` (case-insensitive, first match wins).
   - e.g. `feat/TICK-42-auth-refresh` → `TICK-42`
   - e.g. `fix/AUTH-7/token-expiry` → `AUTH-7`
2. If no match, read `current_ticket` from `.project/config.yaml` (absent or file missing = skip).
3. Store result as `ticket_id` (null if neither source yields a value).

### Step 2 — Provider detection

1. If `.project/config.yaml` exists and has `provider.name` + `provider.mcp_prefix` → use them.
2. Otherwise run `git remote get-url origin`. Match hostname:
   - `github.com` → `{ name: "github", mcp_prefix: "mcp__github__" }`
   - `gitlab.*` → `{ name: "gitlab", mcp_prefix: "mcp__gitlab__" }`
   - No match → `{ name: null, mcp_prefix: null }`
3. Store: `provider_name`, `mcp_prefix`.

### Step 3 — Diff analysis and message generation

1. Run `git diff HEAD` (full diff) and `git diff --name-only HEAD` (changed paths).
2. Classify conventional commit type from changed file paths:
   - Any path contains `fix`, `bug`, `patch`, `hotfix` → `fix`
   - All paths in `docs/` or are `*.md` only → `docs`
   - All paths are config files only (`*.yaml`, `*.json`, `*.toml`, `*.lock`) → `chore`
   - Default → `feat`
3. Derive title (≤60 chars):
   - If `ticket_id` is known and `current_ticket.title` is in config → use the ticket title
   - Otherwise → summarise the most significant change from the diff (largest added block, first changed function/section name)
4. Compose commit message:
   - With ticket: `{ticket_id}: {type}: {title}`
   - Without ticket: `{type}: {title}`

### Step 3b — Evidence plan

Resolve what evidence this PR will carry. Read `project_type` (absent = `generic`) and `ship.evidence` from `.project/config.yaml`.

**Kinds.** If `ship.evidence.kinds` is present it is the complete list and replaces the default. Otherwise use the default for `project_type`:

| project_type | default kind |
|---|---|
| web, mobile, bi | `image` |
| qa | `link` |
| api | `markdown` |
| cli, library, ai, microservices, generic | `text` |

**Detection.** For every value not set in `ship.evidence`, detect it from the repo. Config always wins over detection. Never write detected values back to `.project/config.yaml`.

| kind | value | how it is detected |
|---|---|---|
| `image` | `start_command` | `package.json` script `dev`, else `start` |
| `image` | `base_url` | port found in that script or the framework config, as `http://localhost:{port}` (default `3000`) |
| `image` | `viewports` | default `[375, 1280]` |
| `markdown` | `spec_path` | first existing of `openapi.yaml`, `openapi.yml`, `openapi.json`, `docs/openapi.*`, `swagger.yaml`, `swagger.json` |
| `link` | test tool | Playwright if `playwright.config.*` exists or `@playwright/test` is a dependency; Allure if `allure-results/` exists, `--alluredir` appears in test config, or an `allure` package is a dependency |
| `link` | report source | in `.github/workflows/*` or `.gitlab-ci.yml`: `deploy-pages` or `allure generate` → published report; `upload-artifact` only → artifact (no browsable report). ReportPortal or Allure TestOps URLs in test config or CI files → hosted report service. `ship.evidence.link.report_url` overrides all of these |

Store the result as `evidence_plan`: the kinds, each resolved value, and — for anything that could not be resolved — the reason (e.g. `OpenAPI spec not found`, `test tool not detected`).

### Step 4 — Confirmation

Display:
```
Proposed commit:
  {commit_message}

Branch: {current_branch} → {base_branch}
PR title: {commit_message}

Evidence:
  kinds: {kinds joined by ", "}
  {one line per kind}

Proceed? [y / e to edit / n to abort]
```

Per-kind line: `image` → `image: {start_command} @ {base_url}, viewports {viewports}`; `markdown` → `markdown: {spec_path}` or `markdown: OpenAPI spec not found`; `link` → `link: {tool} · {report source, or "CI runs page"}` or `link: test tool not detected`; `text` → `text: command transcript`.

- **y** → proceed to Step 5
- **e** → prompt `New message:` (single line); replace `commit_message`; re-display and ask `[y/n]`
- **n** → emit `Aborted — no changes committed` and stop

### Step 5 — Stage, commit, push

```
git add -A
git commit -m "{commit_message}"
git push -u origin {current_branch}
```

On `git push` failure: emit the git error verbatim followed by `✗ Push failed — resolve conflicts or check remote permissions` and stop.

### Step 5b — Produce evidence

Runs after a successful push and before PR creation, and only when the provider hosts PRs (skip for Jira/Plane). Produce one `evidence_block` (markdown) per kind in `evidence_plan`. Evidence never blocks `ship`: on any failure the block is `No evidence captured: {reason}` and the flow continues.

- **`text`** — a fenced transcript. For `cli`, run the commands the change affects (from the ticket's scenarios, else from the diff) and record each command, its output, and its exit code. For `library`, `ai`, `microservices`, and `generic`, run the project's test command (from `docs/tools.md`) and include its output; for `ai`, add sample inputs and outputs from the ticket's scenarios.
- **`markdown`** — run `git diff {base_branch}...HEAD -- {spec_path}`. If the diff is empty but source files changed, the block is `spec unchanged`. Otherwise render each added or changed operation as `### {METHOD} {path}` followed by a parameters table, the request body (schema or example), and a responses table (status, schema or example). If `spec_path` is unresolved the block is `No evidence captured: OpenAPI spec not found`.
- **`link`** — GitHub only; on GitLab the block is `No evidence captured: link evidence is GitHub-only`. Use `ship.evidence.link.report_url` if set. Otherwise, if a test tool was detected, link the branch's runs page `https://github.com/{owner}/{repo}/actions?query=branch%3A{current_branch}` labelled `CI run (report published on completion)` and name the detected tool. If no tool was detected and no `report_url` is set, the block is `No evidence captured: test tool not detected`. Never edit the PR after creation to add a report link.
- **`image`** — GitHub only; on GitLab the block is `No evidence captured: image evidence is GitHub-only`. Start the app with `start_command`, wait up to 60 seconds for `base_url` to respond, then capture each added or changed page (from the ticket's scenarios, else the routes touched by the diff) at every viewport into a temporary directory, using the project's browser tooling (e.g. the `browser` skill or Playwright). Stop the app. If it does not start, or no pages were identified, the block is `No evidence captured: {reason}` (e.g. `no UI change detected`). Otherwise host the images on the orphan branch `pr-evidence`, never on the feature branch:
  1. `git fetch origin pr-evidence` (ignore failure) and open a temporary worktree on it — `git worktree add {tmp} pr-evidence` when the branch exists, else `git worktree add --detach {tmp}` followed by `git checkout --orphan pr-evidence` and `git rm -rf .` inside it.
  2. Copy the images into `{tmp}/{ticket_id or branch-slug}/`, commit, `git push origin pr-evidence`, read the pushed commit sha, then remove the temporary worktree.
  3. Reference each image as `![{page} @ {viewport}px](https://github.com/{owner}/{repo}/blob/{sha}/{dir}/{file}?raw=true)`.

Then append each string in `ship.evidence.extra` verbatim, one per line, after the generated blocks.

### Step 6 — PR creation

Determine `base_branch`: read `base_branch` from `.project/config.yaml`; default to `main` if absent or file missing.

**PR body:**
```
{one-sentence summary derived from commit message}

{if ticket_id known} Closes #{ticket_id}

## Evidence
{evidence blocks from Step 5b, then ship.evidence.extra strings}
```

The `## Evidence` section is always present, even when it only reads `No evidence captured: {reason}`.

For GitHub use `Closes #<number>` (numeric issue ID). For GitLab use `Closes <ticket_key>`.

**GitHub** (`provider_name == "github"`):
1. ToolSearch(`mcp__github__create_pull_request`) — if found, call with `title`, `body`, `head: current_branch`, `base: base_branch`.
2. On duplicate-PR error (branch already has an open PR): extract existing URL from error, emit `ℹ PR already exists: {url}` and stop cleanly.
3. On success: emit `✓ PR created: {pr_url}`, extract the PR number from `pr_url`, and continue to Step 7.

**GitLab** (`provider_name == "gitlab"`):
1. ToolSearch(`mcp__gitlab__create_merge_request`) — if found, call with equivalent fields.
2. Same duplicate and success handling as GitHub.
3. On success: stop. The PR watch offer in Step 7 is GitHub-only — do not offer it here.

**Jira / Plane**: emit `ℹ {Provider} does not host PRs — pushed only` and stop.

**No provider detected** or **MCP tool not found**: emit `ℹ No PR created — {reason}` where reason is `"provider not detected"` or `"MCP tool unavailable"`. Print the push URL so the user can open a PR manually.

### Step 7 — Offer a PR watch (GitHub only)

Only runs after a successful GitHub PR creation in Step 6. Skipped entirely for GitLab, Jira, Plane, no-provider, and MCP-unavailable outcomes.

Ask:
```
Watch this PR for CI results and new comments until it's merged or closed? [y/n]
```

- **y** — invoke the `/loop` skill with the prompt `Run a pr-watch tick for PR #{pr_number} in {owner}/{repo}.`, so `/loop` schedules recurring ticks that each re-enter **MODE: pr-watch** (below) for this PR. Emit `✓ Watching PR #{pr_number} — stop anytime with /loop stop.` and continue.
- **n** — emit nothing further; ship mode completes exactly as it did before this change.

---

## MODE: pr-watch

**GitHub only** — this mode only watches GitHub Actions runs and GitHub PR comments. GitLab merge request pipelines are not covered. Runs one tick per invocation; scheduling across ticks is `/loop`'s job, not this mode's. Report-only: it never pushes a commit, re-runs a job, or replies to a comment on your behalf.

Triggered by the `/loop` hand-off from ship mode's Step 7 (`Run a pr-watch tick for PR #{pr_number} in {owner}/{repo}.`), or directly by a user saying "watch PR #42" or "pr-watch 42".

### Step 1 — Load per-PR state

Read `.project/pr-watch/<pr-number>.yaml`. If absent, treat as:
```yaml
last_ci_run_id: null
last_comment_id: null
```

### Step 2 — Check PR state first

Call the GitHub MCP get-PR tool for `{owner}/{repo}#{pr_number}`. If its state is `merged` or `closed`:
- `merged` → emit `✓ PR #{pr_number} merged — watch ending` 
- `closed` (not merged) → emit `PR #{pr_number} closed without merging — watch ending`

Either way, call `ScheduleWakeup` with `stop: true` — do not schedule another tick — and stop this mode. Do not proceed to Steps 3–5.

If the PR is still open, continue to Step 3.

### Step 3 — Fetch CI status for the head commit

Call the GitHub MCP tool that lists check runs / workflow runs for the PR's current head commit SHA. Compare the latest run's ID to `last_ci_run_id`:
- Same ID → no new CI result this tick.
- Different ID (or `last_ci_run_id` was null) → this is a new run. If its conclusion is a failure, record it for Step 5. If the run has completed (any conclusion) and the project's evidence plan includes `link` (kinds from `ship.evidence.kinds`, else the `project_type` default — see **MODE: ship** Step 3b), also record it as the report source for Step 5. Update `last_ci_run_id` to this run's ID regardless of outcome (success or failure) so it isn't re-reported next tick.

### Step 4 — Fetch new comments

Call the GitHub MCP tools for PR review comments and issue comments. Filter to comments with ID greater than `last_comment_id` (or all comments, if `last_comment_id` is null — but on the very first tick, only record the latest ID as baseline rather than reporting pre-existing comments as "new"). Update `last_comment_id` to the highest comment ID seen.

### Step 5 — Report findings, take no action

- **New CI failure found**: report the run name, the failing job, and a link — e.g. `✗ CI failed on PR #42: {job name} — {run_url}`. Do not push a commit, do not re-trigger the run.
- **New comment(s) found**: report each as `[author]: body` (truncate body to ~300 chars). Do not reply.
- **Completed run with `link` evidence**: report `ℹ Test report for PR #{pr_number}: {url}`, where `{url}` is `ship.evidence.link.report_url` if set, else the run's URL. Report it once per run. Do not edit the PR body or comment on the PR.
- **Neither**: this is a quiet tick — report nothing new, per `/loop`'s own no-op convention.

### Step 6 — Persist state and schedule next tick

Write the updated `last_ci_run_id` and `last_comment_id` to `.project/pr-watch/<pr-number>.yaml`. Call `ScheduleWakeup` with `stop: false` and a delay appropriate to how often PR activity actually changes (do not poll faster than roughly once a minute) to schedule the next tick.

---

## MODE: release-notes

Generate ticket-level release notes by diffing two semver git tags. Publishes to a GitLab Release when the configured provider is GitLab; otherwise writes `docs/release_notes/{tag_name}.md`.

### Step 0 — Parse environment qualifier

Before any git calls, extract an optional environment qualifier from the user's input:

| Input contains | `env_qualifier` |
|---|---|
| `for uat`, `uat`, `release candidate` | `uat` |
| `for prod`, `prod`, `production`, `for production` | `prod` |
| *(none)* | `none` |

Store as `env_qualifier`. Used in Step 7.

### Step 1 — Verify on a tag

Run:
```
git describe --exact-match --tags HEAD
```

- **Success** → `current_tag` = trimmed output (e.g. `v1.2.0`)
- **Failure** → emit:
  ```
  ⚠ Not on a git tag — checkout the tag you want to release notes for and re-run.
  ```
  Stop.

### Step 2 — Find previous tag (semver-aware)

Run:
```
git tag --sort=-version:refname | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]'
```

Returns all semver tags sorted newest-first. Find `current_tag` in the list; take the next entry as `previous_tag`.

**First release fallback** — if `current_tag` is the only semver tag (no entry follows it in the list):
```
previous_ref = git rev-list --max-parents=0 HEAD
```
Emit: `ℹ First release — ranging from initial commit.`

Store result as `previous_tag_or_ref`.

### Step 3 — Collect commits in range

Run:
```
git log {previous_tag_or_ref}..{current_tag} --format="%H %s"
```

If output is empty:
```
No commits between {previous_tag_or_ref} and {current_tag}.
```
Stop.

Collect all lines as `commits` (list of `{hash, subject}`).

### Step 3b — Collect OpenSpec spec changes (conditional)

**OpenSpec detection**: check whether `openspec/specs/` exists in the repo root.

- **Absent** → set `spec_changes = []` and skip this step entirely.
- **Present** → run:
  ```
  git diff {previous_tag_or_ref}..{current_tag} -- openspec/specs/
  ```

Parse the diff output to build `spec_changes`: an array of `{capability, summary_lines[]}` objects, one per changed spec file. Derive `capability` from the file path — it is the directory name between `openspec/specs/` and `/spec.md` (e.g. `openspec/specs/auth-flow/spec.md` → `auth-flow`).

For each changed spec file, read the `+` and `-` diff lines (excluding file header lines starting with `+++`/`---`) and synthesise human-readable summary bullets:

| Diff signal | Summary bullet |
|---|---|
| `+` line adds a `## ` or `### ` heading | `Added section: {heading text}` |
| `-` line removes a `## ` or `### ` heading | `Removed section: {heading text}` |
| `+` line adds a `- The system SHALL` or `- SHALL` requirement | `New requirement: {requirement text, truncated to 120 chars}` |
| `-` line removes a `- The system SHALL` or `- SHALL` requirement | `Removed requirement: {requirement text, truncated to 120 chars}` |
| Net `+` lines > 20 with no structural markers above | `Expanded: {N} lines added` |
| Net `-` lines > 20 with no structural markers above | `Reduced: {N} lines removed` |
| Only minor changes (≤5 net lines, no structural markers) | `Minor edits` |

Collect bullets as `summary_lines` for that capability. Omit capabilities where the only summary is `Minor edits` if there are 5 or more changed capabilities (de-noise for large releases).

Sort `spec_changes` alphabetically by `capability`.

If the diff produces no output (no spec files changed in this range): set `spec_changes = []`.

### Step 4 — Extract ticket references

For each commit subject, apply all four patterns in order (all patterns applied to every subject):

| Pattern | Example | Notes |
|---------|---------|-------|
| `[A-Z]+-\d+` | `PROJ-42`, `AUTH-7` | Jira/Plane/GitLab project keys |
| `(?:Closes?\|Fixes?\|Resolves?)\s+#(\d+)` | `Closes #42` | GitHub/GitLab closing keywords — capture group is the number |
| `#(\d+)` | `#42` | Bare hash reference — capture group is the number |
| Full issue URL ending in `/issues/\d+` or `/-/issues/\d+` | URL | Extract trailing number |

Collect all matched IDs into `ticket_ids` (strings). Deduplicate. If count > 50: keep first 50, emit `ℹ {N} ticket references found — showing first 50`.

Commits with no match go into `unlinked_commits` (store subject only).

### Step 5 — Fetch ticket titles

Emit: `Fetching {N} tickets…`

For each ID in `ticket_ids`, call the provider's get-ticket tool using `mcp_prefix` from `.project/config.yaml`:
- **GitHub**: `mcp__github__get_issue(issue_number: id)`
- **GitLab**: `mcp__gitlab__get_issue(iid: id)`
- **Jira / Plane**: get-issue tool from `tool_contracts` in `references/providers.json`

On success: record `{id, title, labels}`.
On any failure (MCP error, timeout, 404): record `{id, title: null, labels: []}` and continue — do not block.

If `.project/config.yaml` is absent (no provider configured): set all titles to null, skip MCP calls, continue.

Emit after all calls: `✓ {fetched}/{N} tickets resolved.`

### Step 6 — Group by label

**State labels to exclude** when selecting the group label: `todo`, `in-progress`, `in-review`, `blocked`.

For each ticket, take its **first label that is not a state label** as the group key. Tickets with no qualifying label → group `Unlabelled`.

Sort groups alphabetically. Within each group, preserve the order tickets appeared in the commit log.

### Step 7 — Apply environment framing

| `env_qualifier` | Header |
|---|---|
| `none` | `Release {current_tag}` |
| `uat` | `Release Candidate {current_tag}` |
| `prod` | `Released {current_tag} to production` |

Store as `header`.

### Step 8 — Build release body

Read the template from `assets/release-notes-template.md` (relative to this skill file). Render it by substituting the variables below. The template uses Handlebars-style `{{variable}}` placeholders and `{{#if}}` / `{{#each}}` blocks.

| Variable | Value |
|---|---|
| `{{header}}` | Environment-framed title from Step 7 |
| `{{previous_tag_or_ref}}` | Previous tag or initial commit SHA |
| `{{current_tag}}` | Current tag name |
| `{{total_resolved}}` | Count of tickets with a resolved title |
| `{{label_groups}}` | Array of `{name, count, plural, tickets[]}` — one entry per non-state label group, sorted alphabetically; omit groups with zero tickets |
| `{{unlabelled_tickets}}` | Array of tickets with no qualifying label; omit `### Unlabelled` block if empty |
| `{{other_commits}}` | Array of `{subject}` for unlinked commits |
| `{{spec_changes}}` | Array of `{capability, summary_lines[]}` from Step 3b; empty array when not an OpenSpec project or no spec files changed |

Rendering rules:
- `{{#if plural}}` is true when count > 1 (for "tickets" vs "ticket" pluralisation).
- Omit the `{{#if other_commits}}` block entirely if `unlinked_commits` is empty **or** if `release.include_unlinked_commits` is `false` in `.project/config.yaml`.
- For tickets where title fetch failed: render `{{title}}` as `(title unavailable)`.

Store the rendered output as `release_body`.

### Step 9 — Publish

Read `provider.name` from `.project/config.yaml` (treat as absent if file missing).

#### GitLab (`provider.name == "gitlab"`)

Call `mcp__gitlab__create_release(project_id: gitlab_project_id, tag_name: current_tag, name: header, description: release_body)`.

- On 409 / "already exists" error → emit `ℹ Release already exists for {current_tag} — skipping publish.` and print `release_body` to terminal.
- On success → emit `✓ GitLab Release created: {current_tag}`
- Tool unavailable (MCP server not configured) → emit `ℹ Could not publish to GitLab — copy the release notes below and create manually.` and print `release_body` to terminal.

#### All other providers (GitHub, Jira, Plane, or no provider)

Write `docs/release_notes/{current_tag}.md`:
1. Create `docs/release_notes/` directory if absent (silently).
2. Write `release_body` as the file content (no YAML front matter).
3. Emit: `✓ Release notes written: docs/release_notes/{current_tag}.md`

### Step 10 — Summary output

```
Release notes for {current_tag}
Range:   {previous_tag_or_ref} → {current_tag}
Tickets: {total_resolved} resolved across {G} label groups
Published: {GitLab Release: {current_tag} | docs/release_notes/{current_tag}.md}
```

### Config (optional)

`.project/config.yaml` accepts an optional `release` key:

```yaml
release:
  include_unlinked_commits: true   # default: true; set false to omit ### Other section
```

All other behaviour derives from existing config fields (`provider.name`, `gitlab_project_id`, `mcp_prefix`).

### Edge Cases

| Scenario | Behaviour |
|---|---|
| Not on a tag | Emit warning, stop (Step 1) |
| No previous semver tag | Range from initial commit, emit notice (Step 2) |
| Zero commits in range | Emit notice, stop (Step 3) |
| All commits unlinked | Notes contain only `### Other` section |
| Tracker MCP unavailable | Degrade: IDs without titles, continue (Step 5) |
| `docs/release_notes/` absent | Create silently (Step 9) |
| GitLab Release already exists | Emit notice, print body (Step 9) |
