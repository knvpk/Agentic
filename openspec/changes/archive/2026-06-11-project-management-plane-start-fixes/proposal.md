## Why

The `project-management` skill has two clusters of bugs that silently break real workflows:

**Start mode does not transition state**: When `start TICK-n` is run on a ticket in `backlog` state (the default for all newly created Plane tickets), the skill warns but never calls `update_ticket`. The ticket stays in Backlog. On Plane this affects every ticket — Plane always creates issues in Backlog. Additionally, even for the `todo` path that does call `update_ticket`, GitLab and GitHub transitions are missing the label-delta helper, so old state labels (e.g. `todo`) are never removed.

**Plane provider data is wrong**: The reference files and providers.json contain several inaccuracies verified against the current Plane API and pricing:
- Modules (epics) are available on the free plan; only the distinct *Epics work item type* (Plane Pro) requires a paid plan — the skill conflates the two
- The free plan allows only 1 active cycle at a time; this constraint is unmodelled
- The REST auth header is `X-API-Key` (uppercase) but the reference has `X-Api-Key`, silently failing all REST calls and forcing MCP-only path
- `state_mapping` stores `state_name` strings, but the Plane REST API requires a state **UUID** — there is no step to resolve names to UUIDs at init and cache them

## What Changes

- **`SKILL.md` — start mode Step 4**: extend the `backlog` branch to also offer the in-progress transition (WIP check + `update_ticket`); add provider-branching to Step 4 so GitLab/GitHub use the label-delta helper (matching `ticket update` behaviour)
- **`references/rest/plane.md`**: fix auth header to `X-API-Key`; add `list_states` endpoint; document state UUID requirement
- **`providers.json` — Plane entry**: fix `plan_variants.free.epics` → `true` (Modules are free); add `active_cycles_limit: 1` to `plan_variants.free`; fix `rest_config.auth_header` capitalisation; add `list_states` to `tool_contracts`; update `state_mapping` to note UUID lookup requirement
- **`references/plane.md`**: correct the plan feature table; add note about state UUID resolution; document 1-active-cycle free limit
- **`SKILL.md` — init Step 4 (Plane)**: add a `list_states` probe call that builds a `plane_state_ids` map (canonical → UUID) and stores it in `.project/config.yaml`

## Capabilities

### Modified Capabilities

- `start-mode-state-transition`: `backlog` state now triggers in-progress transition offer; label-delta applied for GitLab/GitHub
- `plane-provider-correctness`: auth header fixed; state UUIDs resolved at init; Modules correctly marked as free; cycle limit modelled

## Impact

- `skills/project-management/SKILL.md` — start mode Step 4; init Step 4 (Plane section)
- `skills/project-management/references/rest/plane.md`
- `skills/project-management/references/plane.md`
- `skills/project-management/references/providers.json`
