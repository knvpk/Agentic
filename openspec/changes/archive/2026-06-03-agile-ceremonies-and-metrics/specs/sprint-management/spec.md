## ADDED Requirements

### Requirement: sprint plan is a new sub-mode of sprint
The `sprint plan` sub-mode SHALL be triggered by input matching: "plan sprint", "sprint planning", "sprint plan". It SHALL follow the behaviour defined in the `sprint-ceremonies` capability: fetch DoR-checked backlog candidates ranked by priority, present them for selection, and add selected tickets to the active sprint.

#### Scenario: sprint plan is routed correctly
- **WHEN** user inputs "sprint plan" or "plan sprint"
- **THEN** skill routes to the sprint plan sub-mode, not to any other sprint sub-mode

### Requirement: sprint review is a new sub-mode of sprint
The `sprint review` sub-mode SHALL be triggered by input matching: "sprint review", "review sprint", "what shipped". It SHALL follow the behaviour defined in the `sprint-ceremonies` capability.

#### Scenario: sprint review is routed correctly
- **WHEN** user inputs "sprint review" or "what shipped"
- **THEN** skill routes to sprint review

### Requirement: sprint retro is a new sub-mode of sprint
The `sprint retro` sub-mode SHALL be triggered by input matching: "sprint retro", "retrospective", "retro". It SHALL follow the behaviour defined in the `sprint-ceremonies` capability.

#### Scenario: sprint retro is routed correctly
- **WHEN** user inputs "sprint retro" or "retrospective"
- **THEN** skill routes to sprint retro

### Requirement: sprint close is a new sub-mode of sprint
The `sprint close` sub-mode SHALL be triggered by input matching: "sprint close", "close sprint", "end sprint", "finish sprint". It SHALL follow the behaviour defined in the `sprint-ceremonies` capability, including appending to `velocity_log` and clearing `active_sprint`.

#### Scenario: sprint close is routed correctly
- **WHEN** user inputs "sprint close" or "close sprint"
- **THEN** skill routes to sprint close

#### Scenario: sprint close intent routing does not conflict with sprint create
- **WHEN** user inputs "close sprint"
- **THEN** skill routes to sprint close, not sprint create
