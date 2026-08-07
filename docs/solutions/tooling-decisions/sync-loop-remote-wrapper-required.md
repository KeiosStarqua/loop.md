---
title: "Why sync-loop.sh Must Be Fetched via sync-loop-remote.sh, Not Piped Directly"
date: 2026-08-07
category: tooling-decisions
module: sync-loop-scripts
problem_type: tooling_decision
component: tooling
severity: low
applies_when:
  - "Writing a bash script that locates sibling files via `$(dirname \"${BASH_SOURCE[0]}\")` and may be invoked through `curl | bash`"
  - "Deciding whether to pipe a raw script URL directly into `bash` instead of using a wrapper that stages dependencies first"
tags: [bash, curl-pipe-bash, bash-source, set-u, remote-script, sync-loop]
---

# Why sync-loop.sh Must Be Fetched via sync-loop-remote.sh, Not Piped Directly

## Context

`README.md` recommends installing `LOOP.mdc` into a target repo by piping
`sync-loop-remote.sh` through `curl | bash`, and explicitly warns not to pipe
`sync-loop.sh` directly (`README.md:52`). A user asked why the direct,
simpler-looking `curl .../scripts/sync-loop.sh | bash` isn't good enough,
since the raw file is public on GitHub either way.

`sync-loop.sh` resolves its own directory to find the template files that
must sit next to it:

```5:8:scripts/sync-loop.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="${CONFIG_ROOT}/LOOP.mdc"
EXAMPLE_ENV="${CONFIG_ROOT}/loop.env.example"
```

`sync-loop-remote.sh` exists purely to make that resolution possible when the
caller has no local checkout: it downloads `sync-loop.sh` plus its two
sibling files (`LOOP.mdc`, `loop.env.example`) into one real cache directory,
then `exec`s the script from there so `BASH_SOURCE[0]` points at a real path
with the right neighbors:

```17:23:scripts/sync-loop-remote.sh
mkdir -p "$CACHE/scripts"
fetch "$SYNC_LOOP_SCRIPT_URL" "$CACHE/scripts/sync-loop.sh"
fetch "${LOOP_CONFIG_RAW_BASE}/LOOP.mdc" "$CACHE/LOOP.mdc"
fetch "${LOOP_CONFIG_RAW_BASE}/loop.env.example" "$CACHE/loop.env.example"
chmod +x "$CACHE/scripts/sync-loop.sh"

exec "$CACHE/scripts/sync-loop.sh" "$@"
```

## Guidance

Never pipe a script that resolves paths via `${BASH_SOURCE[0]}` directly from
`curl` into `bash` (e.g. `curl -fsSL <url>/sync-loop.sh | bash`). When a
script is read from `bash`'s standard input rather than executed from a real
file, `BASH_SOURCE[0]` is unset. Combined with `set -euo pipefail` (which
implies `set -u`), referencing it aborts the script immediately — before it
ever gets to the missing-template error a reader might expect.

Verified locally by simulating the direct-pipe path:

```bash
curl -fsSL <raw-sync-loop.sh-url> | bash -s -- --init /path/to/repo
```

```
bash: line 5: BASH_SOURCE[0]: unbound variable
bash: line 5: cd: null directory
```

If a script needs files that live next to it on disk, provide (or require
callers to use) a small wrapper that first downloads the script *and* its
siblings into one real directory, then executes the downloaded copy from
that path — never the pattern `curl <script-url> | bash`. That is exactly
what `sync-loop-remote.sh` does for `sync-loop.sh`.

## Why This Matters

The failure is not "missing template" (which would at least explain itself
via `sync-loop.sh`'s own `die "không tìm thấy template: $TEMPLATE"` check at
`scripts/sync-loop.sh:101`) — it's an unrelated, confusing `unbound variable`
error thrown before the script's own validation logic ever runs, because
`set -u` trips on `BASH_SOURCE[0]` first. Anyone hitting this without reading
the script source would reasonably suspect a broken URL or a bash version
issue, not a path-resolution assumption baked into the script.

## When to Apply

- Any bash script under this repo (or copied from it) that derives paths
  from its own location (`dirname "${BASH_SOURCE[0]}"` or `$0`) and ships a
  "remote install" story via `curl | bash`.
- Reviewing a PR that adds a new `curl | bash` one-liner to documentation —
  check whether the target script depends on sibling files before assuming
  a direct pipe is safe.

## Examples

Direct pipe (breaks — do not recommend this):

```bash
curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop.sh | bash -s -- --init /path/to/repo
```

Wrapper pipe (works — this is what `README.md` documents):

```bash
curl -fsSL https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.sh | bash -s -- --init /path/to/repo
```

## Related

- `README.md:52` — existing one-line warning against piping `sync-loop.sh` directly.
- `scripts/sync-loop-remote.sh` — the wrapper that makes the remote-install flow safe.
- `scripts/sync-loop.sh:5-8` — the path resolution this wrapper exists to satisfy.
- `scripts/sync-loop.sh:101` — the template-not-found guard that would otherwise be the first error surfaced.
