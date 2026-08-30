# Copy LOOP.mdc template into a target repo and replace REPLACE_* from .cursor/loop.env
# Keep this file ASCII. Windows PowerShell 5.1 parses BOM-less .ps1 as the system
# ANSI code page; a UTF-8 em dash becomes U+201D and closes double-quoted strings.
#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Init,
    [switch]$Setup,
    [switch]$Force,
    [string]$Owner,
    [string]$Workspace,
    [string]$ProjectName,
    [string]$ProjectUrl,
    [string]$ProjectId,
    [string]$TargetRepo = '.'
)

$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$ConfigRoot = Split-Path -Parent $ScriptDir
$Template = Join-Path $ConfigRoot 'LOOP.mdc'
$ExampleEnv = Join-Path $ConfigRoot 'loop.env.example'

$Placeholders = @(
    'REPLACE_LINEAR_OWNER_DISPLAY_NAME'
    'REPLACE_LINEAR_WORKSPACE'
    'REPLACE_LINEAR_PROJECT_NAME'
    'REPLACE_LINEAR_PROJECT_URL'
    'REPLACE_LINEAR_PROJECT_ID'
)

function Show-Usage {
    @'
Usage:
  sync-loop.ps1 [-Init] [[-TargetRepo] <path>]
  sync-loop.ps1 -Setup -Owner NAME -Workspace SLUG -ProjectName NAME `
                -ProjectUrl URL -ProjectId ID [-Force] [[-TargetRepo] <path>]

  No flags: copy LOOP.mdc -> TARGET/.cursor/rules/LOOP.mdc
            and replace REPLACE_* with values from TARGET/.cursor/loop.env.
            If TARGET/.cursor/loop.env is missing -> create from loop.env.example
            then sync immediately (no error). Edit loop.env and re-run if defaults
            are wrong for this repo.

  -Init        only create TARGET/.cursor/loop.env from loop.env.example (no overwrite,
               no sync) - use when you want to edit before syncing

  -Setup       all three steps in one command: create loop.env from five Linear flags
               (if missing, or overwrite with -Force) then sync immediately.
               Missing flag when loop.env does not exist -> clear error for that flag.
               Existing loop.env is kept (flags ignored) unless -Force.

  -Force       only with -Setup: overwrite an existing loop.env

TARGET repo defaults to the current directory (.)
'@ | Write-Host
}

function Write-ErrorAndExit {
    param([string]$Message)
    Write-Error $Message
    exit 1
}

function Read-EnvFile {
    param([string]$EnvFile)

    $vars = @{}
    foreach ($line in Get-Content -LiteralPath $EnvFile -Encoding utf8) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.TrimStart().StartsWith('#')) {
            continue
        }
        if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            $key = $Matches[1]
            $value = $Matches[2]
            if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
                ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            $vars[$key] = $value
        }
        else {
            Write-ErrorAndExit "invalid line in $EnvFile`: $line"
        }
    }
    return $vars
}

function Test-Placeholders {
    param(
        [hashtable]$Vars
    )

    $missing = @()
    foreach ($key in $Placeholders) {
        if (-not $Vars.ContainsKey($key) -or [string]::IsNullOrEmpty($Vars[$key])) {
            $missing += $key
        }
    }
    if ($missing.Count -gt 0) {
        Write-ErrorAndExit "missing values in .cursor/loop.env: $($missing -join ', ')"
    }
}

function Remove-ChecklistSection {
    param([string[]]$Lines)

    $output = New-Object System.Collections.Generic.List[string]
    $skip = $false
    foreach ($line in $Lines) {
        if ($line -match '^### Checklist REPLACE') {
            $skip = $true
            continue
        }
        if ($skip -and $line -match '^### ') {
            $skip = $false
        }
        if (-not $skip) {
            [void]$output.Add($line)
        }
    }
    return $output
}

function Invoke-Init {
    param([string]$Target)

    $dest = Join-Path $Target '.cursor/loop.env'
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    if (Test-Path -LiteralPath $dest) {
        Write-Host "already exists: $dest (not overwritten)"
        return
    }
    Copy-Item -LiteralPath $ExampleEnv -Destination $dest
    Write-Host "created: $dest - fill in this repo's Linear values"
}

function Invoke-Setup {
    param(
        [string]$Target,
        [bool]$ForceSetup,
        [hashtable]$SetupValues
    )

    $dest = Join-Path $Target '.cursor/loop.env'
    if ((Test-Path -LiteralPath $dest) -and -not $ForceSetup) {
        Write-Host "already exists: $dest (kept as-is; use -Force to overwrite)"
    }
    else {
        $missing = @()
        foreach ($key in $Placeholders) {
            if (-not $SetupValues.ContainsKey($key) -or [string]::IsNullOrEmpty($SetupValues[$key])) {
                $missing += $key
            }
        }
        if ($missing.Count -gt 0) {
            Write-ErrorAndExit "missing flags for -Setup (loop.env does not exist yet): $($missing -join ', ')"
        }

        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        $lines = @(
            '# Linear values for this repo - created by sync-loop.ps1 -Setup'
        )
        foreach ($key in $Placeholders) {
            $lines += "$key=$($SetupValues[$key])"
        }
        [System.IO.File]::WriteAllText(
            $dest,
            ($lines -join [Environment]::NewLine),
            [System.Text.UTF8Encoding]::new($false)
        )
        Write-Host "created: $dest"
    }

    Invoke-Sync -Target $Target
}

function Invoke-Sync {
    param([string]$Target)

    $envFile = Join-Path $Target '.cursor/loop.env'
    $outDir = Join-Path $Target '.cursor/rules'
    $outFile = Join-Path $outDir 'LOOP.mdc'

    if (-not (Test-Path -LiteralPath $Template)) {
        Write-ErrorAndExit "template not found: $Template"
    }

    if (-not (Test-Path -LiteralPath $envFile)) {
        Invoke-Init -Target $Target
        Write-Host "  (using default Linear values from loop.env.example - edit $envFile and re-run if wrong for this repo)"
    }

    $vars = Read-EnvFile -EnvFile $envFile
    Test-Placeholders -Vars $vars

    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    $content = Remove-ChecklistSection -Lines (Get-Content -LiteralPath $Template -Encoding utf8)
    $text = ($content -join [Environment]::NewLine)

    foreach ($key in $Placeholders) {
        $text = $text.Replace($key, $vars[$key])
    }

    if ($text -match 'REPLACE_LINEAR_[A-Z_]+') {
        Write-Error "unreplaced placeholders remain:"
        $lineNumber = 0
        foreach ($line in $text -split "`r?`n") {
            $lineNumber++
            if ($line -match 'REPLACE_LINEAR_[A-Z_]+') {
                Write-Error "${lineNumber}:$line"
            }
        }
        exit 1
    }

    [System.IO.File]::WriteAllText($outFile, $text, [System.Text.UTF8Encoding]::new($false))
    Write-Host "written: $outFile"
    foreach ($key in $Placeholders) {
        Write-Host "  $key=$($vars[$key])"
    }
}

$target = (Resolve-Path -LiteralPath $TargetRepo).Path
if (-not (Test-Path -LiteralPath $target -PathType Container)) {
    Write-ErrorAndExit "not a directory: $target"
}

$setupValues = @{
    REPLACE_LINEAR_OWNER_DISPLAY_NAME = $Owner
    REPLACE_LINEAR_WORKSPACE          = $Workspace
    REPLACE_LINEAR_PROJECT_NAME       = $ProjectName
    REPLACE_LINEAR_PROJECT_URL        = $ProjectUrl
    REPLACE_LINEAR_PROJECT_ID         = $ProjectId
}

if ($Setup) {
    Invoke-Setup -Target $target -ForceSetup:$Force.IsPresent -SetupValues $setupValues
}
elseif ($Init) {
    Invoke-Init -Target $target
}
else {
    Invoke-Sync -Target $target
}
