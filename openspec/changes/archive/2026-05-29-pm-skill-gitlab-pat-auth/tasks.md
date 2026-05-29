## 1. providers.json — Expand GitLab mcp_setup

- [x] 1.1 Change `auth_methods` from `["oauth"]` to `["oauth", "pat"]`
- [x] 1.2 Add `"pat"` key to `install_commands` with value `claude mcp add gitlab --scope project --transport http {url} --header "Authorization=Bearer {token}"`
- [x] 1.3 Add `"pat_prompt"` field: `"Enter your GitLab Personal Access Token (api scope required):"`
- [x] 1.4 Add `"pat_url"` field: `"https://gitlab.com/-/user_settings/personal_access_tokens"`
- [x] 1.5 Add `"pat_env"` field: `"GITLAB_TOKEN"`

## 2. SKILL.md — Update init Step B auth table and env pre-check

- [x] 2.1 In the auth method table, change the GitLab row from `OAuth only` to include the PAT install command (matching the Jira row structure)
- [x] 2.2 Add env pre-check logic before the OAuth/PAT question: read `mcp_setup.pat_env`, check if that env var is set; if yes emit `Found GITLAB_TOKEN in environment — using PAT auth ✓` and skip the question

## 3. references/gitlab.md — Update setup documentation

- [x] 3.1 Remove "only option for cloud" from the OAuth setup heading
- [x] 3.2 Add a PAT setup block with the `--header` install command and a note that `api` scope is required
