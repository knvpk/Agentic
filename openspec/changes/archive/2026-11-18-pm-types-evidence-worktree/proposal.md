## Why

The project-management skill's PRs carry no proof of what was built: `ship` builds the PR body from a one-line summary and a `Closes` line, so reviewers must check out the branch to see anything. Separately, `project_type` only covers five shapes, missing `qa`, `ai`, `bi`, `cli` and `library` repos, and `start` always creates a git worktree, which breaks projects that need untracked files, a running dev server, or submodules.

## What Changes

- Add five `project_type` values: `qa`, `ai`, `bi`, `cli`, `library`. Each gets a stack question, supplementary labels, a docs scaffold file set, interactive-fill questions, bulk-generation doc mapping, and BDD seed patterns. No new doc files are introduced; the new types reuse existing ones.
- Add a `ship.evidence` block to `.project/config.yaml` and an `## Evidence` section in the PR body produced by `ship`. Evidence has four kinds (`image`, `link`, `markdown`, `text`) with a default per project type: web → image, qa → link, api → markdown (derived from the OpenAPI spec diff), cli/library/generic → text. Tool, report location, spec path and start command are auto-detected from the repo; config only overrides. `extra` is a list of plain strings appended as written.
- Add a `start.worktree` boolean (default `true`) to `.project/config.yaml`. When `false`, `start` creates the branch in place with `git checkout -b` instead of `git worktree add`. A dirty working tree in that mode becomes a fourth condition of the existing pre-flight gate. `init` asks the question.
- Add `ship` and `start` object definitions to the config schema; extend `project_type_enum` and `stack_enum`.
- Tighten the config schema so `stack` must belong to the declared `project_type` (plus `other`), and define the `base_branch` key that `ship` already reads.
- Ship's PR body drops the hard-coded session URL line.
- `pr-watch` surfaces the detected test-report link in its tick report once CI completes. It remains report-only and does not edit the PR.

## Capabilities

### New Capabilities
- `ship-evidence`: evidence kinds, per-project-type defaults, repo auto-detection of tools/specs/reports, the `ship.evidence` config block, and how `ship` renders the `## Evidence` PR section including the "none captured: reason" fallback.

### Modified Capabilities
- `project-type-detection`: five new types, their stack questions, doc scaffold file sets, and supplementary labels.
- `config-schema`: extended `project_type_enum`/`stack_enum`; new `start` and `ship` objects.
- `docs-management`: scaffold file set and `tools.md` variant per new type.
- `docs-interactive-fill`: Step B conditional questions for the new types.
- `bulk-ticket-generation`: doc files read per new type.
- `ticket-content-generation`: BDD seed patterns for the new types.
- `ship-mode`: PR body gains the Evidence section; session URL line removed.
- `start-mode-worktree-delegation`: worktree creation becomes conditional on `start.worktree`; init asks the question.
- `start-mode-autonomy`: dirty working tree (in-place mode) is a fourth gate condition.
- `pr-watch`: tick report surfaces the test-report link.

## Impact

- `skills/project-management/SKILL.md`: init (type, stack, worktree question, labels), docs, bulk, ticket BDD seeds, start (Step 2h), ship (Steps 3-6), pr-watch.
- `skills/project-management/references/config.schema.json`: enums, `start`, `ship` blocks, stack `if/then` unchanged.
- Specs under `openspec/specs/` listed above.
- No change to provider adapters or MCP tool contracts. GitHub image hosting for `image` evidence is in scope only as far as the design describes; GitLab qa report resolution is out of scope.
