## Why

The `docker-modular-stack` skill's service templates contain Docker Compose service names with underscores (e.g. `graph_db1_server`, `idp_server`, `prefect_server`). Underscores are not valid DNS hostname characters (RFC 952/1123), so CoreDNS silently fails to resolve any service with an underscore in its name. Additionally, Authentik defaults to binding at port 9000 internally, causing cross-service SSO URLs to carry an explicit port suffix that can be avoided.

## What Changes

- **Service template files** (`assets/services/`) — all underscore service keys replaced with hyphenated equivalents; all hostname references (env var URLs, `depends_on` keys) updated consistently throughout
- **`authentik/service.yaml`** — adds `AUTHENTIK_LISTEN__HTTP: "0.0.0.0:80"` so Authentik binds at port 80 internally; LiteLLM SSO endpoint references updated to `http://idp-server/...` (no port suffix)
- **`assets/env.template`** — `FALKORDB_URI` updated to reference `graph-db1-server`
- **SKILL.md lint checklist (Mode C)** — new "CoreDNS networking" subsection with two rules: no underscores in service names; Authentik must include `AUTHENTIK_LISTEN__HTTP: "0.0.0.0:80"`
- **`references/catalog.md`** — container names updated to reflect actual template names

## Capabilities

### New Capabilities

- `coredns-service-name-normalization`: DNS-safe hyphenated service names baked directly into all templates; lint rule to catch violations in user-added services
- `coredns-port-normalization`: Authentik configured to bind at port 80 via `AUTHENTIK_LISTEN__HTTP` in its template; cross-service SSO URL references updated accordingly

### Modified Capabilities

- `skill-definition`: SKILL.md gains two CoreDNS-specific lint checklist items (Mode C)

## Impact

- `skills/docker-modular-stack/assets/services/authentik/service.yaml`
- `skills/docker-modular-stack/assets/services/falkor_db/service.yaml`
- `skills/docker-modular-stack/assets/services/grafana/service.yaml`
- `skills/docker-modular-stack/assets/services/graphiti/service.yaml`
- `skills/docker-modular-stack/assets/services/litellm/service.yaml`
- `skills/docker-modular-stack/assets/services/mission_control/service.yaml`
- `skills/docker-modular-stack/assets/services/chroma.yaml`
- `skills/docker-modular-stack/assets/services/prefect/service.yaml`
- `skills/docker-modular-stack/assets/services/webui.yaml`
- `skills/docker-modular-stack/assets/env.template`
- `skills/docker-modular-stack/SKILL.md` — lint checklist only
- `skills/docker-modular-stack/references/catalog.md`
- No changes to existing projects already scaffolded — this only affects new scaffold runs
