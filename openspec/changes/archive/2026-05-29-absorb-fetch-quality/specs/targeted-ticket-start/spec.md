## ADDED Requirements

### Requirement: start mode ranks and trims comments when the ticket has more than 10
When the fetched ticket has more than 10 comments, the skill SHALL score each comment by: reporter/assignee authorship (+3), presence of code references — MR/PR URLs, backtick blocks, or branch/commit keywords (+2), body length > 100 characters (+1), bot author pattern — `[bot]`, `github-actions`, `dependabot`, `renovate` (−5). The skill SHALL keep the top 7 scored comments plus the last 3 (most recent), deduplicate by comment ID, and expose the result as `priority_comments`. The context block SHALL include `comments_total` and `comments_shown` counts when trimming occurs.

#### Scenario: Busy ticket trimmed to at most 10 priority comments
- **WHEN** a fetched ticket has 50 comments
- **THEN** `priority_comments` contains at most 10 entries and the context block header reads `Comments (10 of 50 shown — ranked by relevance)`

#### Scenario: Ticket with 10 or fewer comments is passed through unchanged
- **WHEN** a fetched ticket has 8 comments
- **THEN** all 8 comments are included without ranking and no `comments_total` / `comments_shown` note is added

#### Scenario: Reporter comments ranked to top
- **WHEN** the ticket reporter left 2 comments among 40 total
- **THEN** both reporter comments appear in `priority_comments`

#### Scenario: Bot comments deprioritized
- **WHEN** `dependabot[bot]` authored 6 comments among 40 total
- **THEN** none of the bot comments appear in `priority_comments` unless their score exceeds non-bot comments

---

### Requirement: start mode fetches linked issues when the description is insufficient
When the fetched ticket's description is fewer than 150 characters, is empty, or consists solely of cross-reference links with no prose, the skill SHALL attempt to fetch linked/related issues via the provider's `list_issue_relations` MCP tool (or equivalent from `tool_contracts` in `references/providers.json`). If the tool is unavailable for the provider, the skill SHALL skip silently and continue. Fetched linked issues SHALL be appended to the context block as a `--- Linked Issues ---` section with each entry showing: ID, state, and title.

#### Scenario: Thin description triggers linked issue fetch
- **WHEN** ticket description is 60 characters of cross-reference text only
- **THEN** skill calls the provider's linked-issues MCP tool and appends results to the context block

#### Scenario: Adequate description skips linked issue fetch
- **WHEN** ticket description is 400 characters of prose
- **THEN** linked issue fetch is skipped entirely — no additional MCP call is made

#### Scenario: Provider without linked-issues MCP tool skips silently
- **WHEN** `list_issue_relations` or equivalent is absent from the provider's `tool_contracts`
- **THEN** the `--- Linked Issues ---` section is omitted from the context block and no error is shown

#### Scenario: Linked issues rendered in context block
- **WHEN** linked issue fetch returns 3 issues
- **THEN** context block contains a `--- Linked Issues ---` section with 3 entries, each showing ID, state, and title

---

### Requirement: start mode renders custom provider fields in the context block
After fetching the ticket, the skill SHALL collect all non-null, non-standard fields returned by the provider's `get_ticket` MCP response (such as `Sprint`, `Story Points`, `Epic`, `Fix Version`, `Priority`) and render them in a `--- Provider Fields ---` section in the context block passed to `opsx:explore`. If the provider returns no custom fields, this section is omitted entirely.

#### Scenario: Sprint and story points rendered when present
- **WHEN** the provider returns a ticket with `Sprint: "Sprint 4"` and `Story Points: 5`
- **THEN** the context block contains a `--- Provider Fields ---` section with `Sprint: Sprint 4` and `Story Points: 5`

#### Scenario: Provider fields section omitted when empty
- **WHEN** the provider returns no custom fields or all custom fields are null
- **THEN** the `--- Provider Fields ---` section is not present in the context block

---

### Requirement: start mode scans description and comments for code cross-references
After fetching the ticket and its comments, the skill SHALL scan the full text of the description and all comment bodies for: MR/PR URLs (GitLab `/-/merge_requests/N`, GitHub `/pull/N`), branch name mentions (branch keyword followed by a word of 4–80 characters), and commit SHAs (7–40 hex characters). Results SHALL be deduplicated and capped at 10. The extracted references SHALL be included in the context block as a `--- Code References in Issue ---` section.

#### Scenario: MR URL extracted from description
- **WHEN** description contains `https://gitlab.com/org/repo/-/merge_requests/55`
- **THEN** that URL appears in the `--- Code References in Issue ---` section of the context block

#### Scenario: GitHub PR URL extracted from a comment
- **WHEN** a comment body contains `https://github.com/owner/repo/pull/12`
- **THEN** that URL appears in the `--- Code References in Issue ---` section

#### Scenario: Cap at 10 refs enforced
- **WHEN** description and comments contain 18 distinct code references
- **THEN** `--- Code References in Issue ---` contains exactly 10 entries

#### Scenario: Section shows none when no references found
- **WHEN** description and all comments contain no MR/PR URLs, branch mentions, or commit SHAs
- **THEN** context block shows `--- Code References in Issue ---\n(none found)`
