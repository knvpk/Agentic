## Context

The project-management skill's init mode (Step B) determines how to authenticate a provider's HTTP MCP server. For GitHub, Jira, and Plane this is already data-driven: `mcp_setup.auth_methods` in `providers.json` lists available methods and `install_commands` holds the CLI command per method. GitLab's entry has `auth_methods: ["oauth"]` only, so the skill's auth table in SKILL.md hardcodes "OAuth only" and the install command omits the `--header` flag.

GitLab API v4 — the same base path that serves `/api/v4/mcp` — accepts two auth header formats:
- `PRIVATE-TOKEN: glpat-xxxx` (GitLab-native)
- `Authorization: Bearer glpat-xxxx` (OAuth-compatible, works with PATs too)

The `claude mcp add --header` flag uses the `Key=Value` format, matching how GitHub's MCP is configured.

## Goals / Non-Goals

**Goals:**
- Add PAT as a valid auth method for GitLab in `providers.json`
- Auto-detect `GITLAB_TOKEN` in environment before asking; use it silently if found
- Keep OAuth as the default when no env var is present
- Fix `references/gitlab.md` to no longer say "only option for cloud"

**Non-Goals:**
- Supporting `PRIVATE-TOKEN` header (use `Authorization: Bearer` for consistency with GitHub pattern)
- Changing the auth flow for any provider other than GitLab
- Adding GITLAB_TOKEN env-var collection to `required_env` (it's already standard; users who have it set get auto-selection, others go through the prompt)

## Decisions

### 1. Use `Authorization: Bearer` not `PRIVATE-TOKEN`

**Decision**: The PAT install command uses `--header "Authorization=Bearer {token}"`.

**Rationale**: Consistent with GitHub's MCP pattern. GitLab API v4 accepts both, but `Authorization: Bearer` is OAuth-compatible and more portable. The `--header` flag in `claude mcp add` uses `Key=Value` syntax which maps cleanly to this format.

**Alternative considered**: `PRIVATE-TOKEN: {token}` — rejected because it's GitLab-specific and inconsistent with the GitHub pattern already established in `providers.json`.

### 2. Env check is a pre-question step, not `required_env`

**Decision**: Before presenting the OAuth/PAT choice, SKILL.md checks `$GITLAB_TOKEN`. If found, it skips the question and proceeds directly to the PAT path.

**Rationale**: `required_env` entries are checked *after* the auth method is chosen. Checking earlier avoids making users confirm a choice they've already implicitly made. The behavior mirrors how many CLI tools handle pre-set credentials.

**Alternative considered**: List `GITLAB_TOKEN` in `required_env` with `skip_if_server_manages_auth: true` — rejected because `required_env` is post-choice. Adding a new `skip_if_env_found` flag would complicate the schema unnecessarily.

### 3. `pat_env` field added to providers.json GitLab entry

**Decision**: Add `"pat_env": "GITLAB_TOKEN"` to the GitLab `mcp_setup` block so the skill knows which env var name to check.

**Rationale**: Keeps the pre-question env check data-driven (SKILL.md reads `pat_env` from providers.json) rather than hardcoding `GITLAB_TOKEN` in SKILL.md prose. Future providers with PAT support can declare their own env var name.

## Risks / Trade-offs

- **GitLab Duo license requirement**: The `/api/v4/mcp` endpoint requires a Duo Pro/Enterprise subscription. A valid PAT authenticates correctly (200/401) but tool calls may 403 if the account lacks a Duo license. This is unchanged from the OAuth path — the skill's existing 403 lazy re-probe handles it. No new mitigation needed.

- **Token scope**: GitLab PATs need `api` scope for full MCP access. The `pat_prompt` in providers.json will note this, but there's no runtime check. Risk: users create a narrower-scoped token and see 403s on specific tools. Mitigation: note in prompt and gitlab.md.

## Migration Plan

No migration needed. Existing OAuth-configured projects are unaffected — the init flow only runs on first setup or `--probe`. Users who re-run init on an existing project will see the new PAT option offered.

## Open Questions

_(none — all decisions resolved during exploration)_
