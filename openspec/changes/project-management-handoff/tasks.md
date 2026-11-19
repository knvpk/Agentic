## 1. Change shell at start

- [x] 1.1 In `skills/project-management/SKILL.md` MODE: start, add a step after the gate/branch resolution that runs `openspec new change "<ticket-id>-<slug>"` and writes `linked_issue` + `base_ref` into `.openspec.yaml`
- [x] 1.2 Handle the gate-declined path (shell created, no branch) and the existing-change path (reuse, no second change)
- [x] 1.3 Remove the Step 5a post-explore `linked_issue` backfill block

## 2. Explore verdict contract

- [x] 2.1 Rewrite the Step 5a explore prompt to require `## Verdict`, `## Assumptions`, and `## Open Questions` in `design.md`
- [x] 2.2 Add the blocking-vs-assumption definition to the skill
- [x] 2.3 Add the post-explore verdict check with a single re-prompt when `## Verdict` is missing

## 3. needs-input stop and resume

- [x] 3.1 On `needs-input`: post one ticket comment with blocking questions via the provider write path, set `status: awaiting-answers` in `.openspec.yaml`, and stop
- [x] 3.2 On `start <ticket>` with a matching `awaiting-answers` change: skip transition/branch, fold answers into `design.md`, re-evaluate the verdict, clear the status when `ready`

## 4. Fallback

- [x] 4.1 Replace "Start implementing now" in Step 5b with "create a change for this ticket" and update the matching `help start` text

## 5. Edit guard

- [x] 5.1 Add `skills/project-management/scripts/require-change.sh` (branch ticket-id extraction, active-change `linked_issue.id` match, allow `openspec/changes/` paths and non-ticket branches)
- [x] 5.2 Document the PreToolUse hook settings snippet in the `start` section; confirm `start` never writes settings
- [x] 5.3 Test the script against: no change (blocked), linked change (allowed), archived-only (blocked), artifact path (allowed), `main` (allowed)

## 6. Verify

- [x] 6.1 Run `openspec validate project-management-handoff` and fix any spec format errors
- [ ] 6.2 Dry-run `start` on a sample ticket and confirm the change shell exists before explore and that a `needs-input` verdict stops and resumes
