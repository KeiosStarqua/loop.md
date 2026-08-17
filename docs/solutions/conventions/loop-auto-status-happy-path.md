---
title: "LOOP Happy Path Auto-Advances Status Plan → In Progress → Compound → Done"
date: 2026-08-17
category: conventions
module: loop-template
problem_type: convention
component: documentation
severity: high
applies_when:
  - "Editing LOOP.md or LOOP.mdc status / automation completion rules"
  - "Configuring Generate plan, Implement, or Compound automation prompts"
  - "Documenting owner handoff or Serial Plan admission to Plan"
tags: [loop, linear, status, serial-plan, cursor-automations, conventions]
---

# LOOP Happy Path Auto-Advances Status Plan → In Progress → Compound → Done

## Context

Older LOOP docs used a manual handoff: after `ce-plan`, status stayed on `Plan` until the owner clicked **In Progress**; after `ce-work`, status went to **In Review** until someone moved to **Compound**; after `ce-compound`, status stayed on **Compound**. That handoff is obsolete.

## Guidance

1. **Happy path (required):**
   - `Plan` → `ce-plan` → auto-merge plan PR → auto status **In Progress**
   - `In Progress` → `ce-work` → auto-merge work PR → auto status **Compound**
   - `Compound` → `ce-compound` → auto-merge compound PR if any → auto status **Done**
2. **Do not** treat **In Review** or “owner clicks In Progress / leave Compound unchanged” as the happy path. Mention those only as legacy/fallback notes if needed.
3. **Fallback kept:** if Implement starts and the plan PR is not merged, stop, set status **Todo**, comment why (manual status jump).
4. **Serial Plan:** an outside routine/agent admits issues to **Plan** one at a time; wait until that issue reaches **Done** before the next **Plan**.
5. **Sync surfaces:** `LOOP.md` ↔ `LOOP.mdc`, `AUTOMATIONS.md`, and `automations/*.json` prompt samples. Do not invent Cursor Automations UI saves.

## Why This Matters

Agents and owners reading stale “không đổi status” / “In Review” instructions will leave issues stuck mid-loop and block Serial Plan admission of the next issue.

## Related

- `LOOP.md` / `LOOP.mdc` — Cursor Automations, Serial Plan, post-step quy trình
- `AUTOMATIONS.md` — diagram + Cách dùng
- [Auto Merge Plan Pull Request After ce-plan Step](./loop-auto-merge-plan-pr.md)
- [Auto Merge Pull Request After ce-work Step](./loop-auto-merge-work-pr.md)
