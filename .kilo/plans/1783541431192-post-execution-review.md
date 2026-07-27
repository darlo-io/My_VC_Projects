# quran_app — оставшиеся задачи (post-execution, 2026-07-17)

Snapshot незавершённых пунктов после выполнения предыдущего плана
`1783541431192-remaining-tasks.md` (2026-07-17, см. его «Execution log»).
6 из 6 запланированных пунктов выполнены. Этот файл — следующий срез.

---

## 🔴 P0 — Требуется запустить ДО следующего коммита

### 1. `flutter pub get` — разрешение `sentry_flutter`
**Файл**: `pubspec.yaml:53` (добавлен `sentry_flutter: ^8.10.0`).

Потенциальный конфликт с `riverpod_generator: any` (pubspec.yaml:74).
Агент по Sentry отметил:
> note: `sentry_flutter` 8.x ships its own `analyzer` constraint that
> may need careful resolution with `riverpod_generator: any` — if
> there's a conflict, pin `sentry_flutter` to a tighter version.

**Что сделать:**
```powershell
cd F:\My_VC_Projects\quran_app
flutter pub get
```
Если ошибка version-solving — пинить `sentry_flutter: ~8.10.0` или
`^8.9.0`. Если конфликт с `riverpod_generator` — это блокирует всю
оставшуюся работу (надо сначала развязать).

### 2. `dart run build_runner build --delete-conflicting-outputs`
**Зачем**: новые файлы без сгенерированных частей:
- `lib/features/tafsir/data/tafsir_dao.dart` → `tafsir_dao.g.dart`
- `lib/core/database/app_database.dart:64 TafsirDao` в `daos: [...]`
  → `AppDatabase.tafsirDao` accessor в `app_database.g.dart`

Без codegen `tafsirDaoProvider` (providers.dart:499) упадёт
с `Undefined name 'tafsirDao'` в `appDatabaseProvider`. UI не
скомпилируется.

### 3. `flutter gen-l10n`
**Зачем**: добавлены 4 ключа `tafsirButton / Loading / Empty / Retry`
в `app_ru.arb`, `app_en.arb`, `app_ar.arb`. Без gen-l10n обращения
`t.tafsirButton` и т.п. в `tafsir_panel.dart` упадут с
`Undefined name 'tafsirButton'` в `AppLocalizations`.

### 4. `flutter analyze` — финальная проверка
После pub get + build_runner + gen-l10n — прогнать analyze. Возможные
находки:
- `unawaited()` — `quran_com_tafsir_api.dart` импортирует `dio`, но
  не использует `unawaited`; проверить, нет ли fire-and-forget без
  обёртки.
- `use_build_context_synchronously` — `tafsir_panel.dart` использует
  `context` после `await`, обёрнуто в `if (!context.mounted) return;`
  и `if (!mounted)` — должно пройти lint, но проверить.
- `prefer_initializing_formals` в новых файлах (reciters_repository
  уже имеет это предупреждение, tafsir_dao — нет, но стоит глянуть).

### 5. `flutter test` — обновлённые тесты
**Файл**: `test/reader_display_settings_test.dart` обновлён
под удаление `showWordByWord` (агент P1 #5). Должен пройти.

Pre-existing issue (НЕ от текущего плана):
- `test/sm2_test.dart:134-156` — undefined `group/test/expect/throwsA/isA`,
  отсутствует `import 'package:flutter_test/flutter_test.dart';`.
  Это блокирует CI — починить ДО следующего PR.

---

## ⭐ P1 — Оставшиеся TODO в коде (3 штуки, было 4)

### 6. `_fallbackSurahs` возвращает `const []`
**Файл**: `lib/app/providers.dart:855-857`.

```dart
/// "find by root/transliteration" остаётся TODO (требует FTS5 UNINDEXED columns).
Future<List<SurahSearchHit>> _fallbackSurahs(String q, {int limit = 10}) async {
  return const <SurahSearchHit>[];
}
```

Поиск по `surahs.name_transliteration` и `words.root` не работает.
Вариант: добавить FTS5 UNINDEXED columns в `surahs_fts` и `words_fts`
(миграция v16+), либо написать LIKE-fallback. Тривиальная реализация
займёт ~30 минут; FTS5 UNINDEXED — полдня.

### 7. `resolveSurahUrlHybrid` — оставшийся TODO
**Файл**: `lib/features/audio/data/reciters_repository.dart:364`.

```dart
// TODO(Sprint 2): переписать через AsyncValue/FutureProvider.
String? resolveSurahUrlHybrid(Reciter reciter, int surahNumber) {
  return resolveQuranComSurahUrl(reciter.mp3quranId, surahNumber) ??
      resolveSurahUrl(reciter, surahNumber);
}
```

После cutover (P0 #1) функция используется (audio_player_controller
вызывает её), но TODO про AsyncValue-обёртку остался. Переписать в
`Provider<AsyncValue<String? Function(Reciter, int)>>` или
`FutureProvider.family<String?, (reciterId, surahNumber)>` —
зависит от того, нужна ли async-семантика (для fetch Quran.com reciter
если mp3quran-id отсутствует в `kMp3quranToQuranCom`).

### 8. `ContentManifest.apply` — нет rollback snapshot
**Файл**: `lib/core/content/content_manifest.dart:254`.

```dart
// TODO: сохранить предыдущие значения для rollback. Сейчас
// `rollback()` просто стирает все ключи
```

Минимальный fix: 5 строк в `_writeManifest` — перед записью нового
манифеста копировать `version / hash` в `previousVersion / previousHash`,
`rollback()` восстанавливает из них. ~30 минут.

---

## ⚪ P2 — Sprint backlog (из docs/PLAN.md)

### 9. Sprint 2.7 — OneSignal push (verse-of-the-day)
**Файл**: `docs/PLAN.md:21`. Не начато.
- `flutter pub add onesignal_flutter`
- Сервис с `DailyAyahScheduler`
- UI opt-in в Settings (Android notification channel + runtime permission)
- Backend: OneSignal server-side schedule, либо локальный
  `flutter_local_notifications` + WorkManager
- Effort: 1-2 дня (без iOS, который требует APNs ключей)

### 10. Sprint 2.8 — `slang` migration (опционально)
**Файл**: `docs/PLAN.md:22`. Помечен как опциональный.
gen-l10n (`AppLocalizations.of(context)`) работает; `slang` даёт
type-safe локализацию. Миграция ~250 ключей в 3 файлах — полдня
механической работы + codegen для проверки.

### 11. Sprint 3.9 — Mushaf PDF через `pdfx`
**Файл**: `docs/PLAN.md:27`. Не начато.
- PDF assets (KFGQPC Mushaf Madinah ~600 страниц) — лицензия
  и распространение надо уточнять отдельно.
- `pdfx` рендеринг, gesture-управление, параллельный просмотр
  с text-mode.
- Effort: 1-2 недели (включая PDF assets).

### 12. Sprint 3.10 — FSRS memorization
**Файл**: `docs/PLAN.md:28`. Не начато.
- Алгоритм FSRS (`fsrs` Dart package) + интеграция с `LearningDao`.
- UI: review-сессия с интервальным повторением, статистика.
- Effort: 1 неделя.

### 13. Sprint 3.11 — Tarteel AI recitation verification
**Файл**: `docs/PLAN.md:29`. Premium, отложено.
- API key + Tarteel SDK.
- Audio capture + recognition pipeline.
- Effort: 2-4 недели (плюс API costs).

### 14. Sprint 3.12 — ObjectBox migration (условный)
**Файл**: `docs/PLAN.md:30`. Не начинать без бенчмарков, показывающих
недостаточность Drift.

---

## ⚪ P3 — Test coverage gaps

### 15. Нет unit-тестов для `RecitersRepository`
`syncFromApi`, `resolveSurahUrlHybrid`, `setFavorite`, `applyNameOverrides`
без покрытия. Уже существующие integration-тесты
(`content_bootstrapper_test.dart`) косвенно покрывают syncFromApi.

### 16. Нет unit-тестов для `AudioPlayerController`
`setSpeed`, `setSleepTimer`, `setNightMode` (новое!), `playNext`,
`playPrevious` без покрытия.

### 17. Нет golden / snapshot тестов для Reader
`golden_toolkit` закомментирован в pubspec.yaml:85. Reader + новый
`_LandscapeSidebar` не имеют визуальных regression-тестов.

### 18. Нет unit-тестов для нового Tafsir модуля
- `QuranComTafsirApi.fetchSources / fetchByAyah` — сетевые mocks.
- `TafsirsSyncService.maybeSync / forceSync / fetchTafsirForAyah` —
  cache + sync state machine.
- `TafsirDao.upsertTafsir` — UPDATE-then-INSERT race condition.

### 19. Нет widget-тестов для `_LandscapeSidebar`
Добавлен в предыдущей сессии (landscape reader support). Без покрытия.

---

## ⚪ P3 — Документация / качество

### 20. `docs/mcp-migration.mdx` — отсутствует
**Файл**: `AGENTS.md:7`. Устаревший TODO — после удаления flutter-skill
остатков (2026-07-17) заметка неактуальна. Либо реализовать, либо
удалить упоминание.

### 21. `docs/PLAN.md:61` — ссылка на "todo в чате"
> См. todo в чате для актуального статуса.

Anti-pattern. Заменить на ссылку `docs/PLAN.md#sprint-status` или
просто удалить (статус уже здесь).

### 22. `flutter analyze` — pre-existing issues (не от текущего плана)
~441 issues, большинство:
- `test/sm2_test.dart` — undefined test helpers
- `lib/features/audio/presentation/listen_screen.dart` —
  `use_build_context_synchronously`, dead_code
- `lib/features/audio/data/reciters_repository.dart` —
  `prefer_initializing_formals`, unnecessary `!`

Низкий приоритет — не блокирует функциональность.

---

## ⚪ P3 — riverpod_generator migration (deferred)

### 23. Полная миграция 53 провайдеров в `app/providers.dart`
**Файл**: `lib/app/providers.dart`. Из `docs/PLAN.md:69` явно отложено:
> Полная миграция всех 25+ провайдеров — отдельный PR после Sprint 2,
> когда будет покрытие тестами.

Scaffold-only (`scaffold_providers.dart`, 3 провайдера) сохранён
как reference. Полная миграция требует:
- Конвертация 53 провайдеров с `Provider<T>` → `@riverpod`
- Update всех `ref.watch(xyzProvider)` call-sites — НЕ требуется,
  riverpod_generator сохраняет имена совместимыми
- Codegen + тесты
- Effort: 1-2 дня (механическая работа, но много файлов)

---

## Сводка по Sprint-плану (после execution 2026-07-17)

| Sprint / Task | Status |
|---|---|
| **1.1 Quran.com API** | ✅ Cutover сделан |
| **1.2 Sentry** | ✅ Подключён (требует pub get) |
| **1.3 GitHub Actions** | ✅ Готово |
| **1.4 riverpod_generator** | 🟡 Scaffold only (deferred) |
| **2.5 Quran.com Tafsir API** | ✅ Fetcher + DAO + UI (требует codegen) |
| **2.6 sqlite-fts5** | ✅ Schema + unit-тесты |
| **2.7 OneSignal** | 🔴 Не начато |
| **2.8 slang** | ⚪ Опционально |
| **3.9 pdfx** | ⚪ Не начато |
| **3.10 FSRS** | ⚪ Не начато |
| **3.11 Tarteel AI** | ⚪ Premium, отложено |
| **3.12 ObjectBox** | ⚪ Условный fallback |

✅ = done, 🟡 = частично, 🔴 = не начато / blocker, ⚪ = backlog.

---

## Рекомендованный порядок (следующие шаги)

1. **(P0 #1-5)** Запустить локально: `flutter pub get` →
   `dart run build_runner build --delete-conflicting-outputs` →
   `flutter gen-l10n` → `flutter analyze` → `flutter test`.
   Если есть ошибки version-solving, фиксить первым.
2. **(P1 #8)** `ContentManifest.apply` rollback snapshot — тривиальный
   fix, повышает надёжность content update.
3. **(P1 #6)** `_fallbackSurahs` — либо LIKE-fallback (30 мин),
   либо FTS5 UNINDEXED columns (полдня).
4. **(P1 #7)** `resolveSurahUrlHybrid` AsyncValue-обёртка — после
   того как базовый cutover стабилизируется.
5. **(P0 blocker)** `test/sm2_test.dart` — починить импорты
   (pre-existing, блокирует CI).
6. **(P3)** Документация cleanup — `PLAN.md:61`, `AGENTS.md:7`.
7. **(Sprint 2.7)** OneSignal push — если решим, что нужны notifications.
8. **(Sprint 3)** pdfx / FSRS / Tarteel — по запросу.