# adb-helpers.ps1 — устройство c1316607 + общие операции для агента.
#
# PowerShell-модуль, который решает 4 самых частых проблемы из AGENTS.md:
#
#  1. PowerShell `>` редирект кодирует бинарь в UTF-16 LE — поэтому
#     `cat *.sqlite > file` создаёт corrupted dump. Решение: тянуть
#     через `adb exec-out ... base64 -w 0` и декодировать в PS.
#
#  2. Координаты. `adb shell input tap` принимает device_px; Flutter
#     inspect пишет в DP. `Invoke-AdbTapDp` сам считает ratio
#     через `wm size` / `wm density` и тапает в физических пикселях.
#
#  3. Скриншоты 1080x2376 не открываются как image в MCP-клиенте.
#     Решение: `Save-ScreenOut` сразу ресайзит до 720px по длинной
#     стороне через System.Drawing и сохраняет как .png.
#
#  4. Logcat quota 300 строк — `Clear-AppLogs` чистит после длинных тестов.
#
# Usage:
#   . "F:\My_VC_Projects\quran_app\tools\dev\adb-helpers.ps1"
#   Invoke-AdbTapDp -DpX 180 -DpY 250 -Tag 'surah-chip'
#   Save-ScreenOut -OutPath "F:\dev\shots\01.png"
#   Copy-AppDatabase -OutPath "F:\dev\app.db"
#
# Set-Alias для быстрого доступа (опционально, в своём профиле):
#   Set-Alias atdp Invoke-AdbTapDp
#   Set-Alias aps  Copy-AppDatabase

$Global:DeviceSerial = 'c1316607'
$Global:Package       = 'com.quran.app.quran_app'
$Global:FlutterBin    = 'C:\Users\007\develop\flutter\bin\flutter.bat'
$Global:ProjectRoot   = 'F:\My_VC_Projects\quran_app'
$Global:StatePath     = 'F:\dev\device_state.json'
$Global:AdbForwardPort = 22080   # см. flutter-supervisor.ps1 (10808 занят Xray VPN)

# ─── Helpers ────────────────────────────────────────────────────────────

function Get-DpToPxRatio {
    <#
    Возвращает { Ratio, WidthPx, HeightPx, DpWidth, DpHeight }.
    1 DP = effectiveDensity/160 px. ratio = px per dp.

    `wm density` возвращает и Physical, и Override — берём Override
    (он определяет фактический rendering scale для приложения).
    На c1316607: Physical=640, Override=480 → ratio=3.
    #>
    param([string]$Serial = $Global:DeviceSerial)

    $sizeLine = (& adb -s $Serial shell wm size 2>$null) | Out-String
    # Override density идёт второй строкой; первая строка — Physical.
    $denLines = (& adb -s $Serial shell wm density 2>$null) | Out-String
    $dpi = 480
    if ($denLines -match 'Override density:\s*(\d+)') {
        $dpi = [int]$Matches[1]
    } elseif ($denLines -match '(\d+)') {
        $dpi = [int]$Matches[1]  # fallback на Physical
    }

    if ($sizeLine -match '(\d+)x(\d+)') {
        $wPx = [int]$Matches[1]; $hPx = [int]$Matches[2]
    } else { $wPx = 1080; $hPx = 2376 }

    $ratio = $dpi / 160.0
    [pscustomobject]@{
        Ratio    = $ratio
        WidthPx  = $wPx
        HeightPx = $hPx
        DpWidth  = [int]($wPx / $ratio)
        DpHeight = [int]($hPx / $ratio)
        Dpi      = $dpi
    }
}

function Invoke-AdbTapDp {
    <#
    Тап в DP-координатах. Конвертирует в device px автоматически.
    .EXAMPLE
      Invoke-AdbTapDp -DpX 180 -DpY 250 -Tag 'surah-chip'
    #>
    param(
        [Parameter(Mandatory)] [int]$DpX,
        [Parameter(Mandatory)] [int]$DpY,
        [string]$Serial = $Global:DeviceSerial,
        [string]$Tag    = ''
    )
    $r = Get-DpToPxRatio -Serial $Serial
    $pxX = [int]($DpX * $r.Ratio)
    $pxY = [int]($DpY * $r.Ratio)
    $tagStr = if ([string]::IsNullOrEmpty($Tag)) { '' } else { " $Tag" }
    Write-Host ("[tap{0}] DP({1},{2}) -> px({3},{4}) ratio={5}" -f $tagStr, $DpX, $DpY, $pxX, $pxY, $r.Ratio)
    & adb -s $Serial shell input tap $pxX $pxY
}

function Save-ScreenOut {
    <#
    Скриншот + pull + resize до MaxLongSide. Один вызов = один файл PNG.

    ВАЖНО: PowerShell `>` редирект кодирует бинарь в UTF-16 LE на
    Windows. Используем `[System.IO.File]::WriteAllBytes` от
    [System.IO.Stream]::ReadAsync — bytes-as-bytes pipeline.
    #>
    param(
        [Parameter(Mandatory)] [string]$OutPath,
        [string]$Serial   = $Global:DeviceSerial,
        [int]$MaxLongSide  = 720,
        [switch]$NoResize
    )
    $tmp = "$OutPath.tmp.png"

    # Binary-safe: adb exec-out → MemoryStream → File. Никаких
    # редиректов через PS pipeline.
    $proc = Start-Process -FilePath adb -ArgumentList @(
        '-s', $Serial, 'exec-out', 'screencap', '-p'
    ) -RedirectStandardOutput $tmp -PassThru -NoNewWindow -Wait

    if ((Test-Path $tmp) -and (Get-Item $tmp).Length -lt 100) {
        Remove-Item -Force $tmp -ErrorAction SilentlyContinue
        throw "Screenshot failed: empty file at $tmp"
    }

    if ($NoResize) {
        Move-Item -Force $tmp $OutPath
        return
    }

    Add-Type -AssemblyName System.Drawing
    try {
        $img = [System.Drawing.Image]::FromFile($tmp)
        $w = $img.Width; $h = $img.Height
        $maxSide = [Math]::Max($w, $h)
        if ($maxSide -le $MaxLongSide) {
            $img.Dispose()
            Move-Item -Force $tmp $OutPath
            return
        }
        $scale = $MaxLongSide / $maxSide
        $nw = [int]($w * $scale); $nh = [int]($h * $scale)

        $bmp = New-Object System.Drawing.Bitmap $nw, $nh,
            ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $g = [System.Drawing.Graphics]::FromImage($bmp)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.DrawImage($img, 0, 0, $nw, $nh)
        } finally {
            if ($g) { $g.Dispose() }
            $img.Dispose()
        }
        $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        Write-Host "[screen] $OutPath ($w x $h -> $nw x $nh)"
    } finally {
        if ($bmp) { try { $bmp.Dispose() } catch {} }
        Remove-Item -Force $tmp -ErrorAction SilentlyContinue
    }
}

function Copy-AppDatabase {
    <#
    Pull SQLite-БД приложения БЕЗ UTF-16-кодирования.
    PowerShell `>` redirect на Windows преобразует бинарь в UTF-16 LE,
    ломая sqlite3. Workaround: тянуть через `adb exec-out ... base64 -w 0`
    и декодировать в PS.
    .EXAMPLE
      Copy-AppDatabase -OutPath F:\dev\app.db
    #>
    param(
        [Parameter(Mandatory)] [string]$OutPath,
        [string]$Serial   = $Global:DeviceSerial,
        [string]$Package  = $Global:Package,
        [string]$DbPath   = 'app_flutter/quran_app.sqlite'
    )
    $b64 = "$OutPath.b64"
    $cmd = "run-as $Package base64 -w 0 $DbPath"
    & adb -s $Serial shell $cmd > $b64
    $text = Get-Content $b64 -Raw
    # Trim whitespace; PS sometimes adds line endings.
    $clean = ($text -replace '\s', '')
    $bytes = [Convert]::FromBase64String($clean)
    [System.IO.File]::WriteAllBytes($OutPath, $bytes)
    Remove-Item -Force $b64 -ErrorAction SilentlyContinue
    Write-Host "[db] pulled $OutPath ($($bytes.Length) bytes)"
}

# ─── App / Flutter state ────────────────────────────────────────────────

function Clear-AppLogs {
    <#
    Очистить logcat — иначе после длинных тестов logcat quota 300 сбивается.
    #>
    param([string]$Serial = $Global:DeviceSerial)
    & adb -s $Serial logcat -c
    Write-Host "[logs] cleared"
}

function Restart-AppOnly {
    <#
    Рестарт APK без убийства flutter run. Используется после правок
    Flutter-кода, которые требуют cold-relaunch.

    ОСТОРОЖНО: relaunch APK всё равно убьёт VM connection
    (Dart isolate пересоздаётся). Supervisor должен перезапустить
    flutter run после этого.
    #>
    param(
        [string]$Package = $Global:Package,
        [string]$Serial  = $Global:DeviceSerial
    )
    Write-Host "[restart] $Package (will trigger flutter run auto-rebuild)"
    & adb -s $Serial shell am force-stop "$Package"
    Start-Sleep -Seconds 1
    & adb -s $Serial shell am start -n "$Package/$Package.MainActivity" 2>$null
    Write-Host "[restart] relaunched"
}

function Get-AppState {
    <#
    Текущее состояние приложения и VM. Читает из
    $Global:StatePath (пишется flutter-supervisor.ps1).
    #>
    param([string]$StatePath = $Global:StatePath)
    if (Test-Path $StatePath) {
        $s = Get-Content $StatePath -Raw | ConvertFrom-Json
    } else {
        $s = [pscustomobject]@{ vmUri = $null; fwdPort = $null; appPid = $null; lastRestart = $null }
    }
    $s | Add-Member -NotePropertyName 'appRunning' -NotePropertyValue (
        (& adb -s $Global:DeviceSerial shell "pidof $Global:Package" 2>$null) -match '^\d+'
    ) -Force
    return $s
}

function Set-DeviceState {
    <#
    Записать state — supervisor вызывает после каждого lifecycle-event.
    #>
    param(
        [string]$VmUri       = $null,
        [int]$FwdPort       = $null,
        [string]$AppPid     = $null,
        [string]$StatePath  = $Global:StatePath
    )
    $dir = Split-Path $StatePath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $s = if (Test-Path $StatePath) {
        Get-Content $StatePath -Raw | ConvertFrom-Json
    } else {
        [pscustomobject]@{ vmUri = $null; fwdPort = $null; appPid = $null; lastRestart = $null }
    }
    if ($VmUri)   { $s.vmUri = $VmUri }
    if ($FwdPort) { $s.fwdPort = $FwdPort }
    if ($AppPid)  { $s.appPid = $AppPid }
    $s.lastUpdate = (Get-Date -Format 'o')
    $s | ConvertTo-Json | Set-Content -Path $StatePath -Encoding UTF8
}

# ─── Module exports ─────────────────────────────────────────────────────
# PowerShell auto-exports all functions defined in a dot-sourced script.
# (Export-ModuleMember не нужен — это не .psm1, функции доступны через dot-source.)

# ─── Sprint 1.5 follow-up: uiautomator-based helpers ──────────────
#
# `adb shell uiautomator dump` выдаёт точные bounds для каждого element на
# экране. Это истина — tap по центру bounds = 100% точно, не зависит
# от ratio. Используется когда `adb shell input tap` (или
# `Invoke-AdbTapDp`) промахивается мимо кнопки.

function Get-AdbUiBounds {
    <#
    Парсит uiautomator dump и возвращает bounds [x1, y1, x2, y2]
    для элемента с заданным `text`, `content-desc` или `resource-id`.
    Возвращает массив из 4 int'ов или $null если не найдено.
    .EXAMPLE
        $bounds = Get-AdbUiBounds -Text "Аль-Фатиха"
        if ($bounds) {
            $cx = [int](($bounds[0] + $bounds[2]) / 2)
            $cy = [int](($bounds[1] + $bounds[3]) / 2)
            adb shell input tap $cx $cy
        }
    #>
    param(
        [string]$Text = '',
        [string]$ContentDesc = '',
        [string]$ResourceId = '',
        [string]$Serial = $Global:DeviceSerial
    )

    $dumpPath = "$env:TEMP\uidump.xml"
    $null = & adb -s $Serial shell uiautomator dump /sdcard/ui.xml
    $null = & adb -s $Serial pull /sdcard/ui.xml $dumpPath 2>$null
    if (-not (Test-Path $dumpPath)) { return $null }
    $xml = [xml](Get-Content $dumpPath -Raw)

    # XPath: найти node с заданным текстом / content-desc / resource-id.
    $node = $null
    if ($Text) {
        $node = $xml.node | Where-Object { $_.text -eq $Text -or $_.class -eq $Text } | Select-Object -First 1
    }
    if (-not $node -and $ContentDesc) {
        $node = $xml.node | Where-Object { $_.content-desc -eq $ContentDesc } | Select-Object -First 1
    }
    if (-not $node -and $ResourceId) {
        $node = $xml.node | Where-Object { $_.resource-id -eq $ResourceId } | Select-Object -First 1
    }
    if (-not $node -or -not $node.bounds) { return $null }

    # bounds="[x1,y1][x2,y2]"
    if ($node.bounds -match '\[(\d+),(\d+)\]\[(\d+),(\d+)\]') {
        return @([int]$Matches[1], [int]$Matches[2], [int]$Matches[3], [int]$Matches[4])
    }
    return $null
}

function Invoke-AdbTapAtText {
    <#
    Тап в центр элемента с заданным текстом (через uiautomator dump).
    Точнее чем `Invoke-AdbTapDp` — bounds берутся прямо из UI-дерева.
    .EXAMPLE
        Invoke-AdbTapAtText -Text "Аль-Фатиха"
    #>
    param(
        [Parameter(Mandatory)] [string]$Text,
        [string]$Serial = $Global:DeviceSerial
    )
    $bounds = Get-AdbUiBounds -Text $Text -Serial $Serial
    if (-not $bounds) {
        Write-Host "[tap-at-text] '$Text' not found in UI tree"
        return $false
    }
    $cx = [int](($bounds[0] + $bounds[2]) / 2)
    $cy = [int](($bounds[1] + $bounds[3]) / 2)
    Write-Host "[tap-at-text] '$Text' bounds=($($bounds[0]),$($bounds[1]),$($bounds[2]),$($bounds[3])) -> ($cx, $cy)"
    & adb -s $Serial shell input tap $cx $cy
    return $true
}

function Write-Utf8NoBom {
    <#
    PowerShell `Set-Content` (без `-Encoding`) добавляет UTF-8 BOM
    (0xEF 0xBB 0xBF), который ломает Dart analyzer: «Target of URI
    doesn't exist». Используй эту функцию вместо `Set-Content` для
    любых .dart-файлов. Отсутствие BOM экономит 3 байта и спасает
    analyzer cache.
    .EXAMPLE
        Write-Utf8NoBom -Path "lib/foo.dart" -Content "..."
    #>
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Content
    )
    $dir = Split-Path $Path -Parent
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    # Encoding without preamble → no BOM.
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# ─── Sprint 2 dev-quality: structured logging for taps ────────────────
#
# `Write-Host` теряется в логах. `Write-Verbose` — правильный путь
# для отладочного вывода который можно перенаправить через
# `-Verbose` или `$VerbosePreference = "Continue"`.

$VerbosePreference = 'SilentlyContinue'  # по умолчанию тихо

function Write-TapLog {
    param([string]$Message)
    Write-Verbose $Message
}
