## ADDED Requirements

### Requirement: backlog refine fetches unestimated tickets from the backlog and walks through them one at a time
The skill SHALL fetch all tickets in the `backlog` or `todo` state that have no story-point estimate (i.e., no numeric value in the estimate field), present them one at a time in priority order, and prompt the user for a story-point estimate for each. The user MAY skip a ticket by entering `s` or `skip`. After the session the skill SHALL report how many tickets were estimated.

#### Scenario: Unestimated tickets presented in priority order
- **WHEN** user invokes `backlog refine` and 4 unestimated tickets exist
- **THEN** tickets are shown one at a time starting from highest priority

#### Scenario: Story point entry saves estimate to provider
- **WHEN** user enters `5` for a ticket
- **THEN** skill updates the ticket's estimate field via the provider MCP tool and advances to the next ticket

#### Scenario: Skip bypasses the ticket without modifying it
- **WHEN** user enters `skip` or `s` for a ticket
- **THEN** skill moves to the next ticket without calling any update API

#### Scenario: Session summary shown at end
- **WHEN** user has gone through all presented tickets
- **THEN** skill outputs `Refined: 3 estimated, 1 skipped, 0 remaining`

#### Scenario: No unestimated tickets produces a clear message
- **WHEN** all backlog/todo tickets already have estimates
- **THEN** skill outputs `All backlog tickets are estimated — nothing to refine`

### Requirement: backlog refine checks Definition of Ready for each ticket
For each ticket presented during refinement, the skill SHALL evaluate DoR criteria: (1) non-empty description, (2) at least one label. If either criterion fails, the skill SHALL display a `⚠ Not ready` indicator alongside the ticket and list the failing criteria. The user may still provide an estimate; the DoR warning is informational only.

#### Scenario: Ticket with empty description is flagged
- **WHEN** a ticket has no description
- **THEN** refine shows `⚠ Not ready: missing description` before the estimate prompt

#### Scenario: Ticket with no labels is flagged
- **WHEN** a ticket has no labels
- **THEN** refine shows `⚠ Not ready: no labels assigned`

#### Scenario: DoR-passing ticket shows no warning
- **WHEN** a ticket has both a description and at least one label
- **THEN** no warning is shown and the estimate prompt is presented cleanly

### Requirement: backlog refine shows ticket context to aid estimation
When presenting each ticket, the skill SHALL display the ticket ID, title, description (truncated to 200 characters if longer), current labels, and any existing relationships (blocked-by, parent). This gives the user enough context to estimate without opening the tracker.

#### Scenario: Full context shown per ticket
- **WHEN** user is refining TICK-42
- **THEN** output shows ID, title, truncated description, labels, and any blocked-by relationships before the estimate prompt

#### Scenario: Long description is truncated
- **WHEN** description exceeds 200 characters
- **THEN** only the first 200 characters are shown followed by `…`
