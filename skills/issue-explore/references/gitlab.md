# Provider: GitLab

Schema: [schema.json](schema.json)

**CLI:** `glab` — `brew install glab` or https://gitlab.com/gitlab-org/cli  
**MCP:** tools prefixed `mcp__gitlab__`  
**API env vars:** `GITLAB_TOKEN` (required), `GITLAB_URL` (optional, default `https://gitlab.com`)

## URL patterns (newest first — never delete old ones)

```python
patterns = [
    r'/(.+)/-/issues/(\d+)',    # current:  /group/project/-/issues/NNN
    r'/(.+)/issues/(\d+)',      # legacy:   /group/project/issues/NNN
]
```

## State normalization

```python
def normalize_state(raw):
    raw = (raw or "").lower().strip()
    if raw == "opened": return "open"
    if raw == "closed": return "closed"
    return "unknown"
```

---

## Interface Step A — Fetch raw issue

Store result in `/tmp/ii_raw_issue.json`.

**via CLI**

`glab` auto-detects the project from the current directory's git remote when `--repo` is omitted.
Only pass `--repo` if `PROJECT_REF` was explicitly provided (URL or `group/project#NNN`).

```bash
# PROJECT_REF known:
glab issue view "$ISSUE_ID" --repo "$PROJECT_REF" --output json > /tmp/ii_raw_issue.json

# PROJECT_REF empty — let glab detect from cwd:
glab issue view "$ISSUE_ID" --output json > /tmp/ii_raw_issue.json
```

**via MCP**  
Call `mcp__gitlab__get_issue` with `project_id=PROJECT_REF` (omit if empty) and `issue_iid=ISSUE_ID`.
Write the raw response JSON to `/tmp/ii_raw_issue.json`.

**via API**
```bash
BASE="${GITLAB_URL:-https://gitlab.com}"
ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1],safe=''))" "$PROJECT_REF")

curl -sf --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$BASE/api/v4/projects/$ENC/issues/$ISSUE_ID" > /tmp/ii_raw_issue.json
```

---

## Interface Step B — Fetch raw comments

Store result in `/tmp/ii_raw_comments.json` (array of note objects).

**via CLI** (notes embedded in issue JSON — reuse `/tmp/ii_raw_issue.json`)
```bash
python3 -c "
import json
d = json.load(open('/tmp/ii_raw_issue.json'))
notes = d.get('notes') or d.get('comments') or []
json.dump(notes, open('/tmp/ii_raw_comments.json','w'))
"
```

**via MCP**  
Call `mcp__gitlab__list_issue_notes` with `project_id` and `issue_iid`.
Write the raw array to `/tmp/ii_raw_comments.json`.

**via API**
```bash
curl -sf --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$BASE/api/v4/projects/$ENC/issues/$ISSUE_ID/notes?per_page=50&sort=asc" \
  > /tmp/ii_raw_comments.json
```

---

## Interface Step C — Fetch raw linked issues

Store result in `/tmp/ii_raw_linked.json` (array of issue objects). Run only if description is insufficient (see SKILL.md Step 5a).

**via CLI**
```bash
python3 - <<'PY'
import json, re, subprocess, os

desc  = json.load(open('/tmp/ii_raw_issue.json')).get("description","") or ""
proj  = os.environ.get("_II_PROJECT","")
refs  = list(dict.fromkeys(re.findall(r'(?<![a-zA-Z])#(\d+)', desc)))[:5]
out   = []
for ref in refs:
    cmd = ["glab","issue","view", ref,"--output","json"]
    if proj: cmd += ["--repo", proj]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode == 0:
        out.append(json.loads(r.stdout))
json.dump(out, open('/tmp/ii_raw_linked.json','w'))
PY
```

**via MCP**  
Call `mcp__gitlab__list_issue_related_issues` for first-class links, then also extract `#NNN` refs from description and call `mcp__gitlab__get_issue` for each.
Write array of raw issue objects to `/tmp/ii_raw_linked.json`.

**via API**
```bash
BASE="${GITLAB_URL:-https://gitlab.com}"
ENC=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1],safe=''))" "$PROJECT_REF")

curl -sf --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "$BASE/api/v4/projects/$ENC/issues/$ISSUE_ID/related_issues" > /tmp/ii_raw_related.json

python3 - <<'PY'
import json, re, os, subprocess, urllib.parse

related = json.load(open('/tmp/ii_raw_related.json'))
desc    = json.load(open('/tmp/ii_raw_issue.json')).get("description","") or ""
base    = os.environ.get("GITLAB_URL","https://gitlab.com")
token   = os.environ.get("GITLAB_TOKEN","")
proj    = os.environ.get("_II_PROJECT","")

candidates = []
for rel in related[:5]:
    iid = rel.get("iid")
    p   = (rel.get("references") or {}).get("full","").split("#")[0]
    if iid and p: candidates.append((p, iid))
for ref in re.findall(r'(?<![a-zA-Z])#(\d+)', desc)[:5]:
    if proj: candidates.append((proj, ref))

out, seen = [], set()
for p, iid in candidates[:5]:
    key = f"{p}#{iid}"
    if key in seen: continue
    seen.add(key)
    enc = urllib.parse.quote(p, safe="")
    r = subprocess.run(["curl","-sf","--header",f"PRIVATE-TOKEN: {token}",
                        f"{base}/api/v4/projects/{enc}/issues/{iid}"],
                       capture_output=True, text=True)
    if r.returncode == 0 and r.stdout:
        out.append(json.loads(r.stdout))
json.dump(out, open('/tmp/ii_raw_linked.json','w'))
PY
```

---

## Normalize — write `/tmp/ii_normalized.json`

Run after Steps A, B, C. Maps GitLab raw fields to [schema.json](schema.json).

```python
import json, os

issue    = json.load(open('/tmp/ii_raw_issue.json'))
comments = json.load(open('/tmp/ii_raw_comments.json')) if os.path.exists('/tmp/ii_raw_comments.json') else []
linked   = json.load(open('/tmp/ii_raw_linked.json'))   if os.path.exists('/tmp/ii_raw_linked.json')   else []

def normalize_state(raw):
    raw = (raw or "").lower().strip()
    return {"opened": "open", "closed": "closed"}.get(raw, "unknown")

labels_list = issue.get("labels", [])
def derive_issue_type(labels):
    joined = " ".join(l.lower() for l in labels)
    if any(x in joined for x in ("bug", "defect", "fix", "error")): return "bug"
    if any(x in joined for x in ("feature", "enhancement", "story", "epic", "improvement")): return "feature"
    if any(x in joined for x in ("task", "chore", "maintenance")): return "task"
    return "unknown"

normalized = {
    "id":          str(issue.get("iid", issue.get("id",""))),
    "title":       issue.get("title",""),
    "state":       normalize_state(issue.get("state","")),
    "url":         issue.get("web_url",""),
    "author":      (issue.get("author") or {}).get("name") or (issue.get("author") or {}).get("username",""),
    "assignees":   [(a.get("name") or a.get("username","")) for a in (issue.get("assignees") or [])],
    "labels":      labels_list,
    "description": issue.get("description","") or "",
    "comments": [
        {"author": (n.get("author") or {}).get("name") or (n.get("author") or {}).get("username","?"),
         "body":   (n.get("body") or "")[:400]}
        for n in comments
        if not n.get("system")
    ][:10],
    "linked_issues": [
        {"id":      str(li.get("iid", li.get("id",""))),
         "title":   li.get("title",""),
         "state":   normalize_state(li.get("state","")),
         "summary": (li.get("description") or "")[:400]}
        for li in linked
    ][:5],
    "issue_type":  derive_issue_type(labels_list),
    "provider":    "gitlab",
    "fetched_via": os.environ.get("FETCH_METHOD","api")
}

json.dump(normalized, open('/tmp/ii_normalized.json','w'), indent=2)
print("Normalized issue written to /tmp/ii_normalized.json")
```
