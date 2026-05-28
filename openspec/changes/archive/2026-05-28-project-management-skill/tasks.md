## 1. Skill Scaffold & Frontmatter

- [x] 1.1 Create `skills/project-management/` directory
- [x] 1.2 Write `SKILL.md` with agentskills.io-compliant frontmatter (name, description <1024 chars, compatibility)
- [x] 1.3 Add mode routing table to SKILL.md mapping trigger phrases to: init, docs, sprint, ticket, next, status
- [x] 1.4 Create `skills/project-management/references/` directory

## 2. Provider Registry

- [x] 2.1 Create `references/providers.json` with schema version field and empty providers array
- [x] 2.2 Add GitHub entry: mcp_prefix, tool_contracts (create_ticket, update_ticket, list_tickets, create_label, create_milestone, sprint: null), state_mapping, plan_variants, fallbacks
- [x] 2.3 Add GitLab entry: mcp_prefix, tool_contracts, state_mapping, plan_variants, fallbacks
- [x] 2.4 Add Jira entry: mcp_prefix, tool_contracts (including sprint, board), state_mapping, plan_variants, fallbacks
- [x] 2.5 Add Plane entry: mcp_prefix, tool_contracts (including cycles, modules), plan_variants (free/paid), fallbacks for epics and relationships
- [x] 2.6 Write `references/github.md` — limitations (no native sprints/epics, milestone proxy, label-based state), setup instructions
- [x] 2.7 Write `references/gitlab.md` — milestone-as-sprint, EE-only blocks relation, setup instructions
- [x] 2.8 Write `references/jira.md` — sprint board_id requirement, agile API notes, setup instructions
- [x] 2.9 Write `references/plane.md` — free plan limitations (no modules/epics), cycle=sprint mapping, setup instructions

## 3. Init Mode & Capability Detection

- [x] 3.1 Implement init mode: detect provider from git remote or ask user
- [x] 3.2 Implement ToolSearch probe (signal 1): verify required MCP tools exist for selected provider
- [x] 3.3 Implement API probe (signal 2): call safe read endpoints per feature (epics, sprints, relationships, sub_issues)
- [x] 3.4 Map probe responses (200/403/missing) to capability flags per design decision D1
- [x] 3.5 Write capability results to `.project/config.yaml` with `probed_at` ISO-8601 timestamp
- [x] 3.6 For ambiguous probe results, ask user the minimum required question (y/n per feature)
- [x] 3.7 Implement lazy re-probe on unexpected mid-session 403 (update config, retry with fallback)
- [x] 3.8 Implement `init --probe` flag to force re-detection ignoring cache
- [x] 3.9 Implement user notification when fallback strategy is activated
- [x] 3.10 Bootstrap canonical state labels during init for label-dependent providers (GitHub, GitLab): create todo, in-progress, in-review, blocked labels if absent; skip for native-state providers (Jira, Plane)

## 4. Docs Management Mode

- [x] 4.1 Implement docs mode entry point: check if `docs/` exists, scaffold if not
- [x] 4.2 Scaffold `docs/prd.md` with sections: Overview, Features, Non-Functional Requirements, Requirements, Scenarios
- [x] 4.3 Scaffold `docs/architecture.md` with sections: Overview, Components, Data Flow, Architecture Decisions
- [x] 4.4 Scaffold `docs/database.md` with sections: Overview, Entities, Relationships, Schema Notes
- [x] 4.5 Scaffold `docs/tools.md` with sections: Language, Framework, CI/CD, Command Runner, Dev Environment, Testing, App Dependencies (Docker), Linting & Formatting
- [x] 4.6 Implement docs read helper: reads all four files and returns section-indexed content for use by other modes
- [x] 4.7 Implement docker-modular-stack suggestion: when a service name is added to tools.md `## App Dependencies (Docker)`, check against docker-modular-stack catalog and suggest the skill if matched
- [x] 4.8 Add `context_repos` support in `.project/config.yaml`: accept a list of local repo paths for cross-repo context fallback

## 5. Ticket Content Generation

- [x] 5.1 Implement ticket brief generator: accept user description as input
- [x] 5.2 Implement relevance matcher: given ticket topic, score each docs section by keyword/semantic match; return only sections above threshold
- [x] 5.3 Apply relevance matcher across all four docs files (prd.md, architecture.md, database.md, tools.md); collect matching pieces only
- [x] 5.4 Implement local repo fallback: when docs yield no match, search `src/`, `lib/`, config files by filename and content proximity to ticket topic
- [x] 5.5 Implement cross-repo fallback: when local search yields nothing and `context_repos` is set in config.yaml, search those repo paths
- [x] 5.6 Generate `## Context` block from matched pieces with source path + section references; warn if fallback chain exhausted with no match
- [x] 5.7 Generate `## Requirements` block using SHALL normative language (minimum 2 requirements)
- [x] 5.8 Generate `## Scenarios` block in GIVEN/WHEN/THEN BDD format (one block per distinct behaviour)
- [x] 5.9 Generate `## Use Cases` block with Actor, Precondition, Flow (numbered), Postcondition
- [x] 5.10 Generate `## Non-Functional` block from prd.md NFR section and user input
- [x] 5.11 Generate `## OpenSpec Hint` line: `/opsx:ff <ticket title>` using this ticket as context

## 6. Ticket Management Mode

- [x] 6.1 Implement ticket create: resolve MCP tool from providers.json tool_contracts, call with generated brief as body
- [x] 6.2 Enforce minimum ticket fields: title + at least one label or sprint assignment
- [x] 6.3 Implement canonical state machine validation before all state transitions
- [x] 6.4 Implement ticket update: state transition, label change, assignee, sprint assignment
- [x] 6.5 Implement `blocked` state: prompt for reason and optional blocking ticket ref, add `blocked` label
- [x] 6.6 Implement ticket list with canonical state filter (translate to provider query syntax)
- [x] 6.7 Implement parent/child relationship: native if supported, label (`epic:{slug}`) + description note if not
- [x] 6.8 Implement blocks/blocked-by relationship: native if supported, comment (`Blocked by: #{id}`) if not
- [x] 6.9 Implement relates-to relationship: native if supported, bidirectional label/comment if not

## 7. Sprint Management Mode

- [x] 7.1 Implement sprint create: map to milestone (GitHub/GitLab), sprint (Jira), or cycle (Plane) via providers.json
- [x] 7.2 For Jira: probe available boards, present selection, store board_id in config.yaml before sprint create
- [x] 7.3 Implement sprint add-ticket: assign issue to active sprint/milestone/cycle
- [x] 7.4 Implement sprint remove-ticket: clear sprint/milestone/cycle assignment from issue
- [x] 7.5 Implement label CRUD: create, list, assign labels via provider MCP tools
- [x] 7.6 Implement status mode: fetch active sprint tickets, group by canonical state, display counts + IDs

## 8. Next-Ticket Scheduler Mode

- [x] 8.1 Implement active sprint ticket fetch: single MCP batch call, returns all open in-sprint tickets with title, description, state, priority, estimate, relationships
- [x] 8.2 Resolve blocked ticket IDs: for each ticket with blocked-by links, check if any blocker is non-done
- [x] 8.3 Build unblocks-others map: count how many open tickets each candidate blocks (dependency fan-out)
- [x] 8.4 Score candidates: (1) in-progress WIP, (2) priority, (3) fan-out count, (4) smallest estimate
- [x] 8.5 Output recommendation: ticket ID, title, one-to-two sentence plain-English reasoning
- [x] 8.6 Handle empty candidate pool: output "No eligible tickets" with list of blocked tickets and their blockers

## 9. Verification

- [x] 9.1 Verify `npx skills` lists `project-management` with correct description
- [x] 9.2 Verify init mode writes `.project/config.yaml` with all required fields and probed_at timestamp
- [x] 9.3 Verify docs scaffold creates all four files (prd.md, architecture.md, database.md, tools.md) with correct section headers
- [x] 9.4 Verify generated ticket body contains all required sections including OpenSpec Hint
- [x] 9.9 Verify ticket context includes only relevant sections (not full docs files)
- [x] 9.10 Verify local file fallback activates when docs have no match for the ticket topic
- [x] 9.11 Verify docker-modular-stack suggestion appears when a catalog-matched service is added to tools.md
- [x] 9.5 Verify canonical state transitions reject invalid paths and dispatch valid ones to provider MCP
- [x] 9.6 Verify label fallback activates and notifies user when epics capability is false
- [x] 9.7 Verify next-ticket excludes blocked tickets and outputs reasoning with recommendation
- [x] 9.8 Verify sprint create maps correctly for each provider (milestone/sprint/cycle)
