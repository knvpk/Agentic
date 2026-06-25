# Starbursting

**Goal:** Map what you don't know before committing to a solution — generate comprehensive questions using the 5W1H framework.

**When to use:** Starting a new project or initiative, scoping requirements, doing discovery research, or when the user is jumping to solutions before defining the problem.

---

## The 6 question categories

| Category | Focus |
|---|---|
| **WHO** | Stakeholders, users, owners, affected parties, decision-makers |
| **WHAT** | Deliverables, features, constraints, definitions, scope |
| **WHERE** | Markets, environments, channels, geographies, contexts |
| **WHEN** | Deadlines, sequences, milestones, triggers, frequency |
| **WHY** | Motivation, success criteria, underlying need, rationale |
| **HOW** | Processes, implementation, measurement, tooling, execution |

---

## Phase 1 — Question generation

Generate 2 questions per category (12 total). Questions must surface genuine unknowns — things that, if unanswered, would cause the project to fail or take a wrong direction.

Rules:
- Open-ended only — no yes/no questions
- Avoid questions with obvious answers
- Good questions reveal blind spots and feel slightly uncomfortable
- Do not restate the topic back as a question

**Output format — exactly:**
```
- WHO: [Question 1]
- WHO: [Question 2]
- WHAT: [Question 1]
- WHAT: [Question 2]
- WHERE: [Question 1]
- WHERE: [Question 2]
- WHEN: [Question 1]
- WHEN: [Question 2]
- WHY: [Question 1]
- WHY: [Question 2]
- HOW: [Question 1]
- HOW: [Question 2]
```

---

## Phase 2 — Answer exploration

When the user picks a question, provide 5 answer perspectives that:
- Address different dimensions (not just the most obvious answer)
- Represent different stakeholder viewpoints where relevant
- Include conventional and unconventional answers
- Surface tradeoffs, dependencies, or follow-on questions
- Suggest how to actually get the answer (interview, data pull, prototype, etc.)

**Output format — exactly:**
```
- [Perspective 1]
- [Perspective 2]
- [Perspective 3]
- [Perspective 4]
- [Perspective 5]
```

---

## Example

**Input:** "We're planning to build an internal employee onboarding tool."

**Phase 1:**
```
- WHO: Which teams have the highest onboarding failure rate, and what does "failure" mean in their context — slow ramp, early attrition, or manager dissatisfaction?
- WHO: Who will own and maintain the tool after launch — HR, IT, or team leads — and do they have capacity and motivation to keep it current?
- WHAT: What does a "completed" onboarding look like, and how will the tool know when an employee has genuinely absorbed material vs. just clicked through it?
- WHAT: What currently exists (spreadsheets, wikis, Slack channels) that employees actually rely on — will the new tool replace or supplement those?
- WHERE: Are new hires all in-office, hybrid, or fully remote, and does the tool need to behave differently across those contexts?
- WHERE: Are there regional legal differences in what must be communicated during onboarding — labor law, benefits, privacy notices — requiring localized content?
- WHEN: How long is the intended onboarding period — 30 days, 90 days — and how does the tool's engagement model change across that arc?
- WHEN: Will the tool be used synchronously (during sessions) or asynchronously (self-paced), and have we validated which leads to better outcomes?
- WHY: Is the real problem that onboarding content is missing, disorganized, or simply not being completed — because these require very different solutions?
- WHY: Have we measured the current cost of slow onboarding in productivity loss, and are we building this on evidence or intuition?
- HOW: Who is accountable for updating role-specific content when processes change — and is that baked into someone's job description?
- HOW: How will we measure whether this tool actually improves outcomes, and what's our baseline for comparison?
```

**Phase 2 on "Who will own and maintain the tool after launch?":**
```
- HR typically owns onboarding content but often lacks technical capacity — without IT support, content goes stale within 6 months as no one has time to update it.
- IT can maintain the infrastructure but rarely owns the content — split ownership creates a gap where neither team feels fully responsible for quality.
- Team leads are closest to role-specific needs but will only contribute if content creation is low-friction (a form, not a CMS) and built into their existing workflow.
- A dedicated onboarding program manager can own it holistically — if this role doesn't exist, the tool launch may need to include a proposal to fund it.
- A federated model (HR owns structure, team leads own role pages) can work but requires explicit governance: who resolves conflicts, who deprecates stale content, who reviews on a cadence?
```

---

## Edge cases

- **User has already answered some questions:** Acknowledge those and focus the remaining questions on the open unknowns.
- **User wants answers, not questions:** Explain the value of question-first thinking briefly, then offer to do both — generate questions and immediately explore each with Phase 2.
- **Team is doing customer discovery:** The Phase 1 question list can be used directly as an interview guide — suggest this.
- **Questions feel obvious:** Push further — rewrite any question that has a quick yes/no answer into an open form that surfaces the real unknown beneath it.
