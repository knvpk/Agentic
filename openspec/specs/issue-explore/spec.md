# Spec: issue-explore

## Purpose

Defines the requirements for the `issue-explore` skill, which fetches a work item from GitLab, GitHub, Jira, or Plane (auto-detected) and loads it — together with the current code repository context — into an exploration/spec skill session. The issue tracker and the code host are treated as independent systems.

## Requirements

### Requirement: Provider is auto-detected from input without user intervention

The skill SHALL detect the issue tracker from the input format alone: full URLs are resolved via hostname patterns in `references/providers.json`, Jira keys (`PROJ-NNN`) are always auto-detected, `owner/repo#N` format is resolved from the git remote, and bare numbers use token + remote + git log heuristics — the user is prompted only when all heuristics fail.

#### Scenario: Full GitLab URL resolves provider without prompt
- **WHEN** user runs `/issue-explore https://gitlab.company.com/group/project/-/issues/42`
- **THEN** provider is set to `gitlab` and `issue_id` to `42` without asking the user anything

#### Scenario: Jira key always auto-detects
- **WHEN** user runs `/issue-explore PROJ-123`
- **THEN** provider is set to `jira` and `issue_id` to `PROJ-123` with no prompt

#### Scenario: Bare number falls back to actionable prompt
- **WHEN** user runs `/issue-explore 99` with no tokens set and no git remote
- **THEN** the skill shows a table listing exactly what to set per provider, not a generic error

---

### Requirement: Fetch method is resolved in order CLI → MCP → API token

The skill SHALL try `glab`/`gh`/`jira` CLI first, then scan `system-reminder` for `mcp__{provider}__*` tools, then check the provider's token env var. It SHALL ask the user for a token only when all three paths are unavailable, and show a permanent-fix table after.

#### Scenario: CLI takes precedence when installed
- **WHEN** `glab` is on PATH and provider is `gitlab`
- **THEN** `FETCH_METHOD` is set to `cli` without checking for MCP or tokens

#### Scenario: MCP used when CLI absent but tools are in context
- **WHEN** `glab` is not on PATH and `mcp__gitlab__get_issue` appears in `system-reminder`
- **THEN** `FETCH_METHOD` is set to `mcp`

#### Scenario: Token fallback when CLI and MCP unavailable
- **WHEN** neither CLI nor MCP is available but `GITLAB_TOKEN` is set
- **THEN** `FETCH_METHOD` is set to `api`

---

### Requirement: Issue is fetched and normalized to a provider-agnostic schema

The skill SHALL delegate fetching to `references/{provider}.md`, which produces raw JSON files in `/tmp/`. The skill then normalizes them to `references/schema.json` format at `/tmp/ii_normalized.json`. Linked issues are fetched only when the description is insufficient (< 150 chars, empty, or cross-refs only).

#### Scenario: Normalized file written after fetch
- **WHEN** any provider fetch completes
- **THEN** `/tmp/ii_normalized.json` exists and contains `id`, `title`, `state`, `issue_type`, `description`, `comments`, and `linked_issues` fields

#### Scenario: Linked issues fetched only when description is thin
- **WHEN** issue description is 80 characters of cross-reference links only
- **THEN** Step C runs and `/tmp/ii_raw_linked.json` is written

#### Scenario: Linked issues skipped when description is adequate
- **WHEN** issue description is 500 characters of prose
- **THEN** Step C is skipped and no linked-issue fetch occurs

---

### Requirement: Comments are ranked and trimmed when the issue has more than 10

When the normalized issue has more than 10 comments, the skill SHALL score each by author relevance (reporter/assignee +3), code references (+2), body length > 100 chars (+1), and bot author (−5), keep the top 7 scored plus the last 3 (most recent), deduplicate, and write back to `/tmp/ii_normalized.json` as `priority_comments`.

#### Scenario: Busy issue trimmed to at most 10 priority comments
- **WHEN** an issue has 40 comments
- **THEN** `priority_comments` contains at most 10 entries and `comments_total` is 40

#### Scenario: Reporter's comments ranked highest
- **WHEN** the issue reporter left 2 comments among 40 total
- **THEN** both reporter comments appear in `priority_comments`

#### Scenario: Bot comments deprioritized
- **WHEN** a `github-actions[bot]` left 5 comments
- **THEN** none of the bot comments appear in `priority_comments` unless no higher-scored comments exist

---

### Requirement: Code host cross-references are extracted from the issue body

The skill SHALL scan `description` and all `comments[].body` for MR/PR URLs, branch name mentions, and commit SHAs, deduplicate, and cap at 10. These are passed to the exploration context as `CODE_REFS`.

#### Scenario: MR URL extracted from description
- **WHEN** description contains `https://gitlab.com/org/repo/-/merge_requests/55`
- **THEN** that URL appears in `CODE_REFS`

#### Scenario: Cap at 10 refs enforced
- **WHEN** description and comments contain 25 distinct code references
- **THEN** `CODE_REFS` contains exactly 10 entries

---

### Requirement: Branch creation is opt-in and requires explicit user confirmation

The skill SHALL detect the repo's branching strategy from existing branch topology, derive a 2–4 word slug from the issue title using LLM reasoning, build the branch name as `{prefix}{issue_id}-{slug}`, then ask the user to confirm, provide a custom name, or decline — before touching git.

#### Scenario: Branch name proposed before creation
- **WHEN** provider is `jira`, issue ID is `PROJ-42`, title is "Add OAuth login support"
- **THEN** user is asked to confirm `feature/PROJ-42-oauth-login-support` (or similar slug) before any git command runs

#### Scenario: User can override branch name
- **WHEN** user types a custom name at the confirmation prompt
- **THEN** the custom name is sanitized and used instead of the generated slug

#### Scenario: `--no-branch` skips creation entirely
- **WHEN** user runs `/issue-explore PROJ-42 --no-branch`
- **THEN** no git commands run and skill proceeds to exploration in Step 6

#### Scenario: Gitflow repo uses `hotfix/` prefix for bugs
- **WHEN** repo has `develop`, `release`, and `hotfix` branches and issue type is `bug`
- **THEN** branch name starts with `hotfix/`

---

### Requirement: Branch is created from the latest remote state of the base branch

When the user confirms branch creation, the skill SHALL checkout `base_branch`, pull `origin/{base_branch}`, and then create the new branch. Pull failure is non-fatal and shows a named warning. All git errors are mapped to actionable messages before display.

#### Scenario: New branch created from pulled base
- **WHEN** user confirms branch creation and `origin/develop` exists
- **THEN** git checks out `develop`, pulls latest, then creates the feature branch

#### Scenario: Already-existing branch switches without error
- **WHEN** branch name already exists locally
- **THEN** skill switches to it and continues without failing

#### Scenario: Pull failure is non-fatal
- **WHEN** `git pull origin develop` fails due to no network
- **THEN** skill shows a warning naming the fix (`git pull origin develop`) and continues with local state

---

### Requirement: Issue and repo context are assembled into a structured block and passed to the spec skill

The skill SHALL build a context block from `/tmp/ii_normalized.json` plus `CODE_HOST`, `CODE_REPO`, `CODE_BRANCH`, and `CODE_COMMITS`. If issue tracker and code host differ, a cross-system note is added. The skill SHALL scan `system-reminder` for available spec skills in priority order (`opsx:explore` → `spec-kit` → `explore` → `spec`) and invoke the first match.

#### Scenario: Cross-system note added when hosts differ
- **WHEN** issue is from Jira and code host is GitLab
- **THEN** context block contains `NOTE: Issue tracker (jira) and code host (gitlab) are different systems.`

#### Scenario: opsx:explore invoked when available
- **WHEN** `opsx:explore` appears in `system-reminder` skills
- **THEN** skill invokes `opsx:explore` with the full context block

#### Scenario: Fallback menu shown when no spec skill loaded
- **WHEN** no matching spec skill is found in `system-reminder`
- **THEN** skill presents the context block with a 5-option next-steps menu and waits for user reply

---

### Requirement: Temporary files are always cleaned up after Step 6

Regardless of whether Step 6b succeeds or fails, the skill SHALL delete `/tmp/ii_raw_issue.json`, `/tmp/ii_raw_comments.json`, `/tmp/ii_raw_linked.json`, and `/tmp/ii_normalized.json`.

#### Scenario: Temp files removed after successful exploration
- **WHEN** spec skill is successfully invoked
- **THEN** all four `/tmp/ii_*` files are deleted

#### Scenario: Temp files removed even when spec skill invocation fails
- **WHEN** spec skill invocation raises an error
- **THEN** cleanup still runs and all four `/tmp/ii_*` files are deleted

---

### Requirement: New providers are added via registry only — SKILL.md is not modified

Adding a new issue tracker SHALL require only: a new entry in `references/providers.json` (with `name`, `hostname_patterns`, `url_path_patterns`, `cli_tool`, `token_env`, `mcp_prefix`) and a new `references/{provider}.md` implementing fetch Steps A–C and normalization.

#### Scenario: New provider detected without SKILL.md changes
- **WHEN** a new provider entry is added to `references/providers.json` with correct hostname patterns
- **THEN** full URLs for that provider are detected and routed without any change to `SKILL.md`
