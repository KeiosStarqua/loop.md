---
title: "Auto Merge Plan Pull Request After ce-plan Step"
date: 2026-08-16
category: conventions
module: loop-template
problem_type: convention
component: documentation
severity: medium
applies_when:
  - "Editing LOOP.md or LOOP.mdc planning workflow rules"
  - "Configuring Generate plan automation or manual ce-plan steps"
  - "A pull request containing docs/plans is created during ce-plan"
tags: [loop, ce-plan, pull-request, merge-request, auto-merge, cursor-automations, conventions]
---

# Auto Merge Plan Pull Request After ce-plan Step

## Context

In the loop workflow, `ce-work` requires the plan file (and its PR) to be merged into `main` before implementation can begin. If the plan PR remained open after `ce-plan`, the subsequent `Implement` step (`In Progress`) would stop with status `Todo` until the plan PR was manually merged.

To streamline the workflow and eliminate unnecessary manual intervention, any pull/merge request created during or after the `ce-plan` step (containing the plan) must be automatically merged into `main` after resolving any conflicts.

## Guidance

1. **Auto-merge plan PR in `ce-plan` / Generate plan flow:**
   - When `ce-plan` creates a PR/MR (or commits to a branch), the agent must verify no conflicts with `main` (resolving conflicts if any exist).
   - Auto-merge the pull/merge request into `main`.
   - Attach the PR/MR URL to the Linear issue.
2. **Post-`ce-plan` Notification:**
   - Include the plan path, Linear issue link, and plan PR merge status in the mandatory Linear comment to the owner.
3. **Sync surfaces:**
   - Update both `LOOP.md` and `LOOP.mdc` synchronously.
   - Update `AUTOMATIONS.md` for operator-level details.

## Why This Matters

- **Eliminates friction** — `Implement` (`In Progress`) can immediately proceed to `ce-work` because the prerequisite (merged plan) is automatically satisfied.
- **Durable single source of truth** — Plans land on `main` immediately, allowing consistent branching and context retrieval.

## Related

- `LOOP.md` / `LOOP.mdc` — **Cursor Automations**, **Quy trình vòng sau `ce-plan`**
- `AUTOMATIONS.md` — Generate plan step
- [Any LOOP Step That Creates a PR Must Attach the URL to the Linear Issue](./loop-attach-pr-url-to-linear-issue.md)
