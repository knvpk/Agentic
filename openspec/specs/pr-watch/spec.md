## Purpose
Defines `pr-watch`, a recurring `/loop`-driven mode that watches a single GitHub pull request for CI status changes and new comments until it is merged or closed. It only reports findings — it never acts on them.

## Requirements

### Requirement: watch checks GitHub Actions run status and PR comments each tick
On each invocation (one `/loop` tick), the skill SHALL fetch the PR's current GitHub Actions run status for its head commit and any PR comments — review and issue comments — created since the last tick, using the stored state for that PR.

#### Scenario: CI status fetched for head commit
- **WHEN** a watch tick runs for PR #42
- **THEN** skill fetches the GitHub Actions run status for PR #42's current head commit

#### Scenario: Only new comments considered
- **WHEN** PR #42 has 12 comments and 9 were already seen on a prior tick
- **THEN** only the 3 new comments are evaluated this tick

### Requirement: watch persists last-seen state across ticks
The skill SHALL persist, per watched PR, the last-seen CI run ID and the last-seen comment ID in a state file at `.project/pr-watch/<pr-number>.yaml`, so state survives across separate `/loop` ticks and session restarts.

#### Scenario: State written after a tick with new findings
- **WHEN** a tick observes a new CI run or new comments
- **THEN** skill updates `.project/pr-watch/<pr-number>.yaml` with the latest run ID and comment ID before the tick ends

#### Scenario: State read at the start of each tick
- **WHEN** a new tick starts for PR #42
- **THEN** skill reads the existing state file for PR #42 to determine what's already been reported, rather than re-reporting the same CI run or comment

### Requirement: watch reports findings but takes no action on them
When a CI run fails or a new comment is found, the skill SHALL summarize it to the user and SHALL NOT push commits, reply to comments, re-run jobs, or otherwise act on the finding automatically.

#### Scenario: CI failure reported, not fixed
- **WHEN** the watch detects a failed GitHub Actions run on PR #42
- **THEN** skill reports the failure (run name, failing job, link) and takes no further action — no commit, no re-run trigger

#### Scenario: New comment reported, not replied to
- **WHEN** the watch detects a new review comment on PR #42
- **THEN** skill reports the comment's author and body and takes no further action — no automatic reply

### Requirement: watch stops when the PR is merged or closed
Each tick SHALL check the PR's state. If merged or closed, the skill SHALL report the outcome and end the loop rather than scheduling another tick.

#### Scenario: Merged PR ends the watch
- **WHEN** a tick finds PR #42 has been merged
- **THEN** skill reports `✓ PR #42 merged — watch ending` and ends the loop with no further ticks scheduled

#### Scenario: Closed-without-merge PR ends the watch
- **WHEN** a tick finds PR #42 has been closed without merging
- **THEN** skill reports `PR #42 closed without merging — watch ending` and ends the loop

#### Scenario: Open PR with no new findings schedules the next tick
- **WHEN** a tick finds PR #42 still open, CI unchanged, and no new comments
- **THEN** skill reports a quiet/no-op tick per `/loop`'s own convention and schedules the next tick

### Requirement: watch is GitHub-only in this change
The skill SHALL only offer and run this watch for GitHub-hosted PRs. GitLab merge request pipelines are explicitly out of scope for this change.

#### Scenario: GitLab merge requests are not watched
- **WHEN** ship mode completes a GitLab merge request
- **THEN** no watch offer is made and no `pr-watch` state file is created

### Requirement: Tick report surfaces the test-report link when CI completes
When a tick observes that the head commit's CI run has completed on a project whose evidence plan includes `link`, the report SHALL include the resolved test-report URL (or the CI run URL when no published report is resolvable). The tick SHALL NOT edit the PR body or comment on the PR.

#### Scenario: Completed run reports the link
- **WHEN** a tick finds PR #42's CI run completed and the project is `qa` with a detected Allure Pages report
- **THEN** the tick output includes the Pages report URL

#### Scenario: PR is not modified
- **WHEN** a tick reports a report link
- **THEN** the PR body and comments are unchanged
