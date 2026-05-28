## Context

Claude Code users currently manage project documentation (PRDs, architecture, database schemas) outside the AI workflow, and interact with issue trackers (GitHub, GitLab, Jira, Plane) through separate tools. There is no single skill that bridges structured local docs, provider-agnostic ticket management, and the opsx implementation pipeline.

The `issue-explore` skill already established a provider detection pattern (`references/providers.json`) and MCP-first access. This skill extends that pattern into full project lifecycle management — keeping the registries decoupled but structurally compatible for future merger.

Constraints:
- MCP servers vary in completeness per provider and per plan tier
- GitHub has no native sprint/epic concept at the Issues API level
- Plane free plan lacks Modules (epics)
- All ticket operations must go through MCP tools, not raw HTTP, for security and portability
- Docs always live locally in `docs/`; no wiki or Confluence integration in v1

## Goals / Non-Goals

**Goals:**
- Single skill entry point for docs management, ticket lifecycle, and "what to work on today"
- MCP-first provider communication with runtime capability probing
- Canonical state machine and relationship model mapped bidirectionally to each provider
- Rich ticket content generation (requirements, scenarios, use cases) ready as input for `opsx:ff`
- Graceful degradation via labels when native features (epics, relationships) are unavailable
- `.project/config.yaml` as the single source of capability truth per project

**Non-Goals:**
- Wiki or Confluence management (docs are local only in v1)
- GitHub Projects v2 / GraphQL sprint support (milestone proxy used instead)
- Generating OpenSpec spec files (that is `opsx:ff`/`opsx:new`'s responsibility)
- Bidirectional sync between local docs and remote provider
- Merging with `issue-explore` (forward-compatible but separate in v1)

## Decisions

### D1: MCP-first with two-signal capability probing

**Decision:** Use MCP tools as the sole transport layer. Probe capabilities at `init` using: (1) ToolSearch to check if the MCP tool exists, (2) a safe read call to check for 403/success. Fall back to asking the user only when probing is ambiguous.

**Rationale:** Raw HTTP requires token management and per-provider auth code. MCP abstracts this. Two-signal probing catches both "tool not in this MCP server" and "tool exists but plan restricts it" — the two distinct failure modes.

**Alternative considered:** CLI tools (gh, glab, jira CLI) as primary — rejected because CLI availability is not guaranteed in all environments, and MCP is already the standard in this project.

### D2: providers.json per-skill, structurally compatible with issue-explore

**Decision:** Maintain a separate `references/providers.json` inside `skills/project-management/`. It extends the `issue-explore` schema with PM-specific fields: `plan_variants`, `fallbacks`, `state_mapping`, `tool_contracts`.

**Rationale:** Decouples the two skills' release cycles. The shared structure (provider name, hostname patterns, MCP prefix) means merging later requires only a schema union, not a rewrite.

**Alternative considered:** Shared providers.json at repo root — rejected because it creates a hard coupling between two independent skills.

### D3: Label-based fallbacks for missing native features

**Decision:** When a provider/plan lacks native epics, blocks relations, or relates-to, simulate with structured labels (`epic:{slug}`, `blocks:#{id}`, `relates:#{id}`) and a description comment. Fallback strategy declared per-feature in `providers.json`.

**Rationale:** Labels are universally supported. The naming convention makes machine-readable grouping possible (search by `epic:*` prefix). Silent fallback is avoided — the user is always notified which mode is active.

**Alternative considered:** Storing relationships in `.project/` local files as a side-channel — rejected because it diverges from the provider as source of truth.

### D4: Ticket content as opsx-ready brief, not as spec

**Decision:** Generated ticket bodies contain: summary, requirements (SHALL), BDD scenarios (GIVEN/WHEN/THEN), use cases (actor + flow), non-functional constraints, context links to docs sections, and a `/opsx:ff` hand-off hint. The skill does NOT create `openspec/specs/` files.

**Rationale:** `opsx:ff` and `opsx:new` own spec generation. The ticket is the input brief to those skills. Generating specs inside ticket creation would duplicate responsibility and couple the two pipelines.

### D5: Milestone as sprint proxy for GitHub

**Decision:** GitHub milestones are used as the sprint abstraction. Sprint create = milestone create. Sprint membership = milestone assignment on issue.

**Rationale:** GitHub Projects v2 requires GraphQL and a `project`-scoped PAT not available in `mcp__github__`. Milestones are universally available via the Issues API and sufficient for sprint tracking at the team level.

**Alternative considered:** GitHub Projects v2 via GraphQL — deferred to v2 of the skill when a dedicated MCP tool is available.

### D6: Canonical state machine with bidirectional provider mapping

**Decision:** The skill enforces a canonical state set: `backlog → todo → in-progress → in-review → done | blocked`. Each state maps to provider-native states/labels declared in `providers.json`. State transitions are validated against the canonical machine before dispatching to the provider.

```
Canonical       GitHub              GitLab          Jira          Plane
────────────    ──────────────────  ──────────────  ────────────  ──────────────
backlog         open (no label)     open            Backlog       Backlog
todo            open + todo label   open + To Do    To Do         Unstarted
in-progress     open + in-progress  In Progress     In Progress   In Progress
in-review       open + in-review    In Review       In Review     In Review
done            closed              closed          Done          Done
blocked         open + blocked      open + blocked  Blocked       Blocked (custom)
```

### D7: "Next ticket" as pure read + score algorithm

**Decision:** The scheduler fetches all open in-sprint tickets, reads their titles and descriptions, eliminates blocked tickets (any open blocker), then scores by: (1) already in-progress (WIP continuation), (2) priority, (3) unblocks-others count (dependency fan-out), (4) estimate size. No user input required per invocation.

**Rationale:** Algorithmic recommendation is faster and lower-friction than interactive questions. The reasoning output ("TICK-42 unblocks 3 tickets, high priority, no open dependencies") gives the user enough context to override.

## Risks / Trade-offs

- **MCP tool gaps** → Mitigation: two-signal probe detects gaps at init, not mid-operation. Fallbacks are pre-declared per feature.
- **GitHub milestone-as-sprint is lossy** → Mitigation: documented limitation; GitHub Projects v2 deferred to v2. Users needing real sprints on GitHub should use Plane or Jira.
- **Label namespace pollution for fallbacks** → Mitigation: structured prefixes (`epic:`, `blocks:`, `relates:`) isolate PM labels. Users warned at init if fallback mode is active.
- **Capability cache staleness** → Mitigation: lazy re-probe on unexpected 403 mid-session; user can force `init --probe` at any time.
- **Ticket content quality depends on prd.md completeness** → Mitigation: skill reads and references specific prd.md sections; warns if the relevant section is sparse.
- **Provider API rate limits during next-ticket fetch** → Mitigation: fetch once per invocation, cache ticket list in session; no polling.

## Migration Plan

New skill — no migration required. Steps to activate:

1. Copy `skills/project-management/` into a project's skills path
2. Ensure the relevant MCP server is configured in Claude Code settings
3. Run `/project-management init` — probes provider, writes `.project/config.yaml`
4. Optionally run `/project-management docs` to scaffold `docs/prd.md`, `docs/architecture.md`, `docs/database.md`

Rollback: remove `skills/project-management/` and `.project/config.yaml`. No remote state is modified by the skill itself except ticket/label/milestone creation in the provider.

## Open Questions

- **Q1**: Should `.project/config.yaml` be gitignored by default or committed? Committing makes team-wide capability config shareable; gitignoring keeps token-adjacent config private. Lean: committed (no secrets stored there, only capability flags and provider name).
- **Q2**: For Jira, sprint creation requires a board ID. Should `init` ask for it, or probe available boards and present a selection? Lean: probe + selection list.
- **Q3**: Should the "next ticket" output include an estimate of time to completion, or only ticket identity + reasoning? Lean: include estimate if the ticket has one set in the provider, omit if not.
