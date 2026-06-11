## Delta: provider-adapter

### New Requirements

#### Requirement: Plane rest_config uses the correct auth header casing

The Plane REST API requires the header `X-API-Key` (all-caps `API`). The skill SHALL use this exact casing in `rest_config.auth_header` for the Plane provider.

##### Scenario: REST call to Plane uses X-API-Key header
- **WHEN** the skill makes a REST call to the Plane API
- **THEN** the request header is `X-API-Key: {token}` — not `X-Api-Key` or any other variant

---

#### Requirement: Plane provider resolves state names to UUIDs at init and caches them

The Plane REST API `PATCH .../issues/{id}/` accepts a `state` field containing a UUID, not a human-readable state name. The skill SHALL resolve Plane state names to UUIDs during `init` and store them in `.project/config.yaml` as `plane_state_ids`.

##### Scenario: Init calls list_states and builds plane_state_ids map
- **WHEN** init runs for a Plane provider
- **THEN** skill calls `GET /api/v1/workspaces/{slug}/projects/{project_id}/states/` (REST or MCP), maps each returned state name to the canonical state via `state_mapping`, and writes a `plane_state_ids` map to `.project/config.yaml`

##### Scenario: plane_state_ids used for REST state transitions
- **WHEN** the skill transitions a Plane ticket state via REST
- **THEN** it reads the UUID from `plane_state_ids[canonical_state]` in config and passes it as `state` in the PATCH body — it does NOT pass the state name string

##### Scenario: Unmapped state warns and falls back to MCP
- **WHEN** a canonical state has no matching Plane state name in the project
- **THEN** skill emits `⚠ Could not map canonical state '<state>' to a Plane state — state transitions for that state will use MCP only.` and uses MCP for that transition

##### Scenario: plane_state_ids refreshed on init --probe
- **WHEN** user runs `init --probe` for a Plane provider
- **THEN** skill re-calls `list_states`, rebuilds the UUID map, and overwrites `plane_state_ids` in config

---

#### Requirement: Plane plan_variants correctly distinguish Modules from Epics

Plane has two distinct grouping concepts: **Modules** (grouping containers, available on all plans) and **Epics** (a dedicated work item type, available on Pro/Business only). The skill SHALL model these separately in `plan_variants`.

##### Scenario: Plane free plan has modules available
- **WHEN** `plan_variants.free` is read for the Plane provider
- **THEN** `modules` is `true` — the skill can call `create_module` and `list_modules` without expecting a 403

##### Scenario: Plane free plan does not have the Epic work item type
- **WHEN** `plan_variants.free` is read for the Plane provider
- **THEN** `epics` is `false` — epic-level features require Pro plan; label fallback strategy is used

##### Scenario: Plane free plan active cycle limit is modelled
- **WHEN** `plan_variants.free` is read for the Plane provider
- **THEN** `active_cycles_limit` is `1` — only one cycle can be active at a time on the free plan

##### Scenario: Plane pro plan has unlimited active cycles
- **WHEN** `plan_variants.pro` is read for the Plane provider
- **THEN** `active_cycles_limit` is `null` — no limit applies

---

#### Requirement: Plane tool_contracts includes list_states

The skill SHALL include `list_states` in the Plane `tool_contracts` so that the state UUID resolution step can resolve to MCP when REST is unavailable.

##### Scenario: list_states resolves via MCP when REST unavailable
- **WHEN** REST is unavailable during Plane init and `list_states` is in `tool_contracts`
- **THEN** skill calls `mcp__plane__list_states` to retrieve project states
