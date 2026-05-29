## Purpose

Delta spec for the existing `ticket-content-generation` capability. Body generation (Summary, Context, Requirements, Scenarios, Use Cases, NFR, OpenSpec Hint) is now invoked per-ticket at create time from a manifest row, not only from direct `ticket new` conversational input.

## MODIFIED Requirements

### Requirement: Generated ticket body contains all six required sections
Every ticket created by the skill SHALL include: Summary, Context (derived from docs/), Requirements (SHALL statements), Scenarios (GIVEN/WHEN/THEN), Use Cases (actor + flow), Non-Functional Constraints, and an opsx hand-off hint.

This requirement now applies to tickets created through THREE entry points:
1. Direct `ticket new` conversational input (existing behavior).
2. `bulk` mode manifest creation — body is generated at create time per manifest row using the row's title, type, and source doc section as input.
3. `ticket new` breakdown manifest creation — same as bulk mode, scoped to matching doc sections.

For manifest-sourced tickets, the source doc section provides the primary context input in place of the conversational description. The Context block SHALL reference the originating doc section explicitly.

#### Scenario: Manifest-sourced ticket body contains all required sections
- **WHEN** a ticket is created from a bulk manifest row titled "Auth token silent refresh" sourced from `docs/prd.md §Features`
- **THEN** the generated body contains `## Summary`, `## Context`, `## Requirements`, `## Scenarios`, `## Use Cases`, `## Non-Functional`, and `## OpenSpec Hint`

#### Scenario: Context block references source doc section for manifest-sourced tickets
- **WHEN** a ticket is created from a manifest row sourced from `docs/architecture.md §Components — AuthService`
- **THEN** `## Context` contains: `> Derived from docs/architecture.md §Components — AuthService`

#### Scenario: New ticket body via direct input still contains all required sections
- **WHEN** a ticket is created via direct `ticket new` conversational input
- **THEN** the body contains all required sections (existing behavior unchanged)

#### Scenario: OpenSpec hint line is always present
- **WHEN** any ticket is created (via direct input, bulk manifest, or breakdown manifest)
- **THEN** the `## OpenSpec Hint` section contains a `/opsx:ff` command line referencing the ticket title
