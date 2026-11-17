# Spec: global-claude-config

## Purpose

Defines the git-tracked global CLAUDE.md, its content rules, and the `task link` mechanism that symlinks it into `~/.claude`.

## Requirements

### Requirement: Global CLAUDE.md is git-tracked
The repo SHALL contain `global/CLAUDE.md` as the single source of the user's global Claude instructions.

#### Scenario: Content
- **WHEN** `global/CLAUDE.md` is read
- **THEN** it contains the docstring/comment rule, the four behavioral guidelines, and a pointer to the `my-brain` skill, and contains no Ruflo content and no principles text

### Requirement: Docstring and comment rule
`global/CLAUDE.md` SHALL instruct that docstrings, comments and documentation are added only when explicitly requested or when the line of code or config is not self-explanatory.

#### Scenario: Self-explanatory code
- **WHEN** Claude generates code whose lines are self-explanatory and no docs were requested
- **THEN** it adds no docstrings, comment blocks, or documentation files

### Requirement: Principles are removed from repo CLAUDE.md
`agentic/CLAUDE.md` SHALL NOT contain the Principles section; if no repo-specific content remains the file SHALL be deleted.

#### Scenario: No duplication
- **WHEN** the repo is searched for the principles text
- **THEN** it appears only in `skills/my-brain/SKILL.md`

### Requirement: Link task
A `Taskfile.yaml` SHALL provide `task link` that symlinks `global/CLAUDE.md` to `~/.claude/CLAUDE.md`. It SHALL NOT link skills, which are installed with `npx skills add`. It SHALL be idempotent and SHALL NOT overwrite a real file or a link pointing elsewhere.

#### Scenario: Fresh machine
- **WHEN** `task link` runs and the targets do not exist
- **THEN** the symlinks are created

#### Scenario: Already linked
- **WHEN** `task link` runs and targets already point at the repo
- **THEN** nothing changes and it exits successfully

#### Scenario: Real file in the way
- **WHEN** `~/.claude/CLAUDE.md` exists as a regular file
- **THEN** the task exits non-zero with a message naming the file and changes nothing

### Requirement: krishna is untouched
The change SHALL NOT modify any file under `krishna/`.

#### Scenario: No krishna edits
- **WHEN** the change is applied
- **THEN** no path under `../krishna` differs
