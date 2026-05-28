# Provider: GitHub

Schema: [schema.json](schema.json)

**CLI:** `gh` — `brew install gh` or https://cli.github.com  
**MCP:** tools prefixed `mcp__github__`  
**API env vars:** `GITHUB_TOKEN` (required)

## URL patterns (newest first — never delete old ones)

```python
patterns = [
    r'/([^/]+/[^/]+)/issues/(\d+)',    # current: /owner/repo/issues/NNN
]
```

## State normalization

```python
def normalize_state(raw):
    raw = (raw or "").lower().strip()
    if raw == "open":   return "open"
    if raw == "closed": return "closed"
    return "unknown"
```

---

## Interface Step A — Fetch raw issue

Store result in `/tmp/ii_raw_issue.json`.

**via CLI**

`gh` auto-detects the repo from the current directory's git remote when `--repo` is omitted.
Only pass `--repo` if `PROJECT_REF` was explicitly provided (URL or `owner/repo#NNN`).

```bash
# PROJECT_REF known:
gh issue view "$ISSUE_ID" --repo "$PROJECT_REF" \
  --json title,state,body,labels,assignees,author,url > /tmp/ii_raw_issue.json

# PROJECT_REF empty — let gh detect from cwd:
gh issue view "$ISSUE_ID" \
  --json title,state,body,labels,assignees,author,url > /tmp/ii_raw_issue.json
```

**via MCP**  
Split `PROJECT_REF` on `/` to get `owner` and `repo`.
Call `mcp__github__get_issue` with `owner`, `repo`, `issue_number=ISSUE_ID`.
Write the raw response to `/tmp/ii_raw_issue.json`.

**via API**
```bash
curl -sf \
  --header "Authorization: Bearer $GITHUB_TOKEN" \
  --header "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$PROJECT_REF/issues/$ISSUE_ID" > /tmp/ii_raw_issue.json
```

---

## Interface Step B — Fetch raw comments

Store result in `/tmp/ii_raw_comments.json` (array of comment objects).

**via CLI**

```bash
# PROJECT_REF known:
gh issue view "$ISSUE_ID" --repo "$PROJECT_REF" --json comments > /tmp/ii_raw_comments.json

# PROJECT_REF empty:
gh issue view "$ISSUE_ID" --json comments > /tmp/ii_raw_comments.json
```

**via MCP**  
Call `mcp__github__list_issue_comments` with `owner`, `repo`, `issue_number`.
Write array to `/tmp/ii_raw_comments.json`.

**via API**
```bash
curl -sf \
  --header "Authorization: Bearer $GITHUB_TOKEN" \
  --header "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$PROJECT_REF/issues/$ISSUE_ID/comments?per_page=50" \
  > /tmp/ii_raw_comments.json
```

---

## Interface Step C — Fetch raw linked issues

Store result in `/tmp/ii_raw_linked.json`. GitHub has no first-class related-issues API — extract `#NNN` cross-refs from the body. Run only if description is insufficient (see SKILL.md Step 5a).

**via CLI**
```bash
python3 - <<'PY'
import json, re, subprocess, os

body = json.load(open('/tmp/ii_raw_issue.json')).get("body","") or ""
repo = os.environ.get("_II_PROJECT","")
refs = list(dict.fromkeys(re.findall(r'(?<![a-zA-Z])#(\d+)', body)))[:5]
out  = []
for ref in refs:
    cmd = ["gh","issue","view", ref,"--json","title,state,body,url"]
    if repo: cmd += ["--repo", repo]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode == 0:
        out.append(json.loads(r.stdout))
json.dump(out, open('/tmp/ii_raw_linked.json','w'))
PY
```

**via MCP**  
Extract `#NNN` refs from body, call `mcp__github__get_issue` for each.
Write array to `/tmp/ii_raw_linked.json`.

**via API**
```bash
python3 - <<'PY'
import json, re, os, subprocess

body  = json.load(open('/tmp/ii_raw_issue.json')).get("body","") or ""
token = os.environ.get("GITHUB_TOKEN","")
repo  = os.environ.get("_II_PROJECT","")
refs  = list(dict.fromkeys(re.findall(r'(?<![a-zA-Z])#(\d+)', body)))[:5]
out   = []
for ref in refs:
    r = subprocess.run(
        ["curl","-sf","--header",f"Authorization: Bearer {token}",
         "--header","Accept: application/vnd.github+json",
         f"https://api.github.com/repos/{repo}/issues/{ref}"],
        capture_output=True, text=True)
    if r.returncode == 0 and r.stdout:
        out.append(json.loads(r.stdout))
json.dump(out, open('/tmp/ii_raw_linked.json','w'))
PY
```

---

## Normalize — write `/tmp/ii_normalized.json`

Run after Steps A, B, C. Maps GitHub raw fields to [schema.json](schema.json).

```python
import json, os

# gh CLI wraps comments under {"comments": [...]}; API returns a bare array
raw_comments = json.load(open('/tmp/ii_raw_comments.json')) if os.path.exists('/tmp/ii_raw_comments.json') else []
if isinstance(raw_comments, dict):
    raw_comments = raw_comments.get("comments", [])

issue  = json.load(open('/tmp/ii_raw_issue.json'))
linked = json.load(open('/tmp/ii_raw_linked.json')) if os.path.exists('/tmp/ii_raw_linked.json') else []

def normalize_state(raw):
    raw = (raw or "").lower().strip()
    return raw if raw in ("open","closed") else "unknown"

label_names = [l.get("name","") for l in (issue.get("labels") or [])]
def derive_issue_type(labels):
    joined = " ".join(l.lower() for l in labels)
    if any(x in joined for x in ("bug", "defect", "fix", "error")): return "bug"
    if any(x in joined for x in ("feature", "enhancement", "story", "epic", "improvement")): return "feature"
    if any(x in joined for x in ("task", "chore", "maintenance")): return "task"
    return "unknown"

normalized = {
    "id":          str(issue.get("number", issue.get("id",""))),
    "title":       issue.get("title",""),
    "state":       normalize_state(issue.get("state","")),
    "url":         issue.get("html_url") or issue.get("url",""),
    "author":      (issue.get("user") or issue.get("author") or {}).get("login",""),
    "assignees":   [(a.get("login","")) for a in (issue.get("assignees") or [])],
    "labels":      label_names,
    "description": issue.get("body","") or "",
    "comments": [
        {"author": (c.get("user") or c.get("author") or {}).get("login","?"),
         "body":   (c.get("body") or "")[:400]}
        for c in raw_comments
    ][:10],
    "linked_issues": [
        {"id":      str(li.get("number", li.get("id",""))),
         "title":   li.get("title",""),
         "state":   normalize_state(li.get("state","")),
         "summary": (li.get("body","") or "")[:400]}
        for li in linked
    ][:5],
    "issue_type":  derive_issue_type(label_names),
    "provider":    "github",
    "fetched_via": os.environ.get("FETCH_METHOD","api")
}

json.dump(normalized, open('/tmp/ii_normalized.json','w'), indent=2)
print("Normalized issue written to /tmp/ii_normalized.json")
```
