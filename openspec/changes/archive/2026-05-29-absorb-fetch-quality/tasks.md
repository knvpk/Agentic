## 1. Comment Ranking in pm start

- [x] 1.1 Add a comment-ranking sub-step to MODE: start Step 2 in `skills/project-management/SKILL.md` — after the `get_ticket` MCP call, check if comment count > 10
- [x] 1.2 Implement the scorer: reporter/assignee +3, code refs regex +2, body length > 100 +1, bot pattern −5
- [x] 1.3 Keep top 7 scored + last 3 (most recent), deduplicate by comment ID or first 40 chars of body
- [x] 1.4 Store as `priority_comments` with `comments_total` and `comments_shown` counts
- [x] 1.5 Update Step 6 context block to render `priority_comments` instead of raw comments, with the ranked-relevance note when trimming occurred

## 2. Linked Issue Fetching in pm start

- [x] 2.1 Add a thin-description check to MODE: start Step 2: trigger when description < 150 chars, empty, or cross-refs only
- [x] 2.2 Attempt to call `list_issue_relations` (or provider equivalent from `tool_contracts`) when trigger condition is met
- [x] 2.3 Handle missing MCP tool gracefully — skip silently, omit the section, no error shown
- [x] 2.4 Add `--- Linked Issues ---` section to Step 6 context block, each entry as `ID [state] title`

## 3. Custom Provider Fields in pm start

- [x] 3.1 After `get_ticket` call in Step 2, collect all non-null fields beyond the standard set (id, title, description, state, labels, assignees, sprint, priority, issue_type)
- [x] 3.2 Add `--- Provider Fields ---` section to Step 6 context block rendering each collected field as `key: value`
- [x] 3.3 Omit the section entirely when no custom fields are present

## 4. Code Cross-Reference Scanning in pm start

- [x] 4.1 After fetch in Step 2, scan description + all comment bodies with three regex patterns: GitLab MR URLs, GitHub PR URLs, branch name mentions (branch keyword + word), commit SHAs (7–40 hex chars)
- [x] 4.2 Deduplicate results, cap at 10, store as `ticket_code_refs`
- [x] 4.3 Add `--- Code References in Issue ---` section to Step 6 context block; show `(none found)` when list is empty

## 5. Spec Update

- [x] 5.1 Apply the delta spec from `openspec/changes/absorb-fetch-quality/specs/targeted-ticket-start/spec.md` into `openspec/specs/targeted-ticket-start/spec.md` — append the four ADDED requirement blocks
