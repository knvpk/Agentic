## 1. Routing Table

- [x] 1.1 Add `start` row to the Mode Routing table in `skills/project-management/SKILL.md` with triggers: "start TICK-42", "work on TICK-42", "begin TICK-42", "let's work on #42"

## 2. Ticket ID Parsing

- [x] 2.1 Add ticket ID parsing logic to `MODE: start` — handle bare number, key format (`PROJ-42`), hash format (`#42`), and full URL
- [x] 2.2 Add Jira bare-number guard: if provider is Jira and input is bare number, ask for project key prefix

## 3. Ticket Fetch

- [x] 3.1 Read provider and `mcp_prefix` from `.project/config.yaml` and call the configured MCP's `get_ticket` (or equivalent) tool to fetch the ticket

## 4. Project Doc Context Enrichment

- [x] 4.1 Run the Context Fallback Chain (prd.md → architecture.md → database.md → tools.md → local src → context_repos) filtered to the ticket topic, reusing the existing shared-section logic
- [x] 4.2 Emit the "No relevant context found" warning if all chain steps miss

## 5. State Transition

- [x] 5.1 After fetch, check ticket's canonical state; if `todo`, ask "Move to in-progress? [y/n]" and call `update_ticket` on Y using `state_mapping`
- [x] 5.2 If state is `backlog`, warn "not in active sprint" and ask to continue
- [x] 5.3 If state is already `in-progress`, skip silently

## 6. Branch Creation

- [x] 6.1 Add branching strategy detection (gitflow / three-branch / single-branch / trunk) reusing the Step 5a logic from `issue-explore`
- [x] 6.2 Derive branch name slug from ticket title using the same prompt-to-self approach (prefix + id + slug)
- [x] 6.3 Present derived branch name to user and ask for confirmation (Y/n/custom name); skip entirely if `--no-branch` passed

## 7. Context Assembly and opsx:explore Invocation

- [x] 7.1 Assemble context block: issue fields, project doc sections from fallback chain, code repo context (remote, branch, recent commits)
- [x] 7.2 Detect `opsx:explore` in loaded skills; invoke it with the context block
- [x] 7.3 If `opsx:explore` is not loaded, present context block inline with five numbered next-step options

## 8. Update next Mode Output

- [x] 8.1 In `MODE: next` Step 5, replace the two-line hint (`/project-management ticket update … --state in-progress` + `/opsx:ff …`) with: `Ready to start? /project-management start <id>`

## 9. Update Skill Frontmatter

- [x] 9.1 Update the `description` field in the SKILL.md frontmatter to include `start` in the list of modes (currently "Six modes: …")
