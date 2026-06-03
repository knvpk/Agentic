## ADDED Requirements

### Requirement: CoreDNS scaffold configures Authentik to bind at port 80
When CoreDNS networking mode is selected and `authentik` is included in the scaffold, the skill SHALL add `AUTHENTIK_LISTEN__HTTP: "0.0.0.0:80"` and `AUTHENTIK_LISTEN__HTTPS: "0.0.0.0:9443"` to the `idp-server` (normalized from `idp_server`) container environment. These env vars MUST NOT be added in Traefik mode. `AUTHENTIK_LISTEN__HTTP` changes the port the server process binds to inside the container; `COMPOSE_PORT_HTTP` does not achieve this and MUST NOT be used.

#### Scenario: Authentik listen env vars added in CoreDNS mode
- **WHEN** CoreDNS mode is selected and `authentik` is scaffolded
- **THEN** the output `docker/authentik/service.yaml` contains `AUTHENTIK_LISTEN__HTTP: "0.0.0.0:80"` in the `idp-server` environment block

#### Scenario: Authentik listen env vars not added in Traefik mode
- **WHEN** Traefik mode is selected and `authentik` is scaffolded
- **THEN** `AUTHENTIK_LISTEN__HTTP` does not appear in the output service YAML

### Requirement: Cross-service SSO URL references to Authentik drop the port suffix in CoreDNS mode
When CoreDNS mode is selected, the skill SHALL rewrite any cross-service URL references that include `idp-server:9000` (or `idp_server:9000` before name normalization) to use `idp-server` without a port suffix, since Authentik now binds at port 80.

#### Scenario: LiteLLM SSO endpoint references updated
- **WHEN** CoreDNS mode is selected and both `authentik` and `litellm` are scaffolded
- **THEN** `docker/litellm/service.yaml` contains:
  - `GENERIC_TOKEN_ENDPOINT: "http://idp-server/application/o/token/"`
  - `GENERIC_USERINFO_ENDPOINT: "http://idp-server/application/o/userinfo/"`
  — with no `:9000` port suffix

#### Scenario: Traefik mode retains original port in SSO references
- **WHEN** Traefik mode is selected and both `authentik` and `litellm` are scaffolded
- **THEN** `docker/litellm/service.yaml` retains `http://idp_server:9000/application/o/token/` unchanged

### Requirement: Lint mode flags Authentik without port normalization env vars in CoreDNS projects
When linting an Authentik service definition in a CoreDNS project, the skill SHALL report an error if `COMPOSE_PORT_HTTP` is absent or set to a value other than `"80"`.

#### Scenario: Missing AUTHENTIK_LISTEN__HTTP triggers lint warning
- **WHEN** lint is run on an Authentik service YAML in a CoreDNS project and `AUTHENTIK_LISTEN__HTTP` is not set
- **THEN** lint reports: "Authentik is missing `AUTHENTIK_LISTEN__HTTP: '0.0.0.0:80'` — in CoreDNS mode it will bind at port 9000, requiring all cross-service SSO URLs to include `:9000`"

#### Scenario: Correct listen address passes lint
- **WHEN** lint is run on an Authentik service YAML with `AUTHENTIK_LISTEN__HTTP: "0.0.0.0:80"`
- **THEN** no port-related lint error is reported
