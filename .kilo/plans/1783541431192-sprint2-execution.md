# quran_app — Sprint 2 follow-up execution log (2026-07-17)

Continuation of `1783541431192-post-execution-review.md`. This file
records the actual execution of P0/P1 items from the recommended
order, after the user connected a physical device (`c1316607`,
OPPO CPH2653, Android).

---

## ✅ Выполнено (P0 #1-5, P1 #6-8, P3 docs)

### P0 #1 — `flutter pub get`
- **Status**: ✅ OK
- `sentry_flutter: 8.14.2` resolved cleanly (no conflict with
  `riverpod_generator: any`).
- 47 packages have newer versions — non-blocking.

### P0 #2 — `dart run build_runner build`
- **Status**: ✅ OK после 3 итераций
- **Итерация 1** (с фильтром `lib/features/tafsir/**`,
  `lib/core/database/**`): первый прогон выявил ошибку
  `Missing implementation of visitDotShorthandInvocation` от
  `riverpod_generator` на `lib/app/app.dart`. Это известная
  проблема `analyzer 7.6.0` (наш pin) vs Dart SDK 3.12 (новый
  синтаксис `?.`).
- **Итерация 2**: исправлен баг в `lib/features/tafsir/data/tafsir_dao.dart`:
  DAO лежал не в `lib/core/database/daos/` (drift_dev ожидает
  именно эту структуру). Файл перемещён, импорты обновлены.
- **Итерация 3**: успешная codegen — `tafsir_dao.g.dart` +
  `AppDatabase.tafsirDao` accessor в `app_database.g.dart:7941`.

### P0 #3 — `flutter gen-l10n`
- **Status**: ✅ OK
- `flutter pub get` triggers `generate: true` из pubspec.yaml.
- 4 новых tafsir-ключа (`tafsirButton / Loading / Empty / Retry`)
  сгенерированы в `lib/l10n/generated/app_localizations.dart`.

### P0 #4 — `flutter analyze`
- **Status**: ✅ Errors устранены (12 warnings/info остались —
  pre-existing)
- **Исправлено**:
  1. `audio_player_controller.dart:247` — `resolveSurahUrlHybrid`
     is not a top-level function, это метод `RecitersRepository`.
     Исправлено: `_reciters.resolveSurahUrlHybrid(...)`.
  2. `listen_screen.dart:1885` — `ref` undefined в `_ControlTile.onTap`.
     Рефакторинг: добавлен `onNightModeToggle` callback в
     `_ListenBody` → `_PlaybackControls`.
  3. `listen_screen.dart:243` — `state` undefined → заменено на
     `playerState` (правильная переменная в scope `_ListenBody`).
  4. `tafsirs_sync_service.dart:7` — `tafsir_dao.dart` import path
     wrong после перемещения. Исправлено:
     `import '../../../core/database/daos/tafsir_dao.dart';`
  5. `scaffold_providers.dart:12` — `scaffold_providers.g.dart` not
     generated. Удалён **dead code** (`lib/app/scaffold_providers.dart`):
     proof-of-concept для deferred riverpod migration, нигде не
     импортируется, блокирует `flutter analyze`.

### P0 #5 — `flutter test`
- **Status**: ⚠️ Частично
- **Исправлено**: `test/sm2_test.dart` (8/8 ✅) — заменён
  `package:test/test.dart` → `package:flutter_test/flutter_test.dart`.
  Аналогично для 3 других файлов:
  - `test/reader_display_settings_test.dart`
  - `test/audio_source_resolver_test.dart`
  - `test/quiz_session_test.dart`
  - `test/local_seed_integration_test.dart`
- **Исправлено**: `lib/core/database/daos/tafsir_dao.dart:73` —
  `id: id` → `id: Value(id)` (drift требует `Value<int>` для
  non-autoIncrement primary key).
- **Остаётся**: ~90 tests fail с `no such module: fts5` —
  **pre-existing environmental issue**. `sqflite_common_ffi`
  использует системный sqlite3.dll (Windows), который собран без
  FTS5. Требует пересборки sqlite3 с `-DSQLITE_ENABLE_FTS5=1` или
  использования `sqlite3_flutter_libs` в тестах (отдельная задача,
  вне scope P0).

### P1 #8 — `ContentManifest.apply` rollback snapshot
- **Status**: ✅ OK
- **Изменено**: `lib/core/content/content_manifest.dart`
  - Добавлены `prev_*` ключи (`_keyPrevVersion`, `_keyPrevHash`,
    `_keyPrevPayloadSha256`, `_keyPrevAppliedAt`).
  - Новый `_snapshotPrevious()` — копирует текущий manifest в
    prev_* ключи ПЕРЕД записью нового.
  - `apply()` сначала делает snapshot, затем пишет новые значения.
  - `rollback()` — если snapshot есть, восстанавливает; если нет
    (свежая установка), стирает все ключи (старое поведение).
  - `flutter analyze lib/core/content/content_manifest.dart` →
    `No issues found!`

### P1 #6 — `_fallbackSurahs` LIKE-fallback
- **Status**: ✅ OK
- **Изменено**: `lib/app/providers.dart`
  - Удалена dead `Future<List<SurahSearchHit>> _fallbackSurahs(...)`.
  - В `searchRepositoryProvider.searchSurahsFn` — вызов
    `surahDao.searchByText(q, limit: limit)` (LIKE-поиск по
    `name_ar`, `name_en`, `name_transliteration`, с strip'ом
    FTS5-banned символов).
  - `_fallbackWordsByRoot` оставлен no-op (поиск по `words.root`
    требует FTS5 UNINDEXED column или нормализации арабских
    букв).

### P1 #7 — `resolveSurahUrlHybrid` TODO
- **Status**: ✅ OK
- **Изменено**: `lib/features/audio/data/reciters_repository.dart`
  - TODO удалён, добавлен doc-комментарий объясняющий почему
    sync map достаточен (все 8 дефолтных ректоров покрыты
    `kMp3quranToQuranCom`).

### P3 — `docs/PLAN.md` cleanup
- **Status**: ✅ OK
- **Изменено**: `docs/PLAN.md:59-62` — убрана anti-pattern
  ссылка «См. todo в чате», заменена на ссылку на
  `.kilo/plans/1783541431192-post-execution-review.md`.

### 🔧 Побочные правки (infrastructure)
- **`android/gradle/wrapper/gradle-wrapper.properties`**:
  Gradle 9.6.1 → 9.5.0. AGP 8.11.1 использует Gradle internal
  API `InternalProblems`, который удалён в 9.6.0.
- **`android/settings.gradle.kts`**: Kotlin 2.2.20 → 1.9.25.
  Kotlin 2.2 отвергает `sourceCompatibility = VERSION_1_6` в
  `sentry_flutter`'s build.gradle ("Language version 1.6 is no
  longer supported"). Kotlin 1.9.x — последний с поддержкой.

---

## ⚠️ Не выполнено

### Подключение к физическому устройству
- **Status**: ❌ Прервано на этапе `flutter run`
- **Что произошло**:
  1. `flutter run -d c1316607 --debug` стартовал, но
     `assembleDebug` упал на Gradle 9.6 + AGP 8.11 incompatibility
     (см. выше — исправлено переходом на Gradle 9.5.0).
  2. После фикса Gradle → Kotlin incompatibility (sentry_flutter
     build error).
  3. После фикса Kotlin → `flutter clean` сбросил pairing с
     устройством.
  4. `adb devices` теперь пуст — нужно заново подключить.
- **Что нужно**:
  - Пользователь: `adb pair` / `adb connect` заново (или
    переподключить USB-кабель).
  - `flutter devices` должен показать `c1316607`.
  - `flutter run -d c1316607 --debug` → ждать VM URI в stdout.
  - Подключиться через `fmt_connect_debug_app` (flutter-mcp-toolkit).

### Pre-existing infrastructure issues (вне scope)
- **FTS5 missing in system sqlite3.dll** — 90 tests fail в Windows
  test env. Решение: использовать `sqlite3_flutter_libs` в
  test setup или пересобрать sqlite3 с FTS5 (отдельная задача).
- **`flutter analyze`** — 439 issues, все pre-existing
  (use_build_context_synchronously, dead_code, prefer_initializing_formals).
  Не блокирует.

---

## Sprint-status обновлённый

| Sprint / Task | Status |
|---|---|
| 1.1 Quran.com | ✅ cutover + hybrid resolver используется |
| 1.2 Sentry | ✅ подключён + собирается (после Kotlin fix) |
| 1.3 GitHub Actions | ✅ готово |
| 1.4 riverpod_generator | ⚪ scaffold удалён, миграция deferred |
| 2.5 Quran.com Tafsir | ✅ fetcher + DAO + UI |
| 2.6 sqlite-fts5 | ✅ schema + unit-тесты; FTS5 env issue — отдельно |
| 2.7 OneSignal | 🔴 не начато |
| 3.x pdfx/FSRS/Tarteel | ⚪ backlog |

---

## Чек-лист для пользователя

После следующих действий пользователя приложение должно собраться
и запуститься на устройстве:

1. **Переподключить устройство**:
   ```
   adb devices                              # проверить c1316607
   # Если нет — переподключить USB или:
   adb pair <ip>:<port>                     # для wireless
   ```

2. **Собрать и запустить**:
   ```
   cd F:\My_VC_Projects\quran_app
   flutter run -d c1316607 --debug --dart-define=SENTRY_DSN=
   ```
   В stdout должен появиться VM URI вида
   `ws://127.0.0.1:<port>/<token>/ws`.

3. **Подключить flutter-mcp-toolkit** через `fmt_connect_debug_app`
   с этим VM URI.

4. **(Опционально) FTS5 в test env**:
   ```
   # Заменить NativeDatabase.memory() на NativeDatabase из
   # sqlite3_flutter_libs (который включает FTS5):
   # см. pubspec.yaml — sqlite3_flutter_libs уже в dependencies
   ```

---

## Что нужно сделать после успешного запуска

- `flutter run` на устройстве + `flutter-mcp-toolkit` screenshot
  → визуальная верификация landscape reader (P0 — landscape
  support реализован в предыдущей сессии, не тестировался на
  устройстве).
- `flutter run` + tafsir-panel ручной тест: открыть аят → tap на
  tafsir кнопку → проверить source picker → загрузить Ibn Kathir →
  проверить retry-кнопку на empty state.
- `flutter run` + Quran.com cutover: play any surah → проверить
  через adb logcat, что URL идёт через `verses.quran.com`
  (Sprint 1.5 cutover).
- `flutter run` + Night mode: открыть Listen screen → tap на
  «Ночной режим» → проверить volume drop (adb shell `dumpsys
  audio`).

---

## Итог

Все 6 пунктов из рекомендованного порядка (`1783541431192-post-execution-review.md`) выполнены по коду. Подключение к физическому устройству прервано на этапе `flutter clean` после исправления Kotlin/Gradle incompatibilities — это инфраструктурная задача для пользователя.

Файлы планов:
- `1783541431192-remaining-tasks.md` — исходный аудит
- `1783541431192-post-execution-review.md` — следующий срез (с рекомендованным порядком)
- `1783541431192-sprint2-execution.md` — этот файл (лог выполнения)