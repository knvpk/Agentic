## Context

The `project-management` skill is a prompt-only skill (`SKILL.md`). All behaviour is defined in natural-language instructions read by the model at runtime. There is no compiled code — fixing a bug means editing the instruction text and reference data files.

The six bugs fall into two groups:
1. **start mode Step 4** — wrong control flow for backlog state; missing provider branching for label-delta
2. **Plane provider reference data** — wrong auth header, missing state UUID resolution, wrong plan feature table

## Goals / Non-Goals

**Goals:**
- `start TICK-n` transitions ticket to `in-progress` regardless of whether the ticket starts in `backlog` or `todo` state
- GitLab and GitHub start transitions remove the old state label (matching `ticket update` behaviour)
- Plane REST calls use the correct auth header (`X-API-Key`)
- Plane state transitions use UUIDs resolved at init (cached in config)
- Plane free plan correctly modelled: Modules available, 1 active cycle limit

**Non-Goals:**
- Changing the WIP limit enforcement logic
- Adding Plane-specific sprint (cycle) limit enforcement beyond modelling it in `plan_variants`
- Fixing the `docs` mode or other unrelated skill modes
- Changing how Jira state transitions work (they work correctly already)

## Decisions

### D1 — Merge the `backlog` and `todo` paths in start Step 4

**Decision**: Replace the `backlog` warn-only path with a combined prompt:
> "TICK-n is in backlog (not assigned to the active sprint). Move to in-progress? [y/n]"

On `y`: run WIP Limit Check, then call `update_ticket` via the provider-specific path. On `n`: proceed to Step 5 without transition.

**Rationale**: The current behaviour (warn → continue with no transition) is always wrong. The user ran `start` — they intend to work on the ticket. Separating "not in sprint" warning from "move to in-progress" offer would require two confirmations for what is one intent. A single prompt combining both concerns is less friction.

**Alternative considered**: Keep separate prompts (first warn about sprint, then ask about state). Rejected — two interrupts for one intent.

### D2 — start Step 4 must mirror `ticket update` provider branching

**Decision**: Add explicit provider branching to start Step 4's `update_ticket` call:
```
- GitHub, Jira, Plane: call update_ticket directly (via Shared: Provider Write Path Resolution)
- GitLab: use Shared: Provider Write Path Resolution + label-delta helper
```

**Rationale**: `ticket update` already has correct provider branching (line 1512–1513 in SKILL.md). `start` Step 4 currently says only "call `update_ticket` translating via `state_mapping`" with no provider branching — this causes GitLab to add the new state label but never remove the old one. The fix is to make start Step 4 reference the same shared procedure.

### D3 — Plane state UUIDs resolved at init, cached in config

**Decision**: During `init` Step 4 (Plane provider), call `GET /api/v1/workspaces/{slug}/projects/{id}/states/` and build a `plane_state_ids` map:
```yaml
plane_state_ids:
  backlog: "<uuid>"
  todo: "<uuid>"
  in-progress: "<uuid>"
  in-review: "<uuid>"
  done: "<uuid>"
```
Stored in `.project/config.yaml`. Any operation that needs to set Plane state reads from this map rather than passing `state_name`.

**Rationale**: The Plane REST API `PATCH /issues/{id}` accepts `state` as a UUID, not a name. The MCP server resolves this internally, so MCP "works" while REST fails. Resolving once at init and caching is the lightest fix — no per-call `list_states` overhead.

**Alternative considered**: Per-call `list_states` lookup. Rejected — adds an extra MCP/REST call on every state transition; init is the right time to probe and cache.

### D4 — Modules ≠ Epics; `plan_variants.free.epics` stays `false` but meaning changes

**Decision**: Keep `plan_variants.free.epics: false` to mean "Plane's *Epic work item type* (Pro-only)", but add `modules: true` as a separate capability. Update `references/plane.md` and `references/rest/plane.md` to clarify the distinction. The `create_epic` tool contract continues to point at `create_module` for Pro; free plan falls back to label strategy.

**Rationale**: Plane has two distinct concepts: **Modules** (grouping containers, free) and **Epics** (a dedicated issue type with its own hierarchy, Pro). The current skill conflates them. The MCP `create_module` tool is correct for Pro epics. Free users should use the label fallback as before — but the capability probe at init should probe `list_modules` not `list_epics`, and should not 403 on free.

### D5 — Auth header fix: `X-Api-Key` → `X-API-Key`

**Decision**: Update `providers.json` `rest_config.auth_header` and `references/rest/plane.md` auth table to use `X-API-Key`.

**Rationale**: Plane's API documented header is `X-API-Key`. The casing mismatch causes REST calls to fail silently (401/403), making the skill always fall through to MCP. Fixing this restores the intended REST → CLI → MCP priority.

## Risks / Trade-offs

**[Risk] `plane_state_ids` cache goes stale** if user renames states in Plane. Mitigation: document in init output that re-running `init --probe` refreshes the cache. On a 404 state UUID, fall back to MCP (which resolves names dynamically).

**[Risk] Plane free plan cycle limit** — skill currently has no enforcement of the 1-active-cycle limit. This change models it in `plan_variants.free.active_cycles_limit: 1` but does not add enforcement logic (out of scope per Non-Goals). The stored value can be used by a future enhancement.

**[Risk] `backlog` → `in-progress` combined prompt** may confuse users who intentionally start a backlog ticket they know is out-of-sprint. Mitigation: the prompt text explicitly notes the sprint situation, giving the user full context to say `n`.
