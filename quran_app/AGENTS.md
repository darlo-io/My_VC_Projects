# Agent Instructions — quran_app

Project-specific notes that are non-obvious. General Flutter/Dart rules live in the global Kilo instructions.

## MCP `flutter-mcp-toolkit` (Arenukvern/mcp_flutter) — server-only integration

**Active MCP** — `flutter-mcp-toolkit` (Arenukvern/mcp_flutter v4.x). Используется для hot reload, screenshot, UI inspection, оценки Dart-выражений и т.д.

**Режим: server-only (Option A)**, без in-app пакета `mcp_toolkit`:
- *Почему не in-app*: `mcp_toolkit` транзитивно тянет `intentcall_platform`, чей `build.gradle` ломает Android-сборку (NullPointerException в `FlutterPluginUtils.getLegacyAndroidExtension$gradle`). Это upstream-баг mcp_flutter v4.x — `intentcall_platform` не готов для standalone Android-использования.
- *Что теряем*: semantic snapshot (`fmt_capture_ui_snapshot` возвращает ограниченный layout), dynamic tools (`quran.play_ayah`, `quran.reciter_status`).
- *Что работает*: 30 `fmt_*` tools через прямой VM service connection (`fmt_connect_debug_app`). Один раз подключаем — все инструменты доступны.

- **Репозиторий**: `F:\My_VC_Projects\mcp_flutter` (клон Arenukvern/mcp_flutter@main)
- **Бинарь (Windows)**: `F:\My_VC_Projects\mcp_flutter\build\flutter-mcp-toolkit-server.exe` — AOT-compiled через `dart compile exe` (т.к. upstream не публикует Windows release artifacts)
- **MCP config** (`.kilo/kilo.jsonc`):
  ```jsonc
  "flutter-mcp-toolkit": {
    "type": "local",
    "command": ["F:\\My_VC_Projects\\mcp_flutter\\build\\flutter-mcp-toolkit-server.exe"],
    "args": ["--no-await-dnd"],
    "enabled": true
  }
  ```
- **Workflow**: запускаем `flutter run --debug` вручную (или через `tools/dev/supervisor.ps1`), получаем VM URI из stdout, передаём в `fmt_connect_debug_app` через MCP. После подключения все `fmt_*` tools доступны.

### Tool surface (30 tools, prefix `fmt_*`)

- **Lifecycle**: `fmt_connect_debug_app`, `fmt_discover_debug_apps`, `fmt_hot_reload_flutter`, `fmt_get_vm`, `fmt_get_extension_rpcs`
- **Inspection**: `fmt_inspect_widget_at_point`, `fmt_capture_ui_snapshot` (screenshot + layout + errors in one bundle)
- **Dynamic**: `fmt_list_client_tools_and_resources`, `fmt_client_tool`, `fmt_client_resource` — для app-registered tools (`quran.play_ayah` появится здесь после `addMcpTool`)
- **Debug**: `fmt_recent_logs`, `fmt_evaluate_dart` (Dart eval в VM)
- **Interaction** (через semantic-snapshot refs): `fmt_tap_widget`, `fmt_enter_text`, `fmt_scroll`, `fmt_swipe`

См. `instructions` поле в `initialize` response — там полный список с описаниями.

### Maintenance

- **One-time setup** (на новой машине):
  ```powershell
  # 1. Клонируем MCP-сервер
  git clone --depth 1 https://github.com/Arenukvern/mcp_flutter.git F:\My_VC_Projects\mcp_flutter

  # 2. Собираем Windows AOT-бинарь (у upstream нет Windows release)
  $env:Path = "C:\Users\007\develop\flutter\bin;$env:Path"
  pwsh tools/dev/install-mcp-flutter.ps1

  # 3. In-app пакет НЕ добавляем (см. «server-only (Option A)» выше —
  # `mcp_toolkit` ломает Android-сборку). Используем только бинарь.
  cd F:\My_VC_Projects\quran_app
  flutter pub get
  ```

- **После обновления upstream**:
  ```bash
  cd F:\My_VC_Projects\mcp_flutter && git pull
  pwsh tools/dev/install-mcp-flutter.ps1
  ```

- **Smoke test** (без подключения к Flutter app — сервер ждёт):
  ```powershell
  $env:Path = "C:\Users\007\develop\flutter\bin;$env:Path"
  Get-Process -Name 'flutter-mcp-toolkit' -ErrorAction SilentlyContinue | Stop-Process -Force
  $proc = Start-Process -FilePath 'F:\My_VC_Projects\mcp_flutter\build\flutter-mcp-toolkit-server.exe' `
      -RedirectStandardInput 'F:\dev\mcp-smoke2.in' `
      -RedirectStandardOutput 'F:\dev\mcp-smoke2.out' `
      -NoNewWindow -PassThru
  Get-Content F:\dev\mcp-smoke2.out | Select-Object -First 5
  ```
  Ожидаем `{"ok":true,"data":{"protocolVersion":"2024-11-05",...}}` (с `tools.listChanged: true` и подробными `instructions` в `serverInfo`).

### Hard rules

- **Always** `flutter run --debug` — release-mode игнорирует mcp_flutter (asserts в VM extensions).
- **Tools не появятся** пока нет debug-сессии с подключённым `fmt_connect_debug_app`. Это не баг сервера — он ждёт app.
- **Не запускай `dart compile exe` в режиме debug** — это упадёт с ошибкой "Debug builds cannot be AOT compiled". Если нужно пересобрать, сначала `flutter clean`.
- **`flutter run` на устройстве должен быть без VM URI issues** — `mcp_server_dart` сам находит Flutter debug targets через machine discovery (`flutter attach --machine`), не нужно копировать URI руками.
- **In-app `mcp_toolkit` пока не подключаем** — upstream-баг в `intentcall_platform` ломает Android Gradle. Когда пофиксят — переключимся на hybrid-режим (server + in-app dynamic tools).

## Using `flutter-mcp-toolkit` from Kilo

Once the MCP is loaded, these tools are available directly (prefix `fmt_*`):

| Tool | Use |
|---|---|
| `fmt_discover_debug_apps` | List running Flutter debug targets with canonical ws URIs |
| `fmt_connect_debug_app` | Connect to a target (auto-discovered or by URI) |
| `fmt_hot_reload_flutter` | Hot reload the app for instant UI updates |
| `fmt_capture_ui_snapshot` | Screenshot + layout + errors in one bundle |
| `fmt_inspect_widget_at_point` | Map screenshot coordinates to widget/render node |
| `fmt_recent_logs` | Ring buffer of `print` / `debugPrint` output |
| `fmt_evaluate_dart` | Evaluate Dart expressions в VM (мощно для проверки state) |
| `fmt_list_client_tools_and_resources` | List dynamic tools/resources registered by app code (`quran.play_ayah`, `quran.reciter_status`) |
| `fmt_client_tool` / `fmt_client_resource` | Execute dynamic entries |

**Semantic-snapshot** — один JSON-snapshot даёт `Element` tree с stable refs. После можно тапать по ref (а не по координатам), и сервер сам маппит ref → widget → action. Tap/enter_text/scroll/swipe принимают ref, а не pixel coords.

Prefer these over `adb exec-out screencap` / `adb shell input tap` — they are widget-aware, not pixel-aware.

## Active device

Currently paired: `c1316607` (OPPO CPH2653, Android). VM service URI after `flutter run` looks like `ws://127.0.0.1:<port>/<token>=/ws` and is printed in the `flutter run` stdout.

## Device development helpers (`tools/dev/`)

Scripts в `tools/dev/` решают 4 хронические боли отладки:

| Боль | Решение |
|---|---|
| PowerShell `>` кодирует бинарь в UTF-16 LE → corrupted DB-дампы | `Copy-AppDatabase` использует `adb exec-out ... base64 -w 0` + native decode |
| Координаты: `adb input tap` принимает **device px**, Flutter inspect — **DP** | `Invoke-AdbTapDp` сам считает `effectiveDensity/160`. Для c1316607 это `3` (effective density 480). |
| Скриншоты 1080×2376 не открываются MCP image-tools | `Save-ScreenOut` через System.Drawing ресайзит до 720px по длинной стороне в один вызов |
| VM connection отваливается каждые ~3 мин после `am force-stop` → реконнект цикл ~5 мин | `Start-FlutterSupervisor` запускает watchdog-loop: перезапускает APK каждые `pidof` check, перезапускает flutter run если умер, **публикует VM URL в `F:\dev\device_state.json`** |

См. `tools/dev/README.md` для полного описания и примеров.

### После любого реконнекта

```powershell
. "F:\My_VC_Projects\quran_app\tools\dev\adb-helpers.ps1"
. "F:\My_VC_Projects\quran_app\tools\dev\flutter-supervisor.ps1"
Get-FlutterState | Format-List       # → vmUri, fwdPort, appPid
```

Затем `fmt_connect_debug_app` с этим `vmUri`.

### Hard rules

- **Не убивай `am force-stop com.quran.app.quran_app` пока supervisor жив** — он сам restart'нет APK. Если force-stop обязателен, сначала `Stop-FlutterSupervisor` чтобы не было гонки.
- **adb forward** всегда на **tcp:22080** (фиксированный порт supervisor'а). Не пересоздавай через `adb forward tcp:N tcp:M` — fix в `flutter-supervisor.ps1`. Порт 10808 занят Xray VPN — не использовать.

## Audio playback — CDN and cache (rebuilt 2026-07-05)

The audio feature (`lib/features/audio/`) is wired end-to-end. The original
CDN (`cdn.islamic.network`) and Russian mirror (`cdn.alislam.ru`) both became
unreliable in mid-2026 — DNS hijacks to `*.bahriya.net` returning 403, plus
a 70/7s cumulative rate-limit on the Islamic Network CDN. The fix in v0.2
**migrated to MP3Quran.net** as the primary source — it offers:

- **241+ reciters** with full Hafs rewaya coverage (vs. the 8 hardcoded ones
  we shipped with), fetched via `GET /api/v3/reciters?language=ar`
- **Per-surah files** (one MP3 per surah), e.g.
  `https://server8.mp3quran.net/afs/001.mp3` — no more 7..286-file
  concatenation we needed with cdn.alislam.ru's per-ayah mode
- **Ayat timing API** at `GET /api/v3/ayat_timing?surah=N&read=M` for
  word-level highlighting during playback (Phase 3 — не подключено ещё)
- **Multi-server CDN** (server6..server18) — different reciters hosted on
  different servers, so a single-server outage doesn't kill playback
- **Multi-language** — `language=ar|eng|ru|...` switches UI strings

### Reciter coverage

`lib/features/audio/data/reciters_repository.dart` defines a hardcoded
mapping for 8 default reciters (each → mp3quran reciter+moshaf+server).
All 8 have 114 surahs in Hafs Murattal on mp3quran.net. The remaining
~233 are populated on demand by [RecitersSyncService.syncFromApi].

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

### Reciter cache (DB)

`lib/features/audio/data/reciters_repository.dart` управляет таблицей
[Reciters] в локальной БД. На старте [ensureSeeded] делает:

1. Вставляет 8 дефолтных ректоров из `kDefaultReciters`, если таблица пуста.
2. Заполняет mp3quran-метаданные (`mp3quranId`, `mp3quranServer`,
   `mp3quranMoshafId`, `mp3quranRewaya`, `mp3quranSurahTotal`,
   `mp3quranCachedAt`) из `_defaultMp3quranById` — идемпотентно.

[syncFromApi] подтягивает полный список (~241 ректор) с mp3quran.net
и записывает в ту же таблицу (id = `mp3quran:<id>`). Поиск по имени
(`nameAr`/`nameEn`) в выпадающем меню — см. `reciter_picker_screen.dart`.

Не дёргаем на каждом запуске (см. рекомендации из задачи);
[syncFromApi] вызывается через **[RecitersSyncService.maybeSync]**
(см. ниже) с двух триггеров:

1. **Background worker** при bootstrap — `unawaited(service.maybeSync())`
   из `ContentBootstrapper.bootstrap()` сразу после `_fetchFromNetworkInBackground`.
   Skip'ает сетевой запрос если кеш свежий **И** все ректоры в БД имеют
   mp3quran-метаданные.
2. **Manual** — кнопка «Обновить список» в AppBar `ReciterPickerScreen`
   вызывает `service.forceSync()` (TTL игнорируется, нужен для
   пользователей «хочу свежий список прямо сейчас»).

### Background sync: `RecitersSyncService`

`lib/features/audio/data/reciters_sync_service.dart`. Singleton
через `recitersSyncServiceProvider`. Состояние через
`ValueNotifier<RecitersSyncState>` — UI может показывать прогресс.

**Cache TTL — 7 дней** (`_kDefaultCacheTtl`). `maybeSync` скипает
сетевой запрос если оба условия:
- `latestMp3quranSync() < cacheTtl` (т.е. последний успешный sync
  меньше 7 дней назад)
- `countRecitersWithoutMp3quranInfo() == 0` (все 8+ дефолтных ректоров
  уже имеют mp3quran-метаданные)

На **первом запуске после миграции v9→v10**: `ensureSeeded` заполняет
mp3quran-метаданные для 8 дефолтных ректоров, поэтому
`latestMp3quranSync()` возвращает «сегодня» — НО
`countRecitersWithoutMp3quranInfo() > 0` (мы не знаем про 233 других),
поэтому `maybeSync` всё равно пойдёт на sync. После полного успешного
sync'а оба условия возвращают true/false (0), и на ближайшие 7 дней
сетевых запросов не будет.

**Rate-limit** — у mp3quran.net не задокументирован, но `GET
/api/v3/reciters?language=ar` возвращает ~100 KB JSON, держим разумный
лимит в 10 RPS (та же логика, что для AlQuran Cloud — см. секцию
«Rate limiting on cdn.alislam.ru» ниже).

**Ошибки**: если sync провалился (timeout, 5xx, DNS) — ловим в
`_safeRun` на bootstrap, логируем через `developer.log`, состояние
переходит в `failed`. Юзер увидит это в snackbar при следующем ручном
sync'е (когда сам нажмёт «Обновить»).

### Listen UI redesign (2026-07-05)

`lib/features/audio/presentation/listen_screen.dart` — переработан
по мотивам `docs/images/listen.png`. Ключевые отличия от старой
версии:

- **Одна карточка ректора** вместо горизонтальной карусели
  ([`_ReciterCard`]). На ней: круглая буква (первая буква имени) с
  градиентным gold-кругом, display-имя на языке пользователя, арабское
  имя, rewaya с переводом. Чекмарк справа внизу указывает, что
  ректор выбран.
- **Тап по карточке** открывает выпадающий список ([`_ReciterDropdownSheet`])
  с поиском, бейджем 128 kbps, звёздочкой избранного и селектом.
  Выбор из списка обновляет выбранного ректора.
- **Селекторы Сура / Аят** ([`_SurahAyahSelectors`]) в одну строку,
  каждый тап открывает bottom sheet.
- **Панель аята** ([`_AyahPanel`]) с геометрическим «медальоном» в стиле
  референса, арабским текстом сур, плавно анимированным
  счётчиком «Аят N из M» (`AnimatedSwitcher`).
- **Плеер** ([`_Player`]) с золотой круглой кнопкой play/pause, рядом
  loop / prev / next / shuffle.
- **Панель контролов** ([`_PlaybackControls`]) — speed, sleep, night
  (горизонтальная раскладка).
- **Темный emerald theme** — глубокий зелёный (`_kEmeraldDeep`) с
  золотыми акцентами (`_kGold`). Применяется через `Theme(data: …)`
  к корню экрана, не затрагивая остальное приложение.
- **Фоновый Islamic-паттерн** — `_IslamicPatternPainter` рисует 8-конечные
  звёзды с золотой обводкой (alpha 0.05), без зависимости от assets.

### Reciter display name локализация

`displayNameForLocale(Reciter r, String localeCode)` в
`reciters_repository.dart` выбирает имя в порядке приоритета:
**ru → en → ar**. БД хранит `nameRu`, `nameEn`, `nameAr` (v11),
поэтому UI не дёргает API для локализации — только читает локальный
кеш.

### Reciter picker

`lib/features/audio/presentation/reciter_picker_screen.dart` —
полноэкранный bottom sheet со списком и поиском:
- `TextField` сверху с case-insensitive фильтром по nameAr + nameEn + nameRu
- Каждый tile: аватар-буква, displayNameRu, subtitle, **128 kbps gold-бейдж**,
  звезда (toggle favorite), чекмарк если выбран
- `setFavorite` пишет `is_favorite` в БД через `ReciterDao.setFavorite`
- Кнопка «Обновить список» в AppBar вызывает `forceSync()`

### Cache file structure

`audio_cache/{reciterId}/{NNN}.mp3` (см. рекомендации в задаче).
`audioCacheRelativePath(reciterId, surah)` в `reciters_repository.dart`.
Подкаталог `audio_cache/{reciterId}/` создаётся автоматически
`createSync(recursive: true)` в `_localFile` (`audio_cache.dart`).

### Per-surah playback pipeline

`AudioPlayerController._playSurahMp3Quran` — простой путь: один
HTTP-запрос на суру → `setFilePath`.

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

### Reciter picker UI

`ListenScreen` показывает карусель избранных + кнопку «Все чтецы»
внизу. По тапу открывается `ReciterPickerScreen` — список с поиском
по `nameAr`/`nameEn` (case-insensitive substring match). Каждый tile
показывает mp3quran-status (✓/⚠) и rewaya, при тапе возвращает
выбранного ректора. Справа в AppBar — кнопка обновления списка через
[syncFromApi].

### Rate limiting on cdn.alislam.ru

`community.islamic.network/knowledgebase/2-is-there-a-rate-limit-on-the-apis-cdn`
(страница JS-рендеренная, читай через `api/discussions/2`):

> - AlAdhan API: **12 req/s** per IP → 429 при превышении
> - AlQuran API: **10 req/s** per IP → 429 при превышении
> - **Cumulative**: **70 requests / 7 seconds** per IP → timeout.
>   **Применяется и к Islamic Network CDN.**
> - Лимиты не изменяемы.

Защита в `lib/features/audio/`:
- `_playSurahByAyah`: `100ms` между загрузками = ровно 10 RPS, на лимите
- `AudioCache._download`: на HTTP **429** ждёт **7 секунд** и ретраит
  (до 3 попыток — этого хватает для кумулятивного лимита 70/7s)
- На больших сурах (Аль-Бакара = 286 аятов) скачивание займёт ~28 секунд
  без учёта 429-пауз; с 429-паузами — до ~минуты. Юзер увидит ошибку раньше.

Что НЕ делать при отладке: спамить `curl cdn.alislam.ru/.../{1..20}.mp3`
подряд — легко превысить лимит и заблокировать себя на 7 секунд
(поэтому мои первые тесты на устройстве шли со скоростью 2 КБ/с).

### Audio cache bug — poison HTML responses

`AudioCache._resolveOrFetch` previously only checked `file.lengthSync() > 0`.
A 403/HTML response from the hijacked `cdn.islamic.network` is **271 bytes**
and was being treated as a valid MP3. The result: player init failed
with `UnrecognizedInputFormatException` ("None of the available extractors
could read the stream"), and a stale 271-byte file lived in the cache
forever.

The fix is `_isLikelyValidMedia(File)` in `audio_cache.dart`:

- File size must be **≥ 1024 bytes** (smallest legitimate ayah file is ~50 KB)
- First 3 bytes must be either `ID3` (`0x49 0x44 0x33`) or MPEG sync
  (`0xFF` + `0xFB/FA/F3/F2`)

When the check fails, the file is deleted and re-downloaded. If you see
this defence fire repeatedly, the URL is serving a 403/HTML response —
check that the reciter's `cdnId` matches what's actually on the CDN
(some reciters have different directory names: e.g. `ar.ahmedalajmi` not
`ar.ahmedajamy`, `ar.saudalshuraim` not `ar.saaborimadina`).

### Quick test after future CDN changes

```bash
# From the device (proxies through whatever VPN/DNS hijack is active):
adb -s c1316607 shell "curl -sS -o /dev/null -w 'code=%{http_code} time=%{time_total}s\n' \
  --max-time 10 'https://cdn.alislam.ru/quran/audio/128/ar.alafasy/1.mp3'"

# From the app — clean state required, or `_inFlight` map is stuck:
adb -s c1316607 shell "am force-stop com.quran.app.quran_app"
adb -s c1316607 shell "am start -n com.quran.app.quran_app/.MainActivity"
# Then: Слушать → tap play on Абдул-Басит (default). Look for "Воспроизведение" + ⏸ icon.
```

If you see `UnrecognizedInputFormatException` in `adb logcat -s AudioPlayer:E`,
the cache fix isn't catching the poison file — manually clean:
```bash
adb -s c1316607 shell "run-as com.quran.app.quran_app \
  sh -c 'rm -f /data/data/com.quran.app.quran_app/app_flutter/audio_cache/*.mp3;
        sqlite3 /data/data/com.quran.app.quran_app/databases/app.db \
          \"DELETE FROM audio_cache_metadata;\"'"
```

### Stale state vs hot reload

`AudioCache` has an in-memory `_inFlight: Map<String, Future<File>>` that
isn't cleared on hot reload. If a download was in progress when hot
reload fired, the next `getOrDownload` may short-circuit to the stale
Future. Recovery: `am force-stop` + relaunch, or call
`AudioCache._inFlight.clear()` (no public API — add one if needed).

### Player state when switching reciters mid-play

`playSurah` cancels the previous download via `_downloadCancel` and
re-fetches. The just_audio `AudioPlayer` is re-initialized with
`setAudioSource()` for per-ayah (new) or `setFilePath()` for per-surah
(legacy). If a play attempt appears to use the wrong reciter (e.g. log
says `ar.abdulbasitmurattal_001.mp3` after you tapped Minshawi), the
`_reciterId` state in `_ListenScreenState` is stale — hot reload preserves
it, so use `am force-stop` to fully reset.