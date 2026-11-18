## Context

Three related gaps in the project-management skill, all keyed off `.project/config.yaml`:

1. `project_type` has five values; each feeds seven tables in `SKILL.md` (init question, stack follow-up, supplementary labels, docs scaffold file set, interactive-fill Step B, bulk doc mapping, BDD seeds) plus `config.schema.json`.
2. `ship` builds the PR body from a one-line summary and `Closes #id`. It reads only `git diff`, never runs anything, so PRs carry no proof of what was built.
3. `start` Step 2h always runs `git worktree add`. `--no-branch` is the only escape, and it skips branching entirely. There is no "branch in place" mode.

`pr-watch` is report-only and GitHub-only by spec; that invariant constrains how evidence links can be resolved after a PR exists.

## Goals / Non-Goals

**Goals:**
- Add `qa`, `ai`, `bi`, `cli`, `library` as first-class project types at parity with the existing five.
- Give each PR an `## Evidence` section whose content is a per-type default, auto-detected from the repo, overridable under `ship.evidence`.
- Let a project choose in-place branching over worktrees with `start.worktree`, asked at init.

**Non-Goals:**
- Refactoring the per-type tables into a data file (`references/project-types.json`). Considered; deferred to keep this change surgical.
- New doc files. The new types reuse `prd.md`, `architecture.md`, `database.md`, `tools.md`.
- A second `concerns` dimension on `project_type`. `qa` means a dedicated test-suite repo.
- GitLab support for qa report resolution; image hosting on GitLab.
- Per-invocation flags for worktree choice; `--no-branch` stays as the only flag and wins over config.
- A policy key to block `ship` when evidence is missing.
- Moving `base_branch` under `ship:` or `start:`; it stays top-level.

## Decisions

### D1: Add rows to existing tables, not a data-file refactor
Each new type gets a row in each existing `SKILL.md` table and the matching spec tables. **Alternative:** `references/project-types.json` mirroring `providers.json`, so type six costs one entry. Rejected for now: it rewrites the five working types and widens an already three-part change. Revisit once the new rows exist and the duplication is visible.

### D2: New type content (no new doc files)

| type | stack question (options) | docs scaffold | supplementary labels |
|---|---|---|---|
| `library` | Language? (python, typescript, go, rust, other) | prd, architecture, tools | `breaking-change`, `deprecation`, `semver`, `docs-gap` |
| `ai` | Shape? (llm-app, rag, agent, ml-training, other) | prd, architecture, tools | `prompt`, `eval`, `model`, `guardrail`, `cost`, `latency` |
| `bi` | Tooling? (dbt, metabase, superset, looker, powerbi, other) | prd, architecture, database, tools | `metric-definition`, `data-quality`, `dashboard`, `source` |
| `cli` | Language? (python, go, node, rust, other) | prd, architecture, tools | `breaking-change`, `ux`, `flags`, `exit-codes`, `completion`, `packaging`, `cross-platform` |
| `qa` | Test tool? (playwright, cypress, pytest, k6, other) | prd, architecture, tools | `flaky`, `coverage-gap`, `regression`, `test-data`, `env` |

`stack` remains required for every non-generic type (existing `if/then` rule unchanged); every list includes `other`. Public surface (library exports, CLI commands/flags and output contract) is captured in `architecture.md §Components`; `tools.md` uses its generic variant.

### D3: Evidence is four kinds with a per-type default

| kind | renders as | hosting needed |
|---|---|---|
| `link` | URL to a report or run | no |
| `image` | inline screenshot | yes |
| `markdown` | block pasted into PR body | no |
| `text` | fenced transcript | no |

Defaults: `web` → image; `mobile` → image; `bi` → image; `qa` → link; `api` → markdown; `cli`, `library`, `ai`, `microservices`, `generic` → text. A closed set of kinds means `ship` needs one renderer per kind regardless of what produced the item. **Alternative:** free-form evidence plugins. Rejected: unbounded surface, nothing to validate.

### D4: Config is `ship.evidence`, every key optional, detection first

```yaml
ship:
  evidence:
    kinds: [image, markdown]     # replaces the type default when present
    image:    { start_command: ..., base_url: ..., viewports: [...] }
    link:     { report_url: ... }
    markdown: { spec_path: ... }
    extra:    ["Rollback plan: revert PR"]
```

`kinds`, when present, is the full list and replaces the type default (explicit, no merge). Per-kind blocks are overrides for detection only. `extra` is an array of plain strings, appended as written, unconditional. A zero-config project works from the type default plus detection.

### D5: Detection runs at ship time and is shown at confirmation, not persisted
`ship` runs detection when the corresponding override key is absent and prints the resolved evidence plan in its Step 4 confirmation (kinds, tool, spec path, report source). It never writes detected values back to config. **Alternative:** detect at init and write to config for confirmation. Rejected: stale after tooling changes, and a second place that must stay in sync; the confirmation step already gives review. Config always wins over detection.

Detection signals:
- **qa:** `playwright.config.*` reporters / `@playwright/test`; `allure-results/`, `--alluredir`, allure plugins in dependencies; CI files (`.github/workflows/*`, `.gitlab-ci.yml`) with `upload-artifact`, `deploy-pages`, `allure generate`; ReportPortal/TestOps URLs.
- **web:** `package.json` scripts (`dev`, then `start`), default port for `base_url`.
- **api:** OpenAPI spec at `openapi.{yaml,yml,json}`, `docs/openapi*`, `swagger.*`.

### D6: qa links resolve without editing the PR after creation
The report link is derived at ship time: a published report URL if one can already be resolved, otherwise the branch's Actions runs page labelled "CI run (report published on completion)". `pr-watch` surfaces the final report link in its tick report when CI completes, but never edits the PR. **Alternative:** have `pr-watch` append the link to the PR body. Rejected: it breaks the "report-only, takes no action" requirement of `pr-watch`. GitLab: no qa link in v1, consistent with `pr-watch` being GitHub-only.

### D7: api evidence is spec-derived
Diff the detected OpenAPI spec between `base_branch` and `HEAD`; render each added or changed operation as markdown: method + path, parameters, request body schema/example, response schema/example. If endpoint-bearing source files changed but the spec did not, the evidence section says "spec unchanged" instead of rendering empty content. Live-capturing responses is out of scope.

### D8: image hosting on GitHub via orphan branch
Images are committed to an orphan `pr-evidence` branch and linked via `blob/{sha}/{path}?raw=true`, which resolves for viewers of private repos and survives squash-merge. **Alternatives:** commit into the feature branch (history bloat); CI artifacts (not inline). No GitHub image upload API exists. Capture itself (booting the app, driving pages) is performed by whatever the project's `image` config or detection resolves; `ship` attaches, it does not own the browser driver. If capture cannot run, the section reads `No evidence captured: {reason}`. GitLab image hosting is out of scope.

### D9: `start.worktree` with in-place branch creation
`start.worktree: true | false`, default `true` (absent = `true`, no re-asking). When `false`, Step 2h(ii) runs `git checkout -b {BRANCH_NAME} {BASE_BRANCH}` in the current checkout, omits the `Worktree:` line from the context block, and the "no worktree path" scenario applies. `--no-branch` takes precedence over config. A dirty working tree (`git status --porcelain` non-empty) in in-place mode is a fourth pre-flight-gate condition, so the user gets one combined prompt, and the subagent already defers mutation when the gate fires.

`init` asks: `Create a separate git worktree for each ticket? [Y/n]` with a hint naming untracked files, running dev servers, and submodules. The answer is written to `start.worktree`.

## Risks / Trade-offs

- [Seven tables × five types of prose in a 3,000-line `SKILL.md`] → Accepted per D1; revisit a data-file refactor after this lands.
- [Detection heuristics are fragile (custom CI, monorepos)] → Detection is visible at confirmation and every result is overridable under `ship.evidence`; unresolved cases print an explicit reason rather than blanking.
- [Screenshots can leak emails, tokens, real data] → Evidence plan is shown at the confirmation step before anything is pushed; attaching images is part of the existing `y/e/n` decision. No automated redaction in v1.
- [Orphan `pr-evidence` branch pollutes the branch list] → Single, predictable name; documented in the ship help block.
- [In-place branching can carry uncommitted changes onto the new branch] → Dirty-tree gate condition (D9).
- [`start` and `ship` now read nested config objects while `base_branch` stays top-level] → Accepted; moving it is a separate change.
- [qa link may only reach the PR as a runs-page URL] → Stated in the PR text, and `pr-watch` reports the final link.

## Migration Plan

All additions are backward compatible: missing `start.worktree` behaves as `true`; missing `ship.evidence` uses type defaults; existing five types are untouched. Existing configs validate against the extended schema without edits. Rollback is reverting the `SKILL.md`, schema, and spec edits; no persisted data changes (the `pr-evidence` branch is only created when image evidence is attached).

## Open Questions

- Should `ai` evidence default to `text` (sample inputs/outputs) or to a `link` to an eval report? v1 uses `text`; revisit when a project has a standard eval tool to detect.
- Whether the `image` capture driver should be a documented contract (a command in config that writes PNGs into a known directory) or left to the invoking agent. v1 leaves it to the agent and documents only the output location.
