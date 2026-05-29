## Purpose

Defines the scope-width heuristic applied at `ticket new` entry point. When a single ticket request is detected as describing broad scope (multiple behaviors, multiple layers, or wide doc coverage), the skill routes to a mini-bulk flow instead of creating a single ticket.

## ADDED Requirements

### Requirement: Skill evaluates three independent scope-width signals before creating a single ticket
At the start of the `ticket new` sub-mode, the skill SHALL evaluate the user's input against three signals. If ANY single signal is true, the skill SHALL offer a breakdown before proceeding to single-ticket creation.

| Signal | Condition |
|---|---|
| Conjunction signal | Input contains "and" linking two distinct domain nouns, OR a comma-separated list of ≥2 domain items |
| Plural area signal | Input matches a known domain area word (auth, users, payments, notifications, settings, admin, reporting, search, onboarding) WITHOUT a specific action verb (create, delete, update, refresh, fetch, display) |
| Docs breadth signal | A quick relevance scan finds ≥3 distinct doc sections across `docs/` files that match the input topic |

#### Scenario: Conjunction signal triggers breakdown offer
- **WHEN** user inputs "create a ticket for auth and profile management"
- **THEN** the skill detects two domain nouns joined by "and"
- **AND** asks: "I see enough scope here for multiple tickets — propose a breakdown? [y/n]"

#### Scenario: Plural area signal triggers breakdown offer
- **WHEN** user inputs "create a ticket for the auth system"
- **AND** the input contains the area word "auth" without a specific action verb
- **THEN** the skill asks: "I see enough scope here for multiple tickets — propose a breakdown? [y/n]"

#### Scenario: Docs breadth signal triggers breakdown offer
- **WHEN** user inputs "create a ticket for authentication"
- **AND** relevance scan finds matching sections in prd.md, architecture.md, database.md, and api.md
- **THEN** the skill asks: "I see enough scope here for multiple tickets — propose a breakdown? [y/n]"

#### Scenario: Focused input does not trigger breakdown
- **WHEN** user inputs "create a ticket for refresh token on 401 response"
- **AND** the input contains a specific action ("refresh") and no plural area words or conjunctions
- **THEN** no breakdown offer is made and the skill proceeds with single-ticket creation as normal

#### Scenario: Single area word with action verb does not trigger
- **WHEN** user inputs "create a ticket to refresh the auth token"
- **AND** a specific action verb "refresh" is present alongside the area word "auth"
- **THEN** no breakdown offer is made and single-ticket creation proceeds

---

### Requirement: User can decline breakdown and proceed with single ticket
When a breakdown is offered, the user SHALL be able to decline. On decline, the skill SHALL proceed with single-ticket creation exactly as it does today, using the original input.

#### Scenario: User declines breakdown
- **WHEN** the breakdown offer is shown
- **AND** user responds "n"
- **THEN** the skill proceeds with `ticket new` single-ticket flow using the original input
- **AND** no manifest is generated

---

### Requirement: Accepting breakdown routes to mini-bulk flow scoped to matching sections
When the user accepts the breakdown offer, the skill SHALL run the bulk decomposition logic restricted to only the doc sections matching the input topic. The result SHALL be presented as a manifest using the standard manifest review format.

#### Scenario: Accepting breakdown shows narrowed manifest
- **WHEN** user accepts the breakdown offer for "authentication"
- **THEN** the skill runs decomposition scoped to doc sections matching "authentication"
- **AND** the resulting manifest contains only auth-related candidates (not the full docs/ sweep)

#### Scenario: Mini-bulk manifest uses same edit commands as full bulk
- **WHEN** the breakdown manifest is shown
- **THEN** the user can use the same edit commands: skip, rename, merge, type, create
