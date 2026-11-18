## ADDED Requirements

### Requirement: Scenario generation is seeded for the extended project types
For `qa`, `ai`, `bi`, `cli`, and `library` the skill SHALL include 2–3 seed BDD patterns as vocabulary context, with the same guidance-not-copy rule as other types:

- **cli:** `GIVEN an unknown flag / WHEN the command runs / THEN usage is printed to stderr and exit code is 2`; `GIVEN stdin is piped / WHEN run non-interactively / THEN no prompt appears and input is consumed`; `GIVEN --json / WHEN the command succeeds / THEN stdout is valid JSON and logs go to stderr`
- **library:** `GIVEN a consumer calls a deprecated function / WHEN executed / THEN a deprecation warning names the replacement`; `GIVEN a minor release / WHEN a consumer upgrades / THEN existing public calls behave unchanged`
- **ai:** `GIVEN a prompt with retrieved context / WHEN the model answers / THEN the answer is grounded in the context and cites its source`; `GIVEN an unsafe input / WHEN the guardrail evaluates / THEN the request is refused with an explanation`; `GIVEN the eval set / WHEN run on the change / THEN the score is at or above the threshold`
- **bi:** `GIVEN a metric definition / WHEN the dashboard loads / THEN the value equals the source-of-truth query`; `GIVEN a stale source / WHEN data is older than its freshness limit / THEN the dashboard flags it`
- **qa:** `GIVEN a clean environment / WHEN the suite runs / THEN all tests pass without retries`; `GIVEN a flaky test / WHEN it fails intermittently / THEN it is quarantined with a linked ticket`

#### Scenario: cli ticket uses exit-code vocabulary
- **WHEN** a ticket is created on a project with `project_type: cli`
- **THEN** the generated `## Scenarios` contains at least one scenario referencing exit codes, flags, or stdout/stderr

#### Scenario: Seeds guide vocabulary not content
- **WHEN** a qa ticket is created for "checkout flow suite"
- **THEN** scenarios address the checkout flow, not verbatim copies of the seeds
