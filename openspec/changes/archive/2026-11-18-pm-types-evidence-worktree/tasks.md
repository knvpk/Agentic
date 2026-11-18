## 1. Config schema

- [x] 1.1 Extend `project_type_enum` in `skills/project-management/references/config.schema.json` with `qa`, `ai`, `bi`, `cli`, `library`
- [x] 1.2 Extend `stack_enum` with the stack values for the five new types (python, typescript, go, rust, node, llm-app, rag, agent, ml-training, dbt, metabase, superset, looker, powerbi, playwright, cypress, pytest, k6, other)
- [x] 1.3 Add optional top-level `start` object (`additionalProperties: false`, `worktree` boolean, default `true`)
- [x] 1.4 Add optional top-level `ship.evidence` object per the config-schema spec (`kinds`, `image`, `link`, `markdown`, `extra`)
- [x] 1.5 Validate the schema: a config with each new type + stack passes; `library` without `stack` fails; `start.worktree: "no"` fails; `ship.evidence.kinds: [video]` fails

## 2. New project types in SKILL.md

- [x] 2.1 Init Step 2: extend the type question list and the `project_type` value list (`SKILL.md` ~690-700)
- [x] 2.2 Init Step 2: add the five stack-question rows to the conditional follow-up table
- [x] 2.3 Init label bootstrap: add the five supplementary label rows (with colours) to the type-specific labels table
- [x] 2.4 Docs scaffold: add the five rows to the file-set table; update the per-file `*(mobile, web, api, generic)*` annotations so `prd.md`/`database.md` apply to the right new types; use the generic `tools.md` variant for the new types
- [x] 2.5 Docs interactive fill Step B: add the `bi` row to the database question and new rows for `library`, `ai`, `cli`, `qa`
- [x] 2.6 Bulk Step 1: add the five rows to the doc-files-to-read table
- [x] 2.7 Ticket BDD seeds: add the five seed-pattern rows
- [x] 2.8 Update any list of valid project types elsewhere in `SKILL.md` (help text, frontmatter description) found by grepping `microservices`

## 3. start.worktree

- [x] 3.1 Init: add the `Create a separate git worktree for each ticket? [Y/n]` question with the hint, write the answer to `start.worktree`; treat a missing key as `true` without re-asking
- [x] 3.2 Shared pre-flight gate section: add the dirty-tree condition (only when `start.worktree: false`) and its prompt reason text
- [x] 3.3 `start` Step 2h(ii): branch on `start.worktree` — keep `git worktree add` for true/absent, add `git checkout -b {BRANCH_NAME} {BASE_BRANCH}` for false; keep `--no-branch` taking precedence
- [x] 3.4 Step 2h gate-fired path and Step 3: propose the in-place action in `proposed_action`, and omit the `Worktree:` line from the context block in in-place mode (`SKILL.md` ~2356)
- [x] 3.5 Update `help start` text to mention `start.worktree`
- [x] 3.6 Manual check in a scratch repo: worktree true creates a sibling dir; false creates the branch in place; false + dirty tree asks one combined question; `--no-branch` wins

## 4. ship evidence

- [x] 4.1 Ship Step 3/4: add the evidence-plan resolver (kinds from `ship.evidence.kinds` or the project-type default; overrides over detection) and display the plan in the confirmation block
- [x] 4.2 Add detection rules: web (`package.json` scripts, port), api (OpenAPI spec paths), qa (Playwright/Allure/CI signals) as specified in design D5
- [x] 4.3 Add the four kind renderers: `text` transcript with exit codes, `markdown` from OpenAPI spec diff (including the `spec unchanged` case), `link` with the CI-runs-page fallback label, `image` with orphan `pr-evidence` branch hosting
- [x] 4.4 Ship Step 6 PR body: replace the body template with summary + `Closes` + `## Evidence`; remove the hard-coded session URL line; append `ship.evidence.extra` strings verbatim
- [x] 4.5 Add the `No evidence captured: {reason}` fallback for every failure path and make GitLab emit the GitHub-only notes for `link` and `image`
- [x] 4.6 Update `help ship` to describe the Evidence section, the `pr-evidence` branch, and `ship.evidence`
- [x] 4.7 Manual check against a scratch api repo (spec diff rendered; `spec unchanged` case) and a scratch cli repo (transcript with exit code)

## 5. pr-watch

- [x] 5.1 In `MODE: pr-watch`, add the completed-CI branch that includes the resolved test-report URL (or CI run URL) in the tick report when the evidence plan includes `link`; confirm it performs no PR edit or comment

## 6. Specs and verification

- [x] 6.1 Run `openspec validate pm-types-evidence-worktree` and fix any delta-spec format errors
- [x] 6.2 Grep `SKILL.md` for any remaining five-type-only tables (`microservices` rows without the new types) and reconcile
- [x] 6.3 Run `/opsx:verify` for this change before archiving
