---
title: "Auto Merge Pull Request After ce-work Step"
date: 2026-08-17
category: conventions
module: loop-template
problem_type: convention
component: documentation
severity: medium
applies_when:
  - "Editing LOOP.md or LOOP.mdc implementation workflow rules"
  - "Configuring Implement automation or manual ce-work steps"
  - "A pull request is created during ce-work"
tags: [loop, ce-work, pull-request, merge-request, auto-merge, cursor-automations, conventions]
---

# Auto Merge Pull Request After ce-work Step

## Context

In the loop workflow, after completing implementation (`ce-work`), code changes are committed and a pull/merge request is created. To accelerate development loops and reduce manual merge overhead, any PR/MR created during the `ce-work` / `Implement` step must be automatically merged into `main` after resolving any conflicts with `main`.

## Guidance

1. **Auto-merge work PR in `ce-work` / Implement flow:**
   - When `ce-work` creates a PR/MR (or commits on a branch), the agent must verify no conflicts with `main` (resolving conflicts if any exist).
   - Auto-merge the pull/merge request into `main`.
   - Delete the PR head branch on the remote (see [Delete Remote Branch After PR Merge](./loop-delete-branch-after-pr-merge.md)).
   - Attach the PR/MR URL to the Linear issue immediately.
2. **Post-`ce-work` Status and Notification:**
   - Update the Linear issue status to `In Review`.
   - Send a Linear comment (100% Vietnamese) to the owner with what was shipped, PR/MR URL, auto-merge status, and waiting for review/compound.
3. **Sync surfaces:**
   - Keep `LOOP.md` and `LOOP.mdc` strictly synchronized.
   - Update `AUTOMATIONS.md` for operator-level details.
   - Never edit prompts inside `automations/*.json`.

## Why This Matters

- **Streamlines shipping** — Changes land on `main` immediately once tested and verified by `ce-work`, enabling rapid cycle progression.
- **Durable single source of truth** — Next automations (such as `Compound`) and subsequent task loops branch cleanly off up-to-date `main`.

## Related

- `LOOP.md` / `LOOP.mdc` — **Cursor Automations**, **Quy trình vòng `ce-work`**
- `AUTOMATIONS.md` — Implement step
- [Auto Merge Plan Pull Request After ce-plan Step](./loop-auto-merge-plan-pr.md)
- [Any LOOP Step That Creates a PR Must Attach the URL to the Linear Issue](./loop-attach-pr-url-to-linear-issue.md)
