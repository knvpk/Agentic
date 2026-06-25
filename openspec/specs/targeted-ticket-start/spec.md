## Purpose
Defines the behaviour of `/project-management start <id>` — a targeted mode that fetches a specific ticket, enriches it with project doc context, transitions its state, optionally creates a branch, and invokes opsx:explore to begin implementation.

## Requirements

### Requirement: start mode accepts a ticket ID in any supported format
The skill SHALL accept a ticket reference in four formats: bare number (`42`), key format (`PROJ-42`), hash format (`#42`), and full issue URL. The skill SHALL parse the reference and resolve it against the provider configured in `.project/config.yaml` without re-running provider detection.

#### Scenario: Key format resolved without detection
- **WHEN** user runs `/project-management start PROJ-42`
- **THEN** skill reads provider from `.project/config.yaml` and fetches ticket `PROJ-42` via the configured MCP prefix — no heuristic detection is performed

#### Scenario: Bare number resolved for GitHub and GitLab
- **WHEN** user runs `/project-management start 42` with a GitHub or GitLab provider configured
- **THEN** skill treats `42` as the issue number in the configured repo and fetches it

#### Scenario: Bare number for Jira requires full key
- **WHEN** user runs `/project-management start 42` with a Jira provider configured
- **THEN** skill responds: "Jira requires a full key format: `PROJ-42`. What is your project key prefix?"

#### Scenario: Full URL accepted
- **WHEN** user passes a full issue URL (e.g. `https://github.com/owner/repo/issues/42`)
- **THEN** skill extracts the issue number and fetches it using the configured MCP prefix

### Requirement: start mode enriches the ticket with project doc context using the Context Fallback Chain
After fetching the ticket, the skill SHALL run the Context Fallback Chain (prd.md → architecture.md → database.md → tools.md → local src → context_repos) to collect only relevant sections, exactly as the `ticket new` sub-mode does.

#### Scenario: Relevant prd sections included
- **WHEN** ticket title contains a keyword present in docs/prd.md
- **THEN** the matching section from docs/prd.md is included in the context passed to opsx:explore

#### Scenario: Irrelevant sections omitted
- **WHEN** no doc section matches the ticket topic
- **THEN** skill warns: "No relevant context found — Context section may be incomplete" and continues

### Requirement: start mode transitions a todo ticket to in-progress with user confirmation
If the fetched ticket is in the `todo` state, the skill SHALL ask the user once whether to transition it to `in-progress`. The transition SHALL use `state_mapping` from the active provider config.

#### Scenario: todo ticket prompts for transition
- **WHEN** ticket state is `todo`
- **THEN** skill asks: "Move TICK-42 to in-progress? [y/n]"

#### Scenario: in-progress ticket requires no prompt
- **WHEN** ticket state is already `in-progress`
- **THEN** skill skips the state transition prompt and continues silently

#### Scenario: backlog ticket prompts for transition with sprint context
- **WHEN** ticket state is `backlog`
- **THEN** skill asks: "TICK-42 is in backlog (not assigned to the active sprint). Move to in-progress? [y/n]"

#### Scenario: backlog transition confirmed — WIP check runs then state is updated
- **WHEN** ticket state is `backlog` and user answers `y` to the transition prompt
- **THEN** skill runs the WIP Limit Check; if check passes (or no wip_limit is set), skill calls `update_ticket` to transition the ticket to `in-progress` via the provider-specific path

#### Scenario: backlog transition declined — continues without state change
- **WHEN** ticket state is `backlog` and user answers `n`
- **THEN** skill outputs `Transition cancelled — continuing in exploration mode (ticket stays in current state).` and proceeds to branch creation without any state change

#### Scenario: WIP check applied on backlog transition too
- **WHEN** ticket state is `backlog`, user confirms transition, and wip_limit would be exceeded
- **THEN** skill shows the WIP warning and asks `Continue? [y/n]` before calling the provider — same as for todo→in-progress

### Requirement: start mode uses provider-specific write path and label-delta for state transitions
Both the `todo` and `backlog` transition paths SHALL use provider-specific dispatch when calling `update_ticket`.

#### Scenario: GitLab in-progress transition removes old state label
- **WHEN** a GitLab ticket with the `To Do` label is transitioned to `in-progress` via start mode
- **THEN** skill uses the label-delta helper to add the `In Progress` label AND remove the `To Do` label in the same call — not just add the new label

#### Scenario: GitHub in-progress transition removes old state label
- **WHEN** a GitHub ticket with the `todo` label is transitioned to `in-progress` via start mode
- **THEN** skill uses the label-delta helper to add the `in-progress` label AND remove the `todo` label

#### Scenario: Plane in-progress transition uses state UUID
- **WHEN** a Plane ticket is transitioned to `in-progress` via start mode
- **THEN** skill reads the UUID for `in-progress` from `plane_state_ids` in `.project/config.yaml` and passes it as the `state` field in the `update_issue` call

#### Scenario: Jira in-progress transition uses transition name directly
- **WHEN** a Jira ticket is transitioned to `in-progress` via start mode
- **THEN** skill calls `update_ticket` with the transition name `In Progress` from `state_mapping` — no label-delta or UUID lookup needed

### Requirement: start mode optionally creates a branch using the detected branching strategy
The skill SHALL offer to create a branch using the same gitflow/three-branch/single-branch detection logic as the issue-explore skill. Branch creation SHALL require explicit user confirmation. Passing `--no-branch` SHALL skip branch creation entirely.

#### Scenario: Branch name derived from ticket title
- **WHEN** ticket title is "Add OAuth login support"
- **THEN** derived branch name is of the form `feature/PROJ-42-oauth-login-support`

#### Scenario: User confirms branch creation
- **WHEN** skill presents derived branch name and user confirms with Y
- **THEN** branch is created from the detected base branch (develop for gitflow, main/master for single-branch)

#### Scenario: --no-branch skips branch creation
- **WHEN** user invokes `/project-management start TICK-42 --no-branch`
- **THEN** branch creation step is skipped and skill proceeds directly to opsx:explore

### Requirement: start mode invokes opsx:explore with assembled context
The skill SHALL assemble a context block containing issue fields, project doc context from the fallback chain, and code repo context, then invoke `opsx:explore` with it.

#### Scenario: opsx:explore receives full context
- **WHEN** start mode completes fetch, doc enrichment, and branch step
- **THEN** opsx:explore is invoked with a block containing: issue ID, title, state, description, relevant project doc sections, and code repo branch/recent commits

#### Scenario: Missing opsx:explore falls back to inline presentation
- **WHEN** opsx:explore skill is not loaded
- **THEN** skill presents the assembled context block directly and offers: find affected files, list open questions, summarise implementation, start implementing

### Requirement: start mode is routed from natural-language triggers in the routing table
The skill's Mode Routing table SHALL include entries for common phrasings that invoke `start` mode with a ticket reference.

#### Scenario: Trigger phrases route to start mode
- **WHEN** user says "start TICK-42", "work on TICK-42", "begin TICK-42", or "let's work on #42"
- **THEN** skill routes to `start` mode with `TICK-42` as the ticket reference

### Requirement: start mode applies the WIP limit check before transitioning the ticket to in-progress
When the user confirms transitioning a `todo` ticket to `in-progress` via `start` mode, the skill SHALL apply the WIP limit check as defined in the `agile-quality-gates` capability before making the provider state transition call. The check occurs after the user has confirmed the state change (`Move TICK-42 to in-progress? [y/n]` answered `y`) but before the provider MCP call.

#### Scenario: WIP check applied after user confirms transition
- **WHEN** user confirms moving TICK-42 to in-progress and wip_limit would be exceeded
- **THEN** skill shows the WIP warning and asks `Continue? [y/n]` before calling the provider

#### Scenario: WIP check skipped when ticket is already in-progress
- **WHEN** ticket fetched by start mode is already in `in-progress` state
- **THEN** no WIP check is performed (no new in-progress slot is being consumed)

#### Scenario: WIP check skipped when wip_limit is absent
- **WHEN** `.project/config.yaml` has no `wip_limit` key
- **THEN** start mode transitions to in-progress without any WIP check

#### Scenario: start mode with --no-branch still applies WIP check
- **WHEN** user runs `start TICK-42 --no-branch` and wip_limit would be exceeded
- **THEN** WIP check still runs — the --no-branch flag only suppresses branch creation

---

### Requirement: start mode ranks and trims comments when the ticket has more than 10
When the fetched ticket has more than 10 comments, the skill SHALL score each comment by: reporter/assignee authorship (+3), presence of code references — MR/PR URLs, backtick blocks, or branch/commit keywords (+2), body length > 100 characters (+1), bot author pattern — `[bot]`, `github-actions`, `dependabot`, `renovate` (−5). The skill SHALL keep the top 7 scored comments plus the last 3 (most recent), deduplicate by comment ID, and expose the result as `priority_comments`. The context block SHALL include `comments_total` and `comments_shown` counts when trimming occurs.

#### Scenario: Busy ticket trimmed to at most 10 priority comments
- **WHEN** a fetched ticket has 50 comments
- **THEN** `priority_comments` contains at most 10 entries and the context block header reads `Comments (10 of 50 shown — ranked by relevance)`

#### Scenario: Ticket with 10 or fewer comments is passed through unchanged
- **WHEN** a fetched ticket has 8 comments
- **THEN** all 8 comments are included without ranking and no `comments_total` / `comments_shown` note is added

#### Scenario: Reporter comments ranked to top
- **WHEN** the ticket reporter left 2 comments among 40 total
- **THEN** both reporter comments appear in `priority_comments`

#### Scenario: Bot comments deprioritized
- **WHEN** `dependabot[bot]` authored 6 comments among 40 total
- **THEN** none of the bot comments appear in `priority_comments` unless their score exceeds non-bot comments

---

### Requirement: start mode fetches linked issues when the description is insufficient
When the fetched ticket's description is fewer than 150 characters, is empty, or consists solely of cross-reference links with no prose, the skill SHALL attempt to fetch linked/related issues via the provider's `list_issue_relations` MCP tool (or equivalent from `tool_contracts` in `references/providers.json`). If the tool is unavailable for the provider, the skill SHALL skip silently and continue. Fetched linked issues SHALL be appended to the context block as a `--- Linked Issues ---` section with each entry showing: ID, state, and title.

#### Scenario: Thin description triggers linked issue fetch
- **WHEN** ticket description is 60 characters of cross-reference text only
- **THEN** skill calls the provider's linked-issues MCP tool and appends results to the context block

#### Scenario: Adequate description skips linked issue fetch
- **WHEN** ticket description is 400 characters of prose
- **THEN** linked issue fetch is skipped entirely — no additional MCP call is made

#### Scenario: Provider without linked-issues MCP tool skips silently
- **WHEN** `list_issue_relations` or equivalent is absent from the provider's `tool_contracts`
- **THEN** the `--- Linked Issues ---` section is omitted from the context block and no error is shown

#### Scenario: Linked issues rendered in context block
- **WHEN** linked issue fetch returns 3 issues
- **THEN** context block contains a `--- Linked Issues ---` section with 3 entries, each showing ID, state, and title

---

### Requirement: start mode renders custom provider fields in the context block
After fetching the ticket, the skill SHALL collect all non-null, non-standard fields returned by the provider's `get_ticket` MCP response (such as `Sprint`, `Story Points`, `Epic`, `Fix Version`, `Priority`) and render them in a `--- Provider Fields ---` section in the context block passed to `opsx:explore`. If the provider returns no custom fields, this section is omitted entirely.

#### Scenario: Sprint and story points rendered when present
- **WHEN** the provider returns a ticket with `Sprint: "Sprint 4"` and `Story Points: 5`
- **THEN** the context block contains a `--- Provider Fields ---` section with `Sprint: Sprint 4` and `Story Points: 5`

#### Scenario: Provider fields section omitted when empty
- **WHEN** the provider returns no custom fields or all custom fields are null
- **THEN** the `--- Provider Fields ---` section is not present in the context block

---

### Requirement: start mode scans description and comments for code cross-references
After fetching the ticket and its comments, the skill SHALL scan the full text of the description and all comment bodies for: MR/PR URLs (GitLab `/-/merge_requests/N`, GitHub `/pull/N`), branch name mentions (branch keyword followed by a word of 4–80 characters), and commit SHAs (7–40 hex characters). Results SHALL be deduplicated and capped at 10. The extracted references SHALL be included in the context block as a `--- Code References in Issue ---` section.

#### Scenario: MR URL extracted from description
- **WHEN** description contains `https://gitlab.com/org/repo/-/merge_requests/55`
- **THEN** that URL appears in the `--- Code References in Issue ---` section of the context block

#### Scenario: GitHub PR URL extracted from a comment
- **WHEN** a comment body contains `https://github.com/owner/repo/pull/12`
- **THEN** that URL appears in the `--- Code References in Issue ---` section

#### Scenario: Cap at 10 refs enforced
- **WHEN** description and comments contain 18 distinct code references
- **THEN** `--- Code References in Issue ---` contains exactly 10 entries

#### Scenario: Section shows none when no references found
- **WHEN** description and all comments contain no MR/PR URLs, branch mentions, or commit SHAs
- **THEN** context block shows `--- Code References in Issue ---\n(none found)`
