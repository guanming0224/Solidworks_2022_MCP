param(
    [string]$InstallDir = (Join-Path $PSScriptRoot 'runtime\solidworks-mcp'),
    [string]$ProjectDir = $PSScriptRoot,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$packageRoot = $PSScriptRoot

$targets = New-Object System.Collections.Generic.List[string]

if (Test-Path $InstallDir) { $targets.Add($InstallDir) }

$testDir = Join-Path (Split-Path $InstallDir -Parent) 'test'
$packageTestDir = Join-Path $packageRoot 'test'
if ((Test-Path $testDir) -and (Test-Path $packageTestDir)) {
    foreach ($file in Get-ChildItem $packageTestDir -File) {
        $installed = Join-Path $testDir $file.Name
        if (Test-Path $installed) { $targets.Add($installed) }
    }
}

foreach ($skill in 'sw-designer', 'sw-verification', 'sw-manufacturing') {
    $skillDir = Join-Path $ProjectDir ".claude\skills\$skill"
    if (Test-Path $skillDir) { $targets.Add($skillDir) }
}

foreach ($doc in 'CLAUDE.md', 'SW2022_AI_Stack_Install.md') {
    $docPath = Join-Path $ProjectDir $doc
    if (Test-Path $docPath) { $targets.Add($docPath) }
}

$mcpConfigPath = Join-Path $ProjectDir '.mcp.json'
if (Test-Path $mcpConfigPath) {
    $venvPython = Join-Path $InstallDir '.venv\Scripts\python.exe'
    $mcpConfig = Get-Content $mcpConfigPath -Raw | ConvertFrom-Json
    $registered = $mcpConfig.mcpServers.solidworks
    if ($registered -and $registered.command -eq $venvPython -and @($mcpConfig.mcpServers.PSObject.Properties).Count -eq 1) {
        $targets.Add($mcpConfigPath)
    } else {
        Write-Warning ".mcp.json does not match this install (or has other servers); left untouched. Remove the 'solidworks' entry by hand if needed."
    }
}

$emptyPipConfig = Join-Path $env:TEMP 'empty-pip.ini'
if (Test-Path $emptyPipConfig) { $targets.Add($emptyPipConfig) }

if ($targets.Count -eq 0) {
    Write-Host 'Nothing to remove.'
    return
}

Write-Host 'The following will be deleted:'
$targets | ForEach-Object { Write-Host "  $_" }

if (-not $Force) {
    $answer = Read-Host 'Type YES to continue'
    if ($answer -ne 'YES') {
        Write-Host 'Cancelled.'
        return
    }
}

foreach ($target in $targets) {
    Remove-Item $target -Recurse -Force
    Write-Host "Removed $target"
}

$skillsRoot = Join-Path $ProjectDir '.claude\skills'
if ((Test-Path $skillsRoot) -and -not (Get-ChildItem $skillsRoot -Force)) {
    Remove-Item $skillsRoot -Force
}

Write-Host 'Uninstall complete. Python and SolidWorks were not touched.'
