## Context

The PM skill's GitLab integration relies on `mcp__gitlab__update_issue` for every write operation on existing issues: state changes (open/closed), label swaps (which simulate intermediate states like `in-progress`, `in-review`, `blocked`), sprint label assignment, and milestone assignment. The official GitLab MCP server exposes a read-heavy tool set and does not include `update_issue`. This makes GitLab effectively read-only in the PM skill.

GitLab status is simulated through labels: `To Do`, `In Progress`, `In Review`, `Blocked`. A state transition removes the old state label and adds the new one. This is the only mutation needed for status — no native state field exists beyond open/closed.

The `issue-explore` skill already handles this gap with a 3-path approach: MCP → CLI (`glab`) → REST API. The PM skill should adopt the same pattern for writes.

## Goals / Non-Goals

**Goals:**
- State transitions work end-to-end on GitLab even without `update_issue` in the MCP
- Label-based status changes (add/remove) work via `glab` or REST fallback
- Sprint label assignment and removal work via the same fallback chain
- The fallback path is transparent — user sees the same UX regardless of which path executes
- Numeric project ID captured at init so REST calls are possible without extra lookups

**Non-Goals:**
- Adding `update_issue` to the GitLab MCP server (not our control)
- Supporting GitLab without `GITLAB_TOKEN` (already a hard requirement)
- Handling GitLab EE features (iterations, epics) via fallback — this only covers CE label-based states
- Replacing MCP calls where `update_issue` does exist (future-proof: if it gets added, MCP path wins)

## Decisions

### Decision 1: 3-path fallback chain (MCP → glab → REST)

**Chosen**: Walk paths in order — MCP tool first (ToolSearch probe), then `glab` CLI, then `curl` REST.

**Rationale**: MCP is preferred when available (consistent with the rest of the skill). `glab` is simple and reliable if installed. REST is always available given `GITLAB_TOKEN` is required. This matches `issue-explore`'s proven pattern.

**Alternatives considered**:
- REST-only: Simpler but bypasses MCP when it does work. Also loses the `glab` option for users without token/URL config.
- glab-only: Not always installed; not suitable as the sole path.
- Error + instructions: Tell the user to install glab or use REST manually. Worst UX — breaks the workflow silently.

### Decision 2: Store numeric project ID at init

**Chosen**: After provider init, call `mcp__gitlab__get_project` and store `id` (numeric) as `gitlab_project_id` in `.project/config.yaml`.

**Rationale**: The GitLab REST API requires a numeric project ID (or URL-encoded path) for issue endpoints. Fetching it lazily at write time adds latency and a potential failure point. Storing it at init amortizes the cost.

**Alternatives considered**:
- URL-encode the path at call time: Works but fragile (special characters, subgroups). Numeric ID is unambiguous.
- Use path directly (percent-encoded): Valid per GitLab API docs, but encoding logic is error-prone in `Bash` snippets.

### Decision 3: Fallback declared in providers.json, logic in SKILL.md

**Chosen**: Add a `write_fallbacks` block to the GitLab entry in `providers.json` listing ordered fallback strategies. SKILL.md reads this at update time.

**Rationale**: Keeps provider-specific knowledge in the provider reference file. SKILL.md becomes provider-agnostic at the fallback-routing level — it just walks the declared chain.

```json
"write_fallbacks": [
  { "type": "mcp",  "tool": "update_issue" },
  { "type": "cli",  "cmd": "glab issue update {iid} --project {project_path}" },
  { "type": "rest", "endpoint": "PUT /api/v4/projects/{gitlab_project_id}/issues/{iid}" }
]
```

### Decision 4: Label swap logic (remove old + add new) in SKILL.md

**Chosen**: SKILL.md fetches the current labels from the issue, determines which state label to remove, then calls the write path with `remove_labels` and `add_labels` params (REST) or `--remove-label` / `--add-label` flags (glab).

**Rationale**: The label list must be fetched first to avoid overwriting unrelated labels. `update_issue` accepted the full label list; fallback paths need the delta form.

## Risks / Trade-offs

- **`glab` not installed** → Fallback skips to REST. REST always works if `GITLAB_TOKEN` and instance URL are set. Risk is low.
- **Self-hosted GitLab with non-standard URL** → `GITLAB_URL` env var already expected by `issue-explore`; PM skill should read the same var. Document in `references/gitlab.md`.
- **Race condition on label fetch + update** → If another agent updates labels between the fetch and the write, labels could conflict. Acceptable for a skill context (not a high-concurrency system).
- **MCP tool names change in future GitLab MCP releases** → The ToolSearch probe at write time handles this; if `update_issue` appears in a future MCP version, it wins automatically.

## Migration Plan

1. Update `providers.json` — add `write_fallbacks` to GitLab entry, add `gitlab_project_id` to the init-capture contract
2. Update `SKILL.md` init flow — add Step to call `get_project` and store `gitlab_project_id`
3. Update `SKILL.md` ticket → update — replace direct `mcp__gitlab__update_issue` calls with fallback-chain resolution function
4. Update `SKILL.md` sprint add/remove — same fallback-chain replacement
5. Update `references/gitlab.md` — document `glab` as optional dependency, REST fallback, `GITLAB_URL` var
6. No data migration needed — `.project/config.yaml` gains an optional field; existing configs work without it (REST fallback will just fetch project ID on first write)

## Open Questions

- Should `glab` availability be probed at init and stored, or checked lazily at write time? (Lean: lazy — avoids init complexity)
- Should the fallback path used be surfaced to the user? (Lean: yes, one-line notice e.g. `"Using REST API for GitLab write (MCP update_issue not available)"`)
