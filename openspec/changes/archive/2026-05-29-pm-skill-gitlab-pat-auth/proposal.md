## Why

The project-management skill currently treats GitLab MCP auth as OAuth-only, forcing users through a browser flow even when they already have `GITLAB_TOKEN` set in their environment. GitLab's API v4 (which hosts the `/api/v4/mcp` endpoint) fully supports `Authorization: Bearer <pat>` authentication — the same pattern GitHub's MCP uses — making PAT a viable alternative that works headlessly and in CI.

## What Changes

- **`providers.json`** — GitLab `mcp_setup.auth_methods` expanded from `["oauth"]` to `["oauth", "pat"]`; add `pat` install command (`--header "Authorization=Bearer {token}"`), `pat_prompt`, `pat_url`, and `pat_env: "GITLAB_TOKEN"`
- **`SKILL.md`** — init Step B: add env pre-check for `GITLAB_TOKEN` before presenting the OAuth/PAT choice; update the auth table GitLab row from "OAuth only" to include the PAT install command
- **`references/gitlab.md`** — remove "only option for cloud" wording; document both OAuth and PAT setup paths

## Capabilities

### New Capabilities

_(none — this is a refinement to existing provider init behaviour, not a new capability)_

### Modified Capabilities

- `provider-adapter`: The GitLab auth setup step in init now detects `GITLAB_TOKEN` in the environment before asking the user; if found, it skips the OAuth/PAT question and proceeds with PAT auth automatically. The PAT install command is now a valid option alongside OAuth.

## Impact

- `skills/project-management/references/providers.json` — GitLab `mcp_setup` block
- `skills/project-management/SKILL.md` — init Mode, Step B (auth method selection)
- `skills/project-management/references/gitlab.md` — setup documentation
- No breaking changes; OAuth remains the default when `GITLAB_TOKEN` is absent
