# release-notes-mode

## Overview

Adds a `release-notes` mode to the `project-management` skill. Generates ticket-level release notes by diffing two semver git tags, groups resolved tickets by label, and publishes to GitLab Release or a markdown file depending on the configured provider.

## Trigger Phrases

The following phrases route to this mode (added to the Mode Routing table):

| User says | Route |
|-----------|-------|
| `"release notes"`, `"release this"`, `"generate release notes"` | **release-notes** (neutral framing) |
| `"release notes for uat"`, `"release candidate"` | **release-notes** (UAT framing) |
| `"release notes for prod"`, `"release to production"`, `"release notes for production"` | **release-notes** (PROD framing) |

## Mode Algorithm

### Step 1 — Verify on a tag

Run:
```
git describe --exact-match --tags HEAD
```

- **Success** → `current_tag` = output (e.g. `v1.2.0`)
- **Failure** → emit:
  ```
  ⚠ Not on a git tag — checkout the tag you want to release notes for and re-run.
  ```
  Stop. Do not generate notes.

### Step 2 — Find previous tag (semver-aware)

Run:
```
git tag --sort=-version:refname | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]'
```

This returns all semver tags sorted newest-first. Find `current_tag` in the list; take the next entry as `previous_tag`.

**First release fallback** — if `current_tag` is the only semver tag (no entry follows it):
```
previous_ref = git rev-list --max-parents=0 HEAD
```
Emit: `ℹ First release — ranging from initial commit.`

### Step 3 — Collect commits in range

Run:
```
git log {previous_tag_or_ref}..{current_tag} --format="%H %s"
```

Collect all commit hashes and subjects.

### Step 4 — Extract ticket references

For each commit subject, extract ticket IDs using these patterns (in priority order, all applied):

| Pattern | Example match | Notes |
|---------|--------------|-------|
| `[A-Z]+-\d+` | `PROJ-42`, `AUTH-7` | Jira/Plane/GitLab project keys |
| `(?:Closes?\|Fixes?\|Resolves?)\s+#(\d+)` | `Closes #42` | GitHub/GitLab closing keywords |
| `#(\d+)` | `#42` | Bare hash reference |
| Full issue URL | `https://github.com/org/repo/issues/42` | Extract numeric ID |

Deduplicate by ID. Cap at 50 unique IDs — emit `ℹ {N} ticket references found — showing first 50` if over limit.

Commits with no ticket reference are collected separately as `unlinked_commits` (their subjects only).

### Step 5 — Fetch ticket titles

For each unique ticket ID, call the provider's get-ticket tool:
- **GitHub**: `mcp__github__get_issue(issue_number)`
- **GitLab**: `mcp__gitlab__get_issue(iid)`
- **Jira**: Jira MCP get-issue tool from `tool_contracts` in `providers.json`
- **Plane**: Plane MCP get-issue tool from `tool_contracts` in `providers.json`

On success: record `{id, title, labels}`.
On failure (MCP error, timeout): record `{id, title: null, labels: []}` — do not block.

Emit: `Fetching {N} tickets…` before calls. After: `✓ {fetched}/{N} tickets resolved.`

### Step 6 — Group by label

Group tickets by their **first non-state label** (exclude state labels: `todo`, `in-progress`, `in-review`, `blocked`). Tickets with no qualifying label go into `Unlabelled`. Sort groups alphabetically. Within each group, list tickets in the order they appeared in the commit log.

### Step 7 — Apply environment framing

| Detected qualifier | Header |
|---|---|
| none | `Release {current_tag}` |
| `uat` | `Release Candidate {current_tag}` |
| `prod` / `production` | `Released {current_tag} to production` |

Qualifier is parsed from the user's original input (Step 0 of mode entry).

### Step 8 — Build release body

```markdown
## {header}

**Range**: {previous_tag_or_ref} → {current_tag}
**Tickets**: {total_fetched} resolved

### {Label Group} ({N} tickets)
- {TICK-30}: Auth token refresh
- {TICK-31}: Session expiry fix

### Unlabelled ({N} tickets)
- {TICK-38}: Update CHANGELOG

### Other
- chore: bump dependencies
- fix: typo in error message
```

Omit `### Other` section entirely if `release.include_unlinked_commits` is `false` in config, or if `unlinked_commits` is empty.

For tickets with `title: null` (fetch failed): format as `- {id}: (title unavailable)`.

### Step 9 — Publish

Determine publish target from `provider.name` in `.project/config.yaml`:

#### GitLab (`provider.name == "gitlab"`)

Write path resolution (same pattern as Shared: GitLab Write Path Resolution):

1. `ToolSearch("mcp__gitlab__create_release")` → if found, call:
   ```
   mcp__gitlab__create_release(
     project_id: gitlab_project_id,
     tag_name: current_tag,
     name: header,
     description: release_body
   )
   ```
2. `GITLAB_TOKEN` set → REST:
   ```
   POST /api/v4/projects/{gitlab_project_id}/releases
   { "tag_name": current_tag, "name": header, "description": release_body }
   ```
3. Both unavailable → print release body to terminal:
   ```
   ℹ Could not publish to GitLab — copy the release notes below and create manually.
   {release_body}
   ```

On success: `✓ GitLab Release created: {tag_name}`

#### All other providers

Write `docs/release_notes/{current_tag}.md`:
- Create `docs/release_notes/` directory if absent
- File content = release body (no YAML front matter)
- On write success: `✓ Release notes written: docs/release_notes/{current_tag}.md`

### Step 10 — Summary output

```
Release notes for {current_tag}
Range:   {previous_tag_or_ref} → {current_tag}
Tickets: {N} resolved across {G} groups
Published: {GitLab Release at {url} | docs/release_notes/{tag_name}.md}
```

## Config

Optional field in `.project/config.yaml`:

```yaml
release:
  include_unlinked_commits: true   # default: true; set false to omit ### Other section
```

All other behavior is derived from existing config fields (`provider.name`, `gitlab_project_id`).

## Help Block

Added to `help release-notes` (Variant B):

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

Added to help Variant A index under DAILY WORKFLOW:
```
  release-notes  Generate release notes from git tags (prev-tag → current-tag)
```

## Edge Cases

| Scenario | Behaviour |
|----------|-----------|
| Not on a tag | Emit warning, stop |
| No previous semver tag | Range from initial commit, emit notice |
| Zero commits in range | Emit `No commits between {prev} and {current}` and stop |
| All commits unlinked | Notes contain only `### Other` section |
| Tracker MCP unavailable | Degrade: include IDs without titles, continue |
| `docs/release_notes/` does not exist | Create it silently |
| GitLab Release for tag already exists | Emit `ℹ Release already exists for {tag_name} — skipping publish` and print body |
