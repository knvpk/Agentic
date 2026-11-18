## ADDED Requirements

### Requirement: ship mode offers a recurring PR watch after creating a GitHub PR
After successfully creating a GitHub pull request (Step 6 of ship mode), the skill SHALL ask whether to start a recurring watch on that PR via the `/loop` skill. This offer SHALL only be made when a GitHub PR was just created — GitLab merge requests and Jira/Plane push-only flows are unaffected.

#### Scenario: Offer shown after successful GitHub PR creation
- **WHEN** ship mode successfully creates a GitHub PR and emits `✓ PR created: {pr_url}`
- **THEN** skill asks: `"Watch this PR for CI results and new comments until it's merged or closed? [y/n]"`

#### Scenario: Accepting the offer hands off to /loop
- **WHEN** user answers `y` to the watch offer
- **THEN** skill invokes the `/loop` skill with a prompt that re-enters `pr-watch` mode for this PR number, on the cadence `pr-watch` defines

#### Scenario: Declining the offer leaves ship mode unchanged
- **WHEN** user answers `n` to the watch offer
- **THEN** ship mode completes exactly as it did before this change — no watch is started, no state file is created

#### Scenario: Offer is skipped for non-GitHub flows
- **WHEN** ship mode completes a GitLab merge request, or a Jira/Plane push-only flow
- **THEN** no watch offer is shown
