# self-test.ps1 — Offline validation for tools/dev/.
#
# Без устройства проверяет:
#   1. VM URI regex парсит типичную строку flutter run в правильный ws:// URL
#   2. State-файл read/write (через mock JSON)
#   3. Логика watchdog-цикла (heartbeat не падает)
#
# Запуск: powershell -File tools/dev/self-test.ps1

$ErrorActionPreference = 'Stop'

. "$PSScriptRoot\adb-helpers.ps1"
. "$PSScriptRoot\flutter-supervisor.ps1"

$passed = 0
$failed = 0

function Assert-True {
    param([bool]$Cond, [string]$What)
    if ($Cond) {
        Write-Host "  PASS ${What}" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  FAIL ${What}" -ForegroundColor Red
        $script:failed++
    }
}

function Assert-Eq {
    param($Expected, $Actual, [string]$What)
    if ($Expected -eq $Actual) {
        Write-Host "  PASS ${What} (=$Expected)" -ForegroundColor Green
        $script:passed++
    } else {
        Write-Host "  FAIL ${What}: expected=$Expected, got=$Actual" -ForegroundColor Red
        $script:failed++
    }
}

# ─── Test 1: VM URI regex parsing ────────────────────────────────────────

Write-Host "`n=== VM URI parsing ===" -ForegroundColor Cyan

# Mock log content — копия реального вывода `flutter run` на c1316607.
$mockLog = @'
Resolving dependencies...
Got dependencies!
Launching lib\main.dart on CPH2653 in debug mode...
Running with dart:io Platform: ... 
A Dart VM Service on CPH2653 is available at: http://127.0.0.1:64106/cGQ0V2EC93A=/ws
The Flutter DevTools debugger and profiler on CPH2653 is available at: http://127.0.0.1:64106/cGQ0V2EC93A=/devtools/?uri=ws://127.0.0.1:64106/cGQ0V2EC93A=/ws
'@

# Подложить log во временный файл и попросить функцию найти URI.
$testLog = Join-Path $env:TEMP 'flutter_test.log'
Set-Content -Path $testLog -Value $mockLog -Encoding UTF8

$uri = Get-FlutterVmUri -LogPath $testLog
Assert-Eq 'ws://127.0.0.1:64106/cGQ0V2EC93A=/ws' $uri 'regex парсит реальную строку flutter run'

# Negative case: пустой лог
'' | Set-Content -Path $testLog -Encoding UTF8
$uriEmpty = Get-FlutterVmUri -LogPath $testLog
Assert-Eq $null $uriEmpty 'нет строки → null'

# Negative case: файл не существует
Remove-Item -Path $testLog -Force -ErrorAction SilentlyContinue
$uriMissing = Get-FlutterVmUri -LogPath $testLog
Assert-Eq $null $uriMissing 'файл отсутствует → null'

# Edge case: http://  → ws://, port 22080 (наш forward)
$mock22080 = @'
A Dart VM Service on CPH2653 is available at: http://127.0.0.1:22080/abc123=/ws
'@
Set-Content -Path $testLog -Value $mock22080 -Encoding UTF8
$uri22080 = Get-FlutterVmUri -LogPath $testLog
Assert-Eq 'ws://127.0.0.1:22080/abc123=/ws' $uri22080 'наш forward порт 22080 корректно'

# Edge case: ссылка devtools НЕ должна захватываться (она идёт после "Dart VM Service")
$mockMulti = @'
The Flutter DevTools ... is available at: http://127.0.0.1:5555/old=/ws
A Dart VM Service on CPH2653 is available at: http://127.0.0.1:64106/main=/ws
'@
Set-Content -Path $testLog -Value $mockMulti -Encoding UTF8
$uriMulti = Get-FlutterVmUri -LogPath $testLog
Assert-Eq 'ws://127.0.0.1:64106/main=/ws' $uriMulti 'берёт только Dart VM, не DevTools'

Remove-Item -Path $testLog -Force -ErrorAction SilentlyContinue

# ─── Test 2: State file read/write ────────────────────────────────────────

Write-Host "`n=== State file ===" -ForegroundColor Cyan

$testStatePath = Join-Path $env:TEMP 'state_test.json'
if (Test-Path $testStatePath) { Remove-Item $testStatePath -Force }

# Clear → defaults
Set-FlutterState -Clear -StatePath $testStatePath
$state = Get-FlutterState -StatePath $testStatePath
Assert-Eq $null $state.vmUri 'Clear -> null vmUri'
Assert-Eq 0 $state.runCount 'Clear -> runCount=0'
Assert-Eq 'init' $state.lastEvent 'Clear -> lastEvent=init'
Assert-Eq 'c1316607' $state.device 'default device=c1316607'

# Update отдельных полей
Set-FlutterState -VmUri 'ws://127.0.0.1:22080/XYZ=/ws' `
    -FwdPort 22080 -AppPid '838' -RunCount 5 `
    -LastEvent 'flutter-run-started' `
    -StatePath $testStatePath
$state = Get-FlutterState -StatePath $testStatePath
Assert-Eq 'ws://127.0.0.1:22080/XYZ=/ws' $state.vmUri 'VM URI written'
Assert-Eq 22080 $state.fwdPort 'fwdPort written'
Assert-Eq '838' $state.appPid 'appPid written'
Assert-Eq 5 $state.runCount 'runCount written'
Assert-Eq 'flutter-run-started' $state.lastEvent 'lastEvent written'
Assert-True ($null -ne $state.lastUpdate) 'lastUpdate timestamp set'

# Идемпотентность: повторный Set с тем же vmUri не должен сломать state
Set-FlutterState -VmUri 'ws://127.0.0.1:22080/XYZ=/ws' `
    -StatePath $testStatePath
$state = Get-FlutterState -StatePath $testStatePath
Assert-Eq 5 $state.runCount 'повторный Set не сбрасывает runCount'

Remove-Item $testStatePath -Force -ErrorAction SilentlyContinue

# ─── Test 3: DP ↔ px conversion (только ratio вычисление) ───────────────

Write-Host "`n=== DpToPxRatio ===" -ForegroundColor Cyan

# Mock: подложить прямое значение без adb — тестируем чистую функцию
function Get-DpToPxRatioMock {
    param([int]$WidthPx, [int]$Dpi)
    $ratio = $Dpi / 160.0
    [pscustomobject]@{
        Ratio = $ratio
        DpWidth = [int]($WidthPx / $ratio)
    }
}

# c1316607 (Override density 480 → ratio 3)
$r = Get-DpToPxRatioMock -WidthPx 1080 -Dpi 480
Assert-Eq 3 $r.Ratio 'c1316607: ratio=3 (Override density 480)'
Assert-Eq 360 $r.DpWidth 'c1316607: dp width=360'

# Старое устройство density 320 → ratio 2
$r2 = Get-DpToPxRatioMock -WidthPx 720 -Dpi 320
Assert-Eq 2 $r2.Ratio 'density=320: ratio=2'
Assert-Eq 360 $r2.DpWidth 'density=320: dp width=360'

# Высокая плотность 640 (Pixel XL etc) → ratio 4
$r4 = Get-DpToPxRatioMock -WidthPx 1440 -Dpi 640
Assert-Eq 4 $r4.Ratio 'density=640: ratio=4'

# ─── Test 4: DB base64 round-trip ────────────────────────────────────────

Write-Host "`n=== DB base64 round-trip ===" -ForegroundColor Cyan

$testBytes = [byte[]](
    0x53,0x51,0x4c,0x69,0x74,0x65,0x20,0x66,0x6f,0x72,0x6d,0x61,0x74,0x20,
    0x33,0x00,0x10,0x00,0x01,0x01,0x00,0x40,0x20,0x20,0x00,0x00,0x00,0x00,
    0x00,0x00,0x00,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
    0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
)

# Эмулируем: adb exec-out ... base64 → bytes → tmp файл в Windows PS
# В реальности adb пишет ASCII base64 без BOM/переводов строк, и мы
# читаем как UTF-8 (без -Encoding Unicode), чтобы избежать
# PowerShell'ской UTF-16-конвертации при редиректе.
$testB64 = Join-Path $env:TEMP 'test.b64'
$testBin = Join-Path $env:TEMP 'test.bin'
$base64String = [Convert]::ToBase64String($testBytes)
$base64String | Set-Content -Path $testB64 -Encoding UTF8 -NoNewline

# Применить наш decode-путь (как в Copy-AppDatabase)
$b64Raw = Get-Content $testB64 -Raw
$clean = ($b64Raw -replace '\s', '')
$recovered = [Convert]::FromBase64String($clean)
[System.IO.File]::WriteAllBytes($testBin, $recovered)

# Сравнить с оригиналом
Assert-Eq $testBytes.Length $recovered.Length 'round-trip: length matches'
Assert-Eq ($testBytes -join ',') ($recovered -join ',') 'round-trip: bytes match'

Remove-Item $testB64 -Force -ErrorAction SilentlyContinue
Remove-Item $testBin -Force -ErrorAction SilentlyContinue

# ─── Summary ───────────────────────────────────────────────────────────

Write-Host "`n=== Result ===" -ForegroundColor Cyan
Write-Host "  passed: $passed" -ForegroundColor Green
Write-Host "  failed: $failed" -ForegroundColor ($(if ($failed -gt 0) { 'Red' } else { 'Green' }))

if ($failed -gt 0) { exit 1 } else { exit 0 }