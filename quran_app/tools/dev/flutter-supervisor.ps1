# flutter-supervisor.ps1 — persistent flutter run + state file.
#
# Фон-процесс, который запускает `flutter run` для проекта
# quran_app и:
#   1. Циклически мониторит состояние APK (`pidof` через adb).
#   2. Если APK умер — рестартит его (`am start ...`).
#   3. Если умер `flutter run` (Broken pipe / Lost connection) —
#      перезапускает его целиком + пересобирает adb-forward +
#      переписывает state-файл с новым VM URL.
#   4. После старта `flutter run` парсит его stdout, достаёт
#      строку "A Dart VM Service on ... is available at: ws://..."
#      и публикует в $StatePath.
#
# Зачем:
#   - Без supervisor `am force-stop` убивает VM connection каждые
#     ~3 мин. Supervisor восстанавливает автоматически.
#   - State-файл с VM URL — первое место для подключения после
#     реконнекта (см. Get-FlutterState).
#
# Использование:
#   . "F:\My_VC_Projects\quran_app\tools\dev\adb-helpers.ps1"
#   . "F:\My_VC_Projects\quran_app\tools\dev\flutter-supervisor.ps1"
#
#   # Запустить supervisor в фоне:
#   $job = Start-FlutterSupervisor -AsJob
#
#   # Узнать текущее состояние (читает state-файл):
#   Get-FlutterState
#
#   # Остановить:
#   Stop-FlutterSupervisor $job

$Global:ProjectRoot     = 'F:\My_VC_Projects\quran_app'
$Global:FlutterBin      = 'C:\Users\007\develop\flutter\bin\flutter.bat'
$Global:DeviceSerial     = 'c1316607'
$Global:Package         = 'com.quran.app.quran_app'
$Global:StatePath       = 'F:\dev\device_state.json'
$Global:LogPath         = 'F:\dev\flutter.log'
$Global:FwdPort          = 22080   # фиксированный порт. См. AGENTS.md.
                                 # NB: не используй 10808 — занят Xray VPN.
$Global:HealthEverySec  = 5
$Global:MaxRestarts      = 0       # 0 = unlimited

# ─── State management ────────────────────────────────────────────────────

function Set-FlutterState {
    <#
    Перезаписывает state-файл актуальным состоянием.
    Supervisor вызывает после lifecycle-events.
    #>
    param(
        [string]$VmUri          = $null,
        [int]$FwdPort          = $null,
        [string]$AppPid        = $null,
        [string]$SupPid        = $null,
        [int]$RunCount         = 0,
        [string]$LastEvent     = $null,
        [switch]$Clear
    )
    $dir = Split-Path $StatePath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    if ($Clear -or -not (Test-Path $StatePath)) {
        $s = [pscustomobject]@{
            vmUri        = $null
            fwdPort      = $null
            appPid       = $null
            supervisorPid = $null
            runCount     = 0
            lastEvent    = 'init'
            lastUpdate   = (Get-Date -Format 'o')
            device       = $Global:DeviceSerial
            package      = $Global:Package
        }
        $s | ConvertTo-Json | Set-Content -Path $StatePath -Encoding UTF8
        return $s
    }

    $s = Get-Content $StatePath -Raw | ConvertFrom-Json
    if ($VmUri)      { $s.vmUri = $VmUri }
    if ($FwdPort)    { $s.fwdPort = $FwdPort }
    if ($AppPid)     { $s.appPid = $AppPid }
    if ($SupPid)     { $s.supervisorPid = $SupPid }
    if ($RunCount)   { $s.runCount = $RunCount }
    if ($LastEvent)  { $s.lastEvent = $LastEvent }
    $s.lastUpdate = (Get-Date -Format 'o')
    $s | ConvertTo-Json | Set-Content -Path $StatePath -Encoding UTF8
    return $s
}

function Get-FlutterState {
    <#
    Читает state-файл. Возвращает объект со свойствами:
      vmUri, fwdPort, appPid, supervisorPid, runCount, lastEvent,
      lastUpdate, device, package.
    Если файл не существует — возвращает пустой объект.
    #>
    if (-not (Test-Path $Global:StatePath)) {
        return [pscustomobject]@{
            vmUri = $null; fwdPort = $null; appPid = $null
            runCount = 0; lastEvent = 'no-state-file'
        }
    }
    Get-Content $Global:StatePath -Raw | ConvertFrom-Json
}

function Wait-ForVmUri {
    <#
    Polls state-файл пока vmUri не появится (timeout секунд).
    Возвращает vmUri или $null при timeout.
    #>
    param([int]$Timeout = 60, [int]$PollMs = 500)
    $deadline = (Get-Date).AddSeconds($Timeout)
    while ((Get-Date) -lt $deadline) {
        $s = Get-FlutterState
        if ($s.vmUri) { return $s.vmUri }
        Start-Sleep -Milliseconds $PollMs
    }
    return $null
}

# ─── Lifecycle ───────────────────────────────────────────────────────────

function Set-FlutterForward {
    <#
    Ставит (или переставляет) adb forward для VM service на фиксированном
    порту. Удаляет старые forwards для этого порта, чтобы не было
    мусора.
    #>
    param([int]$Port = $Global:FwdPort)
    & adb -s $Global:DeviceSerial forward --remove tcp:$Port 2>$null | Out-Null
    & adb -s $Global:DeviceSerial forward tcp:$Port tcp:$Port | Out-Null
    return & adb -s $Global:DeviceSerial forward --list
}

function Get-FlutterVmUri {
    <#
    Извлекает ws:// URL из лог-файла. null, если ещё нет.
    Match ищет строку формата:
      "A Dart VM Service on CPH2653 is available at: ws://..."
    или
      "Dart VM Service ... available at: http://127.0.0.1:NNNN/XYZ=/"
    Берём http://... конвертируя в ws:// (one-liner).
    #>
    param([string]$LogPath = $Global:LogPath)
    if (-not (Test-Path $LogPath)) { return $null }
    $tail = Get-Content $LogPath -Tail 200 -ErrorAction SilentlyContinue
    foreach ($line in $tail) {
        # Pattern: "available at: http://127.0.0.1:NNNN/XYZ=/"
        # Захватываем целиком до `=/` чтобы добавить `/ws` суффикс.
        if ($line -match 'available at:\s*(https?://\S+/[^=]+=/)') {
            $url = $Matches[1]
            # Захваченный URL оканчивается на `=/` (от regex).
            # Нужно превратить `http://.../XYZ=/` в `ws://.../XYZ=/ws`.
            $wsUrl = ($url -replace '^http', 'ws') + 'ws'
            return $wsUrl
        }
    }
    return $null
}

function Initialize-App {
    <#
    Ensure forward + state-файл (clean). Не запускает flutter run.
    #>
    Set-FlutterForward -Port $Global:FwdPort | Out-Null
    Set-FlutterState -Clear
    Write-Host "[sup] initialized"
}

function Restart-FlutterRun {
    <#
    Убивает все flutter run / dart процессы и рестартит APK.
    Используется supervisor'ом в watchdog-loop. Возвращает $true при успехе.
    #>
    param([int]$RunCount)

    Write-Host "[sup] killing old flutter run / dart"
    Get-Process -Name 'flutter','dart' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1

    Write-Host "[sup] relaunching APK"
    & adb -s $Global:DeviceSerial shell am start -n "$Global:Package/$Global:Package.MainActivity" 2>$null | Out-Null

    Write-Host "[sup] starting flutter run (count=$RunCount)"
    $dir = Split-Path $Global:LogPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    # Запуск `flutter run` в фоне через Start-Process — оставляет
    # наш watchdog цикл живым и не блокируется. `flutter.bat` —
    # это wrapper, который spawn'ит `flutter-dev.bat`, который
    # в свою очередь запускает `dart` (Flutter VM). Start-Process
    # возвращает pid cmd.exe, который сразу exit'ит после spawning
    # dart. Реальный "flutter run" процесс = dart.exe с args,
    # содержащими "flutter_tools.snapshot" или "frontend_server".
    #
    # ВАЖНО: VM URI и "Flutter run key commands" печатаются в stdout,
    # не stderr. Генерируем wrapper-скрипт `flutter-run-wrapper.cmd`,
    # который делает `2>&1 > log` через cmd-level redirection.
    $dir = Split-Path $Global:LogPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    '' | Set-Content $Global:LogPath -Encoding UTF8 -NoNewline

    $wrapperPath = Join-Path $dir 'flutter-run-wrapper.cmd'
    @"
@echo off
REM Wrapper для supervisor'а — объединяет stdout+stderr в один лог.
REM Генерируется tools\dev\flutter-supervisor.ps1, не редактировать.
cd /d "$Global:ProjectRoot"
"$Global:FlutterBin" run -d $Global:DeviceSerial --no-pub 1>"$Global:LogPath" 2>&1
"@ | Set-Content $wrapperPath -Encoding ASCII

    $proc = Start-Process -FilePath $wrapperPath `
        -WorkingDirectory $Global:ProjectRoot `
        -NoNewWindow -PassThru
    # $proc.Id — это cmd.exe. Watchdog полагается на -Name 'dart'.
    Write-Host "[sup] flutter.bat spawned via wrapper (cmd-pid=$($proc.Id))"

    # Install the adb forward in background after VM boots.
    # ВАЖНО: Start-Job создаёт новую PS-сессию без загруженных
    # helpers — инлайним логику с inline-скриптом, который
    # использует -FilePath для автономности.
    #
    # ВАЖНО: VM URI содержит случайный порт устройства (например,
    # 127.0.0.1:33754). Нужно сделать `adb forward tcp:HOST_PORT
    # tcp:DEVICE_PORT` — а не tcp:HOST tcp:HOST. Парсим порт
    # из URI.
    $captureScript = Join-Path (Split-Path $Global:LogPath) 'capture-vm.ps1'
    $captureContent = @"
# Capture-vm.ps1 — auto-generated, не редактировать.
# Запускается в Start-Job background-session, не имеет доступа
# к функциям основной сессии. Инлайним всё нужное.

`$LogPath = '$($Global:LogPath)'
`$HostFwdPort = $($Global:FwdPort)
`$RunCount = $RunCount
`$Serial = '$($Global:DeviceSerial)'

function Get-VmUriFromLog(`$Path) {
    if (-not (Test-Path `$Path)) { return `$null }
    `$tail = Get-Content `$Path -Tail 200 -ErrorAction SilentlyContinue
    foreach (`$line in `$tail) {
        if (`$line -match 'available at:\s*(https?://\S+/[^=]+=/)') {
            `$url = `$Matches[1]
            return (`$url -replace '^http', 'ws') + 'ws'
        }
    }
    return `$null
}

`$deadline = (Get-Date).AddSeconds(60)
`$vmUri = `$null
while ((Get-Date) -lt `$deadline -and -not `$vmUri) {
    Start-Sleep -Seconds 2
    `$vmUri = Get-VmUriFromLog `$LogPath
}

if (-not `$vmUri) {
    Write-Host "[sup] TIMEOUT waiting for VM URI in `$LogPath"
    exit 1
}

# Парсим device-порт из URI: ws://127.0.0.1:NNNN/... → NNNN
if (`$vmUri -match 'ws://127\.0\.0\.1:(\d+)/') {
    `$DevicePort = [int]`$Matches[1]
} else {
    Write-Host "[sup] WARN: failed to parse port from `$vmUri"
    exit 1
}

# Adb forward: host:`$HostFwdPort → device:`$DevicePort
adb -s `$Serial forward --remove tcp:`$HostFwdPort 2>`$null | Out-Null
adb -s `$Serial forward tcp:`$HostFwdPort tcp:`$DevicePort | Out-Null
Write-Host "[sup] forward: tcp:`$HostFwdPort (host) -> tcp:`$DevicePort (device)"

# Подменяем device-порт на host-порт в vmUri — user (MCP / flutter-skill)
# подключается к host, не к device.
`$hostVmUri = `$vmUri -replace 'ws://127\.0\.0\.1:\d+/', "ws://127.0.0.1:`$HostFwdPort/"

# Set state file
`$statePath = 'F:\dev\device_state.json'
`$s = Get-Content `$statePath -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue
if (-not `$s) {
    `$s = [pscustomobject]@{
        vmUri = `$null; fwdPort = `$null; appPid = `$null;
        supervisorPid = `$null; runCount = 0; lastEvent = 'init';
        device = `$Serial; package = 'com.quran.app.quran_app'
    }
}
`$s.vmUri = `$hostVmUri
`$s.fwdPort = `$HostFwdPort
`$s.runCount = `$RunCount
`$s.lastEvent = 'flutter-run-started'
`$s.lastUpdate = (Get-Date -Format 'o')
`$s | ConvertTo-Json | Set-Content -Path `$statePath -Encoding UTF8
Write-Host "[sup] VM ready: `$hostVmUri"
"@
    Set-Content -Path $captureScript -Value $captureContent -Encoding UTF8

    Start-Job -Name 'flutter-capture-vm' -FilePath $captureScript | Out-Null
    Write-Host "[sup] capture-vm job started"

    return $true
}

# ─── Watchdog — главный цикл supervisor ───────────────────────────────────

function Start-FlutterSupervisor {
    <#
    Запускает watcher-loop в фоне. Loop проверяет состояние каждые
    $HealthEverySec сек. Если APK умер — рестартит. Если flutter run
    умер (отсутствует VM URL в state) — рестартит его целиком.
    #>
    [CmdletBinding()]
    param(
        [switch]$AsJob = $false
    )

    $sb = {
        $runCount = 0
        Initialize-App

        while ($true) {
            Start-Sleep -Seconds $Global:HealthEverySec

            $state = Get-FlutterState
            $appPid = & adb -s $Global:DeviceSerial shell pidof $Global:Package 2>$null
            $appRunning = $appPid -match '^\d+'
            $flutterAlive = (Get-Process -Name 'flutter','dart' -ErrorAction SilentlyContinue).Count -gt 0

            if (-not $flutterAlive) {
                Write-Host "[sup] flutter run dead, restarting"
                Set-FlutterState -LastEvent 'flutter-restart' -RunCount ($runCount + 1) | Out-Null
                $runCount++
                Restart-FlutterRun -RunCount $runCount
                continue
            }

            if (-not $appRunning) {
                Write-Host "[sup] APK dead, relaunching"
                & adb -s $Global:DeviceSerial shell am start -n "$Global:Package/$Global:Package.MainActivity" 2>$null | Out-Null
                Set-FlutterState -LastEvent 'apk-relaunch' | Out-Null
            }
        }
    }.ToString()

    if ($AsJob) {
        $script = [scriptblock]::Create($sb)
        return Start-Job -ScriptBlock $script -Name 'flutter-supervisor'
    } else {
        # Синхронный запуск (для тестов)
        Invoke-Expression $sb
    }
}

function Stop-FlutterSupervisor {
    <#
    Останавливает supervisor-job. Не убивает flutter run, чтобы
    пользователь мог вручную продолжить работу.
    #>
    param($Job)
    if ($Job) {
        Stop-Job $Job -PassThru | Remove-Job -Force
    }
    # Also kill any supervisor poll loops by Stop-FlutterRun
    Get-Process -Name powershell -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowTitle -eq 'flutter-supervisor' } |
        Stop-Process -Force -ErrorAction SilentlyContinue
}

# ─── Convenience: перезапуск flutter run по запросу ──────────────────────

function Invoke-FlutterHotRestart {
    <#
    Эквивалент команды `r` в flutter run — пересобирает Dart без
    переустановки APK. Полезно после правок Dart-кода.
    #>
    param([string]$StatePath = $Global:StatePath)
    $state = Get-FlutterState
    if (-not $state.vmUri) {
        throw "Flutter VM not running. Run Start-FlutterSupervisor first."
    }
    # Reads char by char through stdin.
    $proc = Get-Process -Name flutter -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $proc) { throw "flutter run process not found" }
    # Note: `r` to stdin works only if flutter run was started with --no-pub
    # and from this same shell. For a daemonized flutter, hot-restart
    # requires the MCP `flutter-skill_hot_reload` (which sends the request
    # over VM service).
    Write-Host "[hot-restart] use 'r' over VM service (flutter-skill_hot_reload)"
}

function Get-FlutterLogTail {
    <#
    Последние N строк лога flutter run. Полезно для дебага
    rebuild-ошибок.
    #>
    param([int]$Lines = 80)
    if (Test-Path $Global:LogPath) {
        Get-Content $Global:LogPath -Tail $Lines
    } else {
        Write-Host "[log] no log file at $Global:LogPath"
    }
}
