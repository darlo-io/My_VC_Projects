# tools/dev — Persistent Device Development Stack for c1316607

Хелперы для отладки приложения `com.quran.app.quran_app` на устройстве `c1316607`.
Решают 4 самых частых проблемы:

1. **PowerShell `>` кодирует бинарь в UTF-16 LE** — DB-дампы corrupted.
2. **Координаты**. `adb input tap` принимает физические пиксели; Flutter inspect — DP.
3. **Скриншоты 1080×2376 не открываются как image** в MCP-клиенте.
4. **VM connection отваливается** каждые ~3 мин после `am force-stop`.

## Использование

```powershell
. "F:\My_VC_Projects\quran_app\tools\dev\adb-helpers.ps1"
. "F:\My_VC_Projects\quran_app\tools\dev\flutter-supervisor.ps1"

# Persistent supervisor (start once per session)
Initialize-App              # очищает adb forwards, чистит state-файл
Start-FlutterSupervisor     # запускает flutter run + watchdog

# В любом терминале после реконнекта:
$s = Get-FlutterState
Write-Host $s.vmUri
# → ws://127.0.0.1:10808/xyz=/ws
```

## Координаты (Bug #2)

| Ввод | Ожидает | Пример |
|---|---|---|
| `adb shell input tap x y` | device px | `tap 540 750` |
| Flutter `inspect.dump` | DP | Surah chip center (180, 250) |
| `mcp-skill_tap` | DP | `tap с text='Открывающая'` |
| **`Invoke-AdbTapDp`** | **DP, конвертит сам** | **`Invoke-AdbTapDp -DpX 180 -DpY 250`** |

Ratio formula: `effectiveDensity / 160` (для c1316607 = **3**).

## DB pull (Bug #1)

```powershell
# PowerShell `>` редирект → UTF-16 LE → corrupted file. Никогда так.
# Всегда через base64 -w 0:
Copy-AppDatabase -OutPath F:\dev\app.db
sqlite3 F:\dev\app.db "SELECT COUNT(*) FROM audio_cache_metadata;"
```

## Скриншоты (Bug #3)

```powershell
# 1080×2376 PNG → System.Drawing resizes до 720px по длинной стороне
# в один вызов. Файл сразу открывается MCP-инструментами.
Save-ScreenOut -OutPath F:\dev\shots\01.png -MaxLongSide 720
```

Размер на диске: ~120KB. Открывается стандартными image-readers.

## App lifecycle (Bug #4)

```powershell
# 80% реконнектов происходили после `am force-stop com.quran.app.quran_app` —
# это убивает Dart isolate, VM connection умирает через ~3 мин.
#
# Вместо force-stop + ручной `flutter run` запустить supervisor:
Start-FlutterSupervisor

# После правок Flutter-кода (но без force-stop):
#   - supervisor сам перезапустит APK если умер
#   - hot reload через MCP `flutter-skill_hot_reload`

# Если очень нужно force-stop:
Stop-FlutterSupervisor $job    # stop the watchdog job
Get-Process -Name flutter | Stop-Process -Force
Get-Process -Name dart | Stop-Process -Force
& adb -s c1316607 shell am force-stop com.quran.app.quran_app
# потом вернуть supervisor в строй:
Start-FlutterSupervisor
```

## State file

Путь: `F:\dev\device_state.json`. Содержит:

```json
{
  "vmUri": "ws://127.0.0.1:22080/xyz=/ws",
  "fwdPort": 22080,
  "appPid": "29964",
  "supervisorPid": 1234,
  "runCount": 3,
  "lastEvent": "flutter-run-started",
  "lastUpdate": "2026-07-12T23:15:01+03:00",
  "device": "c1316607",
  "package": "com.quran.app.quran_app"
}
```

**После любого реконнекта** первое действие — `Get-FlutterState | Format-List`
и взять `vmUri`. Это сэкономит 2-5 мин на обнаружение URL.

## Fixed forward port

Всегда **tcp:22080** на device → tcp:22080 на host. После старта supervisor:
```powershell
adb -s c1316607 forward --list
# c1316607 tcp:22080 tcp:22080
```

Не нужно пересоздавать каждый раз — supervisor install'ит его после
каждого flutter-run-restart.

Порт 10808 занят Xray VPN на этой машине — не использовать.

## Convenience commands

| Команда | Что делает |
|---|---|
| `Initialize-App` | clean state, init forwards |
| `Start-FlutterSupervisor` | start watchdog (foreground) |
| `Start-FlutterSupervisor -AsJob` | start watchdog в фоне |
| `Get-FlutterState` | показать state-файл |
| `Get-FlutterLogTail -Lines 80` | tail лога flutter run |
| `Set-FlutterState -VmUri X` | manually перезаписать state |

## Ограничения

1. `Restart-FlutterRun` не делает `flutter clean` — APK переустанавливается,
   но `build/` cache сохраняется.
2. `Restart-AppOnly` убивает Dart isolate (новый VM connection). После
   этого используй `Start-FlutterSupervisor`.
3. `Start-FlutterSupervisor -AsJob` пишет watchdog-output в `$LogPath`,
   но Start-Job вывод в основное окно PowerShell — используй
   `Get-FlutterLogTail` чтобы увидеть что supervisor делает.

## Где ещё может быть полезно

- AGENTS.md — секция `Coordinate conventions` для краткой версии.
- `mcp-skill` Flutter SKill — для inspect/connect/tap/hot-reload.
- `adb shell dumpsys` — для текущей Activity.
