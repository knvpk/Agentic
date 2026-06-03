---
name: "OPSX: Archive"
description: Archive a completed change in the experimental workflow
category: Workflow
tags: [workflow, archive, experimental]
---

Archive a completed change in the experimental workflow.

**Input**: Optionally specify a change name after `/opsx:archive` (e.g., `/opsx:archive add-auth`). If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **If no change name provided, prompt for selection**

   Run `openspec list --json` to get available changes. Use the **AskUserQuestion tool** to let the user select.

   Show only active changes (not already archived).
   Include the schema used for each change if available.

   **IMPORTANT**: Do NOT guess or auto-select a change. Always let the user choose.

2. **Check artifact completion status**

   Run `openspec status --change "<name>" --json` to check artifact completion.

   Parse the JSON to understand:
   - `schemaName`: The workflow being used
   - `artifacts`: List of artifacts with their status (`done` or other)

   **If any artifacts are not `done`:**
   - Display warning listing incomplete artifacts
   - Prompt user for confirmation to continue
   - Proceed if user confirms

3. **Check task completion status**

   Read the tasks file (typically `tasks.md`) to check for incomplete tasks.

   Count tasks marked with `- [ ]` (incomplete) vs `- [x]` (complete).

   **If incomplete tasks found:**
   - Display warning showing count of incomplete tasks
   - Prompt user for confirmation to continue
   - Proceed if user confirms

   **If no tasks file exists:** Proceed without task-related warning.

4. **Assess delta spec sync state**

   Check for delta specs at `openspec/changes/<name>/specs/`. If none exist, proceed without sync prompt.

   **If delta specs exist:**
   - Compare each delta spec with its corresponding main spec at `openspec/specs/<capability>/spec.md`
   - Determine what changes would be applied (adds, modifications, removals, renames)
   - Show a combined summary before prompting

   **Prompt options:**
   - If changes needed: "Sync now (recommended)", "Archive without syncing"
   - If already synced: "Archive now", "Sync anyway", "Cancel"

   If user chooses sync, use Task tool (subagent_type: "general-purpose", prompt: "Use Skill tool to invoke openspec-sync-specs for change '<name>'. Delta spec analysis: <include the analyzed delta spec summary>"). Proceed to archive regardless of choice.

5. **Perform the archive**

   Create the archive directory if it doesn't exist:
   ```bash
   mkdir -p openspec/changes/archive
   ```

   Generate target name using current date: `YYYY-MM-DD-<change-name>`

   **Check if target already exists:**
   - If yes: Fail with error, suggest renaming existing archive or using different date
   - If no: Move the change directory to archive

   ```bash
   mv openspec/changes/<name> openspec/changes/archive/YYYY-MM-DD-<name>
   ```

6. **Display summary**

   Show archive completion summary including:
   - Change name
   - Schema that was used
   - Archive location
   - Spec sync status (synced / sync skipped / no delta specs)
   - Note about any warnings (incomplete artifacts/tasks)

7. **Linked issue sync (post-archive)**

   Read `linked_issue` from the archived `.openspec.yaml` at `openspec/changes/archive/YYYY-MM-DD-<name>/.openspec.yaml`.

   **If `linked_issue` is absent**: print terminal-only summary line "No linked issue — skipping ticket sync." and stop.

   **If `linked_issue` is present**: proceed through signal gathering, synthesis, and post steps below.

   #### 7a — Gather signals (run in parallel where possible)

   **Signal 1 — Spec diff**

   Check for delta specs at `openspec/changes/archive/YYYY-MM-DD-<name>/specs/`. If none exist, set spec_signal = empty.

   If delta specs exist, for each `openspec/changes/archive/YYYY-MM-DD-<name>/specs/<capability>/spec.md`:
   - Read the delta spec
   - Read the corresponding main spec at `openspec/specs/<capability>/spec.md` (may not exist yet if this was a new capability)
   - Extract: new requirements (lines/sections added), modified requirements, new capabilities, removed capabilities
   - Label as `spec_signal` (list of bullet points)

   **Signal 2 — Git diff**

   Determine the diff range:
   - If `.openspec.yaml` has `base_ref`: use `git diff <base_ref>..HEAD --stat`
   - Otherwise: use `git diff $(git merge-base HEAD main)..HEAD --stat` (try `main`, then `master`, then `develop` as base)

   ```bash
   git diff <range> --stat
   ```

   Extract:
   - Top 10 changed files by line count (skip binary files)
   - Total: N files changed, X insertions, Y deletions
   - Label as `git_signal`

   **Signal 3 — Session thread**

   Scan the current conversation for:
   - Explicit decisions (phrases like "we decided", "going with", "ruled out", "won't", "will not")
   - Scope changes ("scope changed", "out of scope", "added to scope")
   - Ticket references (`#N`, `PROJ-N`, issue URLs) — collect separately as `related_refs`
   - Label as `thread_signal`

   #### 7b — Skip heuristic

   Skip posting if ALL of the following are true:
   - `spec_signal` is empty or contains only whitespace/formatting changes
   - `git_signal` touches only `.md` files or is empty
   - `thread_signal` has no detected decisions or scope changes

   If skipping: print "No substantive changes detected — skipping ticket comment." and stop.

   #### 7c — Synthesis

   Combine non-empty signals into a structured comment draft:

   ```
   ## Change `<name>` archived

   **Specs:** <spec diff summary, or "no delta specs">
   **Code:** <top changed files with +/- counts, or "no code changes detected">
   **Decisions:** <thread conclusions as bullets, or "none recorded this session">
   ```

   #### 7d — Confirmation and post

   Show the draft comment to the user. Use **AskUserQuestion** to ask:
   > "Post this summary to <provider> issue #<id>?"
   Options: "Post it", "Edit first", "Skip"

   If "Edit first": show the draft as plain text, let the user provide edits, then re-confirm.

   If "Post it" or after edits confirmed:
   - Route via provider:
     - **GitHub**: `mcp__github__add_issue_comment` (repo from `project_ref`, issue_number from `id`)
     - **GitLab**: `mcp__gitlab__create_note` → fallback `glab issue note <id> -m "..."` → fallback `curl` REST (`POST /api/v4/projects/<gitlab_project_id>/issues/<id>/notes`)
     - **Jira**: Jira comment API via configured MCP prefix
     - **Plane**: Plane comment API via configured MCP prefix
   - On write failure: print the comment text to terminal with "⚠ Could not write to tracker — copy and post manually."

   **If spec diff added new requirements**, separately ask:
   > "Append these new acceptance criteria to the ticket body?"
   Options: "Yes, append", "Skip"
   - If yes: fetch current ticket body, append a `## Acceptance Criteria (from <name>)` section, write back via provider adapter. Do NOT overwrite existing content.

   **If `related_refs` is non-empty** (ticket references found in signals, different from primary):
   - Show: "Signals mention these other tickets: <list>"
   - Ask: "Comment on any of these too?" Let user select which ones (multi-select).
   - For each selected: post a shorter comment: "Related change `<name>` was archived. See <primary issue URL> for details."

**Output On Success**

```
## Archive Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Archived to:** openspec/changes/archive/YYYY-MM-DD-<name>/
**Specs:** ✓ Synced to main specs
**Ticket:** ✓ Commented on <provider> #<id>

All artifacts complete. All tasks complete.
```

**Output On Success (No Delta Specs)**

```
## Archive Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Archived to:** openspec/changes/archive/YYYY-MM-DD-<name>/
**Specs:** No delta specs
**Ticket:** ✓ Commented on <provider> #<id>  (or "No linked issue")

All artifacts complete. All tasks complete.
```

**Output On Success With Warnings**

```
## Archive Complete (with warnings)

**Change:** <change-name>
**Schema:** <schema-name>
**Archived to:** openspec/changes/archive/YYYY-MM-DD-<name>/
**Specs:** Sync skipped (user chose to skip)
**Ticket:** ✓ Commented on <provider> #<id>  (or "Skipped — no linked issue" / "Skipped — no substantive changes")

**Warnings:**
- Archived with 2 incomplete artifacts
- Archived with 3 incomplete tasks
- Delta spec sync was skipped (user chose to skip)

Review the archive if this was not intentional.
```

**Output On Error (Archive Exists)**

```
## Archive Failed

**Change:** <change-name>
**Target:** openspec/changes/archive/YYYY-MM-DD-<name>/

Target archive directory already exists.

**Options:**
1. Rename the existing archive
2. Delete the existing archive if it's a duplicate
3. Wait until a different date to archive
```

**Guardrails**
- Always prompt for change selection if not provided
- Use artifact graph (openspec status --json) for completion checking
- Don't block archive on warnings - just inform and confirm
- Preserve .openspec.yaml when moving to archive (it moves with the directory)
- Show clear summary of what happened
- If sync is requested, use the Skill tool to invoke `openspec-sync-specs` (agent-driven)
- If delta specs exist, always run the sync assessment and show the combined summary before prompting
- Step 7 (linked issue sync) runs after the archive move — never before
- Never auto-post to any ticket without user confirmation (show draft first)
- Never overwrite ticket body — append-only; require explicit confirmation for body changes
- If write to tracker fails, always print the comment text to terminal as fallback
- Related ticket comments require per-ticket or batch confirmation — never auto-post
