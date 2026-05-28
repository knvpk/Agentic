# Spec: env-var-reference

## Purpose

Defines the requirements for `references/env-vars.md` — the per-service environment variable reference used by Claude to generate project `.env` files during scaffolding. Covers section structure, variable patterns, alias documentation, external-only credentials, and spliceable section delimiters.

## Requirements

### Requirement: env-vars reference contains a block per service
`references/env-vars.md` SHALL contain one clearly delimited section per service, each containing the exact `.env` variable declarations needed by that service. Variable values SHALL use the `$(openssl rand ...)` pattern for secrets (matching the source `.env.template`) and empty strings for optional external values.

#### Scenario: postgres section present with correct vars
- **WHEN** the `postgres` section of `references/env-vars.md` is read
- **THEN** it contains `DB_USER`, `DB_PASSWORD`, and `DB_NAME` with appropriate default patterns

#### Scenario: langfuse section contains all required vars
- **WHEN** the `langfuse` section is read
- **THEN** it contains `NEXTAUTH_SECRET`, `NEXTAUTH_SALT`, `LANGFUSE_ENC_KEY`, and all `LANGFUSE_S3_*` vars

### Requirement: Shared variables aliased correctly
Where one service uses an alias of another service's variable (e.g. `CLICKHOUSE_USER` mirrors `ANALYTICS_DB_USER`), the reference SHALL document both the primary variable and the alias, with a comment noting they must remain in sync.

#### Scenario: clickhouse section shows alias comment
- **WHEN** the `clickhouse` section is read
- **THEN** `CLICKHOUSE_USER` and `CLICKHOUSE_PASSWORD` appear with a comment linking them to `ANALYTICS_DB_USER` and `ANALYTICS_DB_PASSWORD`

#### Scenario: minio section shows OS alias comment
- **WHEN** the `minio` section is read
- **THEN** `OS_USERNAME` and `OS_PASSWORD` appear with a comment linking them to `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD`

### Requirement: External-only vars included with empty values
Variables that require external credentials (API keys, tokens) SHALL be included in the relevant service section with empty string values and a comment indicating they must be set manually.

#### Scenario: openai key included but empty
- **WHEN** the `litellm` or shared section is read
- **THEN** `OPENAI_API_KEY=""` is present with a comment

#### Scenario: Discord token included but empty
- **WHEN** the `hermes` section is read
- **THEN** `DISCORD_BOT_TOKEN=""` and `DISCORD_USER_ID=""` are present

### Requirement: Sections are independently spliced by Claude
Each service section in `references/env-vars.md` SHALL be delimited (e.g. with a `## <service-name>` header) so Claude can extract only the sections for selected services when generating the target project's `.env`.

#### Scenario: Only selected service vars appear in generated .env
- **WHEN** user selects `postgres` and `valkey` but not `neo4j` or `langfuse`
- **THEN** Claude generates `.env` containing only the `postgres` and `valkey` sections from the reference

#### Scenario: Sections are self-contained
- **WHEN** the `clickhouse` section is extracted in isolation
- **THEN** it contains all variables needed by the `analytics_db` service including aliases
