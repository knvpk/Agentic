## 1. providers.json — Schema Update

- [x] 1.1 Remove `write_fallbacks` field from the GitLab entry
- [x] 1.2 Add `rest_config` block to each provider entry with `base`, `token_env`, and `auth_header` fields (use the reference table from design.md D2)
- [x] 1.3 Add `cli_tool` field to each provider entry (`"gh"` for GitHub, `"glab"` for GitLab, `null` for Jira and Plane)
- [x] 1.4 Verify no other provider entry contains `write_fallbacks`

## 2. openspec/specs/provider-adapter/spec.md — Requirement Updates

- [x] 2.1 Replace the `write_fallbacks` requirement with a `rest_config` + `cli_tool` contract requirement
- [x] 2.2 Update the "tool_contracts maps canonical operations to MCP tool suffixes" requirement to note MCP is the last-resort path, not the primary
- [x] 2.3 Add requirement: skill reads `rest_config.token_env` at runtime to obtain the auth token; token is never stored in config files
- [x] 2.4 Add scenario: Jira/Plane with null `cli_tool` skip step 2 of the resolution chain silently

## 3. openspec/specs/gitlab-write-fallback/spec.md — Rewrite as provider-io-resolution

- [x] 3.1 Replace the file header and purpose to reflect universal provider resolution (not GitLab-specific)
- [x] 3.2 Rewrite the "3-path fallback chain" requirement as provider-agnostic: REST → CLI (if `cli_tool` non-null) → MCP
- [x] 3.3 Remove GitLab-specific scenarios; replace with generic provider scenarios that apply to all four providers
- [x] 3.4 Remove the `write_fallbacks` providers.json requirement (now covered by task 2.1)
- [x] 3.5 Keep the label delta (add + remove) requirement for state transitions — this is still needed for GitLab's label-based state model
- [x] 3.6 Keep the numeric project ID requirement for GitLab REST calls

## 4. openspec/specs/capability-detection/spec.md — Remove MCP Probing from Init

- [x] 4.1 Remove the "two-signal detection" requirement (ToolSearch + 200/403 probe)
- [x] 4.2 Replace with a single REST ping requirement: at init, call `GET /` or equivalent lightweight endpoint with the configured token; store `rest_verified_at` on success
- [x] 4.3 Remove the `probed_at` timestamp requirement; replace with `rest_verified_at`
- [x] 4.4 Keep the mid-session 403 handling requirement — a 403 during operation should still trigger a re-auth prompt, not a silent failure
- [x] 4.5 Keep the project type / stack question and docs scaffold prompt requirements (unrelated to resolution strategy)

## 5. SKILL.md — Init Flow and Operation Dispatch

- [x] 5.1 Update init Step 1 (provider detection): detect from git remote; if undetected, ask user to choose from `(github / gitlab / jira / plane)`
- [x] 5.2 Update init credential collection step: for each provider, prompt for the fields defined in `rest_config` (host URL for self-hosted providers, token env var value masked)
- [x] 5.3 Add init REST verification step: ping the REST API and emit `REST connection verified ✓` or surface the error with setup instructions
- [x] 5.4 Remove ToolSearch / MCP capability probing from init
- [x] 5.5 Update all write operation dispatches to follow REST → CLI → MCP order using `rest_config` and `cli_tool` from providers.json
- [x] 5.6 Update GitLab write operations to remove `write_fallbacks` chain reference; they now use the universal resolution path from 5.5

## 6. Verification

- [x] 6.1 Trace a GitHub init flow: remote detected → token collected → REST ping → config written; confirm no ToolSearch call
- [x] 6.2 Trace a GitLab init flow with `GITLAB_TOKEN` set: remote detected → token confirmed from env → REST ping → config written
- [x] 6.3 Trace a Jira init flow: no git remote match → user asked → host + email + token collected → REST ping
- [x] 6.4 Trace a Plane init flow: no CLI tool → resolution chain skips step 2 silently → REST then MCP
- [x] 6.5 Confirm `write_fallbacks` no longer appears anywhere in providers.json or SKILL.md
- [x] 6.6 Confirm `capability-detection` spec contains no ToolSearch requirement
