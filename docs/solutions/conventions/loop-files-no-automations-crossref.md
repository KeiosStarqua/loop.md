---
title: "Do Not Reference AUTOMATIONS.md in LOOP Files Copied to Target Repos"
date: 2026-08-07
category: conventions
module: loop-rules
problem_type: convention
component: documentation
severity: medium
applies_when:
  - "Editing LOOP.md or LOOP.mdc in my-loop-config"
  - "Adding cross-references or detail pointers inside portable loop rules"
  - "LOOP.mdc will be installed into target repos as a Cursor rule"
tags: [loop-md, loop-mdc, automations-md, cursor-rules, portable-docs, conventions]
---

# Do Not Reference AUTOMATIONS.md in LOOP Files Copied to Target Repos

## Context

`LOOP.md` and `LOOP.mdc` are synced into every target repository. `LOOP.mdc` becomes that repo's Cursor rule file. `AUTOMATIONS.md` lives only in the `my-loop-config` source repo and is not copied during sync.

A heading that pointed readers to `AUTOMATIONS.md` for automation details would break in target repos: agents following the Cursor rule would look for a file that does not exist there.

## Guidance

Keep automation step summaries inline in `LOOP.md` / `LOOP.mdc`. Do not cross-reference repo-local files that are not part of the sync payload.

**Before:**

```markdown
**Cursor Automations (ba bước — chi tiết `AUTOMATIONS.md`):**
```

**After:**

```markdown
**Cursor Automations (ba bước):**
```

The three automation steps (Generate plan, Implement, Compound) remain in the LOOP files themselves. Detailed automation setup stays in `AUTOMATIONS.md` and `README.md` within `my-loop-config` only.

`LOOP.md` and `LOOP.mdc` must stay content-synchronized (`AGENTS.md` rule). When changing either file, update both.

## Why This Matters

Cursor rules are read without the surrounding `my-loop-config` repo context. A broken cross-reference trains agents to chase missing files or hallucinate automation setup. Portable rules should be self-contained for workflow semantics; config-repo docs hold operator-level detail.

## When to Apply

- Any edit to `LOOP.md` or `LOOP.mdc` that might add links or "see also" pointers
- New sections that assume files present only in `my-loop-config` (e.g. `AUTOMATIONS.md`, internal scripts docs)
- Reviewing LOOP content before it ships to many repos via `sync-loop`

## Examples

| Location | Reference `AUTOMATIONS.md`? | Why |
|----------|----------------------------|-----|
| `LOOP.md` / `LOOP.mdc` | No | Copied to target repos |
| `README.md` in `my-loop-config` | Yes | Stays in config repo |
| `AUTOMATIONS.md` | N/A | Source of automation detail |

Verified heading in both LOOP files after the fix:

```25:25:LOOP.md
**Cursor Automations (ba bước):**
```

## Related

- [sync-loop Should Auto-Create loop.env Instead of Requiring a Separate --init](../developer-experience/sync-loop-auto-init-missing-env.md)
- [Why sync-loop.sh Must Be Fetched via sync-loop-remote.sh, Not Piped Directly](../tooling-decisions/sync-loop-remote-wrapper-required.md)
