# Copy LOOP.mdc template into a target repo and replace REPLACE_* from .cursor/loop.jsonc.
# Still reads .cursor/loop.env when loop.jsonc is absent (one project).
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
    [string]$ForceMerge = 'true',
    [string[]]$ProjectName,
    [string[]]$ProjectUrl,
    [string[]]$ProjectId,
    [string]$TargetRepo = '.'
)

$ErrorActionPreference = 'Stop'

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
$ConfigRoot = Split-Path -Parent $ScriptDir
$Template = Join-Path $ConfigRoot 'LOOP.mdc'
$ExampleConfig = Join-Path $ConfigRoot 'loop.jsonc.example'

$Placeholders = @(
    'REPLACE_LINEAR_OWNER_DISPLAY_NAME'
    'REPLACE_LINEAR_WORKSPACE'
    'REPLACE_LOOP_FORCE_MERGE_PR'
    'REPLACE_LINEAR_DEFAULT_PROJECT_NAME'
    'REPLACE_LINEAR_PROJECT_NAMES'
    'REPLACE_LINEAR_PROJECTS_TABLE'
)

function Show-Usage {
    @'
Usage:
  sync-loop.ps1 [-Init] [[-TargetRepo] <path>]
  sync-loop.ps1 -Setup -Owner NAME -Workspace SLUG `
                -ProjectName NAME [-ProjectName NAME2] `
                -ProjectUrl URL [-ProjectUrl URL2] `
                -ProjectId ID [-ProjectId ID2] `
                [-ForceMerge true|false] [-Force] [[-TargetRepo] <path>]

  No flags: copy LOOP.mdc -> TARGET/.cursor/rules/LOOP.mdc
            and replace REPLACE_* with values from TARGET/.cursor/loop.jsonc.
            If loop.jsonc is missing but loop.env exists, read loop.env (one project).
            If both are missing, create loop.jsonc from loop.jsonc.example
            then sync immediately. Edit loop.jsonc and re-run if defaults are wrong.

  -Init        only create TARGET/.cursor/loop.jsonc from loop.jsonc.example
               (no overwrite, no sync). If loop.env exists and loop.jsonc does not,
               do not create loop.jsonc: that file would take priority and hide loop.env.

  -Setup       create loop.jsonc from flags (if missing, or overwrite with -Force)
               then sync. Repeat -ProjectName / -ProjectUrl / -ProjectId once per
               Linear project, in the same order. The first project is the default.
               An existing loop.jsonc or loop.env is kept unless -Force.

  -ForceMerge  true or false. Only with -Setup. Default true.

  -Force       only with -Setup: overwrite an existing loop.jsonc

TARGET repo defaults to the current directory (.)
'@ | Write-Host
}

function Write-ErrorAndExit {
    param([string]$Message)
    Write-Error $Message
    exit 1
}

function Get-DefaultRoleLabel {
    # "mac dinh" in Vietnamese, built from code points so this file stays ASCII.
    -join @(
        [char]0x006D, [char]0x1EB7, [char]0x0063, [char]0x0020,
        [char]0x0111, [char]0x1ECB, [char]0x006E, [char]0x0068
    )
}

function ConvertTo-TableCell {
    param([string]$Value)
    return $Value.Replace('\', '\\').Replace('|', '\|').Replace("`r", '').Replace("`n", ' ')
}

function ConvertTo-JsonStringLiteral {
    param([string]$Value)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('"')
    foreach ($ch in $Value.ToCharArray()) {
        $code = [int]$ch
        switch ($code) {
            92 { [void]$sb.Append('\\') }
            34 { [void]$sb.Append('\"') }
            10 { [void]$sb.Append('\n') }
            13 { [void]$sb.Append('\r') }
            9 { [void]$sb.Append('\t') }
            default {
                if ($code -lt 32) {
                    [void]$sb.Append('\u')
                    [void]$sb.AppendFormat('{0:x4}', $code)
                }
                else {
                    [void]$sb.Append($ch)
                }
            }
        }
    }
    [void]$sb.Append('"')
    return $sb.ToString()
}

function Remove-JsonComments {
    param([string]$Text)
    if ($Text.Length -gt 0 -and [int]$Text[0] -eq 0xFEFF) {
        $Text = $Text.Substring(1)
    }
    $out = New-Object System.Text.StringBuilder
    $inStr = $false
    $escape = $false
    $i = 0
    $n = $Text.Length
    while ($i -lt $n) {
        $c = $Text[$i]
        if ($inStr) {
            [void]$out.Append($c)
            if ($escape) {
                $escape = $false
            }
            elseif ($c -eq '\') {
                $escape = $true
            }
            elseif ($c -eq '"') {
                $inStr = $false
            }
            $i++
            continue
        }
        if ($c -eq '"') {
            $inStr = $true
            [void]$out.Append($c)
            $i++
            continue
        }
        if ($c -eq '/' -and ($i + 1) -lt $n -and $Text[$i + 1] -eq '/') {
            $i += 2
            while ($i -lt $n -and $Text[$i] -ne "`n") {
                $i++
            }
            continue
        }
        if ($c -eq '/' -and ($i + 1) -lt $n -and $Text[$i + 1] -eq '*') {
            $i += 2
            while (($i + 1) -lt $n -and -not ($Text[$i] -eq '*' -and $Text[$i + 1] -eq '/')) {
                $i++
            }
            if (($i + 1) -ge $n) {
                Write-ErrorAndExit 'unterminated /* comment in loop.jsonc'
            }
            $i += 2
            continue
        }
        [void]$out.Append($c)
        $i++
    }
    if ($inStr) {
        Write-ErrorAndExit 'unterminated string in loop.jsonc'
    }
    return $out.ToString()
}

function Format-ProjectsTable {
    param(
        [object[]]$Projects,
        [int]$DefaultIndex
    )
    $roleLabel = Get-DefaultRoleLabel
    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add('| Project | URL | ID | ' + (Get-VaiTroHeader) + ' |')
    [void]$lines.Add('| --- | --- | --- | --- |')
    for ($index = 0; $index -lt $Projects.Count; $index++) {
        $project = $Projects[$index]
        $role = ''
        if ($index -eq $DefaultIndex) {
            $role = $roleLabel
        }
        $projectId = ([string]$project.id).Replace('`', "'")
        [void]$lines.Add(
            ('| {0} | {1} | `{2}` | {3} |' -f `
                (ConvertTo-TableCell ([string]$project.name)), `
                (ConvertTo-TableCell ([string]$project.url)), `
                (ConvertTo-TableCell $projectId), `
                (ConvertTo-TableCell $role))
        )
    }
    return ($lines -join "`n")
}

function Get-VaiTroHeader {
    # Column header matching scripts/loop-jsonc.py. Code points keep this file ASCII.
    -join @(
        [char]0x0056, [char]0x0061, [char]0x0069, [char]0x0020,
        [char]0x0074, [char]0x0072, [char]0x00F2
    )
}

function ConvertTo-LoopView {
    param(
        [string]$OwnerName,
        [string]$WorkspaceName,
        [bool]$ForceMergePr,
        [object[]]$Projects,
        [int]$DefaultIndex
    )
    $names = @()
    foreach ($project in $Projects) {
        $names += [string]$project.name
    }
    $forceText = 'false'
    if ($ForceMergePr) {
        $forceText = 'true'
    }
    return @{
        REPLACE_LINEAR_OWNER_DISPLAY_NAME   = $OwnerName
        REPLACE_LINEAR_WORKSPACE            = $WorkspaceName
        REPLACE_LOOP_FORCE_MERGE_PR         = $forceText
        REPLACE_LINEAR_DEFAULT_PROJECT_NAME = [string]$Projects[$DefaultIndex].name
        REPLACE_LINEAR_PROJECT_NAMES        = ($names -join ', ')
        REPLACE_LINEAR_PROJECTS_TABLE       = (Format-ProjectsTable -Projects $Projects -DefaultIndex $DefaultIndex)
    }
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
            Write-ErrorAndExit "invalid line in ${EnvFile}: $line"
        }
    }
    return $vars
}

function Get-RequiredEnvValue {
    param(
        [hashtable]$Vars,
        [string]$Key
    )
    if (-not $Vars.ContainsKey($Key) -or [string]::IsNullOrWhiteSpace($Vars[$Key])) {
        Write-ErrorAndExit "missing value in loop.env: $Key"
    }
    return $Vars[$Key].Trim()
}

function ConvertFrom-LoopEnv {
    param([string]$EnvFile)
    $vars = Read-EnvFile -EnvFile $EnvFile
    $ownerName = Get-RequiredEnvValue -Vars $vars -Key 'REPLACE_LINEAR_OWNER_DISPLAY_NAME'
    $workspaceName = Get-RequiredEnvValue -Vars $vars -Key 'REPLACE_LINEAR_WORKSPACE'
    $name = Get-RequiredEnvValue -Vars $vars -Key 'REPLACE_LINEAR_PROJECT_NAME'
    $url = Get-RequiredEnvValue -Vars $vars -Key 'REPLACE_LINEAR_PROJECT_URL'
    $id = Get-RequiredEnvValue -Vars $vars -Key 'REPLACE_LINEAR_PROJECT_ID'
    $forceText = 'true'
    if ($vars.ContainsKey('REPLACE_LOOP_FORCE_MERGE_PR') -and -not [string]::IsNullOrWhiteSpace($vars['REPLACE_LOOP_FORCE_MERGE_PR'])) {
        $forceText = $vars['REPLACE_LOOP_FORCE_MERGE_PR'].Trim().ToLowerInvariant()
    }
    if ($forceText -ne 'true' -and $forceText -ne 'false') {
        Write-ErrorAndExit 'REPLACE_LOOP_FORCE_MERGE_PR must be true or false'
    }
    $projects = @([pscustomobject]@{ name = $name; url = $url; id = $id })
    return ConvertTo-LoopView -OwnerName $ownerName -WorkspaceName $workspaceName -ForceMergePr ($forceText -eq 'true') -Projects $projects -DefaultIndex 0
}

function Get-RequiredJsonString {
    param(
        $Object,
        [string]$Name,
        [string]$Where
    )
    $prop = $Object.PSObject.Properties[$Name]
    if (-not $prop -or $prop.Value -isnot [string] -or [string]::IsNullOrWhiteSpace([string]$prop.Value)) {
        Write-ErrorAndExit "$Where.$Name must be a non-empty string"
    }
    return ([string]$prop.Value).Trim()
}

function ConvertFrom-LoopJsonc {
    param([string]$ConfigFile)
    $raw = [System.IO.File]::ReadAllText($ConfigFile)
    $stripped = Remove-JsonComments -Text $raw
    try {
        $data = $stripped | ConvertFrom-Json
    }
    catch {
        Write-ErrorAndExit "invalid loop.jsonc: $($_.Exception.Message)"
    }
    if ($null -eq $data) {
        Write-ErrorAndExit 'loop.jsonc must be an object'
    }
    $ownerName = Get-RequiredJsonString -Object $data -Name 'ownerDisplayName' -Where 'loop.jsonc'
    $workspaceName = Get-RequiredJsonString -Object $data -Name 'workspace' -Where 'loop.jsonc'
    $forceProp = $data.PSObject.Properties['forceMergePr']
    $forceValue = $true
    if ($forceProp) {
        if ($forceProp.Value -isnot [bool]) {
            Write-ErrorAndExit 'forceMergePr must be boolean true/false, not a string'
        }
        $forceValue = [bool]$forceProp.Value
    }
    $projectProp = $data.PSObject.Properties['projects']
    if (-not $projectProp -or $null -eq $projectProp.Value) {
        Write-ErrorAndExit 'projects must be an array with at least one project'
    }
    $projects = @($projectProp.Value)
    if ($projects.Count -eq 0) {
        Write-ErrorAndExit 'projects must be an array with at least one project'
    }
    $normalized = @()
    $seen = @{}
    $defaultIndexes = @()
    for ($index = 0; $index -lt $projects.Count; $index++) {
        $item = $projects[$index]
        if ($null -eq $item -or -not ($item.PSObject)) {
            Write-ErrorAndExit "projects[$index] must be an object"
        }
        $name = Get-RequiredJsonString -Object $item -Name 'name' -Where "projects[$index]"
        $url = Get-RequiredJsonString -Object $item -Name 'url' -Where "projects[$index]"
        $id = Get-RequiredJsonString -Object $item -Name 'id' -Where "projects[$index]"
        if ($seen.ContainsKey($id)) {
            Write-ErrorAndExit "duplicate project id: $id"
        }
        $seen[$id] = $true
        $defaultProp = $item.PSObject.Properties['default']
        if ($defaultProp) {
            if ($defaultProp.Value -isnot [bool]) {
                Write-ErrorAndExit "projects[$index].default must be a boolean"
            }
            if ($defaultProp.Value) {
                $defaultIndexes += $index
            }
        }
        $normalized += [pscustomobject]@{ name = $name; url = $url; id = $id }
    }
    if ($defaultIndexes.Count -gt 1) {
        Write-ErrorAndExit 'only one project may have "default": true'
    }
    $defaultIndex = 0
    if ($defaultIndexes.Count -eq 1) {
        $defaultIndex = [int]$defaultIndexes[0]
    }
    return ConvertTo-LoopView -OwnerName $ownerName -WorkspaceName $workspaceName -ForceMergePr $forceValue -Projects $normalized -DefaultIndex $defaultIndex
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

function Copy-ExampleConfig {
    param([string]$Target)

    $dest = Join-Path $Target '.cursor/loop.jsonc'
    $destDir = Split-Path -Parent $dest
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    if (-not (Test-Path -LiteralPath $ExampleConfig)) {
        Write-ErrorAndExit "example not found: $ExampleConfig"
    }
    Copy-Item -LiteralPath $ExampleConfig -Destination $dest
    Write-Host "created: $dest - fill in this repo's Linear projects"
    return $dest
}

function Invoke-Init {
    param([string]$Target)

    $dest = Join-Path $Target '.cursor/loop.jsonc'
    $legacy = Join-Path $Target '.cursor/loop.env'
    if (Test-Path -LiteralPath $dest) {
        Write-Host "already exists: $dest (not overwritten)"
        return
    }
    if (Test-Path -LiteralPath $legacy) {
        Write-Host "already exists: $legacy - not creating loop.jsonc from the example, because loop.jsonc would take priority and hide loop.env."
        Write-Host "Create .cursor/loop.jsonc by hand from loop.jsonc.example, or re-run -Setup -Force."
        return
    }
    [void](Copy-ExampleConfig -Target $Target)
}

function Get-FlagCount {
    param($Value)
    if ($null -eq $Value) {
        return 0
    }
    return @($Value).Count
}

function Write-LoopJsonc {
    param(
        [string]$Destination,
        [string]$OwnerName,
        [string]$WorkspaceName,
        [bool]$ForceMergePr,
        [string[]]$Names,
        [string[]]$Urls,
        [string[]]$Ids
    )

    $forceLiteral = 'false'
    if ($ForceMergePr) {
        $forceLiteral = 'true'
    }
    $lines = New-Object System.Collections.Generic.List[string]
    [void]$lines.Add('{')
    [void]$lines.Add('  // Owner display name used in Linear comments.')
    [void]$lines.Add('  "ownerDisplayName": ' + (ConvertTo-JsonStringLiteral $OwnerName) + ',')
    [void]$lines.Add('')
    [void]$lines.Add('  // Linear workspace slug.')
    [void]$lines.Add('  "workspace": ' + (ConvertTo-JsonStringLiteral $WorkspaceName) + ',')
    [void]$lines.Add('')
    [void]$lines.Add('  // true: auto-merge PRs after ce-plan / ce-work / ce-compound.')
    [void]$lines.Add('  // false: open the PR and attach the Linear URL; wait for a manual merge.')
    [void]$lines.Add('  "forceMergePr": ' + $forceLiteral + ',')
    [void]$lines.Add('')
    [void]$lines.Add('  // Linear projects that own issues for this repo.')
    [void]$lines.Add('  // "default": true marks where new issues go when the project is not obvious.')
    [void]$lines.Add('  // If none is marked, the first project is the default.')
    [void]$lines.Add('  "projects": [')
    for ($index = 0; $index -lt $Names.Count; $index++) {
        [void]$lines.Add('    {')
        [void]$lines.Add('      "name": ' + (ConvertTo-JsonStringLiteral $Names[$index]) + ',')
        [void]$lines.Add('      "url": ' + (ConvertTo-JsonStringLiteral $Urls[$index]) + ',')
        if ($index -eq 0) {
            [void]$lines.Add('      "id": ' + (ConvertTo-JsonStringLiteral $Ids[$index]) + ',')
            [void]$lines.Add('      "default": true')
        }
        else {
            [void]$lines.Add('      "id": ' + (ConvertTo-JsonStringLiteral $Ids[$index]))
        }
        $suffix = ''
        if ($index -lt ($Names.Count - 1)) {
            $suffix = ','
        }
        [void]$lines.Add('    }' + $suffix)
    }
    [void]$lines.Add('  ]')
    [void]$lines.Add('}')
    $destDir = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }
    [System.IO.File]::WriteAllText(
        $Destination,
        (($lines -join "`n") + "`n"),
        [System.Text.UTF8Encoding]::new($false)
    )
}

function Invoke-Setup {
    param(
        [string]$Target,
        [bool]$ForceSetup
    )

    $dest = Join-Path $Target '.cursor/loop.jsonc'
    $legacy = Join-Path $Target '.cursor/loop.env'
    if ((Test-Path -LiteralPath $dest) -and -not $ForceSetup) {
        Write-Host "already exists: $dest (kept as-is; use -Force to overwrite)"
    }
    elseif ((Test-Path -LiteralPath $legacy) -and -not (Test-Path -LiteralPath $dest) -and -not $ForceSetup) {
        Write-Host "already exists: $legacy (kept as-is; use -Force to write loop.jsonc)"
    }
    else {
        if ([string]::IsNullOrWhiteSpace($Owner) -or [string]::IsNullOrWhiteSpace($Workspace)) {
            Write-ErrorAndExit 'missing flags for -Setup: -Owner and -Workspace'
        }
        $nameCount = Get-FlagCount $ProjectName
        $urlCount = Get-FlagCount $ProjectUrl
        $idCount = Get-FlagCount $ProjectId
        if ($nameCount -eq 0) {
            Write-ErrorAndExit 'missing flags for -Setup: -ProjectName, -ProjectUrl, -ProjectId'
        }
        if ($nameCount -ne $urlCount -or $nameCount -ne $idCount) {
            Write-ErrorAndExit '-ProjectName, -ProjectUrl, and -ProjectId must be passed as matching sets'
        }
        $forceText = $ForceMerge.Trim().ToLowerInvariant()
        if ($forceText -ne 'true' -and $forceText -ne 'false') {
            Write-ErrorAndExit '-ForceMerge must be true or false'
        }
        Write-LoopJsonc -Destination $dest -OwnerName $Owner.Trim() -WorkspaceName $Workspace.Trim() -ForceMergePr ($forceText -eq 'true') -Names @($ProjectName) -Urls @($ProjectUrl) -Ids @($ProjectId)
        Write-Host "created: $dest"
        if (Test-Path -LiteralPath $legacy) {
            Write-Host '  loop.jsonc takes priority; loop.env is ignored while loop.jsonc exists'
        }
    }

    Invoke-Sync -Target $Target
}

function Invoke-Sync {
    param([string]$Target)

    $jsonc = Join-Path $Target '.cursor/loop.jsonc'
    $legacy = Join-Path $Target '.cursor/loop.env'
    $outDir = Join-Path $Target '.cursor/rules'
    $outFile = Join-Path $outDir 'LOOP.mdc'
    $configFile = $null

    if (-not (Test-Path -LiteralPath $Template)) {
        Write-ErrorAndExit "template not found: $Template"
    }

    if (Test-Path -LiteralPath $jsonc) {
        $configFile = $jsonc
        $vars = ConvertFrom-LoopJsonc -ConfigFile $configFile
    }
    elseif (Test-Path -LiteralPath $legacy) {
        $configFile = $legacy
        Write-Host "reading $legacy (one project). For multiple projects, create .cursor/loop.jsonc - that file takes priority over loop.env."
        $vars = ConvertFrom-LoopEnv -EnvFile $configFile
    }
    else {
        $configFile = Copy-ExampleConfig -Target $Target
        Write-Host "  (using default Linear values from loop.jsonc.example - edit $configFile and re-run if wrong for this repo)"
        $vars = ConvertFrom-LoopJsonc -ConfigFile $configFile
    }

    if (-not (Test-Path -LiteralPath $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
    }

    $content = Remove-ChecklistSection -Lines (Get-Content -LiteralPath $Template -Encoding utf8)
    $text = ($content -join "`n")

    foreach ($key in $Placeholders) {
        if (-not $vars.ContainsKey($key)) {
            Write-ErrorAndExit "internal: missing replacement $key"
        }
        $text = $text.Replace($key, [string]$vars[$key])
    }

    if ($text -match 'REPLACE_(LINEAR|LOOP)_[A-Z0-9_]+') {
        Write-Error 'unreplaced placeholders remain:'
        $lineNumber = 0
        foreach ($line in ($text -split "`n")) {
            $lineNumber++
            if ($line -match 'REPLACE_(LINEAR|LOOP)_[A-Z0-9_]+') {
                Write-Error "${lineNumber}:$line"
            }
        }
        exit 1
    }

    [System.IO.File]::WriteAllText($outFile, $text, [System.Text.UTF8Encoding]::new($false))
    Write-Host "written: $outFile"
    Write-Host "  ownerDisplayName=$($vars['REPLACE_LINEAR_OWNER_DISPLAY_NAME'])"
    Write-Host "  workspace=$($vars['REPLACE_LINEAR_WORKSPACE'])"
    Write-Host "  forceMergePr=$($vars['REPLACE_LOOP_FORCE_MERGE_PR'])"
    Write-Host "  projects=$($vars['REPLACE_LINEAR_PROJECT_NAMES'])"
    Write-Host "  default=$($vars['REPLACE_LINEAR_DEFAULT_PROJECT_NAME'])"
}

$target = (Resolve-Path -LiteralPath $TargetRepo).Path
if (-not (Test-Path -LiteralPath $target -PathType Container)) {
    Write-ErrorAndExit "not a directory: $target"
}

if ($Setup) {
    Invoke-Setup -Target $target -ForceSetup:$Force.IsPresent
}
elseif ($Init) {
    Invoke-Init -Target $target
}
else {
    Invoke-Sync -Target $target
}
