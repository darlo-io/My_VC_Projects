# Agent Instructions — quran_app

Project-specific notes that are non-obvious. General Flutter/Dart rules live in the global Kilo instructions.

## MCP `flutter-skill` is patched locally — do not break it

The `flutter-skill` MCP server at `tools/flutter-skill-patched/` is a patched copy of `flutter-skill@0.9.36`. The global npm install (`%APPDATA%\npm\node_modules\flutter-skill`) is **not used** — Kilo's MCP config points at the project copy:

- Config: `.kilo/kilo.jsonc` → `mcp.flutter-skill.command = ["node", "tools/flutter-skill-patched/bin/cli.js", "server"]`
- Permission: global `C:\Users\007\.config\kilo\kilo.jsonc` → `permission.flutter_skill_* = "allow"`

### Patches applied (5 bugs in upstream 0.9.36)

| Bug | File | Fix |
|---|---|---|
| Stale 0-byte stub blocks Dart fallback | `~/.flutter-skill/bin/flutter-skill-windows-x64.exe-v0.9.36` | Delete the stub; package falls back to Dart |
| `spawn('dart')` fails on Windows (no `dart.exe`) | `bin/cli.js` | `shell: true` |
| Wrong package name in entry-point import | `dart/bin/server.dart` | `package:flutter_skill` → `package:flutter_skill_npm` |
| `Process.start('flutter')` fails (no `flutter.exe`, only `.bat`) | `dart/lib/src/cli/server.dart`, `dart/lib/src/cli/launch.dart` | `runInShell: true` |
| URI regex drops the `=` token char | `dart/lib/src/cli/server.dart` | `[a-zA-Z0-9.:/-]+` → `[a-zA-Z0-9.:/=_\-?&#]+` |

### Maintenance

- **Never run `npm update -g flutter-skill` blindly** — it would re-introduce the bugs above. If you do, immediately run:
  ```powershell
  pwsh tools/install-patched-mcp.ps1
  ```
  This re-copies `tools/flutter-skill-patched/` over the global install and re-runs `dart pub get`.

- After cloning the repo on a new machine, run once:
  ```powershell
  $env:Path = "C:\Users\007\develop\flutter\bin;$env:Path"
  dart pub get  # inside tools/flutter-skill-patched/dart/
  ```

- When upstream fixes land, drop them into `tools/flutter-skill-patched/` and re-run the smoke test:
  ```bash
  echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}
       {"jsonrpc":"2.0","method":"notifications/initialized","params":{}}
       {"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | node tools/flutter-skill-patched/bin/cli.js server
  ```
  Expected: `{"jsonrpc":"2.0","id":1,"result":{"serverInfo":{"name":"flutter-skill", ...}}}` plus a `tools/list` payload.

## Using `flutter-skill` from Kilo

Once the MCP is loaded, these tools are available directly:

| Tool | Use |
|---|---|
| `flutter_skill_launch_app` | Spawn `flutter run` and auto-connect |
| `flutter_skill_connect_app` | Attach to an already-running VM service |
| `flutter_skill_screenshot` | Capture the Flutter frame as PNG |
| `flutter_skill_tap` / `swipe` / `long_press` / `double_trap` | Interact by `key` or visible `text` |
| `flutter_skill_inspect` | List tappable elements with bounds |
| `flutter_skill_get_text_content` | Dump all on-screen text |
| `flutter_skill_get_widget_tree` | Widget tree up to N levels |
| `flutter_skill_hot_reload` | Trigger reload on the running app |

Prefer these over `adb exec-out screencap` / `adb shell input tap` — they are widget-aware, not pixel-aware.

## Active device

Currently paired: `c1316607` (OPPO CPH2653, Android). VM service URI after `flutter run` looks like `ws://127.0.0.1:<port>/<token>=/ws` and is printed in the `flutter run` stdout.

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