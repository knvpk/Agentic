---
name: my-brain
description: The user's core engineering principles — everything as code, decoupled, structured (types first), scalable, measured. Use when designing, writing, reviewing, or scaffolding any code, config, or infrastructure, or when choosing between approaches, so the work matches how this user builds things.
---

# my-brain

Five principles. For each: the rule, and a test question to answer yes/no about the work at hand. If an answer is "no", change the work or say why it is an exception.

## 1. Everything as code

Every action must be reproducible without AI/ML, from git alone. History, review and approval come from git; replication for another task should be trivial.

Examples:
- Infrastructure → Pulumi, Terraform
- Data transformation → dbt
- Video → Remotion, HyperFrames

**Test:** Could someone redo this from the repo with no AI and no manual steps?

## 2. Decoupled

Each capability is a module behind a small contract. Modules meet at an interface or the database, never in each other's code. One project's work should be a reusable artifact for others.

**Test:** Could another project reuse this without editing it?

## 3. Structured

Define types first (Pydantic, TypeScript types, schemas), then use them, so mistakes surface at build time instead of runtime.

**Test:** If the data has the wrong shape, does the build or a validator fail, rather than production?

## 4. Scalable

Add a capability by adding a module, not by editing a core.

**Test:** Does adding the next capability mean adding something new rather than modifying what exists?

## 5. Measured

Judge work by numbers (cost, time, counts, outcomes), not impressions.

**Test:** What number shows this worked, and where is it recorded?
