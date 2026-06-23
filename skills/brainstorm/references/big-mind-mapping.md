# Big Mind Mapping

**Goal:** Maximum idea coverage — cast the widest net across all angles of a topic before any filtering.

**When to use:** User is starting fresh, stuck, or wants to explore a problem space without constraints.

---

## Phase 1 — Initial generation

Generate 10 ideas that:
- Cover different aspects: implementation, audience, business model, risks, alternatives, social impact
- Are specific and actionable (not vague platitudes)
- Include at least 2 unconventional or counterintuitive ideas
- Are each a complete thought (2–3 sentences)
- Have no overlap with each other

**Output format — exactly:**
```
- [Idea 1]
- [Idea 2]
...
- [Idea 10]
```
No numbering. No bold headers. No preamble or closing remarks.

---

## Phase 2 — Expansion

When the user picks one idea, expand it into 5 sub-ideas across these dimensions:

1. **Implementation** — how would this actually be built or executed?
2. **Impact** — what's the realistic outcome if this succeeds?
3. **Variation** — a different flavor or approach to the same core idea
4. **Application** — another context or domain this idea could apply to
5. **Challenge + mitigation** — the biggest obstacle and one concrete way around it

**Output format — exactly:**
```
- [Implementation]
- [Impact]
- [Variation]
- [Application]
- [Challenge + mitigation]
```

---

## Example

**Input:** "How might we reduce food waste in restaurants?"

**Phase 1 (excerpt):**
```
- Partner with a local composting company to convert kitchen scraps into sellable garden soil, turning waste into a small revenue stream.
- Implement dynamic menu pricing where dishes using ingredients nearing expiry cost less, incentivizing customers to choose them.
- Train kitchen staff with weekly "waste audits" — weigh and categorize discards to build awareness and accountability over time.
```

**Phase 2 on "dynamic menu pricing":**
```
- Implementation: Integrate expiry tracking into the POS so prices auto-adjust nightly based on ingredient shelf life.
- Impact: Reduces end-of-day waste by up to 30% while increasing sales of near-expiry inventory that would otherwise be discarded.
- Variation: Apply the same logic to tasting menus — offer a surprise "chef's rescue" course at a discount using that day's surplus.
- Application: Grocery retailers use similar markdown logic; a restaurant API could sync with supplier systems to forecast expiry in advance.
- Challenge + mitigation: Customers may perceive discounted items as lower quality — frame it as "today's feature" rather than a markdown.
```

---

## Edge cases

- **Vague topic:** Ask one clarifying question to scope it, then proceed.
- **User wants more than 10:** Generate the next 10 as a second batch with no overlap.
- **User asks for evaluation:** Redirect — this method is generation only. Suggest Six Thinking Hats for balanced evaluation.
