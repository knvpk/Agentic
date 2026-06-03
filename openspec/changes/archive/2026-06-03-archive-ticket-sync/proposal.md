## Why

When `opsx:archive` completes, the linked issue tracker ticket has no awareness of what was actually built. Engineers must manually summarise spec changes, code changes, and session conclusions back onto the ticket — this is skipped in practice, leaving tickets as stale snapshots of intent rather than living records of outcome.

Additionally, the explore workflow (`opsx:explore`, `project-management start`, or any ad-hoc session) surfaces decisions and conclusions in conversation that never reach the ticket. Even teams not using `opsx:explore` have this problem: code lands, the ticket stays unchanged.

## What Changes

- Add **linked issue tracking** to `.openspec.yaml` at change creation time — `opsx:new` (and `project-management start` when it invokes `opsx:new`) writes `linked_issue` (provider, project_ref, id, url) if a ticket context is in scope
- Add a **post-archive ticket sync step** to `opsx:archive` (step 7) that:
  1. Gathers three signal sources: spec diff, git diff, and current session thread
  2. Synthesises a human-readable summary of what changed and why
  3. Posts a comment on the linked issue (and related issues if signals reference them)
  4. Optionally appends new acceptance criteria to the ticket body if specs added requirements
- Update `opsx:explore` to offer a **"capture this"** prompt when conclusions crystallise, updating the linked ticket with decided scope changes, ruled-out items, or newly discovered requirements
- Degrade gracefully when there are no specs (git diff + thread only), no explore session (spec diff + git diff only), or no linked issue (skip silently, show summary in terminal only)

## Capabilities

### New Capabilities

- `archive-ticket-sync`: Post-archive signal gathering (spec diff + git diff + session thread) synthesised into a ticket comment and optional body update on the linked issue

### Modified Capabilities

- `opsx-archive`: Gains step 7 — linked issue sync after the archive move completes
- `opsx-new`: Stores `linked_issue` in `.openspec.yaml` when ticket context is available
- `opsx-explore`: Gains "capture this" offer that writes conclusions to the linked ticket
- `project-management-start`: Passes ticket context to `opsx:new` when invoking it so the link is persisted

## Impact

- `.claude/commands/opsx/archive.md` — add step 7 (signal gathering + ticket sync)
- `.claude/commands/opsx/new.md` — add linked_issue write to `.openspec.yaml` when ticket context present
- `.claude/commands/opsx/explore.md` — add "capture this" offer with ticket update path
- `skills/project-management/SKILL.md` — start mode passes ticket id/provider/url to `opsx:new`
- `openspec/specs/archive-ticket-sync/spec.md` — new capability spec
