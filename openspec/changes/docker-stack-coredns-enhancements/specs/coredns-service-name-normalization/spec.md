## ADDED Requirements

### Requirement: Service templates use hyphenated service names
All Docker Compose service key names in `assets/services/` templates SHALL use hyphens instead of underscores, ensuring they are valid DNS hostnames. This applies unconditionally — both CoreDNS and Traefik modes copy the same templates, and hyphens are valid in both contexts.

#### Scenario: Scaffolded falkor_db uses hyphenated service names
- **WHEN** `falkor_db` is scaffolded in any networking mode
- **THEN** the output `docker/falkor_db/service.yaml` contains `graph-db1-server:` and `graph-db1-browser:` as service keys

#### Scenario: Scaffolded prefect uses hyphenated service names
- **WHEN** `prefect` is scaffolded
- **THEN** the output service YAML contains `prefect-server:`, `prefect-services:`, and `prefect-worker:` as service keys, not their underscore equivalents

#### Scenario: Full stack output contains no underscore service keys
- **WHEN** a full stack including `prefect`, `grafana`, `webui`, `chroma`, `authentik`, `falkor_db`, and `mission_control` is scaffolded
- **THEN** none of the service keys in any output YAML file contain an underscore

### Requirement: Hostname references within templates are consistent with service key names
Wherever a service name appears as a hostname in template files — in URL-form env var values (`http://`, `https://`, `redis://`) and `depends_on` keys — the value SHALL match the hyphenated service key name.

#### Scenario: URL env var references use hyphenated name
- **WHEN** `prefect` is scaffolded
- **THEN** `PREFECT_API_URL: http://prefect-server:4200/api` appears in the output (not `prefect_server`)

#### Scenario: Cross-file hostname reference is consistent
- **WHEN** both `falkor_db` and `graphiti` are scaffolded
- **THEN** `graphiti/service.yaml` contains `FALKORDB_URI: "redis://graph-db1-server:6379"` and `depends_on: graph-db1-server`

#### Scenario: env.template entry uses hyphenated name
- **WHEN** `falkor_db` is scaffolded
- **THEN** the generated `.env` contains `FALKORDB_URI="redis://graph-db1-server:6379"`

### Requirement: Lint mode reports underscore service names as an error
The skill's Mode C lint checklist SHALL flag any service key containing an underscore as an error, since underscores are not valid DNS hostname characters.

#### Scenario: Underscore service name triggers lint error
- **WHEN** lint is run on a service YAML containing `mission_control:` as a service key
- **THEN** lint reports: "Service name `mission_control` contains underscores — not a valid DNS hostname. Use `mission-control` instead."

#### Scenario: Hyphenated service name passes lint
- **WHEN** lint is run on a service YAML containing `mission-control:` as a service key
- **THEN** no underscore-related lint error is reported
