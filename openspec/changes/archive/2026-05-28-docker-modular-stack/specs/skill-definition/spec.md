## ADDED Requirements

### Requirement: Skill frontmatter conforms to agentskills.io spec
The `SKILL.md` file SHALL include valid YAML frontmatter with `name: docker-modular-stack` (matching the directory name), a `description` under 1024 characters covering all three modes and their trigger conditions, and a `compatibility` field noting Docker and Docker Compose v2 as prerequisites.

#### Scenario: Skill is discoverable
- **WHEN** `npx skills` is run in a project that has `skills/docker-modular-stack/` in its path
- **THEN** the skill appears in the listing with name `docker-modular-stack`

#### Scenario: Description triggers on scaffold queries
- **WHEN** a user asks Claude to "set up a docker stack", "add postgres and grafana", or "scaffold docker infrastructure"
- **THEN** Claude identifies and activates the `docker-modular-stack` skill in Scaffold mode

#### Scenario: Description triggers on add-tool queries
- **WHEN** a user says "add [some tool] to docker" or "create a service.yaml for [tool]" and provides documentation
- **THEN** Claude identifies and activates the `docker-modular-stack` skill in Add mode

#### Scenario: Description triggers on lint queries
- **WHEN** a user says "check this service definition" or "does this follow the conventions"
- **THEN** Claude identifies and activates the `docker-modular-stack` skill in Lint mode

---

## MODE A — Scaffold

### Requirement: Skill collects three inputs before scaffolding
Before copying any files, the skill SHALL instruct Claude to collect: (1) project slug, (2) Docker network prefix, and (3) networking mode (CoreDNS or Traefik, default CoreDNS).

#### Scenario: All inputs collected before any files written
- **WHEN** scaffold mode is invoked
- **THEN** Claude asks for project slug, network prefix, and networking mode before creating any files

#### Scenario: Default networking mode applied when not specified
- **WHEN** user does not specify a networking mode
- **THEN** CoreDNS is used

### Requirement: Skill presents service selection menu grouped by layer
The skill SHALL instruct Claude to display all 35 available services grouped by layer and allow the user to select any combination.

#### Scenario: Menu shows all services including newly added
- **WHEN** service selection step is reached
- **THEN** menu includes `ollama`, `webui`, `inspector`, and `neo4j` alongside the original services

#### Scenario: User selects a subset of services
- **WHEN** user specifies only `postgres`, `valkey`, and `grafana`
- **THEN** only those services (plus auto-added dependencies) are scaffolded

### Requirement: Skill auto-resolves transitive service dependencies
The skill SHALL automatically add required dependencies, inform the user, and deduplicate.

#### Scenario: Selecting langfuse auto-adds its dependencies
- **WHEN** user selects `langfuse`
- **THEN** Claude also adds `postgres`, `clickhouse`, `minio`, and `valkey`, and notifies the user

#### Scenario: Duplicate dependency not added twice
- **WHEN** user selects both `langfuse` and `authentik`
- **THEN** `postgres` and `valkey` appear only once in the final service list

### Requirement: Skill generates docker-compose.yaml with local includes
The generated `docker-compose.yaml` SHALL use relative `include:` paths and a `networks.main` IPAM block using the user-supplied prefix.

#### Scenario: Generated compose uses relative paths
- **WHEN** scaffold completes for a project with `postgres` and `grafana` selected
- **THEN** `docker-compose.yaml` contains `include: - docker/postgres/service.yaml` and `include: - docker/grafana/service.yaml`

#### Scenario: Network block uses supplied prefix
- **WHEN** user supplies network prefix `10.9`
- **THEN** `docker-compose.yaml` contains `subnet: 10.9.0.0/16` and `gateway: "10.9.0.1"`

### Requirement: Skill generates .env with only selected-service variables
The generated `.env` SHALL contain only the env var sections for selected services, spliced from `assets/env.template`.

#### Scenario: Unselected service vars excluded
- **WHEN** user selects `postgres` and `valkey` but not `neo4j`
- **THEN** generated `.env` contains no `GRAPH_DB_*` variables

### Requirement: Skill generates Taskfile.yaml with networking tasks
The `Taskfile.yaml` SHALL contain setup and teardown tasks appropriate to the chosen networking mode.

#### Scenario: CoreDNS mode generates systemd-resolved tasks
- **WHEN** CoreDNS networking is selected
- **THEN** `Taskfile.yaml` contains `dns:setup` and `dns:teardown` tasks

#### Scenario: Traefik mode generates /etc/hosts tasks
- **WHEN** Traefik networking is selected
- **THEN** `Taskfile.yaml` contains `hosts:setup` and `hosts:teardown` tasks

---

## MODE B — Add new tool from documentation

### Requirement: Skill derives a compliant service definition from tool documentation
Given any tool documentation (URL, README, Docker Hub page), the skill SHALL instruct Claude to extract image, env vars, ports, volumes, and healthcheck information, then produce a `service.yaml` that passes the full conventions checklist.

#### Scenario: Image tag selection follows convention
- **WHEN** deriving a service for a tool that has alpine and non-alpine tags
- **THEN** Claude selects the alpine variant at the most recent stable version

#### Scenario: Container name is generic not tool-specific
- **WHEN** deriving a service for a tool named "PrometheusDB"
- **THEN** the container service name is a generic purpose noun (e.g. `metrics_db`), not `prometheusdb`

#### Scenario: Generated service passes lint checklist
- **WHEN** Mode B produces a service.yaml
- **THEN** Claude runs the conventions checklist against it before writing the file, and fixes any violations

### Requirement: Skill integrates new service into project files
After deriving the service YAML, the skill SHALL add it to `docker-compose.yaml` includes, add its env vars to `.env`, and (CoreDNS mode) add its hostname to the Corefile.

#### Scenario: New service added to compose includes
- **WHEN** a new tool service is created
- **THEN** its path is appended to the `include:` block in `docker-compose.yaml`

---

## MODE C — Lint / review

### Requirement: Skill validates a service definition against the full conventions checklist
Given a service YAML, the skill SHALL check every item in the conventions checklist and report each failure with the specific rule violated.

#### Scenario: Missing layer label reported
- **WHEN** a service YAML has no `layer=` label
- **THEN** lint reports: "Missing required `layer=` label"

#### Scenario: Floating image tag reported
- **WHEN** a service uses `image: redis:latest`
- **THEN** lint reports: "Image tag must be pinned to a specific version — `latest` is not allowed"

#### Scenario: RC tag reported
- **WHEN** a service uses `image: postgres:18.3-rc1`
- **THEN** lint reports: "Tag must be a stable release — RC/beta/milestone suffixes not allowed"

#### Scenario: Non-alpine variant flagged
- **WHEN** a service uses `image: postgres:18.3` and a `postgres:18.3-alpine` exists
- **THEN** lint reports: "Alpine variant preferred if available"

#### Scenario: Helper container in wrong file reported
- **WHEN** a worker container is defined in a file separate from its parent service
- **THEN** lint reports: "Helper containers must live in the same file as their parent service"

#### Scenario: Init-container flagged
- **WHEN** a service uses an init-container pattern
- **THEN** lint reports: "Init-containers should be avoided — use `depends_on` with healthchecks instead"

#### Scenario: Clean service passes all checks
- **WHEN** a service follows all conventions
- **THEN** lint reports all items as passing with no violations
