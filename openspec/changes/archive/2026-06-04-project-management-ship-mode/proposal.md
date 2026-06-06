## Why

The project-management skill orchestrates the full ticket lifecycle — from creation through sprint management — but stops short of the final step: shipping work. After implementing a ticket, developers must manually stage changes, write a commit message, push, and create a PR, none of which are connected to the active ticket or configured provider. This is repetitive, context-switching, and error-prone.

## What Changes

- **New mode `ship`**: a single command that stages all changes, generates a conventional commit message from the diff, confirms with the user, commits, pushes, and creates a PR against the configured base branch.
- **Ticket-prefix enrichment**: when a ticket ID can be inferred (from branch name first, then `current_ticket` in config), the commit message is prefixed with the ID (`TICK-42: …`) and the PR is linked back to the issue.
- **Standalone operation**: works with no `.project/config.yaml` — auto-detects provider from git remote; still creates the PR if the provider supports it.
- **PR provider awareness**: creates PRs for GitHub (`mcp__github__create_pull_request`) and GitLab (`mcp__gitlab__create_merge_request`); skips PR creation for Jira and Plane (commit + push only).

## Capabilities

### New Capabilities

- `ship`: commit, push, and PR creation in one command — with auto-generated commit message, ticket-prefix enrichment, and confirmation step.

### Modified Capabilities

- `help-index`: updated general help index to include `ship` in the DAILY WORKFLOW section.
- `mode-routing`: new routing entries for `ship`, `commit`, `commit and pr`, `push and pr`, `ship my changes`.

## Impact

- `skills/project-management/SKILL.md`: one new mode (`ship`), two routing table rows, one help index entry, one `help ship` Variant B block.
- No changes to `.project/config.yaml` schema — `ship` reads existing keys (`base_branch`, `current_ticket`) but adds none.
- No changes to `references/providers.json` — provider MCP prefix resolution already exists.
- No breaking changes — purely additive.
