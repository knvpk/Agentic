# Tasks

## [x] T1 — Add routing phrases to Mode Routing table

**File**: `skills/project-management/SKILL.md`
**Section**: `## Mode Routing`

Add these rows to the routing table:

| User says | Mode |
|-----------|------|
| `"release notes"`, `"release this"`, `"generate release notes"` | **release-notes** |
| `"release notes for uat"`, `"release candidate"` | **release-notes** (UAT framing) |
| `"release notes for prod"`, `"release to production"`, `"release notes for production"` | **release-notes** (PROD framing) |

**Verify**: routing table has three new rows for release-notes.

---

## [x] T2 — Add `release-notes` entry to help Variant A index

**File**: `skills/project-management/SKILL.md`
**Section**: `## MODE: help` → Variant A → DAILY WORKFLOW block

Add after the `ship` line:
```
  release-notes  Generate release notes from git tags (prev-tag → current-tag)
```

Also update the unknown mode fallback list at the bottom of Variant B to include `release-notes`.

**Verify**: `help` output lists `release-notes` under DAILY WORKFLOW.

---

## [x] T3 — Add `help release-notes` block to Variant B

**File**: `skills/project-management/SKILL.md`
**Section**: `## MODE: help` → Variant B — after the `help ship` block

Insert:

````
**`help release-notes`**
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
````

**Verify**: `help release-notes` outputs the block above.

---

## [x] T4 — Implement `## MODE: release-notes` section

**File**: `skills/project-management/SKILL.md`
**Location**: After `## MODE: ship` (end of file)

Implement the full mode as specified in `specs/release-notes-mode/spec.md`. The section must include:

- Step 1: Verify on a tag (`git describe --exact-match --tags HEAD`)
- Step 2: Find previous tag with semver sort (`git tag --sort=-version:refname`), first-release fallback
- Step 3: Collect commits (`git log {prev}..{current} --format="%H %s"`)
- Step 4: Extract ticket references (four patterns, deduplicate, cap at 50)
- Step 5: Fetch ticket titles via provider MCP (degrade gracefully on failure)
- Step 6: Group by first non-state label; unlabelled group
- Step 7: Apply environment framing from user qualifier
- Step 8: Build release body (markdown format with label groups + Other section)
- Step 9: Publish — GitLab Release (MCP → REST → print fallback) or `docs/release_notes/{tag}.md`
- Step 10: Summary output line

**Verify**: Section exists in SKILL.md after `## MODE: ship`; all 10 steps present; GitLab write path uses the same resolution pattern as other GitLab writes in the skill.

---

## [x] T5 — Document optional `release` config block

**File**: `skills/project-management/SKILL.md`
**Location**: Within the `## MODE: release-notes` section (Step 9 or a config note subsection)

Document that `.project/config.yaml` accepts an optional `release` key:

```yaml
release:
  include_unlinked_commits: true   # default true; set false to omit "Other" section
```

No schema file changes required — the config schema is validated by init, not by a JSON schema file in this skill.

**Verify**: Config block documented in the mode section.
