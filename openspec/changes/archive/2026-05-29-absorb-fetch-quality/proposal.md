## Why

`project-management start` fetches a ticket and enriches it with project doc context, but its raw ticket fetch is shallow — it misses comment ranking, linked issue fetching, custom provider fields, and code cross-reference scanning that `issue-explore` has built up. When a user starts a ticket with 60 comments or a thin description that leans on linked issues, they get an impoverished exploration context compared to what `issue-explore` would have provided.

## What Changes

- **Add comment ranking/trimming to pm start Step 2** — when a fetched ticket has > 10 comments, apply the same scorer (reporter/assignee +3, code refs +2, body length +1, bot −5), keep top 7 + last 3, write back `priority_comments` with total/shown counts
- **Add linked issue fetching to pm start Step 2** — when description is insufficient (< 150 chars, empty, or cross-refs only), fetch linked/related issues and append their titles and summaries to the context block
- **Add custom provider fields to pm start context block** — render `Sprint`, `Story Points`, `Epic`, and other tracker-specific fields (sourced from the ticket's metadata) in a `--- Provider Fields ---` section
- **Add code cross-reference scanning to pm start Step 2** — scan description + all comment bodies for MR/PR URLs, branch mentions, and commit SHAs; cap at 10; include as `--- Code References in Issue ---` section in the context passed to opsx:explore

## Capabilities

### New Capabilities

*(none — this change only enriches an existing mode)*

### Modified Capabilities

- `targeted-ticket-start`: Step 2 (fetch) and Step 6 (context block) gain comment ranking, linked issue fetching, custom fields rendering, and code cross-reference scanning — all ported from `issue-explore`

## Impact

- `skills/project-management/SKILL.md` — MODE: start, Steps 2 and 6
- `openspec/specs/targeted-ticket-start/spec.md` — new requirements added for the four fetch-quality features
- No changes to `issue-explore` — it continues to serve the zero-config/ad-hoc use case
- No breaking changes — new context sections are additive; the context block gains sections, it does not lose any
