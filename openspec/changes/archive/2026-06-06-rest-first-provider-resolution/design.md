## Context

The project-management skill supports four providers: GitHub, GitLab, Jira, and Plane. The original design used MCP as the primary operation path, with a fallback chain that was per-provider — most notably GitLab, which received a dedicated `write_fallbacks` spec because its MCP is largely read-only. This produced inconsistency: GitHub used MCP directly, GitLab used MCP → glab → REST, Jira used MCP directly, and Plane had partial MCP coverage.

All four providers have stable, token-authenticated REST APIs that cover every operation the skill needs. REST is the oldest and most complete interface for each. The MCP servers are thin wrappers over these same REST APIs. A single resolution order — REST first, CLI second, MCP last — applies uniformly to all providers and eliminates the GitLab exception.

## Goals / Non-Goals

**Goals:**
- One resolution order for all providers: REST → CLI → MCP
- Init collects REST credentials (host + token); if provider is undetected, ask the user
- `providers.json` declares `rest_config` and `cli_tool` per provider, not `write_fallbacks`
- `capability-detection` spec drops MCP ToolSearch probing; uses REST ping instead

**Non-Goals:**
- Changing ticket content, sprint, standup, or agile-quality-gates logic
- Removing MCP entirely — it remains as the last-resort path
- Migrating existing `.project/config.yaml` files in user projects

## Decisions

### D1 — Hardcode REST → CLI → MCP as the universal resolution order

**Decision**: All provider operations (read and write) attempt REST first, then CLI if available, then MCP. No per-provider overrides.

**Rationale**: REST APIs are the ground truth for all four providers. CLI tools (gh, glab) wrap the same REST API and are widely installed in developer environments. MCP is newest and least reliable for writes. A single order removes branching logic and makes behavior predictable regardless of provider.

**Alternative considered**: Read operations use MCP-first (it's fast and doesn't need explicit token management). Rejected — the added complexity of separate read/write paths outweighs the marginal performance benefit.

### D2 — providers.json declares rest_config and cli_tool per provider

**Decision**: Each provider entry in `providers.json` gains:
```json
"rest_config": {
  "base": "https://api.github.com",
  "token_env": "GITHUB_TOKEN",
  "auth_header": "Authorization: Bearer {token}"
},
"cli_tool": "gh"
```
For providers with no CLI (Jira, Plane), `cli_tool` is `null` and the chain skips step 2.

**Rationale**: Declarative config keeps resolution logic in SKILL.md simple — it reads `rest_config` and `cli_tool` from providers.json rather than having provider-specific branches in the skill code.

### D3 — Init asks user if provider undetected, then collects REST credentials

**Decision**: Init flow:
1. Detect provider from git remote URL
2. If undetected → ask: "Which provider? (github / gitlab / jira / plane)"
3. Collect `rest_config` fields: host URL (for self-hosted), token (masked input)
4. Ping REST API with token to verify — store in `.project/config.yaml`
5. No MCP ToolSearch at init

**Rationale**: MCP ToolSearch at init was only needed to discover capabilities and set up fallbacks. With REST-first, the init only needs to know: provider name + credentials. REST ping serves as the health check.

**Alternative considered**: Keep ToolSearch at init to detect MCP availability upfront. Rejected — MCP is now last resort; there's no value in probing it at init.

### D4 — gitlab-write-fallback spec renamed and rewritten as provider-io-resolution

**Decision**: The `gitlab-write-fallback` spec is replaced by `provider-io-resolution`, which defines the universal 3-path chain for all providers. GitLab is no longer a special case.

**Rationale**: The original spec's name and framing encoded GitLab as exceptional. The new universal order means the same spec covers all providers.

### D5 — REST credential storage in .project/config.yaml

```yaml
provider:
  name: gitlab
  host: https://gitlab.company.com   # omitted for SaaS providers with fixed base URL
  token_env: GITLAB_TOKEN             # env var name; actual token not stored in file
  rest_verified_at: 2025-06-06T10:00:00Z
```

Token is read from the environment variable at runtime, not stored in config. `rest_verified_at` replaces `capabilities.probed_at`.

## Provider REST Config Reference

| Provider | Base URL | Token env | CLI tool | Auth header |
|----------|----------|-----------|----------|-------------|
| GitHub | `https://api.github.com` | `GITHUB_TOKEN` | `gh` | `Authorization: Bearer {token}` |
| GitLab | `{host}/api/v4` | `GITLAB_TOKEN` | `glab` | `PRIVATE-TOKEN: {token}` |
| Jira | `{host}/rest/api/3` | `JIRA_TOKEN` + `JIRA_EMAIL` | null | `Authorization: Basic base64({email}:{token})` |
| Plane | `{host}/api/v1` | `PLANE_TOKEN` | null | `X-API-Key: {token}` |
