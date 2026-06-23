# Six Thinking Hats

**Goal:** Parallel thinking across 6 cognitive modes — preventing any single mode (especially criticism or enthusiasm) from dominating.

**When to use:** Decision-making, balanced risk-benefit analysis, evaluating a proposal, or preventing groupthink.

---

## The 6 hats

| Hat | Mode | What to focus on |
|---|---|---|
| ⚪ **WHITE** | Facts | Data, information, and knowledge gaps — state what's known vs. unknown |
| 🔴 **RED** | Emotions | Gut reactions and feelings — no justification required |
| ⚫ **BLACK** | Caution | Specific failure mechanisms — not generic pessimism |
| 🟡 **YELLOW** | Benefits | Specific value pathways — not generic optimism |
| 🟢 **GREEN** | Creativity | Novel alternatives and lateral ideas |
| 🔵 **BLUE** | Process | Meta-reflection — what's missing, what to examine next |

**Key rule:** Hats don't bleed into each other. Black Hat doesn't use Yellow Hat reasoning and vice versa. Each hat is a lens, not a personality.

---

## Phase 1 — Full 6-hat analysis

Provide 1–2 substantive insights per hat (2–3 sentences each).

- **White:** cite or note missing data — do not speculate as fact
- **Red:** state feelings directly without justifying them ("This feels risky" — not "This is risky because...")
- **Black:** be specific about failure mechanisms — not "it might not work"
- **Yellow:** be specific about the value pathway — not "it has potential"
- **Green:** propose alternatives or novel angles — not the obvious first idea
- **Blue:** reflect on the quality of thinking so far and what to examine next

**Output format — exactly:**
```
- WHITE HAT (Facts): [insights]
- RED HAT (Emotions): [insights]
- BLACK HAT (Caution): [insights]
- YELLOW HAT (Benefits): [insights]
- GREEN HAT (Creativity): [insights]
- BLUE HAT (Process): [insights]
```

---

## Phase 2 — Deep-dive on one hat

When the user picks a hat, generate 5 deeper observations that:
- Stay strictly within that hat's cognitive mode — no cross-contamination
- Cover short-term and long-term aspects
- Include concrete scenarios or examples
- Build on but go beyond the Phase 1 insight

**Output format — exactly:**
```
- [Observation 1]
- [Observation 2]
- [Observation 3]
- [Observation 4]
- [Observation 5]
```

---

## Example

**Input:** "Should we launch a freemium tier for our B2B SaaS product?"

**Phase 1:**
```
- WHITE HAT (Facts): B2B SaaS freemium conversion rates average 2–5%, top performers reach 10%. We currently have no data on how many prospects are blocked by price vs. product fit.
- RED HAT (Emotions): This feels exciting — it signals product confidence. It also feels slightly anxious; giving away what we've charged for may feel like devaluing our work.
- BLACK HAT (Caution): Free users generate support burden without revenue. If our support-to-revenue ratio worsens, unit economics break before conversion kicks in.
- YELLOW HAT (Benefits): A free tier is a self-service sales motion — it removes SDRs from early-stage deals and creates a pool of product-qualified leads who've already experienced value.
- GREEN HAT (Creativity): What if the free tier is time-limited (60 days full access) rather than feature-limited? This drives urgency without crippling the experience.
- BLUE HAT (Process): We've spent more time on Yellow and Black than White. The next action should be 10 interviews with churned trials — not a strategic decision made in the abstract.
```

**Phase 2 on BLACK HAT:**
```
- Free users at 80% of support volume but 0% of revenue forces a choice: raise prices for paid users or cut support quality — both hurt retention.
- A freemium tier signals a "lite" product to enterprise procurement, which may hurt positioning against premium-only competitors.
- Feature-limited tiers create resentment — users who hit limits mid-workflow churn to a competitor rather than upgrade, unless the path is frictionless.
- Free users become a vocal minority on review sites; their feedback distorts product prioritization away from the paying customers who drive revenue.
- If a well-funded competitor also launches freemium, we're in a race-to-the-bottom on free tier generosity — a game that favors the larger cash reserve, not the better product.
```

---

## Edge cases

- **User wants a quick answer:** Deliver one insight per hat — six short bullets is still more balanced than one biased answer.
- **Hats conflict sharply:** Surface the conflict explicitly — Black and Yellow disagreeing is the output, not a problem.
- **User only wants specific hats:** Deliver those, and note which perspectives were skipped.
- **Group context:** Suggest assigning one hat per person and rotating — this is the method's original team design.
