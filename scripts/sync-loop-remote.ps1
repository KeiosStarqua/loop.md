# Fetch latest sync-loop.ps1 (+ template) from loop.md on GitHub, then run sync.
#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$SyncArgs
)

$ErrorActionPreference = 'Stop'

$LoopConfigRawBase = if ($env:LOOP_CONFIG_RAW_BASE) {
    $env:LOOP_CONFIG_RAW_BASE
}
else {
    'https://raw.githubusercontent.com/KeiosStarqua/loop.md/refs/heads/main'
}

$SyncLoopScriptUrl = if ($env:SYNC_LOOP_SCRIPT_URL) {
    $env:SYNC_LOOP_SCRIPT_URL
}
else {
    "$LoopConfigRawBase/scripts/sync-loop.ps1"
}

$Cache = if ($env:LOOP_CONFIG_CACHE) {
    $env:LOOP_CONFIG_CACHE
}
elseif ($env:XDG_CACHE_HOME) {
    Join-Path $env:XDG_CACHE_HOME 'loop-config'
}
elseif ($env:LOCALAPPDATA) {
    Join-Path $env:LOCALAPPDATA 'loop-config'
}
else {
    Join-Path $HOME '.cache/loop-config'
}

function Write-ErrorAndExit {
    param([string]$Message)
    Write-Error $Message
    exit 1
}

function Get-RemoteFile {
    param(
        [string]$Url,
        [string]$Destination
    )

    try {
        Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
    }
    catch {
        Write-ErrorAndExit "download failed: $Url"
    }
}

# Windows PowerShell 5.1 parses BOM-less .ps1 as the system ANSI code page.
function Add-Utf8Bom {
    param([string]$Path)

    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $hasBom = ($bytes.Length -ge 3) -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
    if (-not $hasBom) {
        $withBom = New-Object byte[] ($bytes.Length + 3)
        $withBom[0] = 0xEF
        $withBom[1] = 0xBB
        $withBom[2] = 0xBF
        [System.Buffer]::BlockCopy($bytes, 0, $withBom, 3, $bytes.Length)
        [System.IO.File]::WriteAllBytes($Path, $withBom)
    }
}

$scriptsDir = Join-Path $Cache 'scripts'
New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null

$cachedScript = Join-Path $scriptsDir 'sync-loop.ps1'
Get-RemoteFile -Url $SyncLoopScriptUrl -Destination $cachedScript
Add-Utf8Bom -Path $cachedScript
Get-RemoteFile -Url "$LoopConfigRawBase/LOOP.mdc" -Destination (Join-Path $Cache 'LOOP.mdc')
Get-RemoteFile -Url "$LoopConfigRawBase/loop.env.example" -Destination (Join-Path $Cache 'loop.env.example')

& (Join-Path $scriptsDir 'sync-loop.ps1') @SyncArgs
