## MODIFIED Requirements

### Requirement: start mode invokes opsx:explore with assembled context
The skill SHALL assemble a context block containing issue fields, project doc context from the fallback chain, and code repo context, create the change shell (see `explore-handoff-contract`), then invoke `opsx:explore` with the block and a prompt that requires a verdict.

#### Scenario: opsx:explore receives full context
- **WHEN** start mode completes fetch, doc enrichment, branch step, and change shell creation
- **THEN** opsx:explore is invoked with a block containing: issue ID, title, state, description, relevant project doc sections, and code repo branch/recent commits, and a prompt requiring a `## Verdict` in `design.md`

#### Scenario: Missing opsx:explore falls back to inline presentation
- **WHEN** opsx:explore skill is not loaded
- **THEN** skill presents the assembled context block directly and offers: find affected files, list open questions, summarise implementation, create a change for this ticket — and does not offer to start implementing without a change
