---
title: "sync-loop Should Auto-Create loop.env Instead of Requiring a Separate --init"
date: 2026-08-07
category: developer-experience
module: sync-loop-scripts
problem_type: developer_experience
component: tooling
severity: medium
applies_when:
  - "Installing or refreshing LOOP.mdc into a target repo via curl | bash"
  - "A target repo has no per-repo loop env file yet"
  - "Designing a remote installer that currently fails when a local env file is missing"
tags: [sync-loop, loop-env, curl-pipe-bash, auto-init, developer-experience]
---

# sync-loop Should Auto-Create loop.env Instead of Requiring a Separate --init

## Context

Users install loop rules with one recommended command:

```bash
curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash
```

Before the fix, that path died when the target repo had no per-repo loop env file, with an error telling the user to run `--init` first. That forced a multi-step flow (init → edit env → sync) even though the user only wanted one command. Longer alternatives (`--setup` with five Linear flags) were rejected as too heavy for the default path.

## Guidance

Default sync must be idempotent and self-bootstrapping:

1. If the target repo has neither `.cursor/loop.jsonc` nor legacy `.cursor/loop.env`, create `loop.jsonc` from `loop.jsonc.example` (do not overwrite an existing file).
2. Continue sync immediately using those values.
3. Tell the user the defaults may need editing, then re-run the same command.

Keep `--init` for “create only, don’t sync,” and keep `--setup` as an optional power path for callers that already know the Linear values (owner, workspace, and one or more projects). Do not make the happy path require either flag. A legacy `loop.env` is read as a single project when `loop.jsonc` is absent; do not seed a default `loop.jsonc` on top of it, because `loop.jsonc` would take priority.

Verified behavior in `cmd_sync`:

```159:162:scripts/sync-loop.sh
  else
    cmd_init "$target"
    config_file="$jsonc"
    echo "  (dùng giá trị mặc định trong loop.jsonc.example — sửa $config_file rồi chạy lại nếu không đúng cho repo này)"
```

`cmd_init` still refuses to overwrite an existing `loop.jsonc`, and it does not seed `loop.jsonc` when legacy `loop.env` is already present, so re-running the plain sync command is safe once Linear values are filled in.

## Why This Matters

A remote installer that fails on first use teaches users the tool is broken, not that they missed a setup step. Auto-init preserves one memorable command while still requiring an intentional edit of Linear project metadata when the placeholder defaults are wrong.

## When to Apply

- Any `curl | bash` installer that currently hard-errors on a missing local config file that can be safely seeded from a checked-in example
- Sync flows where placeholder defaults are acceptable for a first write, and correct values are a follow-up edit + re-run
- Cases where users explicitly reject long one-shot flag lists for the default path

## Examples

**Before (failed):**

```text
error: chưa có <repo>/.cursor/loop.env — chạy: .../sync-loop.sh --init "<repo>"
```

**After (succeeds on first run):**

```text
đã tạo: <repo>/.cursor/loop.jsonc — hãy điền project Linear của repo
  (dùng giá trị mặc định trong loop.jsonc.example — sửa ... rồi chạy lại nếu không đúng)
đã ghi: <repo>/.cursor/rules/LOOP.mdc
```

Then edit the target repo's `loop.jsonc` (`projects` may list more than one Linear project) and re-run the same curl command.

## Related

- [Why sync-loop.sh Must Be Fetched via sync-loop-remote.sh, Not Piped Directly](../tooling-decisions/sync-loop-remote-wrapper-required.md)
