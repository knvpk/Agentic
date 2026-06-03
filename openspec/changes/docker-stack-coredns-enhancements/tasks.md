## 1. SKILL.md — CoreDNS Service Name Normalization Step

- [x] 1.1 Add step A4.1 after the "Copy service files" step in Mode A scaffold — titled "CoreDNS service name normalization (CoreDNS mode only)"
- [x] 1.2 Document in A4.1: for each copied `.yaml` file, rewrite every service key under `services:` that contains `_` by replacing `_` with `-`
- [x] 1.3 Document in A4.1: after renaming keys, scan all URL-form env var values (`http://`, `https://`, `redis://`) and `depends_on` keys in all copied files and apply the same name substitutions
- [x] 1.4 Embed the full substitution reference table (old → new) from the design doc into A4.1 so the implementer has a concrete lookup
- [x] 1.5 Document in A4.1: apply substitutions to `env.template`-derived `.env` content for any entries referencing normalized service names (specifically `FALKORDB_URI`)

## 2. SKILL.md — CoreDNS Authentik Port Normalization Step

- [x] 2.1 Add step A4.2 immediately after A4.1 — titled "Authentik port normalization (CoreDNS mode only, when authentik selected)"
- [x] 2.2 Document in A4.2: add `COMPOSE_PORT_HTTP: "80"` and `COMPOSE_PORT_HTTPS: "443"` to the `idp-server` environment block in the copied `docker/authentik/service.yaml`
- [x] 2.3 Document in A4.2: rewrite all cross-service URLs containing `idp-server:9000` (or the pre-normalized `idp_server:9000`) to remove the `:9000` suffix — specifically `GENERIC_TOKEN_ENDPOINT` and `GENERIC_USERINFO_ENDPOINT` in `docker/litellm/service.yaml`

## 3. SKILL.md — Lint Checklist Updates (Mode C)

- [x] 3.1 Add a "CoreDNS networking" subsection to the Mode C conventions checklist
- [x] 3.2 Add lint rule: `[ ] Service names contain no underscores (underscores are invalid DNS hostname characters)`
- [x] 3.3 Add lint rule: `[ ] Authentik service includes COMPOSE_PORT_HTTP: "80" and COMPOSE_PORT_HTTPS: "443"`

## 4. Catalog Updates

- [x] 4.1 Add a "CoreDNS service name" column to the service table in `references/catalog.md` showing the normalized hyphenated name for every service that has underscores
- [x] 4.2 Add a note to the Authentik row in the catalog: "CoreDNS mode: add `COMPOSE_PORT_HTTP: 80` and `COMPOSE_PORT_HTTPS: 443`; cross-service SSO URLs reference `idp-server` without port"
- [x] 4.3 Add a note at the bottom of the catalog: "Asset templates are not modified; normalization is applied at scaffold time by SKILL.md step A4.1. If templates are re-synced from upstream, verify the substitution table in A4.1 still covers all underscore service names."

## 5. Verification

- [x] 5.1 Mentally trace a full CoreDNS scaffold with `authentik`, `litellm`, `falkor_db`, `graphiti`, `prefect`, `grafana`, `webui`, `chroma`, `mission_control` selected and confirm every output service name is hyphenated and every cross-reference is updated
- [x] 5.2 Confirm Traefik-mode scaffold trace leaves all service names unchanged
- [x] 5.3 Confirm lint checklist in SKILL.md now covers all three new rules (underscore name, Authentik port, and the existing checks still present)
