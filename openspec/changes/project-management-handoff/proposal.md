## Why

When `project-management start` hands a ticket to `opsx:explore`, the model sometimes edits code directly and never creates an OpenSpec change. The handoff is prose-only: explore has no required exit, `linked_issue` is written "after the session ends" by no one in particular, and the fallback menu offers "Start implementing now". Without a change, `sync archive` has nothing to post to the ticket. This must be fixed before `start` can be chained into an autonomous `next → PR` flow.

## What Changes

- `start` creates the OpenSpec change shell (with `linked_issue` and `base_ref`) itself, before invoking explore, so the handoff is a file on disk rather than a post-hoc check.
- Explore invoked from `start` must end with a structured verdict: `ready` or `needs-input`. A question is blocking only if its answer would change scope, design, or a spec scenario; all other uncertainty is recorded as an explicit assumption in `design.md`.
- `needs-input` stops the ticket's pipeline: questions are written to the change's `design.md` (Open Questions), posted as a ticket comment, and the change is marked `awaiting-answers`. Re-running `start <ticket>` resumes from there.
- A PreToolUse hook blocks `Edit`/`Write` on a ticket-named branch when no change with a matching `linked_issue.id` exists.
- The no-`opsx:explore` fallback drops "Start implementing now" and offers "create a change" instead.
- **BREAKING**: `start`'s explore invocation prompt changes from open-ended ("Let's think through…") to a contract with a mandatory verdict; the post-explore `linked_issue` backfill step is removed.

## Capabilities

### New Capabilities
- `explore-handoff-contract`: change shell creation at start, explore verdict (`ready` / `needs-input`), blocking-vs-assumption rule, `awaiting-answers` stop and resume.
- `change-edit-guard`: PreToolUse hook that blocks edits on a ticket branch without a linked change.

### Modified Capabilities
- `targeted-ticket-start`: "start mode invokes opsx:explore with assembled context" gains the change shell, verdict contract, and a revised fallback.

## Impact

- `skills/project-management/SKILL.md`: MODE: start Steps 2h/5a/5b, plus help text for `start`.
- New hook script and settings snippet (location decided in design.md).
- Specs: `targeted-ticket-start` (modified); two new specs.
- Foundation for the follow-up change `project-management-auto` (orchestrator, merge mode), which depends on the verdict and `awaiting-answers` state.
