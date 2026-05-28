# Adding a new provider

Each provider implements the same three-step interface. The dispatcher in `SKILL.md` routes automatically — you only need to add the provider-specific logic here.

## Checklist

1. **Provider registry** — add a row to the table in `SKILL.md`:
   ```
   | MyProvider | URL contains `myprovider.com`, or `MP-123` key format | [references/myprovider.md](references/myprovider.md) |
   ```

2. **Hostname detection** — add a rule to Step 1 Case A in `SKILL.md`:
   ```python
   elif "myprovider.com" in host:
       provider = "myprovider"
   ```

3. **URL path patterns** — add a patterns block to Step 1 Case A in `SKILL.md`:
   ```python
   elif provider == "myprovider":
       patterns = [
           r'/your/current/path/pattern/(\d+)',   # newest first
       ]
       for p in patterns:
           m = re.search(p, path)
           if m:
               project_ref, issue_id = m.group(1), m.group(2)
               break
       else:
           parse_failed = True
   ```

4. **Fetch method resolution** — add CLI/MCP entries to Step 2 in `SKILL.md`:
   ```python
   cli_map = {..., "myprovider": "mpcli"}
   mcp_map = {..., "myprovider": "mcp__myprovider"}
   ```

5. **Reference file** — create `references/myprovider.md` with:
   - URL patterns list (for future maintainers)
   - **Interface Step A** — fetch issue → outputs `TITLE`, `STATE`, `LABELS`, `DESCRIPTION`, `URL`, `AUTHOR`, `ASSIGNEES`
   - **Interface Step B** — fetch comments → list of `{author, body}`, human only, max 10, ascending
   - **Interface Step C** — fetch linked issues → list of `{id, title, description_summary}`, max 5
   - Each step has three variants: **via CLI**, **via MCP**, **via API**

## URL pattern maintenance

When a provider changes their URL structure:

1. Add the new pattern at the **top** of the patterns list — newest first.
2. Keep old patterns — historical issue links in comments don't update when a provider changes their scheme.
3. Test with a real URL by running `/issue-explore <the-url>`.

## Interface contract

All three steps must produce output in the same format regardless of fetch method (CLI/MCP/API), so the dispatcher can consume them without knowing which method was used.

| Step | Output |
|------|--------|
| A | `ISSUE_TITLE`, `ISSUE_STATE`, `ISSUE_LABELS`, `ISSUE_DESCRIPTION`, `ISSUE_URL`, `ISSUE_AUTHOR`, `ISSUE_ASSIGNEES` |
| B | List of `{author, body}` — human comments only, max 10, ascending |
| C | List of `{id, title, description_summary}` — max 5 |
