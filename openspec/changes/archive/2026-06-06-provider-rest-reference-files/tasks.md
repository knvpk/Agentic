## 1. references/rest/github.md

- [x] 1.1 Create `skills/project-management/references/rest/github.md`
- [x] 1.2 Add auth section: token env `GITHUB_TOKEN`, header format `Authorization: Bearer {token}`, base URL `https://api.github.com`
- [x] 1.3 Add API version note: `Accept: application/vnd.github+json` and `X-GitHub-Api-Version: 2022-11-28` headers required
- [x] 1.4 Add operation table with path patterns for all 10 operations from design.md D4
- [x] 1.5 Add docs link: `https://docs.github.com/en/rest` and OpenAPI spec URL: `https://github.com/github/rest-api-description`

## 2. references/rest/gitlab.md

- [x] 2.1 Create `skills/project-management/references/rest/gitlab.md`
- [x] 2.2 Add auth section: token env `GITLAB_TOKEN`, header format `PRIVATE-TOKEN: {token}`, base URL `{host}/api/v4` (default host `https://gitlab.com`)
- [x] 2.3 Add operation table with path patterns for all 13 operations from design.md D4; note that `{id}` is the numeric project ID (stored as `gitlab_project_id` in config, not the URL-encoded path)
- [x] 2.4 Add docs link: `https://docs.gitlab.com/ee/api/rest/` and OpenAPI spec URL: `https://gitlab.com/gitlab-org/gitlab/-/raw/master/doc/api/openapi/openapi.yaml`

## 3. references/rest/jira.md

- [x] 3.1 Create `skills/project-management/references/rest/jira.md`
- [x] 3.2 Add auth section: envs `JIRA_EMAIL` + `JIRA_TOKEN`, header format `Authorization: Basic {base64(email:token)}`, base URL `{host}/rest/api/3`
- [x] 3.3 Add base64 generation reminder: `echo -n "{email}:{token}" | base64`
- [x] 3.4 Add operation table with path patterns for all 10 operations from design.md D4
- [x] 3.5 Add docs link: `https://developer.atlassian.com/cloud/jira/platform/rest/v3/` and OpenAPI spec URL: `https://dac-static.atlassian.com/cloud/jira/platform/swagger-v3.v3.json`

## 4. references/rest/plane.md

- [x] 4.1 Create `skills/project-management/references/rest/plane.md`
- [x] 4.2 Add auth section: token env `PLANE_TOKEN`, header format `X-Api-Key: {token}`, base URL `https://api.plane.so/api/v1` (self-hosted: `{host}/api/v1`)
- [x] 4.3 Add required context vars: `PLANE_WORKSPACE_SLUG` (in all paths), `PLANE_PROJECT_ID` (in issue/label paths)
- [x] 4.4 Add operation table with path patterns for all 9 operations from design.md D4
- [x] 4.5 Add docs link: `https://developers.plane.so/api-reference/` (no public OpenAPI spec URL available)

## 5. SKILL.md — REST dispatch instruction

- [x] 5.1 Add one instruction line to the REST dispatch section: before constructing any REST call, read `references/rest/{provider}.md`
- [x] 5.2 Add recovery instruction: if a REST call returns 404 or unexpected 401, consult the `docs` link in the reference file to verify the current path before retrying

## 6. Verification

- [x] 6.1 Confirm all four files exist under `references/rest/`
- [x] 6.2 Confirm each file has: auth section, base URL, operation table, docs link
- [x] 6.3 Confirm GitLab file notes that `{id}` is numeric project ID, not URL-encoded path
- [x] 6.4 Confirm Jira file includes the base64 generation reminder
- [x] 6.5 Confirm SKILL.md REST dispatch section references `references/rest/{provider}.md`
- [x] 6.6 Confirm no request body schemas or response field documentation was added (kept minimal)
