## Why

The `next` mode recommends a ticket but leaves a cliff: the user must manually copy the ticket ID, update its state, and separately invoke `/issue-explore` or `/opsx:ff`. A direct `start <ticket-id>` trigger eliminates this friction by combining fetch, project-doc context loading, state transition, and exploration in one step — from within the already-configured project context.

## What Changes

- Add a new **`start` mode** to the `project-management` skill that accepts a ticket ID (bare number, `PROJ-42`, `#42`, or full URL)
- The `start` mode fetches the ticket via the already-configured MCP, loads project doc context (Context Fallback Chain), optionally transitions state to `in-progress`, optionally creates a branch, and invokes `opsx:explore`
- Update the `next` mode's output hint from the manual two-step (`/project-management ticket update … --state in-progress` + `/opsx:ff …`) to a single call: `/project-management start <id>`
- Add routing entry to the Mode Routing table for the new mode

## Capabilities

### New Capabilities
- `targeted-ticket-start`: Fetch a specific ticket by ID, enrich it with project doc context, handle state transition and branch creation, then invoke opsx:explore — all from within the project-management skill using its pre-configured provider

### Modified Capabilities
- `next-ticket-scheduler`: The recommendation output's "To start" hint must change from a two-line manual instruction to a single `/project-management start <id>` call

## Impact

- `skills/project-management/SKILL.md` — new mode section + routing table row + updated `next` output template
- No changes to provider references, config schema, or MCP tool contracts
- No new dependencies; reuses the existing Context Fallback Chain and `state_mapping` already defined in the skill
