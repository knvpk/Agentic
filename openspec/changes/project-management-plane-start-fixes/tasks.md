## 1. Fix start mode Step 4 — backlog state transition

- [ ] 1.1 In `SKILL.md` start mode Step 4, replace the `backlog` row in the state transition table:

  **Current:**
  ```
  | `backlog` | Warn: "TICK-<id> is in backlog and not assigned to the active sprint. Continue anyway? [y/n]" |
  ```

  **Replace with:**
  ```
  | `backlog` | Ask: "TICK-<id> is in backlog (not assigned to the active sprint). Move to in-progress? [y/n]" → on Y run **WIP Limit Check**, then call `update_ticket` via the provider-specific path (see Step 4 provider branching below); on N proceed to Step 5 without transition |
  ```

- [ ] 1.2 Update the WIP Limit Check note below the table to cover the backlog path too:

  **Current:**
  > "WIP Limit Check in start mode: apply the same Shared: WIP Limit Check logic defined in `ticket update`. If user answers `n` to the WIP confirmation, output `Transition cancelled — continuing in exploration mode (ticket stays in todo).` and proceed to Step 5 without the state change."

  **Replace with:**
  > "WIP Limit Check in start mode: apply the same Shared: WIP Limit Check logic defined in `ticket update`. If user answers `n` to the WIP confirmation, output `Transition cancelled — continuing in exploration mode (ticket stays in current state).` and proceed to Step 5 without the state change. The `--no-branch` flag does NOT bypass the WIP check."

## 2. Fix start mode Step 4 — add provider branching for update_ticket call

- [ ] 2.1 In `SKILL.md` start mode Step 4, add a provider branching block immediately after the transition table and the WIP Limit Check note. Insert the following text:

  ```
  **Provider-specific transition call** (for todo→in-progress and backlog→in-progress transitions):
  - **GitHub, Jira, Plane**: use **Shared: Provider Write Path Resolution** to call `update_ticket` with the translated state from `state_mapping`.
  - **GitLab**: use **Shared: Provider Write Path Resolution** + label-delta helper (same as `ticket update`) to add the new state label and remove the previous state label.
  ```

## 3. Fix Plane auth header in providers.json

- [ ] 3.1 In `skills/project-management/references/providers.json`, locate the Plane entry `rest_config.auth_header` and change:

  **Current:** `"auth_header": "X-Api-Key: {token}"`
  **Change to:** `"auth_header": "X-API-Key: {token}"`

## 4. Fix Plane auth header in rest/plane.md

- [ ] 4.1 In `skills/project-management/references/rest/plane.md`, locate the Auth table row for `Auth header` and change:

  **Current:** `| Auth header | X-Api-Key: {token} |`
  **Change to:** `| Auth header | X-API-Key: {token} |`

## 5. Add list_states to Plane REST reference

- [ ] 5.1 In `skills/project-management/references/rest/plane.md`, add a row to the Operations table:

  ```
  | list_states | GET | `/api/v1/workspaces/{slug}/projects/{project_id}/states/` |
  ```

- [ ] 5.2 Add a section below the Operations table:

  ```
  ## State UUID Resolution

  The `state` field in `PATCH .../issues/{issue_id}/` accepts a **UUID**, not a state name.
  Resolve state names to UUIDs at init by calling `list_states` and caching the result
  in `.project/config.yaml` as `plane_state_ids` (canonical → UUID map).
  ```

## 6. Add list_states to Plane tool_contracts in providers.json

- [ ] 6.1 In `skills/project-management/references/providers.json`, add `"list_states": "list_states"` to the Plane `tool_contracts` object.

## 7. Update Plane state_mapping comment in providers.json

- [ ] 7.1 In `skills/project-management/references/providers.json`, add a `_note` field to the Plane `state_mapping` object:

  ```json
  "_note": "state_name values are used for display and init-time UUID resolution only. REST calls use UUIDs from plane_state_ids in .project/config.yaml. MCP calls may accept state_name directly."
  ```

## 8. Fix Plane plan_variants.free in providers.json

- [ ] 8.1 In `skills/project-management/references/providers.json`, update the Plane `plan_variants.free` object:

  **Current:**
  ```json
  "free": {
    "epics": false,
    "sprints": true,
    "sprint_proxy": null,
    "milestones": false,
    "relationships": true,
    "sub_issues": true
  }
  ```

  **Change to:**
  ```json
  "free": {
    "epics": false,
    "_epics_note": "epics=false means the Plane Pro 'Epic' work item type is unavailable. Modules (grouping containers) ARE available on free — use create_module for module epics.",
    "modules": true,
    "active_cycles_limit": 1,
    "sprints": true,
    "sprint_proxy": null,
    "milestones": false,
    "relationships": true,
    "sub_issues": true
  }
  ```

- [ ] 8.2 Update `plan_variants.pro` to add `"modules": true` and `"active_cycles_limit": null` (unlimited) for parity:

  **Current:**
  ```json
  "pro": {
    "epics": true,
    "sprints": true,
    "sprint_proxy": null,
    "milestones": false,
    "relationships": true,
    "sub_issues": true
  }
  ```

  **Change to:**
  ```json
  "pro": {
    "epics": true,
    "modules": true,
    "active_cycles_limit": null,
    "sprints": true,
    "sprint_proxy": null,
    "milestones": false,
    "relationships": true,
    "sub_issues": true
  }
  ```

## 9. Update plane.md plan feature table

- [ ] 9.1 In `skills/project-management/references/plane.md`, replace the Plan Variants table:

  **Current:**
  ```
  | Feature | Free | Pro / Business |
  |---------|------|----------------|
  | Cycles (sprints) | ✓ | ✓ |
  | Modules (epics) | ✗ | ✓ |
  | Blocking relations | ✓ | ✓ |
  | relates-to | ✓ | ✓ |
  | Sub-issues | ✓ | ✓ |
  | Custom states | ✓ | ✓ |
  ```

  **Replace with:**
  ```
  | Feature | Free | Pro / Business |
  |---------|------|----------------|
  | Cycles (sprints) | ✓ (1 active at a time) | ✓ (unlimited active) |
  | Modules | ✓ | ✓ |
  | Epics (work item type) | ✗ | ✓ |
  | Blocking relations | ✓ | ✓ |
  | relates-to | ✓ | ✓ |
  | Sub-issues | ✓ | ✓ |
  | Custom states | ✓ | ✓ |
  ```

- [ ] 9.2 Replace the init probe note below the table:

  **Current:**
  > "The skill probes `list_modules` at init. If it returns 403 → free plan, activate label fallback for epics."

  **Replace with:**
  > "The skill probes `list_modules` at init. If it returns 200 → Modules available (all plans). The skill separately probes for the Epic work item type (Pro-only); if unavailable, label fallback is activated. On free plan, `active_cycles_limit: 1` is stored in config."

## 10. Add Plane state UUID resolution to SKILL.md init

- [ ] 10.1 In `SKILL.md` init Step 4 (REST capability probe), add a Plane-specific step after the general capability probe table:

  ```
  **Plane extra — state UUID resolution**

  If `provider.name == "plane"`, call `GET /api/v1/workspaces/{slug}/projects/{project_id}/states/` via REST (or `mcp__plane__list_states` if REST unavailable). For each returned state, reverse-map its `name` against `state_mapping` `state_name` values to find the matching canonical state. Build a map:

  ```yaml
  plane_state_ids:
    backlog: "<uuid-of-Backlog-state>"
    todo: "<uuid-of-Unstarted-state>"
    in-progress: "<uuid-of-In Progress-state>"
    in-review: "<uuid-of-in-review-label-state>"
    done: "<uuid-of-Done-state>"
  ```

  Store in `.project/config.yaml`. If a canonical state has no matching Plane state name, leave its value as `null` and warn:
  ```
  ⚠ Could not map canonical state '<state>' to a Plane state — check your project's state configuration in Plane.
  ```
  ```

- [ ] 10.2 In `SKILL.md` init Step 8 (notify active fallbacks), add a Plane-specific output line:

  If `plane_state_ids` has any `null` entries:
  ```
  ⚠ Some canonical states could not be mapped to Plane states — state transitions for those states will use MCP only.
  ```

## 11. Verification

- [ ] 11.1 Trace through `start TICK-1` on a Plane ticket in Backlog state: confirm the new Step 4 asks the combined prompt, runs WIP check on Y, calls `mcp__plane__update_issue` with the UUID from `plane_state_ids["in-progress"]`, and emits `✓ Moved to in-progress`.
- [ ] 11.2 Trace through `start TICK-1` on a GitLab ticket with `todo` label: confirm Step 4 uses label-delta helper, adds `In Progress` label, removes `To Do` label.
- [ ] 11.3 Trace through `start TICK-1` on a GitLab ticket in `backlog` state (opened, no state label): confirm combined prompt fires, label-delta adds `In Progress` without removing any state label (since none was present).
- [ ] 11.4 Confirm `init` for Plane now includes a `list_states` call and produces `plane_state_ids` in `.project/config.yaml`.
- [ ] 11.5 Confirm `providers.json` Plane `rest_config.auth_header` is `X-API-Key: {token}`.
- [ ] 11.6 Confirm `references/plane.md` plan table shows Modules ✓ on free, Epics ✗ on free, and cycle limit noted.
