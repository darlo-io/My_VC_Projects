# План оптимизации quran_app (аудит → пошаговое выполнение)

Дата: 2026-08-14. Источник: аудит текущего дерева (3d65aa2 + uncommitted).

## Результаты аудита (кратко)

### Стартап (main.dart → первый кадр)
1. Всё sequentially: `setPreferredOrientations` (await) → `SharedPreferences` → `AudioService.init` (до **8 s** блокирования на MIUI/XOS/EMUI, `main.dart:75,148`).
2. `handler.attach(...)` до runApp eagerly строит весь audio-подграф (`AppDatabase`, 2 API-клиента) — `main.dart:87`.
3. Router `ref.listen(contentReadyProvider)` открывает БД (LazyDatabase + миграции до v19) ещё до первого кадра — `app_router.dart:196`.
4. Каждый warm start: `_backfillMissingRussianSurahNames` — до **228 awaited UPDATE без транзакции** (`content_bootstrapper.dart:179-196`); `isReady()` дублируется (2× COUNT).
5. Каждый старт проходит через `/bootstrap` экран (redirect при `loading`).
6. Мёртвый код: `applyMigrations` в migrations.dart не вызывается; `appVersionProvider` не устанавливается.

### UI — «горячий» путь аудио (самое дорогое)
- `AudioPlayerController` пишет `state.copyWith(positionMs)` на **каждый тик** positionStream без троттлинга и без `==` у state → каскад rebuild на каждый тик: весь `ListenScreen` (`listen_screen.dart:77`), все 286 `_ArabicTextBody` в открытом Reader'е (eager Column!), `MiniPlayer`, инвалидация `wordTimingsForCurrentSurahProvider` → **DB-запрос таймингов всей суры на каждый тик**.
- `CurrentWordId` без `operator==` → нотификация каждого watcher'а каждый тик даже без смены слова.

### UI — reader (134 КБ)
- Список аятов НЕ ленивый: `SingleChildScrollView` + `Column` + eager-цикл (`reader_screen.dart:1797-1868`); book-режим собирает ~286 TextSpan в build на каждый rebuild (:1887-2154).
- `AyahTile.initState` — отдельный DB-запрос слов на каждый аят → 286 запросов при открытии Аль-Бакары (`reader_widgets.dart:88-98`).
- `_onScroll`: O(N) обход 286 GlobalKey на каждый тик (`:1675`); GlobalKey на каждый аят.
- `ValueKey('mushaf-…')` с `textWidthPercent` → полная размонтировка скролла при движении слайдера ширины (`:489-500`).
- **RepaintBoundary — 0 штук на весь lib/.**

### UI — listen
- Фильтр ~241 ректора + дедуп + сортировка в build на каждый keystroke (`listen_screen.dart:1391-1443`).
- `_groupByFavorite` вызывается в `itemBuilder` каждой строки → O(N²) при скролле (:1527-1532).
- `FutureBuilder(future: surahDao.getAll())` — future в build (:836).

### Размер приложения
- Шрифты в бандле (pubspec): ~4,8 МБ. Крупные: CormorantGaramond-Variable **1168 КБ**, Inter-Variable **856 КБ** — используются только для ru/en UI-текста; полный Unicode-охват не нужен.
- `Surah Name Color V4 .ttf` (1099 КБ) и `Juz Name.ttf` (123 КБ) лежат в assets/fonts, но **не в pubspec** — в бандл не попадают, можно удалить/перенести.
- Home-иконки: 7 PNG 66–152 КБ каждая (исходники 370×350 px) отображаются в боксах 20–64 dp; без `cacheWidth`. WebP + ресайз до 192 px дадут ~70–85% экономии (~550 КБ).
- `assets/icon/icon.png` (1088 КБ) — только для launcher-icon генерации, не в бандле (ок).
- Release: минификация R8 дефолтная для `flutter build apk`; подпись debug-ключом (TODO в build.gradle.kts — вне скоупа).

## Фазы выполнения (шаг за шагом, после каждого шага `flutter analyze` + тесты)

### Фаза A — стартап (низкий риск)
- **A1.** `main.dart`: параллелизация — `Future.wait` для orientations + prefs + audio handler; убрать await там, где порядок не важен.
- **A2.** `content_bootstrapper`: `_backfillMissingRussianSurahNames` — pre-check одним SELECT + одна транзакция вместо 228 await; убрать повторный `isReady()`.
- **A3.** `main.dart`: `setPreferredOrientations` — fire-and-forget (без await).
- **A4 (решение пользователя).** Полностью ленивый `AudioService.init` — после первого кадра/первого playback. Требует подтверждения.

### Фаза B — горячий путь аудио (главный видимый эффект)
- **B1.** `AudioPlayerController`: позиция не в StateNotifier state (отдельный лёгкий поток/ValueNotifier для позиций-тикетов); state только при реальных сменах (playing/ buffering/surah/error). Убрать DB-запрос таймингов каждый тик (`wordTimingsForCurrentSurahProvider` отвязать от audioPlayerControllerProvider).
- **B2.** `CurrentWordId` + `AudioPlayerState`: добавить значимые `operator==`/hashCode.
- **B3.** Слова: 1 запрос на суру + группировка по аятам вместо N запросов (`reader_widgets.dart`).
- **B4.** `listen_screen`: мемоизация фильтра/группировки (один раз, не в itemBuilder), FutureBuilder вне build.
- **B5.** RepaintBoundary: MiniPlayer, AyahTile, панели. `cacheWidth` для home-иконок.

### Фаза C — размер приложения
- **C1.** PNG home-иконки → WebP + ресайз 192 px (проверить наличие PIL/cwebp).
- **C2.** Шрифты Inter/Cormorant: subsetting под latin+cyrillic (pyftsubset), при наличии инструмента.
- **C3.** Удалить неиспользуемые `Surah Name Color V4 .ttf`, `Juz Name.ttf` из assets (вне бандла, порядок в репо).

### Фаза D — отложенное/крупное (не в этом проходе, фиксация)
- Ленивый рендер списка аятов (ListView.builder) — большой рефакторинг reader_screen.
- Разбиение reader_screen.dart на подвиджеты (из code review).
- Убрать GlobalKey-обход в `_onScroll` (вместе с ленивым рендером).
- `ValueKey('mushaf-…')` без textWidthPercent + мягкое применение ширины.
- Убрать мёртвый `applyMigrations`, починить `appVersionProvider`.

---

## Результаты выполнения (шаг за шагом, верифицировано)

### A — стартап
- **A1/A3** `main.dart`: orientations/prefs/`AudioService.init` теперь стартуют
  параллельно и await'ятся вместе (критический путь = max из трёх, а не сумма).
- **A2** `content_bootstrapper`: `_backfillMissingRussianSurahNames` — pre-check
  одним `COUNT` SELECT (раньше до 228 awaited UPDATE на каждый warm start);
  при наличии NULL — одна транзакция. Дубль `isReady()` убран:
  `ContentReadyNotifier.bootstrap()` передаёт уже известный результат.
- Попутно починен **синтаксический слом** незавершённого WIP-редизайна
  `reader_screen.dart` (несбалансированные скобки `_AnimatedTopBar`).

### B — горячий путь аудио/Reader
- **B1** `AudioPlayerController`: позиция квантуется до секунд перед записью в
  `StateNotifier` (`StateNotifier` + `operator==` ⇒ ≤1 нотификация/с вместо
  ~20/с). Точные тики — отдельный `positionStream`.
- **B2** `AudioPlayerState` и `CurrentWordId` получили значимые `==`/`hashCode`.
  `wordTimingsForCurrentSurahProvider` отвязан от тиков позиции (`.select` на
  surah/reciter) — убран DB-запрос таймингов на каждый тик.
  `currentWordIdProvider` → `StreamProvider` с `distinct()`: 286 `_ArabicTextBody`
  пересобираются на смене слова, а не каждый тик.
- **B3** Слова суры — один JOIN-запрос (`WordsDao.getBySurah`) + общий
  `wordsForSurahProvider` вместо N запросов в `AyahTile.initState`
  (Бакара: 286 запросов + 572 setState → 1 запрос). `AyahTile` стал
  `ConsumerWidget`.
- **B4** `_ReciterDropdownSheet`: группировка считается один раз за rebuild
  (убрано O(N²) в `itemBuilder`); попутно исправлен дубль выбранного ректора.
  `_SurahListSheet`: `FutureBuilder` future кэшируется в `initState`
  (раньше новый DB-запрос на каждый drag-frame).
- **B5** `RepaintBoundary`: MainScaffold/MiniPlayer, контент Reader'а в
  `_AnimatedControlsFrame`, `_AnimatedTopBar`. `cacheWidth` для home-иконок.

### C — размер приложения
- **C1** Home-иконки PNG→WebP + ресайз до 192 px: **711 КБ → 72 КБ**.
  Скрипт конверсии: `tool/optimize_home_icons.py`. Пути в `home_screen` обновлены.
- **C2** Шрифты: Inter-Variable (убрана ось opsz + сабсет latin/cyrillic)
  **856 → 402 КБ**; CormorantGaramond-Variable **1168 → 793 КБ**.
  Покрытие проверено: все 205 уникальных символов из `.arb` (ru/en) на месте;
  арабские глифы в оригиналах отсутствовали (fallback без регресса).
- **C3** Удалены неиспользуемые `Surah Name Color V4 .ttf`, `Juz Name.ttf`.

### Верификация
- `flutter analyze` — только pre-existing `info` (0 ошибок/warnings).
- `flutter test` — **+196 −24**, идентично baseline в HEAD
  (24 падения — pre-existing, проверено на чистом worktree@HEAD).
- Новый тест `test/words_by_surah_test.dart` (+4, зелёные).
- Smoke на устройстве (CPH2653): приложение стартует, Home рендерится без
  asset-ошибок, субсет-шрифты дают отличные от fallback метрики
  (TextPainter-проверка в VM), Reader в обоих режимах монтирует контент
  (286 аятов Бакары), `wordsForSurahProvider` отдаёт данные одним запросом,
  аудио-контроллер корректно обрабатывает error-state без крэша.

### Замечания / не сделано
- A4 (полностью ленивый `AudioService.init` после первого кадра) — **не
  применялся**: требует отдельного решения (см. вопрос по фазе A). Оставлен
  существующий 8s-таймаут, но теперь параллельно с остальным startup'ом.
- Воспроизведение аудио в smoke: CDN доступен с устройства (curl 200), но
  in-app загрузка вернула `(0) Source error` — вероятно, in-app DNS/DoH-стек
  на этом устройстве (pre-existing, не затронут изменениями). Error-state
  отработан корректно.
- Фаза D (ленивый рендер аятов, рефакторинг reader_screen) — сознательно
  отложена как крупная и рискованная.
