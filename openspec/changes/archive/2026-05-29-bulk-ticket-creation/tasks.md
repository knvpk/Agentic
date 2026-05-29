## 1. Mode Routing

- [x] 1.1 Add `bulk` to the mode routing table in `SKILL.md` (trigger words: "bulk", "generate tickets", "create tickets from docs", "populate backlog")
- [x] 1.2 Add `ticket new` breakdown detection step to `## MODE: ticket → Sub-mode: ticket new` before Step 1 (Collect input)
- [x] 1.3 Add `ticket new` breakdown detection to the shared Query Normalization section — wide-scope inputs route to mini-bulk flow before single-ticket creation

## 2. bulk Mode — Core Section

- [x] 2.1 Write `## MODE: bulk` section in `SKILL.md` with step-by-step flow: read docs → generate candidates → dedup → sort → display manifest
- [x] 2.2 Define the section-to-ticket-type mapping table within the bulk mode section (all doc files, section headers, resulting types)
- [x] 2.3 Define dependency ordering rules: scaffold/migration before feature/task when component/entity name matches
- [x] 2.4 Write deduplication step: call `list_tickets`, compute word-overlap, flag matches as `⚠ possible duplicate of #<id>`, uncheck by default
- [x] 2.5 Write dedup failure fallback: emit warning in manifest header, proceed with all candidates checked

## 3. Ticket Breakdown Detection

- [x] 3.1 Write the three scope-width signal definitions inline in the `ticket new` sub-mode (conjunction signal, plural area signal, docs breadth signal)
- [x] 3.2 Define the known domain area word list in the signal definition (auth, users, payments, notifications, settings, admin, reporting, search, onboarding)
- [x] 3.3 Define the specific action verb exclusion list that prevents the plural area signal from triggering (create, delete, update, refresh, fetch, display)
- [x] 3.4 Write the breakdown offer prompt: "I see enough scope here for multiple tickets — propose a breakdown? [y/n]"
- [x] 3.5 Define the decline path: on `n`, skip to normal single-ticket creation with original input unchanged

## 4. Manifest Review UX

- [x] 4.1 Write the manifest table format spec in `SKILL.md` (row number, check state, title, type, epic columns; grouped by epic)
- [x] 4.2 Define all edit commands with syntax and effect: skip, keep only, check, rename, merge, type, create
- [x] 4.3 Write the merge command flow: prompt user to confirm or override merged title before re-displaying manifest
- [x] 4.4 Write the invalid command fallback: output help line listing all valid commands, re-display manifest unchanged
- [x] 4.5 Write the `create` confirmation step: echo final checked list + count, ask "Confirm? [y/n]" before any MCP calls
- [x] 4.6 Write per-ticket creation acknowledgement: "✓ Created: <title> (#<id>)" on success, "✗ Failed: <title> — <error>" on failure, continue regardless

## 5. Post-Create Offers

- [x] 5.1 Write sprint assignment offer after bulk create (check for `active_sprint` in config; if absent, skip silently)
- [x] 5.2 Write epic label creation offer: derive epic slugs from manifest epic groups, call `create_label` for missing ones, then `add_label` for each ticket in the epic group

## 6. Manifest Header

- [x] 6.1 Write the manifest header format: "Found N ticket candidates from <file list> (dedup: M existing tickets checked)" or "⚠ Dedup skipped — could not reach tracker"

## 7. ticket-content-generation Integration

- [x] 7.1 Update the `ticket new` body generation instructions in `SKILL.md` to note that body generation is also invoked from manifest rows, using the manifest row's title + type + source doc section as input
- [x] 7.2 Ensure the `## Context` block instruction specifies: for manifest-sourced tickets, include `> Derived from <doc file> §<section>` as the first context reference

## 8. Skill Frontmatter

- [x] 8.1 Update `SKILL.md` frontmatter `description` field to mention the `bulk` mode
- [x] 8.2 Update the mode routing table at the top of `SKILL.md` to include the `bulk` trigger row
