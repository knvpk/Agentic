# Role Storming

**Goal:** Break out of a single viewpoint by systematically inhabiting radically different personas — each brings values, language, and constraints that surface ideas no single perspective would find.

**When to use:** Designing for diverse groups, avoiding groupthink, needing stakeholder perspectives, or when the user feels stuck in their own frame.

---

## Phase 1 — 10-perspective sweep

Fully embody each role and respond as that person would — in their voice, from their lived experience.

**Default roles:**
1. A 5-year-old child
2. A tech entrepreneur
3. An environmental activist
4. A retired teacher
5. A professional athlete
6. An artist or creative
7. A scientist or researcher
8. A politician
9. A person from 100 years ago
10. A person from 100 years in the future

For each role:
- Write 2–3 sentences from genuinely inside that worldview
- Use vocabulary, concerns, and values authentic to that role
- Surface something non-obvious — avoid the generic first take
- Do not break character or editorialize

**Output format — exactly:**
```
- [5-year-old child]: [perspective]
- [Tech entrepreneur]: [perspective]
...
```

> **Custom roles:** If the user specifies their own roles (e.g. "use a CFO, a front-line nurse, a teenager"), replace the defaults entirely. Apply the same depth and authenticity standards.

---

## Phase 2 — Deep-dive on one role

When the user picks a role, generate 5 detailed ideas that:
- Reflect that role's specific values, vocabulary, and daily constraints
- Address resources this role has (or lacks)
- Include at least one opportunity and one challenge only visible from this role's position
- Stay fully in character — no "as an AI" language

**Output format — exactly:**
```
- [Idea 1]
- [Idea 2]
- [Idea 3]
- [Idea 4]
- [Idea 5]
```

---

## Example

**Input:** "We're designing a new city park."

**Phase 1 (excerpt):**
```
- [5-year-old child]: I want the swings to go really high and a water sprinkler you can run through in summer — but the bathrooms need to not be scary.
- [Environmental activist]: Native plants only — no grass monoculture, no chemical fertilizers. Design the drainage to recharge the groundwater table, not channel it to a storm drain.
- [Person from 100 years in the future]: Parks in our time are the last heat refuges in dense cities. Every tree species here should be chosen for climate zone 9b, not the current zone.
```

**Phase 2 on "Environmental activist":**
```
- Replace ornamental grass with native wildflowers — 60% less water, no mowing, and pollinator habitat that supports the surrounding urban food ecosystem.
- Install a bioswale along the perimeter to filter stormwater before it enters the drain system, naturally recharging the local water table.
- Use only FSC-certified reclaimed timber for benches — sourcing locally reduces transport emissions and supports regional forestry programs.
- Designate 20% of the park as a no-mow zone with educational signage explaining why "messy" areas are ecologically valuable.
- Partner with a local school program to let students monitor soil health quarterly, giving the park a living ecological data record.
```

---

## Edge cases

- **Role seems sensitive:** Portray the role's perspective honestly without endorsing harmful views — focus on what they value and fear.
- **Topic is highly technical:** Non-expert roles (child, person from the past) often surface the most valuable simplifications — lean into them.
- **Roles are very similar:** Surface the subtle differences — a pediatric nurse and a general nurse have different constraints even if adjacent.
