# Spec: my-brain-skill

## Purpose

Defines the `my-brain` skill: the user's five core engineering principles, each with a test question, and a broad trigger description.

## Requirements

### Requirement: Skill frontmatter conforms to agentskills.io
`skills/my-brain/SKILL.md` SHALL have valid frontmatter with `name: my-brain` (matching the directory) and a `description` under 1024 characters that triggers on designing, writing, reviewing or scaffolding any code, config or infrastructure.

#### Scenario: Skill is discoverable
- **WHEN** `npx skills` lists skills in this repo
- **THEN** `my-brain` appears with its description

#### Scenario: Skill triggers on design work
- **WHEN** a user asks Claude to design a module or scaffold a service
- **THEN** the description matches and `my-brain` is eligible to load

### Requirement: Five principles each with a test question
The skill SHALL define exactly these principles: everything as code, decoupled, structured (types first), scalable, measured. Each SHALL include a one-line rule and a test question usable during review.

#### Scenario: Principle has a test question
- **WHEN** a reader opens any principle section
- **THEN** it contains a rule and a question that can be answered yes/no about a piece of work

### Requirement: Principles only
The skill SHALL NOT contain the behavioral guidelines, the docstring rule, or project-specific work rules.

#### Scenario: No behavioral content
- **WHEN** `SKILL.md` is reviewed
- **THEN** it contains only the five principles and their usage guidance
