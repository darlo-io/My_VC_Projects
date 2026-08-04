# Agent Instructions — quran_app

Project-specific notes that are non-obvious. General Flutter/Dart rules live in the global Kilo instructions.

## Assistant communication style

- **Be brief.** No filler, no verbose reasoning in the final reply.
- **Respond in Russian.** Match the user's language.
- **Ask when unclear.** If the user's request is ambiguous or missing information, ask clarifying questions instead of guessing.

## MCP `flutter-mcp-toolkit` (Arenukvern/mcp_flutter) — server-only

**Active MCP** — `flutter-mcp-toolkit` (Arenukvern/mcp_flutter v4.x). Используется для hot reload, screenshot, UI inspection, оценки Dart-выражений.

**Режим: server-only**, без in-app пакета `mcp_toolkit`:
- *Почему не in-app*: `mcp_toolkit` транзитивно тянет `intentcall_platform`, чей `build.gradle` ломает Android-сборку (`NullPointerException` в `FlutterPluginUtils`). Upstream-баг mcp_flutter v4.x.
- *Что работает* в server-only: 30 `fmt_*` tools через прямой VM service connection (`fmt_connect_debug_app`). Один раз подключаем — все инструменты доступны.
- *Repo*: `F:\My_VC_Projects\mcp_flutter` (клон Arenukvern/mcp_flutter@main).
- Бинарь собирается локально (`dart compile exe`) — upstream не публикует Windows release.

**MCP config** — см. `.kilo/kilo.jsonc` секцию `mcp.flutter-mcp-toolkit`.

**Workflow**: запускаем `flutter run --debug` (через `tools/dev/supervisor.ps1`); MCP-сервер сам находит Flutter debug targets через machine discovery (`flutter attach --machine`), копировать URI руками **не нужно**.

### Tool surface (prefix `fmt_*`)

| Category     | Tools |
|--------------|-------|
| Lifecycle    | `fmt_connect_debug_app`, `fmt_discover_debug_apps`, `fmt_hot_reload_flutter`, `fmt_get_vm`, `fmt_get_extension_rpcs` |
| Inspection   | `fmt_inspect_widget_at_point`, `fmt_capture_ui_snapshot` (screenshot + layout + errors in one bundle) |
| Dynamic      | `fmt_list_client_tools_and_resources`, `fmt_client_tool`, `fmt_client_resource` (app-registered `quran.play_ayah` и т.д.) |
| Debug        | `fmt_recent_logs`, `fmt_evaluate_dart` (Dart eval в VM) |
| Interaction  | `fmt_tap_widget`, `fmt_enter_text`, `fmt_scroll`, `fmt_swipe` (через semantic-snapshot refs) |

**Semantic-snapshot** — один JSON-snapshot даёт `Element` tree со stable refs. После можно тапать по ref (а не по координатам). Предпочитай `fmt_*` вместо `adb exec-out screencap` / `adb shell input tap` — widget-aware, не pixel-aware.

Полный список — в `instructions` поле `initialize` response.

### Maintenance (скрипты в `tools/dev/`)

- **One-time setup** → `pwsh tools/dev/install-mcp-flutter.ps1` (клонирует repo, собирает Windows AOT-бинарь).
- **После обновления upstream** → `git pull` в `F:\My_VC_Projects\mcp_flutter`, затем `pwsh tools/dev/install-mcp-flutter.ps1`.
- **Smoke test** → `pwsh tools/dev/self-test.ps1` (без подключения к Flutter app — сервер ждёт).

### Hard rules

- **Always** `flutter run --debug` — release-mode игнорирует mcp_flutter (asserts в VM extensions).
- **Tools не появятся** пока нет debug-сессии с подключённым `fmt_connect_debug_app`. Это не баг сервера — он ждёт app.
- **Не запускай `dart compile exe` в режиме debug** — упадёт с "Debug builds cannot be AOT compiled". Сначала `flutter clean`.
- **In-app `mcp_toolkit` пока не подключаем** — upstream-баг в `intentcall_platform` ломает Android Gradle. Когда пофиксят — переключимся на hybrid-режим.

## MCP `context7` (Upstash) — документация Flutter-пакетов

**Зачем:** снижает «API-hallucinations» при апгрейдах Flutter-пакетов (`just_audio`, `drift`, `audio_service`, `riverpod`, …). Context7 выдаёт актуальные сигнатуры и примеры из Pub.dev / NPM / GitHub.

Работает параллельно с `flutter-mcp-toolkit`: UI/runtime vs документация. Не требует in-app пакета → Android Gradle не ломается (pure Node.js процесс).

**MCP config** — см. `.kilo/kilo.jsonc` секцию `mcp.context7`.

### Использование

```text
# Агент по контексту сам понимает, когда звать Context7. Если нет — явно:
"Используй Context7, чтобы получить актуальный API just_audio 0.10.x"

# Или в коде:
"context7 resolve just_audio"           → получает Context7 ID
"context7 get-library-docs /just_audio/just_audio topic=audio_source"  → markdown
```

### Hard rules

- **Не вызывай `npx` без `-y`** — зависнет на prompt и заблокирует MCP-сессию.
- Если `npx -y @upstash/context7-mcp` падает с `ENOTFOUND api.context7.com` — проверь VPN/прокси (у нас активен Xray). Context7 не критичен для сборки (`enabled: false` в `kilo.jsonc`).

## Device development helpers (`tools/dev/`)

Скрипты в `tools/dev/` решают 4 хронические боли отладки:

| Боль                                                          | Решение (скрипт) |
|---------------------------------------------------------------|------------------|
| PowerShell `>` кодирует бинарь в UTF-16 LE → corrupted DB-дампы | `adb-helpers.ps1::Copy-AppDatabase` (`adb exec-out ... base64 -w 0` + native decode) |
| `adb input tap` принимает **device px**, Flutter inspect — **DP** | `adb-helpers.ps1::Invoke-AdbTapDp` (считает `effectiveDensity/160` автоматически) |
| Скриншоты 1080×2376 не открываются MCP image-tools            | `adb-helpers.ps1::Save-ScreenOut` (System.Drawing ресайзит до 720px) |
| VM connection отваливается каждые ~3 мин → реконнект-цикл ~5 мин | `flutter-supervisor.ps1::Start-FlutterSupervisor` (watchdog-loop, публикует VM URL в `F:\dev\device_state.json`) |

**Текущий device id** — см. `adb devices` (захардкоженный ID не переживёт переподключения). Текущий `vmUri` — после запуска supervisor в `F:\dev\device_state.json`.

### После любого реконнекта

```powershell
. "$PWD/tools/dev/adb-helpers.ps1"
. "$PWD/tools/dev/flutter-supervisor.ps1"
Get-FlutterState | Format-List       # → vmUri, fwdPort, appPid
```

Затем `fmt_connect_debug_app` с этим `vmUri` (авто-discovery).

### Hard rules

- **Не убивай `am force-stop com.quran.app.quran_app` пока supervisor жив** — он сам restart'нет APK. Если force-stop обязателен, сначала `Stop-FlutterSupervisor`.
- **adb forward** всегда на **tcp:22080** (фиксированный порт supervisor'а). Порт 10808 занят Xray VPN — не использовать.
- **Hot reload может сохранять stale `_inFlight` State** в `AudioCache` — перезапуск через supervisor, не `am force-stop`.

## Audio playback — MP3Quran.net CDN

Аудио-фича (`lib/features/audio/`) end-to-end. v0.2 мигрировала на MP3Quran.net — primary source. Предыдущие CDN (`cdn.islamic.network`, `cdn.alislam.ru`) использовались до v0.2 и заменены на mp3quran.net.

### Что даёт MP3Quran.net

- **241+ reciters** с Hafs rewaya coverage (vs. 8 hardcoded ранее), `GET /api/v3/reciters?language=ar`.
- **Per-surah файлы** (один MP3 на суру), e.g. `https://server8.mp3quran.net/afs/001.mp3`.
- **Ayat timing API** at `GET /api/v3/ayat_timing?surah=N&read=M` (Phase 3 — не подключено).
- **Multi-server CDN** (server6..server18) — разные reciters на разных серверах.
- **Multi-language** — `language=ar|eng|ru|...` switches UI strings.

### Reciter coverage

`lib/features/audio/data/reciters_repository.dart` — hardcoded mapping для 8 default reciters (mp3quran reciter+moshaf+server):

| App id                       | mp3quran id | moshaf | server                      |
|------------------------------|-------------|--------|------------------------------|
| `ar.alafasy`                 | 123         | 123    | server8.mp3quran.net/afs/    |
| `ar.abdulbasitmurattal`      | 51          | 53     | server7.mp3quran.net/basit/  |
| `ar.husary`                  | 118         | 118    | server13.mp3quran.net/husr/  |
| `ar.minshawi`                | 112         | 112    | server10.mp3quran.net/minsh/ |
| `ar.abdurrahmaansudais`      | 54          | 54     | server11.mp3quran.net/sds/   |
| `ar.saaborimadina`           | 31          | 31     | server7.mp3quran.net/shur/   |
| `ar.hudhaify`                | 74          | 74     | server9.mp3quran.net/hthfi/  |
| `ar.ahmedajamy`              | 5           | 5      | server10.mp3quran.net/ajm/   |

Остальные ~233 — `RecitersSyncService.maybeSync()` (см. ниже).

### Reciter cache (DB)

`lib/features/audio/data/reciters_repository.dart` управляет таблицей [Reciters] в локальной БД. На старте [ensureSeeded]:

1. Вставляет 8 дефолтных ректоров из `kDefaultReciters`, если таблица пуста.
2. Заполняет mp3quran-метаданные (`mp3quranId`, `mp3quranServer`, `mp3quranMoshafId`, `mp3quranRewaya`, `mp3quranSurahTotal`, `mp3quranCachedAt`) идемпотентно.

`RecitersSyncService.maybeSync()` подтягивает полный список (~241 ректор) с mp3quran.net. Триггеры:

1. **Background worker** при bootstrap — `unawaited(service.maybeSync())` из `ContentBootstrapper.bootstrap()`. Skip'ает сетевой запрос, если кеш свежий **И** все ректоры в БД имеют mp3quran-метаданные.
2. **Manual** — кнопка «Обновить список» в AppBar `ReciterPickerScreen` → `service.forceSync()` (TTL игнорируется).

**Cache TTL — 7 дней** (`_kDefaultCacheTtl`). После успешного sync'а — 7 дней тишины.

**Rate-limit**: mp3quran.net не задокументировал. Держим 10 RPS как разумный предел (~100 KB JSON на запрос).

**Ошибки**: ловятся в `_safeRun` на bootstrap, логируются через `developer.log`, состояние → `failed`. Юзер увидит это в snackbar при следующем ручном sync'е.

### Listen UI

Следует `docs/images/listen.png`. Детали — в doc-комментариях `lib/features/audio/presentation/listen_screen.dart` и `reciter_picker_screen.dart`.

Компоненты:

- `_ReciterCard` — одна карточка ректора (вместо карусели).
- `_ReciterDropdownSheet` — выпадающий список с поиском.
- `_SurahAyahSelectors` — селекторы в одну строку.
- `_AyahPanel` — панель аята с ornament-медальоном.
- `_Player` — золотая круглая play/pause + loop/prev/next/shuffle.
- `_PlaybackControls` — speed, sleep, night.

Display name: `displayNameForLocale(Reciter r, String localeCode)` выбирает **ru → en → ar** из локального кеша (`nameRu`/`nameEn`/`nameAr`).

### Reciter picker

`lib/features/audio/presentation/reciter_picker_screen.dart` — полноэкранный bottom sheet:

- `TextField` сверху: case-insensitive фильтр по `nameAr`/`nameEn`/`nameRu`.
- Tile: аватар-буква, displayNameRu, subtitle, **128 kbps gold-бейдж**, звезда (favorite), чекмарк.
- `setFavorite` → `ReciterDao.setFavorite` (флаг `is_favorite`).
- AppBar: «Обновить список» → `forceSync()`.

`audio_cache/{reciterId}/{NNN}.mp3` — `audioCacheRelativePath` в `reciters_repository.dart`. Подкаталог создаётся автоматически `createSync(recursive: true)` в `_localFile`.

### Per-surah playback pipeline

`AudioPlayerController._playSurahMp3Quran`:

```dart
final url = resolveSurahUrl(reciter, surah.id); // '${server}${NNN}.mp3'
final file = await _cache.getOrDownload(
  reciterId: reciter.id,
  surah: surah.id,
  url: url,
  cancelToken: cancelToken,
);
await _player.setFilePath(file.path);
await _player.play();
```

### Audio cache defence-in-depth

`AudioCache._isLikelyValidMedia(File)` — защита от poison HTML/403 ответов любого CDN:

- File size ≥ 1024 bytes (smallest legitimate ayah file is ~50 KB).
- First 3 bytes — `ID3` (`0x49 0x44 0x33`) или MPEG sync (`0xFF` + `0xFB/FA/F3/F2`).

Если check fails — файл удаляется и re-download. Если defence срабатывает повторно — reciter's `cdnId` не совпадает с URL паттерном (исторический баг: `ar.ahmedajamy` vs `ar.ahmedalajmi`, `ar.saaborimadina` vs `ar.saudalshuraim`).

### Quick test after future CDN changes

```bash
# С устройства (через активный VPN/DNS):
adb shell "curl -sS -o /dev/null -w 'code=%{http_code} time=%{time_total}s\n' \
  --max-time 10 'https://server8.mp3quran.net/afs/001.mp3'"

# Очистка кеша, если defence не справился:
adb shell "run-as com.quran.app.quran_app \
  sh -c 'rm -f /data/data/com.quran.app.quran_app/app_flutter/audio_cache/*.mp3;
        sqlite3 /data/data/com.quran.app.quran_app/databases/app.db \
          \"DELETE FROM audio_cache_metadata;\"'"
```

Manual verification: Слушать → tap play на дефолтном ректоре. Ожидаем «Воспроизведение» + ⏸ icon.

### Player state when switching reciters mid-play

`playSurah` отменяет предыдущий download и re-fetch'ит новый. `AudioPlayer.setFilePath` инициализируется per-surah.

При подозрении на stale state (лог показывает старого reciter после переключения) — перезапуск через supervisor, не `am force-stop` (см. `### Hard rules` device section).

## Quick reference

| Что                       | Где                                                                  |
|---------------------------|----------------------------------------------------------------------|
| MCP servers               | `.kilo/kilo.jsonc` секция `mcp`                                     |
| Setup / supervisor / smoke| `tools/dev/install-mcp-flutter.ps1`, `flutter-supervisor.ps1`, `self-test.ps1` |
| DB / ADB helpers          | `tools/dev/adb-helpers.ps1`                                          |
| Аудио архитектура         | `lib/features/audio/` (см. doc-комментарии)                          |
| Reference images          | `docs/images/listen.png`, `docs/images/read line by line.png`        |
| Migration chain           | `lib/core/database/migrations.dart`                                  |
| External MCP repo         | `F:\My_VC_Projects\mcp_flutter` (Arenukvern/mcp_flutter@main)        |
