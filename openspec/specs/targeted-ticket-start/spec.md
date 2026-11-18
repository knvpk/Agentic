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
The skill SHALL transition a fetched ticket in `todo` or `backlog` state to `in-progress` automatically, without prompting, unless the combined pre-flight gate (WIP limit, scope-width signal, or estimate threshold — see `start-mode-autonomy`) fires, or the `--confirm` flag was passed. When the gate fires, the skill SHALL ask once, combining the transition decision and the branch/worktree decision into a single question, before performing either. The transition SHALL use `state_mapping` from the active provider config.

#### Scenario: todo ticket transitions automatically when no gate fires
- **WHEN** ticket state is `todo` and none of the gate conditions fire
- **THEN** skill transitions the ticket to `in-progress` without prompting, and reports `✓ TICK-42 → in-progress` as part of the combined summary

#### Scenario: backlog ticket transitions automatically when no gate fires
- **WHEN** ticket state is `backlog` and none of the gate conditions fire
- **THEN** skill transitions the ticket to `in-progress` without prompting, and reports the transition as part of the combined summary

#### Scenario: gated ticket asks a single combined question
- **WHEN** ticket state is `todo` or `backlog` and the gate fires for any reason
- **THEN** skill asks once: `"TICK-42 looks {reason} — transition to in-progress and create its branch anyway? [y/n]"`, covering both the transition and the branch/worktree step

#### Scenario: gated transition declined — continues without state change
- **WHEN** the gate fires and user answers `n`
- **THEN** skill outputs `Transition cancelled — continuing in exploration mode (ticket stays in current state).` and proceeds without any state change or branch/worktree creation

#### Scenario: --confirm flag forces the gate every time
- **WHEN** user runs `/project-management start TICK-42 --confirm`
- **THEN** the combined gate question is asked regardless of WIP, scope-width, or estimate — reproducing the pre-change always-ask behavior for this invocation only

#### Scenario: in-progress ticket requires no prompt and no gate evaluation
- **WHEN** ticket state is already `in-progress`
- **THEN** skill skips the state transition and the gate check entirely, and continues directly to branch/worktree handling

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
The skill SHALL create a git worktree — not a branch switch in the current checkout — using the same gitflow/three-branch/single-branch base-branch detection logic as before. Worktree creation SHALL happen automatically, without prompting, unless the combined pre-flight gate fires or `--confirm` was passed. Passing `--no-branch` SHALL skip both branch and worktree creation entirely, regardless of gate state.

#### Scenario: Branch name derived from ticket title
- **WHEN** ticket title is "Add OAuth login support"
- **THEN** derived branch name is of the form `feature/PROJ-42-oauth-login-support`

#### Scenario: Worktree created automatically when no gate fires
- **WHEN** no gate condition fires for TICK-42
- **THEN** skill runs `git worktree add ../{repo}-TICK-42-{slug} -b feature/TICK-42-{slug} {base}` without prompting, and includes the worktree path in the combined summary

#### Scenario: Worktree creation included in the single combined gate question
- **WHEN** the gate fires and the user confirms with `y`
- **THEN** skill performs both the state transition and the worktree creation in response to that one confirmation — no second prompt for the branch step

#### Scenario: --no-branch skips both branch and worktree creation
- **WHEN** user invokes `/project-management start TICK-42 --no-branch`
- **THEN** no branch or worktree is created, regardless of gate state, and skill proceeds directly without either

#### Scenario: --confirm flag applies to the worktree step too
- **WHEN** user runs `start TICK-42 --confirm`
- **THEN** the combined gate question, covering both transition and worktree creation, is asked even if no risk heuristic would otherwise fire

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
The WIP limit check SHALL be one of three inputs to the single combined pre-flight gate defined in `start-mode-autonomy`, evaluated before any prompt is shown or any action is taken — not after an initial confirmation as before. If the WIP limit would be exceeded, the combined gate fires and the user is asked once before either the transition or the worktree/branch creation happens.

#### Scenario: WIP limit alone is sufficient to fire the combined gate
- **WHEN** wip_limit would be exceeded for TICK-42, and neither the scope-width signal nor the estimate threshold applies
- **THEN** the combined gate still fires, and the user is asked the single combined question before any transition or worktree creation

#### Scenario: WIP check skipped when ticket is already in-progress
- **WHEN** ticket fetched by start mode is already in `in-progress` state
- **THEN** no WIP check is performed as part of gate evaluation, since no new in-progress slot is being consumed

#### Scenario: WIP check skipped when wip_limit is absent
- **WHEN** `.project/config.yaml` has no `wip_limit` key
- **THEN** the WIP condition contributes nothing to the gate evaluation — the gate may still fire from scope-width or estimate threshold

#### Scenario: start mode with --no-branch still evaluates the WIP condition for the transition
- **WHEN** user runs `start TICK-42 --no-branch` and wip_limit would be exceeded
- **THEN** the gate still fires for the transition decision — `--no-branch` only suppresses branch/worktree creation, not the transition gate

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
