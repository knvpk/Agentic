# SCAMPER

**Goal:** Systematically transform an existing idea, product, or process through 7 creative lenses.

**When to use:** User has something that already exists and wants to improve or innovate on it — not starting from scratch.

---

## The 7 lenses

| Lens | Core question |
|---|---|
| **SUBSTITUTE** | What component, material, person, or step can be swapped for something else? |
| **COMBINE** | What two things can be merged to create something new or more valuable? |
| **ADAPT** | What already exists in another domain that can be borrowed and applied here? |
| **MODIFY** | What can be amplified, shrunk, sped up, slowed down, or reframed? |
| **PUT TO OTHER USE** | What other audience, purpose, or market could this serve? |
| **ELIMINATE** | What can be removed or simplified to make this better? |
| **REVERSE** | What happens if the order, roles, or direction is flipped? |

---

## Phase 1 — Full SCAMPER sweep

Apply all 7 lenses to the user's topic. Provide 1–2 specific ideas per lens (2–3 sentences each). Every idea must be concrete and directly tied to the topic — no generic answers.

**Output format — exactly:**
```
- SUBSTITUTE: [idea]
- COMBINE: [idea]
- ADAPT: [idea]
- MODIFY: [idea]
- PUT TO OTHER USE: [idea]
- ELIMINATE: [idea]
- REVERSE: [idea]
```

---

## Phase 2 — Deep-dive on one lens

When the user picks a lens, generate 5 advanced applications that:
- Push beyond the obvious first answer
- Consider multiple contexts or industries
- Include both incremental and radical transformations
- Address implementation realities

**Output format — exactly:**
```
- [Application 1]
- [Application 2]
- [Application 3]
- [Application 4]
- [Application 5]
```

---

## Example

**Input:** "SCAMPER a traditional gym membership model."

**Phase 1:**
```
- SUBSTITUTE: Replace flat monthly fees with a pay-per-minute model tracked via app check-in — casual users pay less, heavy users pay more, and the gym gets honest utilization data.
- COMBINE: Bundle the membership with a meal-prep delivery subscription — members get optimized nutrition sent weekly, creating a complete fitness-as-a-service product.
- ADAPT: Borrow the "freemium" model from software — free cardio equipment access, paid tiers unlock group classes, personal training, and recovery amenities.
- MODIFY: Magnify the social aspect by making every machine face other members (no TV screens) and building workout-partner matching into the app.
- PUT TO OTHER USE: Market unused capacity (6am–10am weekdays) to corporate clients as employee wellness blocks — a B2B product on existing infrastructure.
- ELIMINATE: Remove reception desks and lockers entirely — app-based entry, QR-code lockers, no staff overhead. Use the saved space for an extra studio.
- REVERSE: Instead of members coming to the gym, send rotating equipment boxes monthly with a live-streamed coach who trains them at home.
```

**Phase 2 on ELIMINATE:**
```
- Remove the annual commitment and replace with a rolling 30-day contract — shifts retention from lock-in to earned loyalty.
- Eliminate peak-hour discrimination and incentivize night owls with rewards points for visiting between 10pm–6am.
- Strip out branded merchandise retail space and replace with partner gear-rental lockers — pay-per-use, zero inventory risk.
- Eliminate front-desk check-in with facial recognition entry — reduces staffing costs 40% and removes social friction.
- Remove class size limits by moving all group classes to live-streamed hybrid format — in-person plus unlimited remote participants.
```

---

## Edge cases

- **Intangible topic (a policy, a process):** SCAMPER applies equally — "SUBSTITUTE" a process step, "ELIMINATE" a form, "REVERSE" an approval chain.
- **User doesn't have an existing thing:** Redirect to Big Mind Mapping to generate a starting idea first, then apply SCAMPER to the chosen one.
- **A lens doesn't apply:** Note "not applicable" and briefly explain why — don't force a weak idea.
