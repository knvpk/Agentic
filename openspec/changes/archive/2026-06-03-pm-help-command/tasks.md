## 1. Pre-routing Intercept

- [x] 1.1 Add a "Pre-routing intercepts" subsection at the top of `skills/project-management/SKILL.md`, before the existing "Shared: Query Normalization" section, listing help triggers: `help`, `help <mode>`, `?`, `what can you do`, `commands`, `list commands`
- [x] 1.2 Add a `help` row to the Mode Routing table in `SKILL.md`: `| "help", "help <mode>", "?", "what can you do", "commands", "list commands" | **help** |`

## 2. Help Mode — General (Variant A)

- [x] 2.1 Add `## MODE: help` section to `SKILL.md` after the Mode Routing section
- [x] 2.2 Implement Variant A (no argument): grouped command index table with four categories — SETUP (init, docs), TICKETS (ticket new/update/link/list, bulk), SPRINTS (sprint plan/review/retro/close/milestone/labels), DAILY WORKFLOW (next, start, standup, status, backlog)
- [x] 2.3 Add config status line logic: if `.project/config.yaml` exists output `Current: provider={name} | sprint={active_sprint.name or "none"}`; if absent output `⚠ Not initialized — run: /project-management init`
- [x] 2.4 Add footer line: `Type: help <mode>  for details. Example: help sprint`

## 3. Help Mode — Mode-Specific (Variant B)

- [x] 3.1 Implement `help <mode>` sub-sections for each mode: `init`, `docs`, `ticket`, `sprint`, `next`, `start`, `status`, `standup`, `backlog`, `bulk` — each with one-line description, sub-commands (if applicable), and two example trigger phrases
- [x] 3.2 Add unknown-mode fallback: `Unknown mode: <name>. Valid modes: init, docs, ticket, sprint, next, start, status, standup, backlog, bulk`
