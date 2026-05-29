## ADDED Requirements

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

#### Scenario: backlog ticket triggers a warning
- **WHEN** ticket state is `backlog`
- **THEN** skill warns: "TICK-42 is in backlog and not assigned to the active sprint. Continue anyway? [y/n]"

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
