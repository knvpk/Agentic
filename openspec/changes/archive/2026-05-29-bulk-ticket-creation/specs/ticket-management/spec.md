## Purpose

Delta spec for the existing `ticket-management` capability. The `ticket new` sub-mode gains a pre-creation scope-width check that can route to the breakdown manifest flow.

## MODIFIED Requirements

### Requirement: Ticket create requires title and at least one label or sprint assignment
The skill SHALL NOT create a ticket with only a title. At minimum, a label or sprint/milestone assignment is required.

Before prompting for label/sprint information, the skill SHALL evaluate the input against the scope-width signals defined in the `ticket-breakdown-detection` capability. If any signal is true, the skill SHALL offer a breakdown. Only if the user declines the breakdown offer (or no signal is true) SHALL the skill continue with the single-ticket creation flow.

#### Scenario: Bare title ticket creation is refused
- **WHEN** user asks to create ticket with only "Fix login bug" and no other context
- **THEN** skill prompts for at least a label or sprint before creating

#### Scenario: Wide-scope input triggers breakdown offer before label prompt
- **WHEN** user asks to create a ticket for "user authentication system"
- **THEN** the scope-width check runs BEFORE the label/sprint prompt
- **AND** the skill offers a breakdown: "I see enough scope here for multiple tickets — propose a breakdown? [y/n]"
- **AND** the label/sprint prompt is shown only if user declines breakdown

#### Scenario: Narrow-scope input skips breakdown check and proceeds normally
- **WHEN** user asks to create a ticket for "add retry logic to token refresh endpoint"
- **THEN** no scope-width signal is triggered
- **AND** the skill proceeds directly to the label/sprint prompt as before
