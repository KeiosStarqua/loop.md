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

1. If the target repo's loop env file is missing, create it from `loop.env.example` (do not overwrite an existing file).
2. Continue sync immediately using those values.
3. Tell the user the defaults may need editing, then re-run the same command.

Keep `--init` for “create only, don’t sync,” and keep `--setup` as an optional power path for callers that already know the five Linear values. Do not make the happy path require either flag.

Verified behavior in `cmd_sync`:

```147:150:scripts/sync-loop.sh
  if [[ ! -f "$env_file" ]]; then
    cmd_init "$target"
    echo "  (dùng giá trị Linear mặc định trong loop.env.example — sửa $env_file rồi chạy lại nếu không đúng cho repo này)"
  fi
```

`cmd_init` still refuses to overwrite an existing env file, so re-running the plain sync command is safe once Linear values are filled in.

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
đã tạo: <repo>/.cursor/loop.env — hãy điền giá trị Linear của repo
  (dùng giá trị Linear mặc định trong loop.env.example — sửa ... rồi chạy lại nếu không đúng)
đã ghi: <repo>/.cursor/rules/LOOP.mdc
```

Then edit the target repo's loop env file with the real Linear project and re-run the same curl command.

## Related

- [Why sync-loop.sh Must Be Fetched via sync-loop-remote.sh, Not Piped Directly](../tooling-decisions/sync-loop-remote-wrapper-required.md)
