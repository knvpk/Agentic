---
name: brainstorm
description: Run a structured AI brainstorming session using one of 6 proven methods — Big Mind Mapping (broad idea generation), Reverse Brainstorming (invert the problem), Role Storming (multiple personas), SCAMPER (systematic transformation), Six Thinking Hats (balanced analysis), or Starbursting (question-first discovery). Use when the user wants to generate ideas, explore a problem, make a decision, or scope a project.
---

# Brainstorm

## Step 1 — Pick a method

If the user didn't specify a method, use this table to recommend one:

| User's situation | Method | Reference |
|---|---|---|
| "I need ideas", stuck, blank slate | Big Mind Mapping | [references/big-mind-mapping.md](references/big-mind-mapping.md) |
| "How do we improve / fix / prevent" | Reverse Brainstorming | [references/reverse-brainstorming.md](references/reverse-brainstorming.md) |
| "Different perspectives / stakeholders" | Role Storming | [references/role-storming.md](references/role-storming.md) |
| "We have X, how do we transform it" | SCAMPER | [references/scamper.md](references/scamper.md) |
| "Should we do X", decision, pros/cons | Six Thinking Hats | [references/six-thinking-hats.md](references/six-thinking-hats.md) |
| "Starting X, what do we need to know" | Starbursting | [references/starbursting.md](references/starbursting.md) |

## Step 2 — Load and run

1. Tell the user which method you chose and why (one sentence)
2. Load the corresponding file from the table above
3. Follow the instructions in that file exactly

## General rules (apply to all methods)

- Never evaluate or filter during generation phases — generation and criticism are separate
- Vague topic: ask one clarifying question, then proceed
- Mid-session method switch: keep the context, load the new method's file, reapply
- User wants a summary: synthesize key ideas from the session grouped by theme
