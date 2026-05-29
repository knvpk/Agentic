## Why

After `init` scaffolds a project and docs/ is populated, users must create tickets one at a time via `ticket new`. There is no path from a complete set of requirements docs to a full backlog in a single operation — a critical gap that forces manual, repetitive work and causes scaffold/maintenance tickets (CI, schema migrations, service setup) to be missed entirely. Additionally, when `ticket new` receives a broad topic (e.g. "auth system"), the skill has no mechanism to detect that the input describes multiple tickets and silently creates an under-scoped single ticket.

## What Changes

- **New mode `bulk`**: reads all files in `docs/` and generates a prioritised, dependency-ordered manifest of ticket candidates covering features, scaffold tasks, migrations, maintenance, and spikes — then creates all approved tickets in one pass.
- **Intelligent breakdown in `ticket new`**: detects when a single-ticket request spans wide scope (multiple docs sections, plural behaviors, multi-layer architecture) and proposes a mini-breakdown manifest before creating tickets.
- **Ticket type taxonomy**: introduces typed ticket categories (`feature`, `task`, `scaffold`, `migration`, `maintenance`, `spike`) derived from which doc section the ticket originated in.
- **Manifest review UX**: shared interactive manifest format (checklist table with edit commands) used by both `bulk` and the `ticket new` breakdown path.
- **Post-create sprint assignment**: after bulk creation, offer to assign all created tickets to the active sprint and auto-create epic labels.
- **Deduplication against existing tickets**: before creating, list existing tracker tickets and skip candidates that are semantically equivalent.

## Capabilities

### New Capabilities

- `bulk-ticket-generation`: Core decomposition logic — reads all docs/ files, maps each section to a typed ticket candidate, infers dependencies between candidates, deduplicates against existing tracker tickets, and outputs an ordered manifest.
- `ticket-breakdown-detection`: Scope-width heuristic applied at `ticket new` entry — detects when a single request spans ≥3 doc sections or describes ≥2 distinct behaviors, and routes to mini-bulk flow instead of single-ticket creation.
- `ticket-manifest-review`: Shared interactive manifest UX (preview table + edit commands: skip, keep, rename, merge, type, create) used by both `bulk` mode and `ticket new` breakdown.

### Modified Capabilities

- `ticket-management`: `ticket new` sub-mode gains a pre-creation scope-width check that can route to the breakdown manifest flow.
- `ticket-content-generation`: Body generation (Summary, Context, Requirements, Scenarios, Use Cases, NFR, OpenSpec Hint) is now invoked per-ticket at create time from the manifest, not only from direct `ticket new` input.

## Impact

- `skills/project-management/SKILL.md`: new `bulk` mode section; updated `ticket new` flow with breakdown detection step; updated mode routing table.
- `openspec/specs/`: three new spec files for the new capabilities; two delta specs for modified capabilities.
- No provider API changes — all new logic is pre-creation (doc parsing, manifest generation); ticket creation still uses existing MCP tool contracts.
- No breaking changes to existing modes.
