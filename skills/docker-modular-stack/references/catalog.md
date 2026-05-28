# Service Catalog

## Service Table

| Service | Asset path | Layer | Container name | Dependencies | External secrets | Notes |
|---------|-----------|-------|---------------|-------------|-----------------|-------|
| **coredns** | `services/coredns/` | network | coredns | — | — | Requires host systemd-resolved config; IP hardcoded at `PLACEHOLDER_NET_PREFIX.255.254` |
| **traefik** | `services/traefik/` | network | reverse_proxy | — | — | Exposes ports 80/443/8080; alternative to CoreDNS for HTTP routing |
| **kong** | `services/kong/` | network | kong | — | — | DB-less declarative mode; edit `config/kong.yml` to add routes |
| **postgres** | `services/postgres/` | data | db | — | — | `ADDITIONAL_DBS` env var adds extra databases on first boot |
| **clickhouse** | `services/clickhouse/` | data | analytics_db | — | — | OLAP store; used by otel-collector and langfuse |
| **redis** | `services/redis.yaml` | data | cache1 | — | — | Redis 8; use valkey for Redis-compatible alternative |
| **valkey** | `services/valkey.yaml` | data | cache | — | — | Valkey 9, Redis-compatible; preferred over redis for new projects |
| **minio** | `services/minio.yaml` | data | os | — | — | S3-compatible object store; pre-creates `langfuse` bucket on boot |
| **neo4j** | `services/neo4j/` | data | graph_db | — | — | Community edition; 512M heap max |
| **falkor_db** | `services/falkor_db/` | data | graph_db1_server + graph_db1_browser | — | — | Redis-protocol graph DB; browser UI included |
| **chroma** | `services/chroma.yaml` | data | vector_db | — | — | ChromaDB vector store |
| **neo4j** (simple) | `services/neo4j.yaml` | data | graph_db | — | — | Flat single-file variant of Neo4j; use instead of `neo4j/` for minimal setup |
| **grafana** | `services/grafana/` | observability | grafana + mcp_grafana | analytics_db, db | — | **No datasource YAMLs included** — add to `docker/grafana/config/provisioning/datasources/` per project |
| **tempo** | `services/tempo/` | observability | tempo | — | — | Distributed tracing backend; receives OTLP from otel-collector |
| **otel-collector** | `services/otel-collector/` | observability | otel-collector | analytics_db | — | OTLP collector; forwards traces to ClickHouse |
| **langfuse** | `services/langfuse.yaml` | observability | langfuse + langfuse-worker | db, analytics_db, os, cache | — | LLM tracing; contains `PLACEHOLDER_DNS_ZONE` in URLs |
| **phoenix** | `services/phoenix.yaml` | observability | phoenix | — | — | LLM observability (Arize Phoenix) |
| **hyperdx** | `services/hyperdx.yaml` | observability | hyperdx | — | — | Full-stack observability UI |
| **mailpit** | `services/mailpit.yaml` | communications | mail | — | — | Email dev/test; SMTP on 1025, UI on 8025 |
| **mailslurper** | `services/mailslurper.yaml` | communications | mailslurper | — | — | Email dev/test alternative |
| **authentik** | `services/authentik/` | app_dependency | idp_server + idp_worker | db, cache | — | Identity provider (SSO/OIDC); requires valkey `cache` service name |
| **oryd** | `services/oryd/` | app_dependency | oauth2 + oauth2-migrate + oauth2-consent | db | — | Ory Hydra OAuth2 + Kratos users |
| **graphiti** | `services/graphiti/` | app_dependency | graphiti | falkor_db | — | Knowledge graph MCP; depends on FalkorDB |
| **litellm** | `services/litellm/` | app | litellm | db | `OPENAI_API_KEY`, `APP_AWS_ACCESS_KEY_ID`, `APP_AWS_SECRET_ACCESS_KEY` | LLM proxy; contains `PLACEHOLDER_DNS_ZONE` in SSO endpoints |
| **hasura** | `services/hasura/` | app | graphql-engine | db | — | GraphQL engine with JWT auth |
| **kestra** | `services/kestra/` | app | kestra | db | — | Workflow orchestration |
| **hermes** | `services/hermes/` | app | hermes | — | `DISCORD_BOT_TOKEN`, `DISCORD_USER_ID` | Discord bot; custom Dockerfile |
| **archon** | `services/archon/` | app | archon | — | `CLAUDE_CODE_OAUTH_TOKEN` | AI agent runner; custom Dockerfile |
| **paperclip** | `services/paperclip/` | app | paperclip | — | `GITLAB_URL`, `GITLAB_TOKEN` | File management; custom Dockerfile |
| **tensorzero** | `services/tensorzero/` | app | tensorzero | — | `OPENAI_API_KEY`, `APP_AWS_ACCESS_KEY_ID`, `APP_AWS_SECRET_ACCESS_KEY` | LLM gateway with observability |
| **mission_control** | `services/mission_control/` | app | mission_control | — | — | Control plane UI |
| **prefect** | `services/prefect/` | app | prefect | — | — | Data workflow orchestration |
| **ollama** | `services/ollama.yaml` | app | ollama | — | — | Local LLM model server; sends OTLP traces to otel-collector if selected |
| **webui** | `services/webui.yaml` | app | webui + webui_pipelines + mcpo | ollama (optional) | `GENERIC_API_KEY` | Open WebUI with pipelines and MCP proxy; helper containers in same file |
| **inspector** | `services/inspector.yaml` | app | inspector | — | — | MCP Inspector UI |

---

## Dependency Map

When a service is selected, all services listed under it must also be included.

```
postgres       → (no deps)
clickhouse     → (no deps)
redis          → (no deps)
valkey         → (no deps)
minio          → (no deps)
neo4j          → (no deps)
falkor_db      → (no deps)
chroma         → (no deps)
coredns        → (no deps)
traefik        → (no deps)
kong           → (no deps)
tempo          → (no deps)
phoenix        → (no deps)
hyperdx        → (no deps)
mailpit        → (no deps)
mailslurper    → (no deps)
mission_control → (no deps)

otel-collector → clickhouse
graphiti       → falkor_db
grafana        → postgres, clickhouse
authentik      → postgres, valkey
oryd           → postgres
hasura         → postgres
kestra         → postgres
litellm        → postgres
hermes         → (no deps — external Discord API)
archon         → (no deps — external Claude API)
paperclip      → (no deps — external GitLab API)
tensorzero     → (no deps — external LLM APIs)
prefect        → (no deps)

langfuse       → postgres, clickhouse, minio, valkey
webui          → ollama (optional — include if also selected)
```

**Transitive example**: selecting `langfuse` → auto-add `postgres`, `clickhouse`, `minio`, `valkey`.
**Transitive example**: selecting `grafana` + `otel-collector` → auto-add `postgres`, `clickhouse` (deduplicated).

---

## IP Assignment Convention (CoreDNS mode only)

Assign hardcoded IPs at the **high end** of each layer's range to avoid conflicts with DHCP-assigned addresses.

| Layer | Subnet range | Example IP |
|-------|-------------|-----------|
| network | `PLACEHOLDER_NET_PREFIX.255.y` | `PLACEHOLDER_NET_PREFIX.255.254` (coredns) |
| data | `PLACEHOLDER_NET_PREFIX.254.y` | `PLACEHOLDER_NET_PREFIX.254.1` and up |
| observability | `PLACEHOLDER_NET_PREFIX.253.y` | `PLACEHOLDER_NET_PREFIX.253.1` and up |
| communications | `PLACEHOLDER_NET_PREFIX.252.y` | `PLACEHOLDER_NET_PREFIX.252.1` and up |
| app_dependency | `PLACEHOLDER_NET_PREFIX.251.y` | `PLACEHOLDER_NET_PREFIX.251.1` and up |
| app | `PLACEHOLDER_NET_PREFIX.250.y` | `PLACEHOLDER_NET_PREFIX.250.1` and up |

CoreDNS is pinned to `PLACEHOLDER_NET_PREFIX.255.254` (required — it must be reachable by name from the host).

---

## Grafana Datasources

The `grafana` service template includes **no provisioned datasource files**. Add them manually per project:

```
docker/grafana/config/provisioning/datasources/<name>.yaml
```

Example datasource for postgres:
```yaml
apiVersion: 1
datasources:
  - name: Postgres
    type: grafana-postgresql-datasource
    url: db:5432
    database: ${DB_NAME}
    user: ${DB_USER}
    secureJsonData:
      password: ${DB_PASSWORD}
```
