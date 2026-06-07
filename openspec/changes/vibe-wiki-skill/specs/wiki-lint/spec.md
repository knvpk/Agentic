## ADDED Requirements

### Requirement: Lint checks for orphan pages
`wiki lint` SHALL identify wiki pages with no inbound wikilinks from any other page. It SHALL list orphan node IDs and their paths, and suggest either linking them from a parent page or deleting them.

Affected files: `SKILL.md` (vibe_wiki)

#### Scenario: Orphan pages found
- **WHEN** lint runs and one or more pages have no inbound links
- **THEN** the skill reports each orphan with its path and asks if the user wants to link or remove each one

#### Scenario: No orphans
- **WHEN** every page has at least one inbound wikilink
- **THEN** lint reports "No orphans found" for this check

### Requirement: Lint checks for stub pages
`wiki lint` SHALL identify pages under a threshold line count (default: 5 lines of body content excluding frontmatter). These are stubs — created but not yet enriched.

Affected files: `SKILL.md` (vibe_wiki)

#### Scenario: Stub pages found
- **WHEN** lint runs and one or more pages have fewer than 5 lines of body content
- **THEN** the skill lists each stub and offers to enrich it or ingest a source for it

### Requirement: Lint checks for missing index entries
`wiki lint` SHALL compare all files under `wiki.root` node directories against entries in `index.md`. Any page not listed in `index.md` SHALL be flagged and the missing entry offered for addition.

Affected files: `SKILL.md` (vibe_wiki)

#### Scenario: Page missing from index
- **WHEN** a wiki page exists on disk but has no entry in `index.md`
- **THEN** lint flags it, shows the proposed `index.md` entry, and asks the user to confirm adding it

### Requirement: Lint appends a summary to log.md
After each lint run, the skill SHALL append a timestamped summary entry to `log.md` listing counts: pages checked, orphans found, stubs found, index gaps found.

Affected files: `SKILL.md` (vibe_wiki)

#### Scenario: Lint completes
- **WHEN** lint finishes all checks
- **THEN** an entry is appended to `log.md` in the format `## [<date>] lint | <N> pages, <N> orphans, <N> stubs, <N> index gaps`
