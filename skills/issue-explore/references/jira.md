# Provider: Jira

Schema: [schema.json](schema.json)

**CLI:** `jira` (jira-cli) — `brew install ankitpokhrel/jira-cli/jira-cli` or https://github.com/ankitpokhrel/jira-cli  
**MCP:** tools prefixed `mcp__jira__`  
**API env vars:** `JIRA_URL` (required), `JIRA_USER` (email), `JIRA_TOKEN` (API token)

## URL patterns (newest first — never delete old ones)

```python
patterns = [
    r'/browse/([A-Z][A-Z0-9_]+-\d+)',
    r'/jira/software/projects/[^/]+/issue/([A-Z][A-Z0-9_]+-\d+)',
    r'/jira/core/projects/[^/]+/issue/([A-Z][A-Z0-9_]+-\d+)',
    r'/issues/([A-Z][A-Z0-9_]+-\d+)',
]
```

## State normalization

```python
def normalize_state(raw):
    raw = (raw or "").lower().strip()
    if any(x in raw for x in ("progress","review","testing","doing","development")):
        return "in_progress"
    if any(x in raw for x in ("done","closed","resolved","complete","fixed","won't fix","invalid")):
        return "closed"
    return "open"
```

## ADF helper (Atlassian Document Format → plain text)

```python
def adf_text(node):
    if not node: return ""
    if isinstance(node, str): return node
    t = node.get("type","")
    if t == "text": return node.get("text","")
    content = node.get("content") or []
    sep = "\n" if t in ("paragraph","heading","bulletList","orderedList","listItem","blockquote") else ""
    return sep.join(adf_text(c) for c in content)
```

---

## Interface Step A — Fetch raw issue

Store result in `/tmp/ii_raw_issue.json`.

**via CLI**
```bash
jira issue view "$ISSUE_ID" --raw > /tmp/ii_raw_issue.json
```

**via MCP**  
Call `mcp__jira__get_issue` with `issue_key=ISSUE_ID`.
Write raw response to `/tmp/ii_raw_issue.json`.

**via API**
```bash
AUTH=$(python3 -c "import base64,os; print(base64.b64encode(f\"{os.environ['JIRA_USER']}:{os.environ['JIRA_TOKEN']}\".encode()).decode())")

curl -sf \
  --header "Authorization: Basic $AUTH" \
  --header "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/issue/$ISSUE_ID" > /tmp/ii_raw_issue.json
```

---

## Interface Step B — Fetch raw comments

Store result in `/tmp/ii_raw_comments.json` (array of comment objects).

**via CLI** (`--raw` embeds comments under `fields.comment.comments`)
```bash
python3 -c "
import json
d = json.load(open('/tmp/ii_raw_issue.json'))
comments = ((d.get('fields') or {}).get('comment') or {}).get('comments', [])
json.dump(comments, open('/tmp/ii_raw_comments.json','w'))
"
```

**via MCP**  
Call `mcp__jira__get_issue_comments` with `issue_key`.
Write array to `/tmp/ii_raw_comments.json`.

**via API**
```bash
curl -sf \
  --header "Authorization: Basic $AUTH" \
  --header "Content-Type: application/json" \
  "$JIRA_URL/rest/api/3/issue/$ISSUE_ID/comment?maxResults=50&orderBy=created" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); json.dump(d.get('comments',[]), open('/tmp/ii_raw_comments.json','w'))"
```

---

## Interface Step C — Fetch raw linked issues

Store result in `/tmp/ii_raw_linked.json`. Jira has first-class `issuelinks`. Run only if description is insufficient (see SKILL.md Step 5a).

**via CLI**
```bash
python3 - <<'PY'
import json, subprocess

d     = json.load(open('/tmp/ii_raw_issue.json'))
links = ((d.get("fields") or {}).get("issuelinks") or [])[:5]
out   = []
for link in links:
    related = link.get("outwardIssue") or link.get("inwardIssue")
    if not related: continue
    key = related.get("key","")
    if not key: continue
    r = subprocess.run(["jira","issue","view", key,"--raw"], capture_output=True, text=True)
    if r.returncode == 0:
        out.append(json.loads(r.stdout))
json.dump(out, open('/tmp/ii_raw_linked.json','w'))
PY
```

**via MCP**  
Read `issuelinks` from the fetched issue. For each linked key, call `mcp__jira__get_issue`.
Write array to `/tmp/ii_raw_linked.json`.

**via API**
```bash
python3 - <<'PY'
import json, os, subprocess, base64

d     = json.load(open('/tmp/ii_raw_issue.json'))
links = ((d.get("fields") or {}).get("issuelinks") or [])[:5]
base  = os.environ.get("JIRA_URL","")
auth  = base64.b64encode(f"{os.environ.get('JIRA_USER','')}:{os.environ.get('JIRA_TOKEN','')}".encode()).decode()
out, seen = [], set()

for link in links:
    related = link.get("outwardIssue") or link.get("inwardIssue")
    if not related: continue
    key = related.get("key","")
    if not key or key in seen: continue
    seen.add(key)
    r = subprocess.run(
        ["curl","-sf","--header",f"Authorization: Basic {auth}",
         "--header","Content-Type: application/json",
         f"{base}/rest/api/3/issue/{key}"],
        capture_output=True, text=True)
    if r.returncode == 0 and r.stdout:
        out.append(json.loads(r.stdout))
json.dump(out, open('/tmp/ii_raw_linked.json','w'))
PY
```

---

## Normalize — write `/tmp/ii_normalized.json`

Run after Steps A, B, C. Maps Jira raw fields to [schema.json](schema.json).

```python
import json, os

def adf_text(node):
    if not node: return ""
    if isinstance(node, str): return node
    t = node.get("type","")
    if t == "text": return node.get("text","")
    content = node.get("content") or []
    sep = "\n" if t in ("paragraph","heading","bulletList","orderedList","listItem","blockquote") else ""
    return sep.join(adf_text(c) for c in content)

def normalize_state(raw):
    raw = (raw or "").lower().strip()
    if any(x in raw for x in ("progress","review","testing","doing","development")):
        return "in_progress"
    if any(x in raw for x in ("done","closed","resolved","complete","fixed","won't fix","invalid")):
        return "closed"
    return "open"

def flat_desc(f):
    d = f.get("description")
    return adf_text(d) if isinstance(d, dict) else (d or "")

issue    = json.load(open('/tmp/ii_raw_issue.json'))
comments = json.load(open('/tmp/ii_raw_comments.json')) if os.path.exists('/tmp/ii_raw_comments.json') else []
linked   = json.load(open('/tmp/ii_raw_linked.json'))   if os.path.exists('/tmp/ii_raw_linked.json')   else []

f = issue.get("fields", {})
labels = f.get("labels", []) + [c.get("name","") for c in (f.get("components") or [])]

def derive_issue_type(fields):
    itype = ((fields.get("issuetype") or {}).get("name") or "").lower()
    if any(x in itype for x in ("bug", "defect", "error")): return "bug"
    if any(x in itype for x in ("story", "feature", "epic", "improvement", "new feature")): return "feature"
    if any(x in itype for x in ("task", "sub-task", "subtask", "chore")): return "task"
    return "unknown"

normalized = {
    "id":          issue.get("key","") or str(issue.get("id","")),
    "title":       f.get("summary",""),
    "state":       normalize_state((f.get("status") or {}).get("name","")),
    "url":         issue.get("self","").split("/rest/")[0] + "/browse/" + issue.get("key",""),
    "author":      (f.get("reporter") or {}).get("displayName",""),
    "assignees":   [(f.get("assignee") or {}).get("displayName","")] if f.get("assignee") else [],
    "labels":      [l for l in labels if l],
    "description": flat_desc(f),
    "comments": [
        {"author": (c.get("author") or {}).get("displayName","?"),
         "body":   adf_text(c.get("body"))[:400] if isinstance(c.get("body"), dict) else (c.get("body") or "")[:400]}
        for c in comments
    ][:10],
    "linked_issues": [
        {"id":      li.get("key","") or str(li.get("id","")),
         "title":   (li.get("fields") or {}).get("summary",""),
         "state":   normalize_state(((li.get("fields") or {}).get("status") or {}).get("name","")),
         "summary": flat_desc(li.get("fields") or {})[:400]}
        for li in linked
    ][:5],
    "issue_type":  derive_issue_type(f),
    "provider":    "jira",
    "fetched_via": os.environ.get("FETCH_METHOD","api")
}

json.dump(normalized, open('/tmp/ii_normalized.json','w'), indent=2)
print("Normalized issue written to /tmp/ii_normalized.json")
```
