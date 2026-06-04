## Context

The project-management skill (`skills/project-management/SKILL.md`) is a provider-agnostic skill supporting GitHub, GitLab CE/EE, Jira, and Plane. It uses `.project/config.yaml` for provider config, active sprint state, and optional keys. Provider write operations resolve through an MCP → CLI → REST fallback chain. The skill already creates branches (in `start` mode) and references ticket IDs in branch names.

The `ship` mode will be the final step in the daily workflow loop:
```
next → start → [implement] → ship
```

## Goals / Non-Goals

**Goals:**
- Stage all changes, generate a commit message from the diff, confirm, commit, push, create PR
- Infer ticket ID from branch name (pattern: `feat/TICK-42-…`, `TICK-42-…`, `fix/TICK-42/…`)
- Fall back to `current_ticket` key in `.project/config.yaml` if branch parse fails
- Work standalone with no config (auto-detect provider from git remote)
- Create PRs for GitHub and GitLab; skip PR step for Jira and Plane
- Use `base_branch` from config if set, otherwise default to `main`

**Non-Goals:**
- Amending previous commits
- Interactive staging (partial hunks)
- Force-pushing
- Multi-commit PR workflows

## Decisions

### 1. Commit message generation from diff

Reading the diff and deriving intent is more useful than listing changed files. The skill will:
1. Run `git diff HEAD` (includes staged + unstaged)
2. Inspect changed file paths to classify the conventional commit type: `feat` for new files in feature areas, `fix` for bug-related diffs, `chore` for config/tooling, `docs` for docs-only
3. Derive a short title (≤72 chars) from the ticket title (if available) or the most significant change in the diff
4. If a ticket ID is known, prefix: `TICK-42: feat: add JWT token refresh endpoint`

Fallback: if diff is too large or ambiguous, generate a generic message and always show the confirmation step so the user can edit.

### 2. Ticket ID resolution — branch first, config fallback

Branch-name parsing requires no setup and works in any workflow. Config key `current_ticket` is written by `start` mode for users who use the full loop.

Resolution order:
1. Parse current branch name for pattern `[A-Z]+-\d+` (e.g. `feat/TICK-42-auth` → `TICK-42`)
2. If no match, read `current_ticket` from `.project/config.yaml`
3. If neither, commit without prefix; PR has no issue link

### 3. Provider detection without config

When `.project/config.yaml` is absent:
1. Run `git remote get-url origin`
2. Match against known hostname patterns (same as `init` mode Step 2a)
3. Use matched provider's `mcp_prefix` for PR creation
4. If no match or MCP unavailable → commit + push only; emit `ℹ No PR created — provider not detected`

### 4. Confirmation step

Always show the proposed commit message and PR title before acting. User options: `y` (proceed), `e` (edit message inline), `n` (abort). This prevents silent bad commits.

### 5. PR body auto-generation

PR body contains:
- One-paragraph summary derived from the commit message
- Link to the ticket if ID was resolved: `Closes #42` (GitHub) or `Closes TICK-42` (GitLab)
- The session link appended per repository convention

### 6. PR creation tool selection

| Provider | PR/MR tool | Skip condition |
|---|---|---|
| GitHub | `mcp__github__create_pull_request` | — |
| GitLab | `mcp__gitlab__create_merge_request` | — |
| Jira | none | skip PR, emit `ℹ Jira does not host PRs — pushed only` |
| Plane | none | skip PR, emit `ℹ Plane does not host PRs — pushed only` |

If the MCP tool is missing (ToolSearch returns nothing), fall back to printing the push URL and instructions, not an error.

## Risks / Trade-offs

- **Large diffs**: message quality degrades on large diffs. Mitigated by always showing the confirmation/edit step.
- **Detached HEAD**: `git push` will fail. The skill will detect this and emit a clear error rather than a generic git failure.
- **Nothing to commit**: `git status` shows clean tree. The skill will detect and emit `Nothing to commit — working tree clean` and stop.
- **Branch already has open PR**: `create_pull_request` will fail with a duplicate error. The skill catches this, emits the existing PR URL, and stops cleanly.

## Open Questions

- Should `ship` also transition the ticket from `in-progress` to `in-review` automatically? (Out of scope for v1 — keep ship focused on git/PR; let `ticket update` handle state.)
