## ADDED Requirements

### Requirement: All 26+ service templates bundled in assets/services/
The skill SHALL include a copy of every service definition from the source `docker_services` repo under `assets/services/<service-name>/`. Services with config folders SHALL include their full config tree. Services with Dockerfiles SHALL include the Dockerfile.

#### Scenario: postgres template includes config script
- **WHEN** `assets/services/postgres/` is inspected
- **THEN** it contains `service.yaml` and `config/multiple-databases.sh`

#### Scenario: Flat services stored as single yaml
- **WHEN** a service has no associated config (e.g. `redis`, `valkey`, `minio`)
- **THEN** it is stored as `assets/services/<name>.yaml` (flat file, not a folder)

### Requirement: Hardcoded hostnames replaced with placeholders
Any occurrence of the source project's DNS zone (`knvpk.internal`, `aip.knvpk.internal`) in template files SHALL be replaced with `PLACEHOLDER_DNS_ZONE`. The Docker network prefix (`10.8`) SHALL be replaced with `PLACEHOLDER_NET_PREFIX`.

#### Scenario: coredns Corefile uses placeholder zone
- **WHEN** `assets/services/coredns/Corefile` is read
- **THEN** it contains `PLACEHOLDER_DNS_ZONE` where `aip.knvpk.internal` appeared in the source

#### Scenario: langfuse NEXTAUTH_URL uses placeholder
- **WHEN** `assets/services/langfuse.yaml` is read
- **THEN** `NEXTAUTH_URL` and S3 endpoint values reference `PLACEHOLDER_DNS_ZONE` not `aip.knvpk.internal`

#### Scenario: litellm SSO endpoints use placeholder
- **WHEN** `assets/services/litellm/service.yaml` is read
- **THEN** `GENERIC_TOKEN_ENDPOINT`, `GENERIC_USERINFO_ENDPOINT`, `GENERIC_AUTHORIZATION_ENDPOINT` reference `PLACEHOLDER_DNS_ZONE`

### Requirement: Traefik template included as new service
A `assets/services/traefik/` directory SHALL exist containing a `service.yaml` and `traefik.yaml` config designed for label-based HTTP routing within the Docker network.

#### Scenario: Traefik service exposes ports 80 and 443
- **WHEN** `assets/services/traefik/service.yaml` is read
- **THEN** the service maps ports 80 and 443 to the host

#### Scenario: Traefik reads Docker socket for label-based routing
- **WHEN** `assets/services/traefik/service.yaml` is read
- **THEN** it mounts `/var/run/docker.sock` and references `traefik.yaml` for static config

### Requirement: Grafana template contains no provisioned datasources
The `assets/services/grafana/` directory SHALL contain only `service.yaml` with no `config/provisioning/datasources/` files.

#### Scenario: Grafana assets dir has no datasource yamls
- **WHEN** `assets/services/grafana/` is listed
- **THEN** no files matching `*datasource*` or `*provisioning*` exist

### Requirement: Templates copied verbatim then placeholders substituted
When Claude copies a service to a target project, it SHALL first copy all files from `assets/services/<name>/` to `<project>/docker/<name>/`, then replace all occurrences of `PLACEHOLDER_DNS_ZONE` with `{slug}.internal` and `PLACEHOLDER_NET_PREFIX` with the user-supplied prefix.

#### Scenario: Placeholder substitution applied in copied Corefile
- **WHEN** project slug is `myapp` and coredns is selected
- **THEN** `docker/coredns/Corefile` in the target project contains `myapp.internal`, not `PLACEHOLDER_DNS_ZONE`

#### Scenario: Files without placeholders copied unchanged
- **WHEN** `postgres/config/multiple-databases.sh` contains no placeholders
- **THEN** the file is copied byte-for-byte with no modification
