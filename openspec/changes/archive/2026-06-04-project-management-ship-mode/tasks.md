## 1. Mode Routing & Help

- [x] 1.1 Add `ship` trigger phrases to the Mode Routing table: `ship`, `ship my changes`, `commit and pr`, `commit and create pr`, `push and pr`, `commit all changes` → **ship**
- [x] 1.2 Add `ship` entry to the general help index (Variant A) under DAILY WORKFLOW section
- [x] 1.3 Add `help ship` Variant B block with the full help text from spec

## 2. Pre-routing Intercept (none needed — routing table covers it)

## 3. MODE: ship — Pre-flight

- [x] 3.1 Run `git status --porcelain`; if empty emit `Nothing to commit — working tree clean` and stop
- [x] 3.2 Run `git branch --show-current`; if empty emit `✗ Detached HEAD` error and stop
- [x] 3.3 Store `current_branch`

## 4. MODE: ship — Ticket ID Resolution

- [x] 4.1 Parse `current_branch` for pattern `[A-Z]+-\d+` (case-insensitive, first match)
- [x] 4.2 Fall back to `current_ticket` from `.project/config.yaml` if branch parse yields nothing
- [x] 4.3 Store `ticket_id` (null if no source)

## 5. MODE: ship — Provider Detection

- [x] 5.1 Read `provider.name` + `provider.mcp_prefix` from `.project/config.yaml` if present
- [x] 5.2 Otherwise parse `git remote get-url origin` and match hostname to provider
- [x] 5.3 Store `provider_name`, `mcp_prefix` (null if no match)

## 6. MODE: ship — Diff Analysis & Message Generation

- [x] 6.1 Run `git diff HEAD` and `git diff --name-only HEAD`
- [x] 6.2 Classify conventional commit type from changed file paths (fix / docs / chore / feat)
- [x] 6.3 Derive short title (≤60 chars): from ticket title if available, otherwise from diff summary
- [x] 6.4 Compose full commit message: `{ticket_id}: {type}: {title}` or `{type}: {title}`

## 7. MODE: ship — Confirmation Step

- [x] 7.1 Display proposed commit message, branch, and PR title
- [x] 7.2 Handle `y` → proceed
- [x] 7.3 Handle `e` → prompt for edited message, re-display, ask `[y/n]`
- [x] 7.4 Handle `n` → emit `Aborted` and stop

## 8. MODE: ship — Stage, Commit, Push

- [x] 8.1 Run `git add -A && git commit -m "{commit_message}"`
- [x] 8.2 Run `git push -u origin {current_branch}`
- [x] 8.3 On push failure: emit git error + guidance and stop

## 9. MODE: ship — PR Creation

- [x] 9.1 Determine `base_branch` from config (`base_branch` key) or default `main`
- [x] 9.2 GitHub: ToolSearch `mcp__github__create_pull_request`; call with title, body, head, base
- [x] 9.3 GitLab: ToolSearch `mcp__gitlab__create_merge_request`; call with equivalent fields
- [x] 9.4 Handle duplicate-PR error: extract existing PR URL, emit `ℹ PR already exists: {url}`, stop cleanly
- [x] 9.5 On success: emit `✓ PR created: {pr_url}`
- [x] 9.6 Jira / Plane: emit `ℹ {Provider} does not host PRs — pushed only`
- [x] 9.7 No provider / no MCP tool: emit `ℹ No PR created — {reason}`

## 10. PR Body

- [x] 10.1 Generate one-sentence PR body summary from commit message
- [x] 10.2 Append `Closes #{ticket_id}` line when ticket ID is known (GitHub: issue number; GitLab: ticket key)
- [x] 10.3 Append session URL footer per repo convention
