# Spec delta: archive-ticket-sync

## Section: "Capture this" in opsx:explore

Replace the existing "Capture this in opsx:explore" section with the following:

---

## "Capture this" in opsx:explore

During or after an explore/implementation session, user says "capture this", "sync capture", or "capture".

### Step 0 — Resolve active change and linked_issue

Scan `openspec/changes/` (excluding `archive/`) for `.openspec.yaml` files. Pick the most recently created (by `created` field).

- If no active change: output `No active change found — nothing to capture.` and stop.
- If active change has no `linked_issue`: offer to write to `openspec/changes/<name>/notes.md` instead (append, create if absent). Proceed to Step 2 with notes.md as target.
- If active change has `linked_issue`: proceed to Step 1.

### Step 1 — Gate: did anything meaningful change?

#### Detect project type

SDD project: `openspec/` or `spec-kit/` directory exists at repo root.
Code-first project: neither directory present.

#### SDD gate — spec diff

Check for delta specs at `openspec/changes/<name>/specs/`.

- **Specs changed**: directory exists and contains at least one `.md` file → proceed to Step 2.
- **No spec change**: directory absent or empty → go to Override Prompt.

#### Code-first gate — LLM divergence judge

Fetch the linked ticket body via provider read tool. If fetch fails, degrade: skip judge and proceed to Step 2 with a note that original context was unavailable.

Judge over:
- Ticket body (original intent)
- Full current session conversation

Question: "Does this session contain decisions, scope changes, or approach shifts that differ meaningfully from the original ticket context?"

Output: Yes/No + one-sentence reason.

- **Divergence detected**: proceed to Step 2.
- **No divergence detected**: go to Override Prompt.

#### Override Prompt

When gate says "nothing changed", show reason and use **AskUserQuestion**:
> "Nothing significant looks different from the original ticket: `<judge reason>`. Capture anyway?"

Options: `Yes, capture it` | `Skip`

- `Yes`: proceed to Step 2 with a flag that gate was overridden.
- `Skip`: stop silently.

### Step 2 — Draft delta note

Synthesise across the **full current session** (not just the last exchange).

```markdown
**Session update — <change-name>**

**What changed from the original plan:**
- <bullet: divergence 1>
- <bullet: divergence 2>

**Why:**
<brief reasoning drawn from session>

**Final approach:**
<what was decided>
```

If gate was overridden (user forced capture) and nothing genuinely diverged, use a minimal format:
```markdown
**Session note — <change-name>**

<brief summary of session conclusion>
```

### Step 3 — Confirm and post

Show the draft. Use **AskUserQuestion**:
> "Post this to <provider> #<id>?"

Options: `Post it` | `Edit first` | `Skip`

On `Post it`: use provider routing table (same as `sync → archive`).
On `Edit first`: show draft as editable text, re-confirm.
On `Skip`: stop.

On success: `✓ Posted to #<id>.`
On failure: print draft to terminal with `⚠ Could not post — copy above to post manually.`

---

## Degradation Behaviour (additions to existing table)

| Missing element | Behaviour |
|----------------|-----------|
| Gate: no spec change (SDD) | Override prompt → user decides |
| Gate: no divergence (code-first) | Override prompt with judge reason → user decides |
| Ticket body fetch fails (code-first judge) | Skip judge, proceed to draft with note: "original ticket context unavailable" |
| Gate overridden, nothing diverged | Use minimal session note format |
