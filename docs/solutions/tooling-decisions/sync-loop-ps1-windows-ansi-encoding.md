---
title: "Keep PowerShell Installer Scripts ASCII for Windows PowerShell 5.1"
date: 2026-08-30
category: tooling-decisions
module: sync-loop-scripts
problem_type: tooling_decision
component: tooling
severity: medium
applies_when:
  - "Editing scripts/sync-loop.ps1 or scripts/sync-loop-remote.ps1"
  - "Adding UTF-8 punctuation (em dash, smart quotes) to a .ps1 file that Windows PowerShell 5.1 will parse from disk"
  - "Debugging irm | iex parse errors (Missing closing '}', Unexpected token) after sync-loop-remote.ps1 downloads a cached script"
tags: [powershell, encoding, windows, utf-8, ansi, cp1252, sync-loop]
---

# Keep PowerShell Installer Scripts ASCII for Windows PowerShell 5.1

## Context

The documented Windows install path is:

```powershell
irm https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main/scripts/sync-loop-remote.ps1 | iex
```

`sync-loop-remote.ps1` is ASCII, so `irm | iex` can parse it. It then downloads `sync-loop.ps1` into `%LOCALAPPDATA%\loop-config\scripts\` and invokes that file with `& path`. Windows PowerShell 5.1 parses a BOM-less `.ps1` using the system ANSI code page (CP1252 / CP1258), not UTF-8.

UTF-8 em dash `—` is bytes `E2 80 94`. Under CP1252 those become `â€` plus U+201D (`"`). PowerShell treats U+201D as a double-quote, so a host message such as:

```powershell
Write-Host "created: $dest — fill in this repo's Linear values"
```

terminates at the em dash. The `'` in `repo's` then opens an unterminated single-quoted string, and the parser reports missing `}` starting at `function Invoke-Init`.

## Guidance

- Keep `scripts/*.ps1` ASCII. Use `-` instead of `—`.
- Do not put UTF-8 punctuation inside double-quoted PowerShell strings unless the file is saved with a UTF-8 BOM *and* every download path rewrites that BOM.
- After downloading `sync-loop.ps1`, `sync-loop-remote.ps1` prepends a UTF-8 BOM so Windows PowerShell 5.1 will parse later Unicode if it appears.
- Run `python3 scripts/check-ps1-ascii.py` after editing installer scripts. It fails if a `.ps1` is non-ASCII or if a CP1252 decode would inject a smart quote.

PowerShell 7 defaults to UTF-8, so this bug does not show up under `pwsh` even with em dashes present. Do not treat a successful `pwsh` parse as proof the Windows 5.1 path works.

## Why This Matters

The failure looks like a broken script (`Missing closing '}'`) rather than an encoding mismatch. Users re-running the documented one-liner never reach init/sync; they only see a parse exception from `iex` pointing at the cached copy.

## When to Apply

- Any new string, comment, or here-string in `scripts/*.ps1`
- Reviewing a PR that ports wording from `scripts/sync-loop.sh` (which may contain UTF-8 punctuation) into PowerShell
- A Windows report of `ParserError` / `MissingEndCurlyBrace` after `irm .../sync-loop-remote.ps1 | iex`

## Examples

Breaks on Windows PowerShell 5.1 (UTF-8 em dash in a double-quoted string):

```powershell
Write-Host "created: $dest — fill in this repo's Linear values"
```

Safe:

```powershell
Write-Host "created: $dest - fill in this repo's Linear values"
```

## Related

- `scripts/sync-loop.ps1` — installer; must stay ASCII
- `scripts/sync-loop-remote.ps1` — prepends UTF-8 BOM on the cached `.ps1`
- `scripts/check-ps1-ascii.py` — regression check
- [Why sync-loop.sh Must Be Fetched via sync-loop-remote.sh, Not Piped Directly](./sync-loop-remote-wrapper-required.md)
