---
title: "Any LOOP Step That Creates a PR Must Attach the URL to the Linear Issue"
date: 2026-08-07
category: conventions
module: loop-template
problem_type: convention
component: documentation
severity: medium
applies_when:
  - "Editing LOOP.md or LOOP.mdc automation or post-step flows"
  - "Configuring Cursor Automation prompts for Generate plan or Implement"
  - "An agent creates a pull or merge request during any loop step, not only ce-work"
tags: [loop, linear, pull-request, merge-request, cursor-automations, conventions]
---

# Any LOOP Step That Creates a PR Must Attach the URL to the Linear Issue

## Context

LOOP already required attaching PR/MR URLs during **Implement** (`ce-work`) and in **Quy trình vòng sau `ce-work`**, but **Generate plan** (`ce-plan`) only mentioned checking/resolving conflicts when a PR existed — not attaching the URL. The `automations/generate-plan.json` prompt matched that gap: conflict check without "gán url vào Linear issue".

Owners asking whether post-`ce-plan` comments must include the PR URL exposed ambiguity: comment Linear is mandatory after planning, but URL attachment was tied only to the implement phase.

## Guidance

Treat PR/MR URL attachment as a **cross-step rule**, not an Implement-only step:

1. **Universal rule in LOOP** — after the three automation bullets, state explicitly that any step creating a pull/merge request (`ce-plan`, `ce-work`, automation, or manual) **must** attach that URL to the related Linear issue **immediately when the PR is created**, not deferred to a summary comment or the In Review transition.
2. **Generate plan step** — when status → `Todo` and a PR exists or is created during planning, attach URL PR/MR to Linear **before** conflict checks with `main` (`LOOP.md` automation bullet 1).
3. **Implement step** — unchanged contract: attach URL and move to `In Review`; comment includes the link (`LOOP.md` **Quy trình vòng sau `ce-work`** step 2).
4. **Post-`ce-plan` comment** — still required for plan completion (path, summary, next step). It does **not** replace attaching the PR URL to the issue field/metadata when a PR was created; URL on the issue is the durable anchor, comment is the handoff narrative.
5. **Sync surfaces** — portable rule in `LOOP.md` + `LOOP.mdc` (identical body); operator detail in `AUTOMATIONS.md`; automation prompt in `automations/generate-plan.json` when that step can create a PR.

**After (Generate plan automation bullet):**

```text
nếu có PR thì gắn URL PR/MR vào Linear và kiểm tra/resolve conflict với `main`.
```

**After (shared rule):**

```text
Quy tắc chung — gắn URL PR/MR (bắt buộc): bất kỳ bước nào tạo pull/merge request … đều phải gắn URL PR/MR đó vào issue Linear liên quan ngay khi tạo.
```

## Why This Matters

- **Linear as source of truth** — owners and agents discover open PRs from the issue without hunting Cursor chat or git remotes.
- **No phase confusion** — planning steps that accidentally ship a PR (or reuse an existing branch) still leave a trace on the issue.
- **Automation parity** — JSON prompts and LOOP prose stay aligned so imported automations do not under-specify Implement-only behavior.

## When to Apply

- Adding a new LOOP automation step that might commit or open a PR.
- Auditing loop-distributed repos where agents create PRs but forget Linear attachment until In Review.
- Clarifying owner questions about comment vs issue-field requirements after `ce-plan`.

## Examples

| Situation | Attach URL to Linear issue? | Also comment? |
|-----------|----------------------------|---------------|
| `ce-plan` only produces a plan (no PR opened) | No PR → no URL | Yes — plan path + next step |
| `ce-plan` or Generate plan creates PR | **Yes — immediately** | Yes — plan done; mention PR if relevant |
| `ce-work` / Implement completes | **Yes — before In Review** | Yes — ship summary + link |

## Related

- `LOOP.md` / `LOOP.mdc` — **Quy tắc chung — gắn URL PR/MR**, Cursor Automations, **Quy trình vòng sau `ce-work`**
- `AUTOMATIONS.md` — shared rule + Generate plan step 5
- `automations/generate-plan.json`, `automations/implement.json`
- [LOOP Agent Notifications Use Linear Comments Only](./loop-linear-only-agent-notifications.md) — comment contract vs issue metadata
