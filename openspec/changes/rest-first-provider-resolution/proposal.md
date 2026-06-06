## Why

The project-management skill's provider resolution was designed around MCP-first, with fallback chains that vary per provider (notably a GitLab-specific `write_fallbacks` mechanism). In practice, GitLab's MCP is largely read-only, and the per-provider fallback logic adds maintenance surface without clear benefit. REST APIs are the ground truth for all supported providers — they predate MCP, expose the full API surface, and operate directly on credentials collected at init. A single hardcoded resolution order (REST → CLI → MCP) works uniformly across all providers and eliminates the GitLab exception entirely.

## What Changes

- **`references/providers.json`** — remove `write_fallbacks` field; add `rest_config` (base URL pattern, token env var) and `cli_tool` (binary name or null) per provider entry
- **`openspec/specs/provider-adapter/spec.md`** — replace `write_fallbacks` requirement with `rest_config` + `cli_tool` contract; update tool_contracts to reflect REST-first resolution
- **`openspec/specs/gitlab-write-fallback/spec.md`** — rewrite as `provider-io-resolution` covering the universal 3-path chain; remove GitLab-specific framing
- **`openspec/specs/capability-detection/spec.md`** — remove MCP ToolSearch probing from init; capability detection becomes REST health-check only
- **`SKILL.md`** — init flow simplified: detect provider from git remote, ask user if undetected, collect REST credentials; all write operations use REST → CLI → MCP in that order

## Capabilities

### Modified Capabilities

- `provider-adapter`: resolution contract changes from MCP-first with per-provider fallbacks to universal REST → CLI → MCP
- `gitlab-write-fallback` (renamed `provider-io-resolution`): becomes the single, provider-agnostic resolution spec
- `capability-detection`: MCP ToolSearch removed from init; REST ping replaces it as the health check signal

### Removed Capabilities

- Per-provider `write_fallbacks` declarations in providers.json

## Impact

- `skills/project-management/SKILL.md` — init flow and all write operation dispatches
- `skills/project-management/references/providers.json` — schema change
- `openspec/specs/provider-adapter/spec.md`
- `openspec/specs/gitlab-write-fallback/spec.md` (rename + rewrite)
- `openspec/specs/capability-detection/spec.md`
- No change to ticket content, sprint, or standup logic
