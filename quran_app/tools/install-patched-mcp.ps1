# Install the patched flutter-skill MCP from this project into a target location.
# Usage:
#   pwsh tools/install-patched-mcp.ps1                  # install into global npm location
#   pwsh tools/install-patched-mcp.ps1 -Target <path>  # install into a custom directory
#
# Re-run after every `npm update -g flutter-skill` to re-apply the local patches.

[CmdletBinding()]
param(
    [string]$Target
)

$ErrorActionPreference = 'Stop'

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path (Join-Path $ScriptDir '..')
$SrcDir      = Join-Path $ProjectRoot 'tools\flutter-skill-patched'

if (-not $SrcDir -or -not (Test-Path $SrcDir)) {
    throw "Patched source not found: $SrcDir"
}

if (-not $Target) {
    $npmPrefix = (& npm config get prefix).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "Could not determine npm global prefix. Pass -Target <path>."
    }
    $Target = Join-Path $npmPrefix 'node_modules\flutter-skill'
}

if (-not (Test-Path $Target)) {
    throw "Target directory does not exist: $Target. Run `npm i -g flutter-skill` first, or pass -Target to a directory you control."
}

Write-Host "Source: $SrcDir"
Write-Host "Target: $Target"

# Copy top-level files
foreach ($name in @('package.json', 'README.md', 'LICENSE')) {
    $src = Join-Path $SrcDir $name
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination (Join-Path $Target $name) -Force
    }
}

# Copy directories (without node_modules / .dart_tool to keep them regenerable)
foreach ($name in @('bin', 'dart', 'scripts')) {
    $src = Join-Path $SrcDir $name
    $dst = Join-Path $Target $name
    if (-not (Test-Path $src)) { continue }
    if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
    New-Item -ItemType Directory -Path $dst -Force | Out-Null
    Get-ChildItem -LiteralPath $src -Force | Where-Object {
        $_.Name -notin @('node_modules', '.dart_tool', 'build')
    } | ForEach-Object {
        Copy-Item -Path $_.FullName -Destination $dst -Recurse -Force
    }
}

# Drop a corrupted 0-byte stub from earlier broken download, if present
$stub = Join-Path $env:USERPROFILE '.flutter-skill\bin\flutter-skill-windows-x64.exe-v0.9.36'
if (Test-Path $stub) {
    Remove-Item $stub -Force
    Write-Host "Removed stale stub: $stub"
}

# Resolve dart deps if dart is on PATH
$dart = Get-Command dart -ErrorAction SilentlyContinue
if ($dart) {
    Write-Host "Running `dart pub get`..."
    Push-Location (Join-Path $Target 'dart')
    try { dart pub get 2>&1 | Select-Object -Last 5 | Write-Host } finally { Pop-Location }
} else {
    Write-Host "WARNING: dart not on PATH; run `dart pub get` in $Target\dart manually."
}

Write-Host "Done."