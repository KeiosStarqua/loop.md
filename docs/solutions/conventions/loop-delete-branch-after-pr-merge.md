---
title: "Delete Remote Branch After PR Merge in LOOP Workflow"
date: 2026-08-22
category: conventions
module: loop-template
problem_type: convention
component: documentation
severity: medium
applies_when:
  - "Editing LOOP.md or LOOP.mdc PR merge workflow rules"
  - "Configuring Generate plan, Implement, or Compound automations"
  - "Any LOOP step auto-merges a pull/merge request"
tags: [loop, pull-request, merge-request, branch-cleanup, cursor-automations, conventions]
---

# Delete Remote Branch After PR Merge in LOOP Workflow

## Context

The LOOP workflow auto-merges PRs after `ce-plan`, `ce-work`, and `ce-compound`. Without an explicit cleanup step, merged feature branches accumulate on the remote and clutter the repo. The prior "clean branches" note in Compound was vague and only mentioned `ce-work` branches.

## Guidance

1. **General rule (all PR merges):**
   - Immediately after a PR/MR merges into `main`, delete the PR's head branch on the remote.
   - GitHub: prefer `gh pr merge <n> --merge --delete-branch` (or `--squash` / `--rebase` per repo convention). If already merged: `git push origin --delete <head-branch>`.
   - GitLab: merge with **Remove source branch**, or equivalent API after merge.
   - Safety: only delete head branches of PRs the agent/automation created or can push to; never delete default branches or others' unmerged branches.

2. **Per-step application:**
   - **Generate plan / `ce-plan`:** delete plan PR head branch after auto-merge.
   - **Implement / `ce-work`:** delete ce-work PR head branch after auto-merge.
   - **Compound / `ce-compound`:** delete ce-compound PR head branch after auto-merge; sweep any remaining merged plan / ce-work / ce-compound head branches still on remote.

3. **Order:** merge PR → delete head branch → Linear comment / status change.

4. **Sync surfaces:**
   - Keep `LOOP.md` and `LOOP.mdc` strictly synchronized.
   - Update `AUTOMATIONS.md` for operator-level details.
   - Never edit prompts inside `automations/*.json`.

## Why This Matters

- **Keeps repos tidy** — merged branches do not linger on origin.
- **Explicit agent contract** — replaces ambiguous "clean branches" with a repeatable post-merge step.

## Related

- `LOOP.md` / `LOOP.mdc` — **Quy tắc chung — xóa nhánh sau merge PR**
- `AUTOMATIONS.md` — all three automation steps
- [Auto Merge Plan Pull Request After ce-plan Step](./loop-auto-merge-plan-pr.md)
- [Auto Merge Pull Request After ce-work Step](./loop-auto-merge-work-pr.md)
- [Auto Merge Pull Request After ce-compound Step](./loop-auto-merge-compound-pr.md)
