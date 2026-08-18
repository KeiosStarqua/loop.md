---
title: "Auto Merge Pull Request After ce-compound Step"
date: 2026-08-18
category: conventions
module: loop-template
problem_type: convention
component: documentation
severity: medium
applies_when:
  - "Editing LOOP.md or LOOP.mdc compound workflow rules"
  - "Configuring Compound automation or manual ce-compound steps"
  - "A pull request is created during ce-compound"
tags: [loop, ce-compound, pull-request, merge-request, auto-merge, cursor-automations, conventions]
---

# Auto Merge Pull Request After ce-compound Step

## Context

In the loop workflow, after completing a task loop and transitioning an issue to `Compound`, the `ce-compound` step creates or updates durable learning documents and DOX frameworks. If changes are made, a pull/merge request is created. To keep documentation and learnings immediately integrated into `main` and avoid manual merge overhead, any PR/MR created during the `ce-compound` / `Compound` step must be automatically merged into `main` after resolving any conflicts.

## Guidance

1. **Auto-merge compound PR in `ce-compound` / Compound flow:**
   - When `ce-compound` creates a PR/MR for doc/learning changes, the agent must verify no conflicts with `main` (resolving conflicts if any exist).
   - Auto-merge the pull/merge request into `main`.
   - Attach the PR/MR URL to the Linear issue immediately.
2. **Post-`ce-compound` State:**
   - Clean up branches created during `ce-work` if merged.
   - Do not change Linear issue status when done (the issue remains in `Compound`).
3. **Sync surfaces:**
   - Keep `LOOP.md` and `LOOP.mdc` strictly synchronized.
   - Update `AUTOMATIONS.md` for operator-level details.
   - Never edit prompts inside `automations/*.json`.

## Why This Matters

- **Streamlines closure** — Documentation and learnings land on `main` immediately without requiring manual operator merges.
- **Durable single source of truth** — Next cycles and automations immediately benefit from freshly recorded learnings on `main`.

## Related

- `LOOP.md` / `LOOP.mdc` — **Cursor Automations (Compound)**
- `AUTOMATIONS.md` — Compound step
- [Auto Merge Plan Pull Request After ce-plan Step](./loop-auto-merge-plan-pr.md)
- [Auto Merge Pull Request After ce-work Step](./loop-auto-merge-work-pr.md)
- [Any LOOP Step That Creates a PR Must Attach the URL to the Linear Issue](./loop-attach-pr-url-to-linear-issue.md)
