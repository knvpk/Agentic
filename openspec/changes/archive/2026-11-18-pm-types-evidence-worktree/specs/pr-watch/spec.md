## ADDED Requirements

### Requirement: Tick report surfaces the test-report link when CI completes
When a tick observes that the head commit's CI run has completed on a project whose evidence plan includes `link`, the report SHALL include the resolved test-report URL (or the CI run URL when no published report is resolvable). The tick SHALL NOT edit the PR body or comment on the PR.

#### Scenario: Completed run reports the link
- **WHEN** a tick finds PR #42's CI run completed and the project is `qa` with a detected Allure Pages report
- **THEN** the tick output includes the Pages report URL

#### Scenario: PR is not modified
- **WHEN** a tick reports a report link
- **THEN** the PR body and comments are unchanged
