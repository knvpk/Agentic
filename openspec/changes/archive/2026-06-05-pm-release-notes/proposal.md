## Why

The `project-management` skill has no way to generate release notes. Teams using a tag-based deployment pipeline (tag → UAT, promote tag → PROD) need release notes automatically derived from what changed between two git tags, without manually curating changelogs.

## What Changes

- **`skills/project-management/SKILL.md`** — adds a new `release-notes` mode with routing phrases, tag detection logic, commit parsing, ticket fetching, label-based grouping, and environment voice framing
- **Mode Routing table** — new rows for `"release notes"`, `"release this"`, `"generate release notes"`, and env-qualified variants
- **Help index (Variant A)** — new `release-notes` entry under DAILY WORKFLOW
- **Help block (Variant B)** — new `help release-notes` block
- **Config schema** — optional `release.include_unlinked_commits` boolean (default `true`)

## Capabilities

### New Capabilities

- `release-notes-generation`: Generates ticket-level release notes by diffing two semver git tags, grouping closed tickets by label, and publishing to GitLab Release (when provider is GitLab) or writing to `docs/release_notes/{tag_name}.md` (all other providers)

### Modified Capabilities

- `skill-definition`: Mode Routing table and help index updated to include the new mode

## Impact

- `skills/project-management/SKILL.md`
