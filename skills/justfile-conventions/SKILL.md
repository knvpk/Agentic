---
name: justfile-conventions
description: Conventions for justfile (Just command runner) files observed across this user's older projects — dotenv loading, [doc('...')] recipe descriptions, shebang recipes for multi-line scripts, and variable declarations. Use when creating or editing a justfile/Justfile, adding recipes to a project, or reviewing a justfile for style. Note this user's newer projects use Taskfile.yaml instead — see [[taskfile-conventions]] — prefer that for new projects unless the user asks for Just specifically.
---

# Justfile Conventions

## What This Skill Does

Provides conventions to follow when a project has (or needs) a `justfile`/`Justfile` using [Just](https://just.systems). This is the older task-runner convention in this user's projects — newer projects use go-task (`Taskfile.yaml`); see the `taskfile-conventions` skill for that.

## Rules

### 1. Load `.env` with `set dotenv-load`

Put it near the top, before any variables/recipes:

```just
set dotenv-load
```

### 2. Describe recipes with `[doc('...')]`

Just's `[doc(...)]` attribute is used instead of a comment above the recipe:

```just
[doc('Generate age key-pair with password encryption')]
gen_age_kp:
    age-keygen | age -p > archimedes.age
```

Use `[group('...')]` to bucket related recipes (e.g. `[group('reference')]`) when a justfile grows large enough to need it — most don't.

### 3. Multi-line/scripted recipes get a shebang

For anything beyond a couple of piped commands, use a `#!/usr/bin/env sh` shebang body rather than chaining `&&` across recipe lines:

```just
login:
    #!/usr/bin/env sh
    ip=$(pulumi stack output server_ip)
    stack=$(pulumi stack --show-name)
    ssh -i .secrets/${stack}_server_pvt_key -o PasswordAuthentication=no ubuntu@$ip
```

### 4. Declare variables with `:=`

```just
region := 'ap-south-1'
timestamp := `date +%s`
email := "someone@example.com"
```

### 5. A silent `help` recipe is the common entry point

```just
help:
	@echo "Welcome to <project>"
```

The `@` prefix suppresses echoing the command itself before it runs.

### 6. Recipe bodies use tabs, not spaces

Just requires tab-indented recipe bodies — mixing spaces in will break the file silently in some editors. Match the file's existing indentation exactly.

## Quick Checklist

When creating or reviewing a `justfile`:

- [ ] `set dotenv-load` near the top if the project has a `.env`
- [ ] Recipes documented via `[doc('...')]`, not a plain comment
- [ ] Multi-statement recipes use a `#!/usr/bin/env sh` shebang body
- [ ] Variables declared with `:=`
- [ ] Recipe bodies are tab-indented
- [ ] New projects: consider `taskfile-conventions` instead, unless Just is specifically requested
