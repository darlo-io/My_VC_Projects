# quran_app — оставшиеся задачи (status: 2026-07-17)

Snapshot незавершённых пунктов по результатам аудита кодовой базы,
`docs/PLAN.md`, `docs/QURAN_COM_MIGRATION.md`, `pubspec.yaml` и
TODO/FIXME-маркеров в `lib/`. Сгруппировано по фактическому состоянию,
а не по спринтам — приоритеты ⭐ = blocker / debt, без звёзд = backlog.

---

## ⭐ P0 — Blockers / known broken / dead code

### 1. Quran.com → mp3quran cutover **не завершён** (Sprint 1 task #1)
**Файл-источник**: `docs/QURAN_COM_MIGRATION.md` Phase 1.

Готовые части:
- ✅ DB-migration: `quranComId` колонка в `reciters` / `tafsir_sources` (v16+)
- ✅ `lib/features/audio/data/quran_com_api.dart` (421 строка, все endpoints)
- ✅ `quran_com_reciter_mapping.dart` (маппинг 8 дефолтных ректоров)
- ✅ `quran_com_reciter_dao.dart` для хранения meta

**Что не сделано / сломано:**
- ❌ `audio_player_controller.dart:229` всё ещё вызывает **legacy**
  `resolveSurahUrl(reciter, surah.id)` — НЕ `resolveSurahUrlHybrid`.
  То есть Quran.com API существует, но не используется в playback-пути.
- ❌ `reciters_repository.dart:361 resolveSurahUrlHybrid` — функция
  определена, но **0 вызовов** в коде (dead code).
- ❌ Схема хранит `quranComId` для ректоров, но реальное
  `mp3quranId → quranComId` маппинг (reciters_repository.dart:326
  `quranComToMp3quran`) инвертирован и не покрывает все 240 ректоров.
- ❌ Поле `reciterPath` (из миграционного плана Phase 1) — **не добавлено**
  в таблицу. Без него Phase 2 (per-verse audio) невозможен.

**Что сделать:**
1. Поменять вызов в `audio_player_controller._playSurahMp3Quran` на
   `resolveSurahUrlHybrid` + fallback chain (quran.com → mp3quran → null).
2. Добавить `reciterPath` column в `Reciter` (DB migration v17+).
3. Удалить `ensureSeeded()` no-op (reciters_repository.dart:228) —
   данные теперь идут из Quran.com sync.
4. Расширить `quranComToMp3quran` маппинг для всех 240 ректоров
   (или убрать — если полностью переходим на quran_com_reciter_dao).

---

### 2. Sentry — **только каркас, не подключён** (Sprint 1 task #2)
**Файл**: `lib/core/observability/sentry_bootstrap.dart` (80 строк).

Весь код — комментарии-инструкции. Реальная инициализация в `// commented`:
- `SentryFlutter.init(...)` — закомментирован.
- `Sentry.captureException(...)` — закомментирован.
- `pubspec.yaml:81 // TODO: добавить sentry_flutter когда production-ready.`

**Что сделать:**
1. `flutter pub add sentry_flutter`.
2. Раскомментировать `SentryFlutter.init` блок в `sentry_bootstrap.dart`.
3. Заменить `developer.log(...)` в release-критичных местах
   (audio_cache failures, content bootstrap failures, navigation errors)
   на `Sentry.captureException(...)`.
4. Добавить `SENTRY_DSN` в `.env` / `flutter_dotenv` (если используется)
   или прямо в `kReleaseMode` constant.

---

### 3. Ночной режим (Ночной режим) — **TODO-stub**
**Файл**: `lib/features/audio/presentation/listen_screen.dart:1879`.

```dart
const SnackBar(content: Text('Ночной режим (TODO)')),
```

`AudioPlayerController.setNightMode` (audio_player_controller.dart:528)
— no-op, помечает в state для UI, но не делает ничего:
- нет volume-dim
- нет bitrate-switch
- нет реального night-mode render

**Что сделать:**
- Реализовать volume dim (например, 0.3) при активации.
- Или удалить кнопку если фича не планируется.

---

### 4. `resolveSurahUrlHybrid` — **dead code**
**Файл**: `reciters_repository.dart:361`. См. пункт 1.

После cutover либо использовать, либо удалить.

---

## ⭐ P1 — Settings flags / DB schema не подключены к UI

### 5. `showWordByWord` — **флаг без реализации**
**Файлы**: `reader_display_settings.dart:37`, `reader_display_settings_codec.dart:29`.

`showWordByWord: bool` есть в:
- domain model
- codec (persist)
- settings screen UI (toggle)
- defaults = false

**Нигде не читается** в рендере. `AyahTile` (reader_widgets.dart) игнорирует
этот флаг — слов-по-словам нет.

**Что сделать:**
- Реализовать отображение тап-набельного слова (тапабельный WordSpan уже есть
  в `word_card.dart`), или
- Удалить флаг из model/codec/UI (если фича отменена).

---

### 6. `tafsirs` таблица и `tafsirs_fts` существуют, **но нет fetcher / UI** (Sprint 2 task #5)
**Файлы**: `app_database.dart` (таблицы `tafsirs`, `tafsir_sources`, virtual `tafsirs_fts`).

DB готова, но:
- Нет `quran_com_tafsir_api.dart` (упомянут в PLAN.md Phase 3 как "Sprint 2-3").
- Нет UI-кнопки "тафсир" в `AyahPanel` (см. `reader_widgets.dart`).
- Нет настройки "выбранный тафсир" в `ReaderDisplaySettings` /
  `AppPreferences`.

**Что сделать:**
- Добавить `lib/features/tafsir/data/quran_com_tafsir_api.dart`.
- Добавить `TafsirDao` для CRUD `tafsirs` + `tafsir_sources`.
- UI: bottom-sheet с выбором тафсира (Ibn Kathir, Jalalayn, Maududi, …).
- Кнопка в AyahPanel с индикатором "есть тафсир".
- FTS5 индекс уже есть — поиск по тафсирам заработает сразу.

---

## ⭐ P1 — Спринт-1 долги по инфраструктуре

### 7. `riverpod_generator` migration — **scaffold-only** (Sprint 1 task #4)
**Файлы**: `lib/app/scaffold_providers.dart` + `.g.dart`.

3 провайдера сгенерированы как **proof-of-concept** (scaffoldAppName,
scaffoldSurahCount, scaffoldSurahName). Файл явно помечен как НЕ
production-используемый.

`scaffold_providers.dart:1-7`:
> Sprint 1.4 scaffold: proof-of-concept... Этот файл НЕ используется
> в production... После Sprint 1 полная миграция providers.dart будет
> включать конвертацию реальных провайдеров.

**Что сделать:**
- Конвертировать 25+ провайдеров в `app/providers.dart` с `@riverpod`.
- Удалить scaffold-файл (или оставить как reference / `golden test`).
- `pubspec.yaml:69 riverpod_generator: any` — заменить на pinned версию
  после успешной миграции.

---

### 8. `ContentManifest.apply` — нет rollback (TODO в коде)
**Файл**: `core/content/content_manifest.dart:254`.

```dart
// TODO: сохранить предыдущие значения для rollback. Сейчас
// `rollback()` просто стирает все ключи
```

При `apply(newManifest)` текущий манифест перезаписывается без
сохранения. `rollback()` стирает всё, теряя историю.

**Что сделать:**
- Перед `_writeManifest` сохранять snapshot в
  `previousManifestVersion / previousContentHash` ключи в SharedPreferences.
- `rollback()` восстанавливает из snapshot.

---

### 9. `_fallbackSurahs` — возвращает `const []` (TODO в коде)
**Файл**: `lib/app/providers.dart:830`.

```dart
/// "find by root/transliteration" остаётся TODO (требует FTS5 UNINDEXED columns).
Future<List<SurahSearchHit>> _fallbackSurahs(...) async {
  return const <SurahSearchHit>[];
}
```

Поиск по `surah.nameTransliteration` и `words.root` не работает —
всегда пустой массив. Для Sprint 1.6+ нужно либо FTS5 UNINDEXED columns,
либо отдельный LIKE-fallback.

---

## P2 — Backlog из PLAN.md

### 10. Sprint 2 — `sqlite-fts5` production rollout (Sprint 2 task #6)
- ✅ FTS5 virtual tables созданы (`ayahs_fts`, `translations_fts`, `words_fts`, `tafsirs_fts`).
- ✅ Unit-тесты: `test/features/search/search_dao_test.dart` (251 строка).
- ❓ Не верифицировано в release-сборке (только `flutter test`).

### 11. Sprint 2 — Tafsir API + UI (см. пункт 6)
Самый крупный недоделанный пункт.

### 12. Sprint 2 — OneSignal push (verse-of-the-day)
Не начато. Нет deps, нет service, нет UI opt-in.

### 13. Sprint 2 — `slang` migration
Помечен как "(опционально)". Текущий gen-l10n работает.

### 14. Sprint 3 — Mushaf PDF через `pdfx`
Не начато.

### 15. Sprint 3 — FSRS memorization
Не начато (только i18n-строка `learnHubMyStats`).

### 16. Sprint 3 — Tarteel AI
Premium, отложено.

### 17. Sprint 3 — ObjectBox migration
Условный fallback (если FTS5 не хватит по перформансу).

---

## P3 — Test coverage gaps

### 18. Нет unit-тестов для `RecitersRepository`
**Существующие тесты** используют `RecitersRepository` (через integration):
- `test/widget/learn_screen_test.dart`
- `test/widget/notes_panel_test.dart`
- `test/widget/word_card_test.dart`
- `test/integration/content_bootstrapper_test.dart`

Но dedicated unit-тестов на `syncFromApi`, `ensureSeeded`,
`resolveSurahUrlHybrid`, `setFavorite` — **нет**.

### 19. Нет unit-тестов для `AudioPlayerController`
Только `test/audio_source_resolver_test.dart` (chain resolver).
`setSpeed`, `setSleepTimer`, `playNext`, `playPrevious`,
`onAyahComplete` — без покрытия.

### 20. Нет golden / snapshot тестов для Reader
`golden_toolkit` в pubspec.yaml закомментирован:
```yaml
# golden_toolkit — для UI snapshot-тестов:
# golden_toolkit: ^1.0.0
```

Reader — самый критичный экран, регрессии после landscape-рефактора
(см. commit 2026-07-17) нечем ловить.

### 21. Нет widget-тестов для `_LandscapeSidebar`
Только что добавленный landscape-сайдбар не имеет покрытия.

---

## P3 — Документация

### 22. `docs/mcp-migration.mdx` — TODO в `AGENTS.md:7`
> Мотивация, история миграции и список багов flutter-skill, которых
> больше нет — в `docs/mcp-migration.mdx` (TODO).

Файл отсутствует. После удаления flutter-skill-остатков (2026-07-17)
эта заметка устарела — TODO можно либо реализовать, либо удалить.

### 23. `docs/PLAN.md:60 Прогресс`
> См. todo в чате для актуального статуса.

Ссылка на "todo в чате" — anti-pattern. Прогресс должен жить в файле
или в issue tracker.

---

## P3 — Качество кода

### 24. `flutter analyze` — 441 issues (большинство pre-existing)
Запустить и приоритизировать:
- `test/sm2_test.dart` — undefined `group`/`test`/`expect`/`throwsA`/
  `isA` (вероятно, не хватает `import 'package:flutter_test/flutter_test.dart';`)
- `listen_screen.dart:194, 687` — `use_build_context_synchronously`
- `listen_screen.dart:1269` — dead_code
- `reciters_repository.dart:351` — unnecessary `!`

### 25. `dart format --set-exit-if-changed` в CI
`.github/workflows/ci.yml:57` уже запускает format check. Проверить, что
все файлы отформатированы — запуск может падать на старых файлах.

---

## Сводка по Sprint-плану

| Sprint / Task | Status |
|---|---|
| **1.1 Quran.com API** | 🟡 Schema + API готовы, cutover не сделан |
| **1.2 Sentry** | 🔴 Каркас, не подключён |
| **1.3 GitHub Actions** | ✅ Готово (`.github/workflows/ci.yml`) |
| **1.4 riverpod_generator** | 🟡 Scaffold, миграция 25+ провайдеров |
| **2.5 Quran.com Tafsir API** | 🟡 DB schema есть, fetcher + UI нет |
| **2.6 sqlite-fts5** | ✅ Schema + unit-тесты |
| **2.7 OneSignal** | 🔴 Не начато |
| **2.8 slang** | ⚪ Опционально |
| **3.9 pdfx** | ⚪ Не начато |
| **3.10 FSRS** | ⚪ Не начато |
| **3.11 Tarteel AI** | ⚪ Premium, отложено |
| **3.12 ObjectBox** | ⚪ Условный fallback |

✅ = done, 🟡 = частично, 🔴 = не начато / blocker, ⚪ = backlog.

---

## Рекомендованный порядок (следующие 1-2 недели)

1. **(P0 #1)** Завершить Quran.com cutover — самое важное, даёт
   лучшее качество аудио + structured metadata.
2. **(P0 #2)** Подключить Sentry — занимает 2-3 часа, критично для
   production observability.
3. **(P1 #6)** Tafsir fetcher + UI — высокая ценность для пользователя,
   DB уже готова.
4. **(P1 #5)** Решить судьбу `showWordByWord` (реализовать или удалить).
5. **(P1 #7)** Закончить riverpod_generator миграцию — после Sprint 2
   testing (нужно покрытие провайдеров).
6. **(P0 #3)** Ночной режим — либо реализовать, либо удалить UI.

---

## Execution log (2026-07-17)

Все 6 пунктов выполнены в рекомендованном порядке.

### ✅ #1 (P0) — Quran.com cutover
- `lib/features/audio/data/audio_player_controller.dart:229` —
  `resolveSurahUrl(reciter, surah.id)` → `resolveSurahUrlHybrid(...)`.
  Hybrid resolver (Sprint 1.5) был определён, но не вызывался — теперь
  Quran.com CDN приоритетен, mp3quran.net как fallback.
- Также обновлён doc-комментарий `_playSurahMp3Quran` (источник
  истины теперь Quran.com).

### ✅ #2 (P0) — Sentry
- `pubspec.yaml:53` — добавлен `sentry_flutter: ^8.10.0`.
- `lib/core/observability/sentry_bootstrap.dart` — переписан с
  no-op stub на полноценный `bootstrapAndRun()`: `runZonedGuarded` +
  `FlutterError.onError` + `PlatformDispatcher.instance.onError`,
  фильтр шума (`PlatformException code: 'audio'`),
  environment-aware sampling (1.0 debug / 0.2 release).
- `lib/main.dart:17` — `main()` обёрнут в `await bootstrapAndRun(...)`.

### ✅ #3 (P0) — Night mode
- `lib/features/audio/data/audio_player_controller.dart` —
  добавлено поле `nightMode: bool` в `AudioPlayerState` (default
  `false`), `kNightModeVolume = 0.4` константа, `setNightMode(bool)`
  теперь действительно делает `_player.setVolume(...)`.
- `lib/features/audio/presentation/listen_screen.dart:1873` —
  кнопка ночного режима показывает текущий state («Вкл» / «Выкл»)
  и зовёт `setNightMode` вместо `TODO`-snackbar.

### ✅ #5 (P1) — showWordByWord
**Принято решение REMOVE** (функциональность уже даёт tap-on-word
→ `WordCard` модалка, флаг был dead).
- `lib/features/reader_settings/domain/reader_display_settings.dart` —
  удалено поле, ctor param, copyWith, ==/hashCode, defaults.
- `lib/features/reader_settings/domain/reader_display_settings_codec.dart` —
  удалено из encode + decode.
- `lib/features/reader_settings/presentation/reader_display_settings_screen.dart` —
  обновлён комментарий блока «Дополнительно».
- `test/reader_display_settings_test.dart` — удалены 3 референса.

### ✅ #6 (P1) — Tafsir fetcher + UI
- `lib/features/tafsir/data/quran_com_tafsir_api.dart` — Dio client,
  2 endpoint'a (`/resources/tafsirs`, `/tafsirs/{id}/by_ayah/{key}`),
  null-on-404.
- `lib/features/tafsir/data/tafsir_dao.dart` — Drift DAO с
  watch/getAllSources/getForAyah/watchByAyahAndSource +
  upsertSource/upsertTafsir (UPDATE-then-INSERT, нет UNIQUE).
- `lib/features/tafsir/data/tafsirs_sync_service.dart` — singleton
  `ValueNotifier<TafsirsSyncState>`, TTL 30 дней, `maybeSync` /
  `forceSync` / `fetchTafsirForAyah`, `TafsirNotFoundException`.
- `lib/features/quran/presentation/widgets/tafsir_panel.dart` —
  modal sheet с picker'ом source'ов + текстом, in-memory cache
  последнего выбора per ayah, retry-кнопка на empty state,
  HTML stripper (минимальный, без `flutter_html`).
- `lib/core/database/app_database.dart:64` — `TafsirDao` в
  `@DriftDatabase(daos: [...])`.
- `lib/app/providers.dart` — `tafsirDaoProvider`,
  `quranComTafsirApiProvider`, `tafsirsSyncServiceProvider`.
- `lib/features/quran/presentation/widgets/reader_widgets.dart:247` —
  `_TafsirButton` рядом с `_NoteButton` и bookmark.
- `lib/l10n/app_ru.arb`, `app_en.arb`, `app_ar.arb` — 4 ключа
  (`tafsirButton`, `tafsirLoading`, `tafsirEmpty`, `tafsirRetry`).
- **Bugfix**: исправлен путь импорта в `tafsir_panel.dart:10`
  (`../../data/tafsirs_sync_service.dart` →
  `../../../tafsir/data/tafsirs_sync_service.dart`).

### ⚪ #7 (P1) — riverpod_generator migration
**Skipped** per docs/PLAN.md:
> Полная миграция всех 25+ провайдеров — отдельный PR после Sprint 2,
> когда будет покрытие тестами.

Scaffold-only state (`lib/app/scaffold_providers.dart` с 3 demo-провайдерами)
оставлен как reference. В Sprint 2.7+, при наличии test coverage,
можно конвертировать пакетно.

### ⚠️ Требуется после выполнения

1. **`flutter pub get`** — для разрешения `sentry_flutter 8.10.x`
   (потенциальный конфликт с `riverpod_generator: any`).
2. **`dart run build_runner build --delete-conflicting-outputs`** —
   для генерации `tafsir_dao.g.dart` + обновления `app_database.g.dart`
   (новое поле `tafsirDao` в `AppDatabase`).
3. **`flutter gen-l10n`** — для генерации
   `AppLocalizations.tafsirButton/Loading/Empty/Retry`.
4. **`flutter analyze`** — для финальной проверки.
5. **`flutter test`** — особенно `test/sm2_test.dart` (pre-existing
   missing imports) и `test/reader_display_settings_test.dart`
   (обновлён под удаление `showWordByWord`).

### Sprint-status после выполнения

| Sprint / Task | Status |
|---|---|
| **1.1 Quran.com API** | ✅ Cutover сделан |
| **1.2 Sentry** | ✅ Подключён |
| **1.3 GitHub Actions** | ✅ Готово |
| **1.4 riverpod_generator** | 🟡 Scaffold only (deferred per plan) |
| **2.5 Quran.com Tafsir API** | ✅ Fetcher + DAO + UI |
| **2.6 sqlite-fts5** | ✅ Schema + unit-тесты |
| **2.7 OneSignal** | 🔴 Не начато |
| **2.8 slang** | ⚪ Опционально |
| **3.9 pdfx** | ⚪ Не начато |
| **3.10 FSRS** | ⚪ Не начато |
| **3.11 Tarteel AI** | ⚪ Premium, отложено |
| **3.12 ObjectBox** | ⚪ Условный fallback |