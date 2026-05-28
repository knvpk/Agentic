## 1. Skill Scaffold

- [x] 1.1 Create `skills/docker-modular-stack/` directory
- [x] 1.2 Create `skills/docker-modular-stack/references/` directory
- [x] 1.3 Create `skills/docker-modular-stack/assets/services/` directory

## 2. Service Templates — Network Layer

- [x] 2.1 Copy `coredns/Corefile` to `assets/services/coredns/Corefile`, replacing `aip.knvpk.internal` → `PLACEHOLDER_DNS_ZONE`
- [x] 2.2 Copy `coredns/Dockerfile` to `assets/services/coredns/Dockerfile`
- [x] 2.3 Copy `coredns/service.yaml` to `assets/services/coredns/service.yaml`
- [x] 2.4 Create `assets/services/traefik/traefik.yaml` (new Traefik static config)
- [x] 2.5 Create `assets/services/traefik/service.yaml` (new Traefik service, ports 80/443, Docker socket mount)
- [x] 2.6 Copy `docker/kong/service.yaml` to `assets/services/kong/service.yaml`
- [x] 2.7 Copy `docker/kong/config/kong.yml` to `assets/services/kong/config/kong.yml`

## 3. Service Templates — Data Layer

- [x] 3.1 Copy `docker/postgres/service.yaml` to `assets/services/postgres/service.yaml`
- [x] 3.2 Copy `docker/postgres/config/multiple-databases.sh` to `assets/services/postgres/config/multiple-databases.sh`
- [x] 3.3 Copy `docker/clickhouse/service.yaml` to `assets/services/clickhouse/service.yaml`
- [x] 3.4 Copy `docker/clickhouse/init_scripts/initdb.sql` to `assets/services/clickhouse/init_scripts/initdb.sql`
- [x] 3.5 Copy `docker/redis.yaml` to `assets/services/redis.yaml`
- [x] 3.6 Copy `docker/valkey.yaml` to `assets/services/valkey.yaml`
- [x] 3.7 Copy `docker/minio.yaml` to `assets/services/minio.yaml`
- [x] 3.8 Copy `docker/neo4j/service.yaml` to `assets/services/neo4j/service.yaml`
- [x] 3.9 Copy `docker/falkor_db/service.yaml` to `assets/services/falkor_db/service.yaml`
- [x] 3.10 Copy `docker/chroma.yaml` to `assets/services/chroma.yaml`

## 4. Service Templates — Observability Layer

- [x] 4.1 Copy `docker/grafana/service.yaml` to `assets/services/grafana/service.yaml` (no datasource configs)
- [x] 4.2 Copy `docker/tempo/service.yaml` to `assets/services/tempo/service.yaml`
- [x] 4.3 Copy `docker/tempo/config.yaml` to `assets/services/tempo/config.yaml`
- [x] 4.4 Copy `docker/otel-collector/service.yaml` to `assets/services/otel-collector/service.yaml`
- [x] 4.5 Copy `docker/otel-collector/config.yaml` to `assets/services/otel-collector/config.yaml`
- [x] 4.6 Copy `docker/langfuse.yaml` to `assets/services/langfuse.yaml`, replacing `aip.knvpk.internal` → `PLACEHOLDER_DNS_ZONE`
- [x] 4.7 Copy `docker/phoenix.yaml` to `assets/services/phoenix.yaml`
- [x] 4.8 Copy `docker/hyperdx.yaml` to `assets/services/hyperdx.yaml`

## 5. Service Templates — Communications Layer

- [x] 5.1 Copy `docker/mailpit.yaml` to `assets/services/mailpit.yaml`
- [x] 5.2 Copy `docker/mailslurper.yaml` to `assets/services/mailslurper.yaml`

## 6. Service Templates — App Dependency Layer

- [x] 6.1 Copy `docker/authentik/service.yaml` to `assets/services/authentik/service.yaml`
- [x] 6.2 Copy `docker/oryd/service.yaml` to `assets/services/oryd/service.yaml`
- [x] 6.3 Copy `docker/oryd/config/hydra.yml` to `assets/services/oryd/config/hydra.yml`
- [x] 6.4 Copy `docker/oryd/resources/client_unified_app.json` to `assets/services/oryd/resources/client_unified_app.json`
- [x] 6.5 Copy `docker/graphiti/service.yaml` to `assets/services/graphiti/service.yaml`
- [x] 6.6 Copy `docker/graphiti/config.yaml` to `assets/services/graphiti/config.yaml`

## 7. Service Templates — App Layer

- [x] 7.1 Copy `docker/litellm/service.yaml` to `assets/services/litellm/service.yaml`, replacing `aip.knvpk.internal`/`idp_server.aip.knvpk.internal` → `PLACEHOLDER_DNS_ZONE`
- [x] 7.2 Copy `docker/litellm/config.yaml` to `assets/services/litellm/config.yaml`
- [x] 7.3 Copy `docker/hasura/service.yaml` to `assets/services/hasura/service.yaml`
- [x] 7.4 Copy `docker/kestra/service.yaml` to `assets/services/kestra/service.yaml`
- [x] 7.5 Copy `docker/kestra/config/application.yaml` to `assets/services/kestra/config/application.yaml`
- [x] 7.6 Copy `docker/hermes/service.yaml` to `assets/services/hermes/service.yaml`
- [x] 7.7 Copy `docker/hermes/config.yaml` to `assets/services/hermes/config.yaml`
- [x] 7.8 Copy `docker/hermes/Dockerfile` to `assets/services/hermes/Dockerfile`
- [x] 7.9 Copy `docker/archon/service.yaml` to `assets/services/archon/service.yaml`
- [x] 7.10 Copy `docker/archon/Dockerfile` to `assets/services/archon/Dockerfile`
- [x] 7.11 Copy `docker/paperclip/service.yaml` to `assets/services/paperclip/service.yaml`
- [x] 7.12 Copy `docker/paperclip/Dockerfile` to `assets/services/paperclip/Dockerfile`
- [x] 7.13 Copy `docker/tensorzero/service.yaml` to `assets/services/tensorzero/service.yaml`
- [x] 7.14 Copy `docker/tensorzero/config/tensorzero.toml` to `assets/services/tensorzero/config/tensorzero.toml`
- [x] 7.15 Copy `docker/tensorzero/config/functions/` tree to `assets/services/tensorzero/config/functions/`
- [x] 7.16 Copy `docker/mission_control/service.yaml` to `assets/services/mission_control/service.yaml`
- [x] 7.17 Copy `docker/prefect/service.yaml` to `assets/services/prefect/service.yaml`

## 8. Reference Documents

- [x] 8.1 Create `references/catalog.md` with full service table (name, layer, container name, dependencies, description, external secrets noted)
- [x] 8.2 Add dependency map section to `references/catalog.md` listing transitive deps for each service
- [x] 8.3 Add IP convention table to `references/catalog.md` (layer → subnet range)
- [x] 8.4 Add Grafana datasource note to `references/catalog.md` (grafana entry)
- [x] 8.5 Copy `docker_services/.env.template` verbatim to `assets/env.template` (preserves `$(openssl rand ...)` patterns, alias comments, and all original groupings)

## 9. SKILL.md

- [x] 9.1 Write `SKILL.md` frontmatter: `name: docker-modular-stack`, `description` covering all 3 modes + trigger conditions, `compatibility` (Docker + Compose v2 required)
- [x] 9.2 Write mode-detection table mapping user intent to Scaffold / Add / Lint
- [x] 9.3 Write Mode A (Scaffold): input collection, service menu, dependency resolution, file copy, compose/env/taskfile generation
- [x] 9.4 Write Mode B (Add new tool): doc extraction steps (image, env, ports, volumes, healthcheck), conventions decision guide, post-generation checklist run, project file integration
- [x] 9.5 Write Mode C (Lint): full conventions checklist as binary `[ ]` items covering all rules from `docker_services/Readme.md` including alpine preference, stable-only tags, Dockerfile extension pattern, helper-containers-in-same-file, no init-containers
- [x] 9.6 Verify `SKILL.md` is under 500 lines

## 10. Post-initial additions

- [x] 10.1 Copy `ollama.yaml` to `assets/services/ollama.yaml`
- [x] 10.2 Copy `webui.yaml` to `assets/services/webui.yaml`
- [x] 10.3 Copy `inspector.yaml` to `assets/services/inspector.yaml`
- [x] 10.4 Copy `neo4j.yaml` (flat) to `assets/services/neo4j.yaml`
- [x] 10.5 Add ollama, webui, inspector, neo4j entries to `references/catalog.md` service table
- [x] 10.6 Add webui dependency (→ ollama) to catalog dependency map
- [x] 10.7 Update `SKILL.md` service menu to include ollama, webui, inspector
- [x] 10.8 Update `SKILL.md` flat services list to include the 4 new yamls
- [x] 10.9 Update `SKILL.md` dependency map to include webui → ollama
