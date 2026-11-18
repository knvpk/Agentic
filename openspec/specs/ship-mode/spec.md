## Overview

The `ship` mode is a daily-workflow command in the project-management skill. It stages all local changes, generates a conventional commit message from the diff, presents it for confirmation, commits, pushes, and creates a PR against the configured (or defaulted) base branch. It enriches the commit and PR with a ticket ID when one can be inferred.

## Trigger Phrases

| User says | Routes to |
|---|---|
| `ship`, `ship my changes` | **ship** |
| `commit and pr`, `commit and create pr` | **ship** |
| `push and pr`, `commit all changes` | **ship** |

Add to Mode Routing table and help index.

## Behaviour Specification

### Step 0 — Pre-flight checks

1. Run `git status --porcelain`. If output is empty → emit `Nothing to commit — working tree clean` and stop.
2. Run `git branch --show-current`. If output is empty (detached HEAD) → emit `✗ Detached HEAD — cannot push. Checkout a branch first.` and stop.

Store: `current_branch`.

### Step 1 — Ticket ID resolution

1. Parse `current_branch` for pattern `[A-Z]+-\d+` (case-insensitive, first match wins).
   - e.g. `feat/TICK-42-auth-refresh` → `TICK-42`
   - e.g. `fix/AUTH-7/token-expiry` → `AUTH-7`
2. If no match, read `current_ticket` from `.project/config.yaml` (absent = skip).
3. Store result as `ticket_id` (null if neither source yields a value).

### Step 2 — Provider detection

1. If `.project/config.yaml` exists and has `provider.name` + `provider.mcp_prefix` → use them.
2. Otherwise run `git remote get-url origin`. Match hostname against known patterns:
   - `github.com` → `{ name: "github", mcp_prefix: "mcp__github__" }`
   - `gitlab.*` → `{ name: "gitlab", mcp_prefix: "mcp__gitlab__" }`
   - No match → `{ name: null, mcp_prefix: null }`
3. Store: `provider_name`, `mcp_prefix`.

### Step 3 — Diff analysis and message generation

1. Run `git diff HEAD` to get the full diff.
2. Run `git diff --name-only HEAD` to get changed file paths.
3. Classify conventional commit type from changed paths:
   - Any path contains `fix`, `bug`, `patch`, `hotfix` → `fix`
   - Any path in `docs/`, `*.md` only → `docs`
   - Any path in config files only (`*.yaml`, `*.json`, `*.toml`, `*.lock`) → `chore`
   - Default → `feat`
4. Derive title (≤60 chars after prefix):
   - If `ticket_id` known and ticket title is available (from `current_ticket` in config) → use ticket title
   - Otherwise → summarise the most significant change from the diff (largest new block, first changed function/section name)
5. Compose full commit message:
   ```
   {ticket_id}: {type}: {title}        ← when ticket_id known
   {type}: {title}                     ← when no ticket_id
   ```

### Step 4 — Confirmation step

Display:
```
Proposed commit:
  {commit_message}

Branch: {current_branch} → {base_branch}
PR title: {commit_message}

Proceed? [y / e to edit / n to abort]
```

- **y** → continue to Step 5
- **e** → prompt `New message:` (single line); use edited value as `commit_message`; re-display and ask `[y/n]`
- **n** → emit `Aborted — no changes committed` and stop

### Step 5 — Stage, commit, push

```
git add -A
git commit -m "{commit_message}"
git push -u origin {current_branch}
```

On `git push` failure: emit the git error verbatim + `✗ Push failed — resolve conflicts or check remote permissions` and stop.

### Step 6 — PR creation

Determine `base_branch`: read `base_branch` from `.project/config.yaml`; default to `main` if absent.

**GitHub** (`provider_name == "github"`):

1. ToolSearch(`mcp__github__create_pull_request`) — if found, call with:
   - `title`: `commit_message`
   - `body`: see PR body spec below
   - `head`: `current_branch`
   - `base`: `base_branch`
2. On duplicate-PR error (PR already exists for this branch): extract existing PR URL from error, emit `ℹ PR already exists: {url}` and stop cleanly.
3. On success: emit `✓ PR created: {pr_url}`

**GitLab** (`provider_name == "gitlab"`):

1. ToolSearch(`mcp__gitlab__create_merge_request`) — if found, call with equivalent fields.
2. Same duplicate and success handling.

**Jira / Plane**: emit `ℹ {Provider} does not host PRs — pushed only` and stop after Step 5.

**No provider detected** or **MCP tool not found**: emit `ℹ No PR created — {reason}` (reason: "provider not detected" or "MCP tool unavailable"). Print the push URL for manual PR creation.

### PR Body Spec

```markdown
{one-sentence summary derived from commit message}

{if ticket_id} Closes #{ticket_id}

---
https://claude.ai/code/session_01LGsHbjx8qnfDnarVyuzVdG
```

Use `Closes #<number>` format for GitHub (issue number). Use `Closes <ticket_id>` for GitLab.

## Help Block (`help ship`)

```
ship — commit, push, and create a PR in one command

  Stages all changes, generates a conventional commit message from the diff,
  confirms with you, commits, pushes, and creates a PR.

  Enriches the commit with a ticket ID parsed from the branch name or
  current_ticket in .project/config.yaml (if set).

  Works without .project/config.yaml — auto-detects provider from git remote.
  Skips PR creation for Jira and Plane (commit + push only).

  Options at confirmation:
    y        proceed
    e        edit the commit message
    n        abort — nothing is committed

  Examples:
    "ship"
    "commit and pr"
    "commit all changes"
```

## Edge Cases

| Condition | Behaviour |
|---|---|
| Clean working tree | Emit `Nothing to commit` and stop |
| Detached HEAD | Emit error and stop |
| Branch already has open PR | Emit existing PR URL, stop cleanly |
| Push fails (conflict / permissions) | Emit git error + guidance, stop |
| No provider detected | Commit + push; emit `ℹ No PR created — provider not detected` |
| MCP PR tool not in context | Commit + push; emit `ℹ No PR created — MCP tool unavailable` |
| No ticket ID resolvable | Commit without prefix; PR has no `Closes` line |

## Requirements

### Requirement: ship mode offers a recurring PR watch after creating a GitHub PR
After successfully creating a GitHub pull request (Step 6 of ship mode), the skill SHALL ask whether to start a recurring watch on that PR via the `/loop` skill. This offer SHALL only be made when a GitHub PR was just created — GitLab merge requests and Jira/Plane push-only flows are unaffected.

#### Scenario: Offer shown after successful GitHub PR creation
- **WHEN** ship mode successfully creates a GitHub PR and emits `✓ PR created: {pr_url}`
- **THEN** skill asks: `"Watch this PR for CI results and new comments until it's merged or closed? [y/n]"`

#### Scenario: Accepting the offer hands off to /loop
- **WHEN** user answers `y` to the watch offer
- **THEN** skill invokes the `/loop` skill with a prompt that re-enters `pr-watch` mode for this PR number, on the cadence `pr-watch` defines

#### Scenario: Declining the offer leaves ship mode unchanged
- **WHEN** user answers `n` to the watch offer
- **THEN** ship mode completes exactly as it did before this change — no watch is started, no state file is created

#### Scenario: Offer is skipped for non-GitHub flows
- **WHEN** ship mode completes a GitLab merge request, or a Jira/Plane push-only flow
- **THEN** no watch offer is shown

### Requirement: PR body includes an Evidence section and no session URL line
The PR body SHALL consist of the one-sentence summary, the `Closes` line when a ticket ID is known, and an `## Evidence` section produced per the `ship-evidence` capability. The hard-coded session URL line SHALL NOT be included.

#### Scenario: PR body contains Evidence
- **WHEN** `ship` creates a PR
- **THEN** the body contains an `## Evidence` section, even when it only reads `No evidence captured: {reason}`

#### Scenario: Session URL absent
- **WHEN** `ship` creates a PR
- **THEN** the body does not contain a `claude.ai/code/session` line

### Requirement: Confirmation step shows the evidence plan
Step 4 SHALL display the resolved evidence plan beneath the proposed commit and before `Proceed?`, so the user can abort before images or links are pushed.

#### Scenario: Aborting after seeing the plan
- **WHEN** the user answers `n` after the evidence plan is shown
- **THEN** nothing is committed, pushed, or committed to `pr-evidence`
