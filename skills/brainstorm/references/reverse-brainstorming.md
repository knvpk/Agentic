# Reverse Brainstorming

**Goal:** Invert the problem. Ask "how do we make this as bad as possible?" — then flip those answers into non-obvious solutions.

**When to use:** User wants creative solutions beyond conventional approaches, needs to stress-test a plan, or wants to surface blind spots and failure modes.

---

## Phase 1 — Generate the negatives

Adopt the mindset of a deliberate saboteur. Generate 10 concrete ways to **cause, worsen, or guarantee failure** of the user's stated goal.

Each negative idea must:
- Be specific — not "do nothing" or "ignore the problem"
- Explain the mechanism of harm (2–3 sentences)
- Be realistically possible
- Cover different vectors: process failures, human factors, technical flaws, external forces, communication breakdowns

**Output format — exactly:**
```
- [Negative idea 1]
- [Negative idea 2]
...
- [Negative idea 10]
```
No numbering. No bold headers.

---

## Phase 2 — Flip to solutions

When the user picks one negative idea, generate 5 counters that directly neutralize it:

- Directly prevent or neutralize the negative outcome
- Mix proactive (prevent it) and reactive (recover from it) approaches
- Turn the identified weakness into a designed strength
- Each counter: specific and implementable, 2–3 sentences

**Output format — exactly:**
```
- [Counter 1]
- [Counter 2]
- [Counter 3]
- [Counter 4]
- [Counter 5]
```

---

## Example

**Input:** "We want to improve customer retention for our SaaS product."

**Phase 1 (excerpt):**
```
- Make onboarding so complex that users never reach their first "aha moment," ensuring they cancel before understanding the product's value.
- Send generic, untargeted emails so every communication feels irrelevant, training users to ignore or unsubscribe from all outreach.
- Never alert customers when they're approaching usage limits — let the first sign be a hard block mid-workflow at the worst possible moment.
```

**Phase 2 on "never alert on usage limits":**
```
- Build automated threshold alerts at 70% and 90% usage with a one-click upgrade path directly in the notification.
- Assign a customer success touchpoint when usage crosses 80%, turning a limit warning into a growth conversation.
- Show a live usage dashboard on the product home screen so customers always know their position before hitting a wall.
- Design grace periods for first-time limit hits — let the workflow complete, then explain the limit and offer a trial upgrade.
- Track limit-hit events as a churn signal in the CRM and trigger immediate outreach from the account team within 24 hours.
```

---

## Edge cases

- **User already lists problems:** Skip Phase 1 and go directly to Phase 2 for each problem named.
- **Both phases at once:** Generate all negatives, then immediately flip all of them — present as paired lists.
- **Sensitive topic (security, safety):** Focus on systemic and process failures; avoid ideas that could serve as actual attack blueprints.
- **Unclear goal:** Ask "what specific outcome are you trying to achieve?" before generating — inversion only works with a clear target state.
