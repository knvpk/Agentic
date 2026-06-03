## ADDED Requirements

### Requirement: Lint checklist includes CoreDNS-specific rules
The conventions checklist (Mode C) SHALL include a "CoreDNS networking" subsection with two rules evaluated when the networking mode is CoreDNS:
1. Service names MUST NOT contain underscores
2. Authentik service MUST include `AUTHENTIK_LISTEN__HTTP: "0.0.0.0:80"`

#### Scenario: Lint reports underscore service name in CoreDNS context
- **WHEN** lint is run on a service definition in a CoreDNS project with an underscore service name
- **THEN** the lint error references the invalid DNS hostname and suggests the hyphenated replacement

#### Scenario: Lint reports missing Authentik listen config in CoreDNS context
- **WHEN** lint is run on an Authentik service in a CoreDNS project without `AUTHENTIK_LISTEN__HTTP: "0.0.0.0:80"`
- **THEN** lint reports the missing env var and explains that without it Authentik binds at port 9000, requiring all cross-service SSO URLs to include `:9000`
