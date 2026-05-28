## Context

The `docker_services` repo at `/home/administrator/Projects/docker_services/` is a hand-curated library of 35+ Docker service definitions following strict conventions (layer labels, no exposed ports, pinned image versions, named volumes, healthchecks, CoreDNS `.internal` hostnames). Every new project that needs Docker infrastructure currently copies from this repo manually, and there is no standard way to add a new tool or validate that a service definition is correct.

The `skills/` directory in this project is the home for reusable Claude skills, discoverable via `npx skills` and the agentskills.io spec format.

## Goals / Non-Goals

**Goals:**
- Bundle all 35 service templates inside the skill so it works independently (no dependency on the `docker_services` repo being present)
- Mode A (Scaffold): collect 3 inputs, show service menu, resolve dependencies, copy files with substitution, generate `docker-compose.yaml`, `.env`, `Taskfile.yaml`
- Mode B (Add new tool): given any tool's documentation, derive a compliant `service.yaml` by extracting image/env/ports/volumes/healthcheck and applying all conventions
- Mode C (Lint): validate any service definition against the full conventions checklist, reporting each violation
- Support CoreDNS (default) and Traefik as networking modes

**Non-Goals:**
- Not a runtime tool — does not start or manage containers
- Not a live sync with `docker_services` — templates are snapshots bundled in `assets/`
- Does not validate that the target project has Docker or Compose installed
- Does not handle upgrades (updating service versions in an existing project)

## Decisions

### D1: Templates bundled in `assets/` not referenced from `docker_services`

**Decision**: Copy all service files into `assets/services/` inside the skill.

**Rationale**: The skill must work in any project on any machine. Pointing at an absolute path (`/home/administrator/Projects/docker_services/`) would break for anyone else and for CI environments. Bundling makes the skill self-contained and installable via `npx`.

**Alternative considered**: Symlink or reference the source repo at runtime — rejected because it creates an invisible runtime dependency and doesn't travel with the skill.

### D2: Placeholder substitution over templating engine

**Decision**: Use simple string placeholders (`PLACEHOLDER_DNS_ZONE`, `PLACEHOLDER_NET_PREFIX`, `PLACEHOLDER_COMPOSE_NETWORK`) replaced by Claude's Edit/Write operations.

**Rationale**: Claude performs substitution directly as it copies files — no external tooling required. The number of substitution points is small and known (DNS zone appears in 3 files).

**Alternative considered**: A `scripts/scaffold.sh` that uses `sed` — rejected because it adds a runtime script dependency and Claude can do this natively.

### D3: Traefik as a new template (not in source repo)

**Decision**: Design and bundle a `traefik/service.yaml` + `traefik/traefik.yaml` from scratch.

**Rationale**: The source repo only has CoreDNS. Traefik is a natural alternative for HTTP-routable services. The template exposes ports 80/443/8080 and reads Docker labels for routing — a different model from CoreDNS's DNS-based approach.

### D4: Grafana datasource configs stripped

**Decision**: `assets/services/grafana/service.yaml` contains only the Grafana service, no provisioned datasource YAMLs.

**Rationale**: Datasource configs are project-specific — they reference services by name that may not be selected in every project. The catalog documents where to add them manually.

### D5: Dependency resolution is Claude-driven, not script-driven

**Decision**: The `SKILL.md` lists the dependency graph explicitly. Claude reads it and informs the user which services were auto-added.

**Rationale**: Keeps the skill as pure text instructions with no runtime code. Claude's reasoning is sufficient for a graph of this size.

### D6: Three-mode skill design

**Decision**: The skill explicitly defines three modes (Scaffold, Add, Lint) with a mode-detection table at the top of `SKILL.md`.

**Rationale**: A scaffold-only skill leaves two common problems unsolved — adding arbitrary new services and enforcing conventions on hand-written definitions. Combining all three into one skill keeps the conventions as a single source of truth applied consistently across all modes.

**Alternative considered**: Three separate skills — rejected because the conventions checklist would need to be duplicated across all three, creating drift risk.

### D7: Conventions as a unified linting checklist

**Decision**: All conventions from `docker_services/Readme.md` are encoded as a binary checklist in `SKILL.md` (Mode C). This same checklist drives Mode B generation decisions.

**Rationale**: Prose conventions are ignored or misapplied. A binary checklist is actionable — Claude can run through it item by item both when generating (Mode B) and when reviewing (Mode C). The checklist is the single normative spec for what makes a valid service definition.

**What the checklist covers** (beyond what was in the original Readme.md "Conventions" section):
- Alpine/slim image preference order
- Stable-release-only tag policy
- Custom Dockerfile extension pattern with commented-out `image:` line
- Helper containers must live in same file as parent
- No init-containers

### D8: `assets/env.template` as verbatim source copy

**Decision**: Bundle the source repo's `.env.template` verbatim as `assets/env.template` rather than splitting it into per-service files in a `references/env-vars.md`.

**Rationale**: The original file already has clean `# === Section ===` delimiters per service. Maintaining a separate split copy would create a second source of truth that drifts. Claude reads the single file and splices sections by matching headers to selected services.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| Service templates go stale (upstream image versions change) | Catalog notes templates are snapshots; user should verify versions before production |
| Traefik template untested against real workloads | CoreDNS remains the battle-tested default |
| PLACEHOLDER substitution misses an occurrence | SKILL.md lists all known files containing placeholders |
| Mode B deriving incorrect service from ambiguous docs | Checklist validation step after generation catches most errors; Claude states assumptions explicitly |
| User selects conflicting services (two vector DBs, two caches) | Claude warns but does not block |
| Network prefix collision with existing Docker stacks | SKILL.md instructs Claude to remind user to run `docker network ls` |

## Migration Plan

- No migration needed — net-new skill directory
- Deploy: create `skills/docker-modular-stack/` with all files
- Rollback: delete the directory — no side effects

## Open Questions

All resolved during implementation:
- External API key services (`tensorzero`, `archon`, `hermes`) → documented in catalog with "External secrets" column
- Traefik domain convention → defaults to `{slug}.local`
- `openviking` and `users` (Kratos) services → deferred, not copied into skill assets in this iteration
