---
name: taskfile-conventions
description: Conventions for Taskfile.yaml (go-task) files observed across this user's projects — version pinning, dotenv loading, environment-aware vars, colon-namespaced task names, and desc usage. Use when creating or editing a Taskfile.yaml/Taskfile.yml, adding tasks to a project, or reviewing a Taskfile for style.
---

# Taskfile Conventions

## What This Skill Does

Provides conventions to follow when a project has (or needs) a `Taskfile.yaml` using [go-task](https://taskfile.dev).

## Rules

### 1. Pin `version: "3"`

Every Taskfile starts with `version: "3"` (or `'3'`) — no other version is used across this user's projects.

### 2. Load `.env` via `dotenv`

If the project has a `.env` file, declare it:

```yaml
dotenv: ['.env']
```

For projects with per-environment config, layer an environment-specific file on top, driven by an `APP_ENV` var:

```yaml
vars:
  APP_ENV: '{{.APP_ENV | default "local"}}'

dotenv:
  - '.env'
  - '.env.{{.APP_ENV}}'
```

### 3. Namespace task names with colons

Group related tasks under a common prefix instead of flat names: `db:up`, `db:down`, `db:reset`, `dns:setup`, `dns:teardown`, `infra:bootstrap-state`, `sandbox:build-image`, `sandbox:start`, `lint:all`. Don't invent a separate grouping mechanism — the colon prefix *is* the grouping.

### 4. Every non-trivial task gets a `desc`

`desc:` is what `task --list` shows — write one for any task another person (or agent) would need to discover. Trivial one-off `help`/`welcome` tasks can skip it.

### 5. Use `cmds:` (plural list), even for one command

Prefer:

```yaml
build:
  desc: Build the project
  cmds:
    - pnpm build
```

over the singular `cmd:` form — keeps tasks easy to extend with a second step later without a diff-churning key rename.

### 6. Chain tasks with `task: <name>`, not a shell re-invocation

```yaml
deploy:
  desc: Build and deploy static output to S3
  cmds:
    - task: build
    - aws s3 sync ...
```

### 7. Guard destructive tasks with `prompt:`

Any task that deletes data or is otherwise irreversible gets a confirmation prompt:

```yaml
db:reset:
  desc: Wipe all DB data and reload from scratch
  prompt: This permanently deletes all data in the database. Continue?
  cmds:
    - docker compose down -v
    - docker compose up -d
```

### 8. A `help`/`welcome` task is optional but common

Several projects define a silent, no-op-ish task that just echoes what the stack is for:

```yaml
welcome:
  desc: Show a welcome message for the stack.
  cmds:
    - echo "kora control plane — postgres, falkordb, redis, minio"
```

## Quick Checklist

When creating or reviewing a `Taskfile.yaml`:

- [ ] `version: "3"` at the top
- [ ] `dotenv: ['.env']` present if the project has a `.env` file (plus an env-layered file if the project supports multiple environments via `APP_ENV`)
- [ ] Task names use colon namespaces for related groups, not flat/ad-hoc names
- [ ] Every task a human/agent would discover via `task --list` has a `desc`
- [ ] Multi-step or extensible tasks use `cmds:` (list), not `cmd:`
- [ ] Tasks depend on other tasks via `task: <name>`, not by shelling out to `task <name>`
- [ ] Destructive tasks have a `prompt:` confirmation
