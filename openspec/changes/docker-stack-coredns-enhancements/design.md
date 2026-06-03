## Context

The `docker-modular-stack` skill scaffolds Docker Compose stacks with a choice of CoreDNS or Traefik networking. CoreDNS resolves Docker service names as DNS hostnames. RFC 952/1123 prohibits underscores in DNS labels, so any service name containing `_` is silently unresolvable in CoreDNS mode.

Eleven service keys across the template library contained underscores:
- `graph_db1_server`, `graph_db1_browser` (falkor_db)
- `idp_server`, `idp_worker` (authentik)
- `mission_control`
- `mcp_grafana` (grafana)
- `prefect_server`, `prefect_services`, `prefect_worker`
- `vector_db` (chroma)
- `webui_pipelines` (webui)

Additionally, Authentik (`idp_server`) defaulted to binding at port 9000. The `litellm` template referenced it as `http://idp_server:9000/application/o/...`, producing non-standard SSO URLs.

## Goals / Non-Goals

**Goals:**
- All service template files use hyphenated service names — valid for both DNS and Docker Compose
- All cross-service hostname references (env var URLs, `depends_on` keys, `env.template`) are consistent with the renamed service keys
- Authentik binds at port 80 via `AUTHENTIK_LISTEN__HTTP`; cross-service SSO URLs reference `idp-server` without a port suffix
- Mode C (Lint) flags underscore service names and missing Authentik listen config for user-added services

**Non-Goals:**
- Volume names (Docker identifiers, not DNS hostnames — underscores are harmless)
- Compose network name `{slug}_main` (not DNS-resolved)
- Port normalization for other services (LiteLLM :4000, Grafana :3000, etc.) — addressed separately
- Mode migration for existing scaffolded projects

## Decisions

### D1 — Edit templates directly, not scaffold-time transformation

**Decision**: Update the service template YAML files to use hyphenated names. No runtime transformation step in the skill.

**Rationale**: Hyphens are valid in both Docker Compose service names and DNS hostnames. There is no scenario where a hyphenated name is correct for one mode and wrong for the other. Baking the correct names into the templates means the output is always right — no per-scaffold transformation logic to maintain.

**Alternative considered**: Apply `_` → `-` substitution as a scaffold-time step in SKILL.md (A4.1), leaving templates unchanged. Rejected because it introduces transformation logic that must be kept in sync as templates evolve, adds complexity to the scaffold procedure, and provides no benefit — hyphens work identically in Traefik mode.

### D2 — Scope: service keys and hostname references only

**Decision**: Rename only Docker service name keys (under `services:`) and their appearances as hostnames: `depends_on` keys, URL-form env var values (`http://name`, `redis://name`), and `env.template` entries.

**Rationale**: Volume names (`graph_db1_data`) and config-file keys don't participate in DNS resolution. Renaming them would be noise and could break other tooling. The scoping rule: "if it appears after `://` or as a `depends_on` key, it's a hostname."

### D3 — Authentik port: `AUTHENTIK_LISTEN__HTTP` in template, not host mapping

**Decision**: Add `AUTHENTIK_LISTEN__HTTP: "0.0.0.0:80"` and `AUTHENTIK_LISTEN__HTTPS: "0.0.0.0:9443"` directly to the `idp-server` environment block in `authentik/service.yaml`. No `ports:` mapping added.

**Rationale**: `AUTHENTIK_LISTEN__HTTP` changes the port the server process binds to inside the container (Authentik uses `__` as a config path delimiter). Port 80 is reachable by other containers on the same Docker network without any host mapping. `COMPOSE_PORT_HTTP` — despite its name — only controls the host-side port in Authentik's official docker-compose `ports:` mapping; with no `ports:` section in this template, it is a no-op.

**Alternative considered**: `COMPOSE_PORT_HTTP=80`. Rejected — confirmed no-op in this template.

**Alternative considered**: `ports: ["80:9000"]`. Rejected — exposes Authentik on the host, violates the conventions checklist, and still doesn't simplify inter-container URLs.

### D4 — Cross-reference map applied in templates directly

All cross-service hostname references updated in place:

| File | What changed |
|---|---|
| `assets/services/falkor_db/service.yaml` | keys + `FALKORDB_URL` env var + `depends_on` |
| `assets/services/graphiti/service.yaml` | `FALKORDB_URI` env var + `depends_on` |
| `assets/services/authentik/service.yaml` | service keys + `AUTHENTIK_LISTEN__HTTP/HTTPS` added |
| `assets/services/litellm/service.yaml` | `GENERIC_TOKEN/USERINFO/AUTHORIZATION_ENDPOINT` — `idp_server:9000` → `idp-server` |
| `assets/services/prefect/service.yaml` | service keys + `PREFECT_API_URL` + `depends_on` |
| `assets/services/grafana/service.yaml` | `mcp_grafana` key |
| `assets/services/mission_control/service.yaml` | `mission_control` key |
| `assets/services/chroma.yaml` | `vector_db` key |
| `assets/services/webui.yaml` | `webui_pipelines` key |
| `assets/env.template` | `FALKORDB_URI` value |

## Risks / Trade-offs

**[Risk] Template re-sync from upstream `docker_services` reintroduces underscores** → Mitigation: The lint rule added to Mode C will catch any underscore service names in a linted project. Re-syncing templates requires a review pass — the grep command `grep -rn "^  [a-z].*_.*:" assets/services/` identifies new violations quickly.

**[Risk] User scaffolds with Traefik, later switches to CoreDNS** → Mitigation: Out of scope; the networking mode is fixed at scaffold time. Hyphens in service names are valid in Traefik mode, so the output is correct for both modes regardless.

**[Risk] Authentik port 80 binding fails without sufficient privileges** → Validated working. `AUTHENTIK_LISTEN__HTTP` confirmed to work.

## Migration Plan

Changes are to template asset files and SKILL.md only. Existing scaffolded projects are unaffected. New scaffold runs copy the updated templates and will produce DNS-safe output from the first run.
