# Provider: Plane

Schema: [schema.json](schema.json)

**CLI:** `plane` — no stable official CLI is available yet; MCP or API is the primary fetch method  
**MCP:** tools prefixed `mcp__plane__`  
**API env vars:** `PLANE_API_TOKEN` (required), `PLANE_BASE_URL` (optional; default `https://api.plane.so` for cloud, or your self-hosted base URL)

> **Self-hosted Plane:** add your domain to `ISSUE_EXPLORE_HOSTS`:
> ```bash
> export ISSUE_EXPLORE_HOSTS='{"plane.company.com":"plane"}'
> export PLANE_BASE_URL=https://plane.company.com
> ```

## URL patterns (newest first — never delete old ones)

```python
patterns = [
    r'/([^/]+/projects/[^/]+)/issues/([^/?#]+)',  # /{workspace}/projects/{project-uuid}/issues/{issue-uuid}
]
```

**Group 1** = `{workspace_slug}/projects/{project_uuid}` → stored as `project_ref`  
**Group 2** = `{issue_uuid}` → stored as `issue_id`

In all steps below, split `project_ref` to recover individual components:

```python
import os
parts        = project_ref.split('/projects/', 1)
workspace    = parts[0]
project_uuid = parts[1] if len(parts) > 1 else ""
issue_uuid   = issue_id
base_url     = os.environ.get("PLANE_BASE_URL", "https://api.plane.so").rstrip("/")
token        = os.environ.get("PLANE_API_TOKEN", "")
headers      = {"X-Api-Key": token, "Content-Type": "application/json"}
```

## State normalization

```python
def normalize_state(raw):
    # raw is the state__group field returned by Plane's API
    raw = (raw or "").lower().strip()
    if raw == "started":                       return "in_progress"
    if raw in ("completed", "cancelled"):      return "closed"
    return "open"   # backlog, unstarted, unknown
```

## HTML-to-text helper

Plane stores descriptions and comments as HTML (`description_html`, `comment_html`).

```python
import re

def html_to_text(html):
    if not html: return ""
    html = re.sub(r'<(script|style)[^>]*>.*?</(script|style)>', '', html,
                  flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<br\s*/?>', '\n', html, flags=re.IGNORECASE)
    html = re.sub(r'</(p|div|li|h[1-6]|tr)>', '\n', html, flags=re.IGNORECASE)
    html = re.sub(r'<[^>]+>', '', html)
    for ent, ch in [('&amp;','&'),('&lt;','<'),('&gt;','>'),
                    ('&nbsp;',' '),('&quot;','"'),('&#39;',"'")]:
        html = html.replace(ent, ch)
    return re.sub(r'\n{3,}', '\n\n', html.strip())
```

---

## Interface Step A — Fetch raw issue

Store result in `/tmp/ii_raw_issue.json`.

**via CLI**  
No stable official Plane CLI. Skip to MCP or API.

**via MCP**  
Call `mcp__plane__get_issue` with `workspace_slug=workspace`, `project_id=project_uuid`, `issue_id=issue_uuid`.  
Write raw response to `/tmp/ii_raw_issue.json`.

**via API**
```bash
curl -sf \
  -H "X-Api-Key: $PLANE_API_TOKEN" \
  -H "Content-Type: application/json" \
  "${PLANE_BASE_URL:-https://api.plane.so}/api/v1/workspaces/$WORKSPACE/projects/$PROJECT_UUID/issues/$ISSUE_UUID/" \
  > /tmp/ii_raw_issue.json
```

Or with Python (avoids shell variable complexity):

```python
import json, os, urllib.request

parts        = project_ref.split('/projects/', 1)
workspace    = parts[0]
project_uuid = parts[1] if len(parts) > 1 else ""
issue_uuid   = issue_id
base_url     = os.environ.get("PLANE_BASE_URL", "https://api.plane.so").rstrip("/")
token        = os.environ["PLANE_API_TOKEN"]

url = f"{base_url}/api/v1/workspaces/{workspace}/projects/{project_uuid}/issues/{issue_uuid}/"
req = urllib.request.Request(url, headers={"X-Api-Key": token})
with urllib.request.urlopen(req) as resp:
    data = json.loads(resp.read())

json.dump(data, open('/tmp/ii_raw_issue.json', 'w'), indent=2)
```

---

## Interface Step B — Fetch raw comments

Store result in `/tmp/ii_raw_comments.json` (array of comment objects).

**via CLI**  
No stable official Plane CLI. Skip to MCP or API.

**via MCP**  
Call `mcp__plane__get_issue_comments` with `workspace_slug=workspace`, `project_id=project_uuid`, `issue_id=issue_uuid`.  
Write array to `/tmp/ii_raw_comments.json`.

**via API**
```bash
curl -sf \
  -H "X-Api-Key: $PLANE_API_TOKEN" \
  -H "Content-Type: application/json" \
  "${PLANE_BASE_URL:-https://api.plane.so}/api/v1/workspaces/$WORKSPACE/projects/$PROJECT_UUID/issues/$ISSUE_UUID/comments/" \
  | python3 -c "
import json, sys
d = json.load(sys.stdin)
# response may be a list or {results: [...]}
json.dump(d if isinstance(d, list) else d.get('results', []),
          open('/tmp/ii_raw_comments.json','w'), indent=2)
"
```

---

## Interface Step C — Fetch raw linked issues

Store result in `/tmp/ii_raw_linked.json`. Run only if description is insufficient (see SKILL.md Step 3).

**via CLI**  
No stable official Plane CLI. Skip to MCP or API.

**via MCP**  
Call `mcp__plane__get_issue_relations` with `workspace_slug`, `project_id`, `issue_id`.  
For each related issue ID returned, call `mcp__plane__get_issue`.  
Write array to `/tmp/ii_raw_linked.json`.

**via API**
```python
import json, os, urllib.request

parts        = project_ref.split('/projects/', 1)
workspace    = parts[0]
project_uuid = parts[1] if len(parts) > 1 else ""
issue_uuid   = issue_id
base_url     = os.environ.get("PLANE_BASE_URL", "https://api.plane.so").rstrip("/")
token        = os.environ["PLANE_API_TOKEN"]
hdrs         = {"X-Api-Key": token}

def fetch(url):
    req = urllib.request.Request(url, headers=hdrs)
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())

# Fetch issue relations
rel_url  = (f"{base_url}/api/v1/workspaces/{workspace}/projects/{project_uuid}"
            f"/issue-relations/?issue_id={issue_uuid}")
rels_raw = fetch(rel_url)
rels     = rels_raw if isinstance(rels_raw, list) else rels_raw.get("results", [])

out, seen = [], set()
for rel in rels[:5]:
    # 'related_issue' is the linked issue UUID; skip self-references
    related_id = rel.get("related_issue") or rel.get("issue")
    if not related_id or related_id == issue_uuid or related_id in seen:
        continue
    seen.add(related_id)
    try:
        issue_url = (f"{base_url}/api/v1/workspaces/{workspace}/projects"
                     f"/{project_uuid}/issues/{related_id}/")
        out.append(fetch(issue_url))
    except Exception:
        pass

json.dump(out, open('/tmp/ii_raw_linked.json', 'w'), indent=2)
```

---

## Normalize — write `/tmp/ii_normalized.json`

Run after Steps A, B, C. Maps Plane raw fields to [schema.json](schema.json).

```python
import json, os, re

def html_to_text(html):
    if not html: return ""
    html = re.sub(r'<(script|style)[^>]*>.*?</(script|style)>', '', html,
                  flags=re.DOTALL | re.IGNORECASE)
    html = re.sub(r'<br\s*/?>', '\n', html, flags=re.IGNORECASE)
    html = re.sub(r'</(p|div|li|h[1-6]|tr)>', '\n', html, flags=re.IGNORECASE)
    html = re.sub(r'<[^>]+>', '', html)
    for ent, ch in [('&amp;','&'),('&lt;','<'),('&gt;','>'),
                    ('&nbsp;',' '),('&quot;','"'),('&#39;',"'")]:
        html = html.replace(ent, ch)
    return re.sub(r'\n{3,}', '\n\n', html.strip())

def normalize_state(state_group):
    raw = (state_group or "").lower().strip()
    if raw == "started":                  return "in_progress"
    if raw in ("completed", "cancelled"): return "closed"
    return "open"

def derive_issue_type(issue):
    type_name = ((issue.get("type_detail") or {}).get("name")
                 or issue.get("type") or "").lower()
    if any(x in type_name for x in ("bug", "defect", "error")):    return "bug"
    if any(x in type_name for x in ("feature", "story", "epic")):  return "feature"
    if any(x in type_name for x in ("task", "chore", "sub-task")): return "task"
    return "unknown"

# --- load raw files ---
issue    = json.load(open('/tmp/ii_raw_issue.json'))
comments = json.load(open('/tmp/ii_raw_comments.json')) if os.path.exists('/tmp/ii_raw_comments.json') else []
linked   = json.load(open('/tmp/ii_raw_linked.json'))   if os.path.exists('/tmp/ii_raw_linked.json')   else []

# --- parse project_ref ---
parts        = project_ref.split('/projects/', 1)   # project_ref carried from Step 1
workspace    = parts[0]
project_uuid = parts[1] if len(parts) > 1 else ""
issue_uuid   = issue.get("id", issue_id)

# --- web URL ---
# Cloud: app.plane.so hosts the UI; API is api.plane.so — swap subdomain.
# Self-hosted: same domain for both.
api_base = os.environ.get("PLANE_BASE_URL", "https://api.plane.so").rstrip("/")
app_base = api_base.replace("api.plane.so", "app.plane.so")
web_url  = f"{app_base}/{workspace}/projects/{project_uuid}/issues/{issue_uuid}/"

# --- author ---
cd = issue.get("created_by_detail") or {}
author = cd.get("display_name") or cd.get("username") or issue.get("created_by", "")

# --- assignees ---
assignees = [
    a.get("display_name") or a.get("username", "")
    for a in (issue.get("assignee_details") or [])
    if a.get("display_name") or a.get("username")
]

# --- labels ---
labels = [
    l.get("name", "")
    for l in (issue.get("label_details") or [])
    if l.get("name")
]

# --- description (prefer pre-stripped text; fall back to HTML) ---
description = (
    issue.get("description_stripped")
    or html_to_text(issue.get("description_html") or "")
)

# --- state ---
state = normalize_state(issue.get("state__group", ""))

# --- comments (human only — filter out entries with no actor_detail) ---
def norm_comment(c):
    actor = c.get("actor_detail") or {}
    name  = actor.get("display_name") or actor.get("username") or c.get("actor", "?")
    body  = (c.get("comment_stripped")
             or html_to_text(c.get("comment_html") or ""))
    return {"author": name, "body": body[:400]}

human_comments = [c for c in comments if c.get("actor_detail")]

# --- linked issues ---
def norm_linked(li):
    li_state = normalize_state(li.get("state__group", ""))
    li_desc  = (li.get("description_stripped")
                or html_to_text(li.get("description_html") or ""))
    return {
        "id":      str(li.get("sequence_id") or li.get("id", "")),
        "title":   li.get("name", ""),
        "state":   li_state,
        "summary": li_desc[:400],
    }

# --- custom fields (priority + sequence_id for display) ---
priority    = issue.get("priority", "")
sequence_id = str(issue.get("sequence_id", ""))

custom_fields = {}
if priority:    custom_fields["priority"]    = priority
if sequence_id: custom_fields["sequence_id"] = sequence_id

# --- assemble normalized output ---
normalized = {
    "id":          sequence_id or issue_uuid,  # prefer human-readable sequence number
    "title":       issue.get("name", ""),
    "state":       state,
    "url":         web_url,
    "author":      author,
    "assignees":   assignees,
    "labels":      labels,
    "description": description,
    "comments":    [norm_comment(c) for c in human_comments][:10],
    "linked_issues": [norm_linked(li) for li in linked][:5],
    "issue_type":  derive_issue_type(issue),
    "provider":    "plane",
    "fetched_via": os.environ.get("FETCH_METHOD", "api"),
    "custom_fields": custom_fields,
}

json.dump(normalized, open('/tmp/ii_normalized.json', 'w'), indent=2)
print("Normalized Plane issue written to /tmp/ii_normalized.json")
```
