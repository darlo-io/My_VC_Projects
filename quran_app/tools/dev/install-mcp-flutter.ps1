# install-mcp-flutter.ps1 — собирает Arenukvern/mcp_flutter v4.x из исходников
# для Windows и копирует бинарь в F:\My_VC_Projects\mcp_flutter\build\.
#
# Зачем: у Arenukvern нет Windows release artifacts (только darwin-arm64 и
# linux-x64). Под Windows единственный путь — собрать из исходников через
# `dart compile exe`. Скрипт делает это один раз и кладёт бинарь туда, где
# `.kilo/kilo.jsonc` его ищет.
#
# Зависимости: Dart SDK >=3.12 (идёт с Flutter 3.27+).
# Usage:
#   pwsh tools/dev/install-mcp-flutter.ps1

$ErrorActionPreference = 'Stop'

$RepoDir   = 'F:\My_VC_Projects\mcp_flutter'
$BuildDir  = Join-Path $RepoDir 'build'
$BinPath   = Join-Path $BuildDir 'flutter-mcp-toolkit-server.exe'

# Sanity: Dart SDK
$dart = Get-Command dart -ErrorAction SilentlyContinue
if (-not $dart) {
    throw "Dart SDK not on PATH. Install Flutter >=3.27 (Dart SDK comes with it) and re-run."
}
Write-Host "[build] using $($dart.Source)"

# Sanity: source exists
if (-not (Test-Path $RepoDir)) {
    throw "Repo not found: $RepoDir. Clone first: git clone --depth 1 https://github.com/Arenukvern/mcp_flutter.git $RepoDir"
}

# Workspace pub get
Push-Location $RepoDir
try {
    Write-Host "[build] dart pub get (workspace root)..."
    & dart pub get 2>&1 | Select-Object -Last 3 | Write-Host
} finally {
    Pop-Location
}

# mcp_server_dart pub get
$ServerDir = Join-Path $RepoDir 'mcp_server_dart'
Push-Location $ServerDir
try {
    Write-Host "[build] dart pub get (mcp_server_dart)..."
    & dart pub get 2>&1 | Select-Object -Last 3 | Write-Host
} finally {
    Pop-Location
}

# AOT compile
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
Write-Host "[build] AOT compile flutter_mcp_toolkit_server.dart -> $BinPath"
Push-Location $ServerDir
try {
    & dart compile exe bin/flutter_mcp_toolkit_server.dart -o $BinPath 2>&1 | Select-Object -Last 3 | Write-Host
} finally {
    Pop-Location
}

# Verify
if (-not (Test-Path $BinPath)) { throw "Build did not produce $BinPath" }
$size = (Get-Item $BinPath).Length
Write-Host "[build] OK: $BinPath ($([math]::Round($size / 1MB, 1)) MB)"

# Quick smoke test
Write-Host "[build] smoke test (--help)..."
& $BinPath --help 2>&1 | Select-Object -First 3 | Write-Host

Write-Host ""
Write-Host "DONE. Update .kilo/kilo.jsonc if path differs:"
Write-Host "  command: [\"$BinPath\"]"
Write-Host "  args:    [\"--no-await-dnd\"]"
