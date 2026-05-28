## Purpose
Defines how the skill probes and caches provider capability flags at init time, handles mid-session capability failures, and communicates fallback strategies to the user.

## Requirements

### Requirement: Skill probes provider capabilities via two-signal detection at init
At init, the skill SHALL use two signals to determine capability support: (1) whether the MCP tool exists (ToolSearch), and (2) whether a safe read call to that tool returns 200 or 403.

#### Scenario: ToolSearch miss triggers user prompt
- **WHEN** `ToolSearch("mcp__plane__list_modules")` returns no results
- **THEN** the skill cannot probe and asks the user whether epics are supported on their plan

#### Scenario: 200 response marks capability as supported
- **WHEN** `mcp__plane__list_cycles` is called and returns 200
- **THEN** `capabilities.sprints` is set to `true` in `.project/config.yaml`

#### Scenario: 403 response marks capability as unsupported
- **WHEN** `mcp__plane__list_modules` is called and returns 403
- **THEN** `capabilities.epics` is set to `false` in `.project/config.yaml`
- **AND** the fallback strategy from `providers.json` is activated for epics

### Requirement: Capability results are cached in .project/config.yaml after init
The skill SHALL write probed capability flags to `.project/config.yaml` under `provider.capabilities` with a `probed_at` timestamp.

#### Scenario: Subsequent invocations read from cache
- **WHEN** `.project/config.yaml` exists with a recent `probed_at`
- **THEN** the skill reads capabilities from cache without re-probing

#### Scenario: Cache contains probed_at timestamp
- **WHEN** init completes successfully
- **THEN** `.project/config.yaml` contains `provider.capabilities.probed_at` as an ISO-8601 datetime

### Requirement: Unexpected 403 mid-session triggers lazy re-probe for that feature
If a provider call returns 403 unexpectedly during normal operation, the skill SHALL re-probe that specific capability, update the cache, and retry the operation using the fallback strategy.

#### Scenario: Mid-session epic creation 403 triggers label fallback
- **WHEN** a ticket creation with `parent_id` returns 403 after init declared epics supported
- **THEN** the skill re-probes epics, updates `config.yaml` to `false`, and retries using the label fallback
- **AND** notifies the user: "Epic support not available, switched to label fallback"

### Requirement: User is always notified when a fallback strategy is active
The skill SHALL explicitly tell the user which fallback is in use whenever a capability gap is detected or activated.

#### Scenario: Label fallback notification on epic creation
- **WHEN** epics capability is false and user creates a parent ticket
- **THEN** skill outputs: "Plane free plan detected — using label `epic:{slug}` to simulate epic membership"

#### Scenario: init --probe forces re-detection ignoring cache
- **WHEN** user runs `/project-management init --probe`
- **THEN** the skill re-runs all capability probes and overwrites `.project/config.yaml`
