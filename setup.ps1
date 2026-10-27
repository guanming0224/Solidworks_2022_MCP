param(
    [string]$InstallDir = (Join-Path $PSScriptRoot 'runtime\solidworks-mcp'),
    [string]$ProjectDir = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$packageRoot = $PSScriptRoot

function Find-Python {
    foreach ($candidate in @(@('py', '-3'), @('python'))) {
        $exe = $candidate[0]
        if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) { continue }
        $extra = @($candidate | Select-Object -Skip 1)
        $version = $null
        try { $version = & $exe @extra -c 'import sys; print(sys.version_info[0]*100+sys.version_info[1])' 2>$null } catch { }
        if ($LASTEXITCODE -ne 0 -or -not $version) { continue }
        if ([int]$version -ge 310) { return ,@($exe) + $extra }
    }
    throw 'Python 3.10+ not found. Install it from python.org (tick "Add to PATH") and rerun.'
}

if (-not (Test-Path 'HKLM:\SOFTWARE\SolidWorks') -and -not (Get-ChildItem 'HKLM:\SOFTWARE\SolidWorks*' -ErrorAction SilentlyContinue)) {
    Write-Warning 'SolidWorks registry key not found. The MCP needs SolidWorks 2022 installed on this PC.'
}

$python = Find-Python
Write-Host "Using Python: $($python -join ' ')"

Write-Host "[1/5] Copying MCP source to $InstallDir"
New-Item -ItemType Directory -Force $InstallDir | Out-Null
robocopy (Join-Path $packageRoot 'solidworks-mcp') $InstallDir /E /XD .venv .git __pycache__ /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy failed ($LASTEXITCODE)" }

Write-Host '[2/5] Creating venv'
$venvPython = Join-Path $InstallDir '.venv\Scripts\python.exe'
if (-not (Test-Path $venvPython)) {
    & $python[0] @($python | Select-Object -Skip 1) -m venv (Join-Path $InstallDir '.venv')
    if ($LASTEXITCODE -ne 0) { throw 'venv creation failed' }
}

Write-Host '[3/5] Installing dependencies (mcp pinned to <2)'
$emptyPipConfig = Join-Path $env:TEMP 'empty-pip.ini'
Set-Content $emptyPipConfig '' -Encoding ascii
$env:PIP_CONFIG_FILE = $emptyPipConfig
# Windows PowerShell 5.1 turns any pip stderr warning into a terminating error under 'Stop';
# the exit codes below are checked explicitly instead.
$ErrorActionPreference = 'Continue'
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install -r (Join-Path $packageRoot 'requirements-lock.txt')
if ($LASTEXITCODE -ne 0) { throw 'dependency install failed' }
& $venvPython -m pip install --no-deps -e $InstallDir
if ($LASTEXITCODE -ne 0) { throw 'solidworks-mcp install failed' }
$ErrorActionPreference = 'Stop'

Write-Host "[4/5] Setting up project folder $ProjectDir"
$skillsTarget = Join-Path $ProjectDir '.claude\skills'
New-Item -ItemType Directory -Force $skillsTarget | Out-Null
robocopy (Join-Path $packageRoot 'skills') $skillsTarget /E /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy failed ($LASTEXITCODE)" }
foreach ($doc in 'CLAUDE.md', 'SW2022_AI_Stack_Install.md') {
    $target = Join-Path $ProjectDir $doc
    if (-not (Test-Path $target)) { Copy-Item (Join-Path $packageRoot "docs\$doc") $target }
}
$testTarget = Join-Path (Split-Path $InstallDir -Parent) 'test'
New-Item -ItemType Directory -Force $testTarget | Out-Null
Copy-Item (Join-Path $packageRoot 'test\*') $testTarget -Force

$dataDir = Join-Path $InstallDir 'data'
$dataTempDir = Join-Path $dataDir 'tmp'
$dataSkillsDir = Join-Path $dataDir 'skills'
New-Item -ItemType Directory -Force $dataTempDir, $dataSkillsDir | Out-Null

$mcpConfigPath = Join-Path $ProjectDir '.mcp.json'
$mcpConfig = [ordered]@{
    mcpServers = [ordered]@{
        solidworks = [ordered]@{
            type    = 'stdio'
            command = $venvPython
            args    = @('-m', 'sw_mcp.server')
            env     = [ordered]@{
                TEMP               = $dataTempDir
                TMP                = $dataTempDir
                SW_MCP_SKILLS_DIR  = $dataSkillsDir
            }
        }
    }
}
if (Test-Path $mcpConfigPath) {
    Write-Warning ".mcp.json already exists, not overwritten. Make sure it points to $venvPython"
} else {
    $mcpConfig | ConvertTo-Json -Depth 5 | Set-Content $mcpConfigPath -Encoding utf8
}

Write-Host '[5/5] Verifying'
& $venvPython -c "import mcp.server.fastmcp, win32com.client, sw_mcp.server; print('import OK')"
if ($LASTEXITCODE -ne 0) { throw 'import check failed' }

Write-Host ''
Write-Host 'Install complete. Next steps:'
Write-Host '  1. Open SolidWorks 2022.'
Write-Host "  2. Start Claude Code inside $ProjectDir"
Write-Host "  3. Approve the 'solidworks' MCP from .mcp.json on first launch."
Write-Host '  4. Run sw_status and confirm it reports 2022.'
