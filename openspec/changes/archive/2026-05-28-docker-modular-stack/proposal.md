## Why

Setting up Docker infrastructure for a new project requires assembling service definitions from scratch every time — writing healthchecks, volumes, network config, env vars, and image pins that have already been battle-tested in existing projects. Beyond scaffolding, there is no standard workflow for adding an arbitrary new tool to the stack, or for validating that a service definition follows the project's conventions. This skill solves all three: scaffold from a curated library, derive a new service from docs, and lint any service against the conventions.

## What Changes

- New skill `docker-modular-stack` added to `skills/`
- Skill operates in three modes: **Scaffold** (copy templates), **Add** (derive service from docs), **Lint** (validate against conventions checklist)
- Skill bundles 35 service template files in `assets/services/` with placeholder substitution for DNS zone and network prefix
- Skill bundles `assets/env.template` (verbatim copy of source `.env.template`) for per-service env var splicing
- `references/catalog.md` documents every service with layer, dependencies, container name, and external secrets
- `references/catalog.md` includes the conventions checklist used in Add and Lint modes
- Supports CoreDNS (default) and Traefik as networking modes

## Capabilities

### New Capabilities

- `skill-definition`: The `SKILL.md` file covering all three modes — Scaffold workflow (A1–A7), Add-new-tool workflow (B1–B3), and Lint checklist (C), plus mode-detection table
- `service-templates`: 35 service YAML/config/Dockerfile templates in `assets/services/`, with hardcoded hostnames replaced by `PLACEHOLDER_DNS_ZONE`, `PLACEHOLDER_NET_PREFIX`, `PLACEHOLDER_COMPOSE_NETWORK`; includes new Traefik template not in source repo
- `service-catalog`: `references/catalog.md` — full service table with layer, container name, dependencies, external secrets, notes; dependency map; IP convention table; Grafana datasource note
- `env-var-reference`: `assets/env.template` — verbatim copy of source `.env.template`; sections delimited by `# === Service ===` headers; Claude splices selected sections into new project `.env`

### Modified Capabilities

## Impact

- New directory: `skills/docker-modular-stack/`
- No changes to existing code or config
- Requires `npx skills` or Claude Code to discover and invoke the skill
- Source service definitions drawn from `/home/administrator/Projects/docker_services/`
