# Quran App

Modern Offline-First Quran-приложение, реализующее архитектуру из [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md).

## Статус

**MVP v0.1 (Чтение)** — реализован и собирается в debug-APK.

Реализовано:
- ✅ Тёмно-зелёная исламская тема с золотыми орнаментами (Cormorant Garamond / Inter / Amiri Quran)
- ✅ Drift-схема БД: все таблицы из архитектуры (Surahs, Ayahs, Words, WordTimings, Reciters, Translators, Translations, TafsirSources, Tafsirs, Bookmarks, Notes, LastPosition, ReadingHistory, LearningWords, AudioCacheMetadata, SettingsEntries)
- ✅ FTS5-индексы с нормализацией арабского (`ayahs_fts`, `translations_fts`, `words_fts`) + триггеры синхронизации
- ✅ Загрузка контента из API (Alquran.cloud) с манифестом и проверкой готовности
- ✅ Riverpod 2.x + go_router 14.x
- ✅ Локализация ru / en / ar с авто-определением языка системы при первом запуске
- ✅ Главный экран: приветствие, «Продолжить чтение», сетка функций
- ✅ Чтение: список сур → mushaf-страница с аятами, переводами, закладками
- ✅ Закладки: добавление/удаление, список с быстрым переходом
- ✅ Поиск: FTS5-поиск по аятам + режим «только суры»
- ✅ Настройки: язык, размер арабского шрифта, выбор перевода, аудио-кеш
- ✅ Заглушки для будущих MVP: Listen, Learn, Statistics, Tasbih, Hifz

## Структура проекта

```
lib/
├── main.dart                  # Точка входа
├── app/
│   ├── app.dart               # MaterialApp + темизация
│   ├── providers.dart         # Riverpod-провайдеры (DI)
│   └── router/                # go_router
├── core/
│   ├── theme/                 # Цвета, типографика, тема
│   ├── database/              # Drift-схема + DAO
│   ├── networking/            # Dio API client
│   ├── content/               # Манифест + bootstrapper
│   ├── search/                # ArabicNormalizer
│   ├── storage/               # SharedPreferences обёртка
│   └── common/                # Утилиты
├── features/
│   ├── home/                  # Главный экран
│   ├── quran/                 # Чтение (список сур + mushaf)
│   ├── bookmarks/             # Закладки
│   ├── search/                # Поиск
│   ├── settings/              # Настройки
│   ├── audio/                 # Заглушка (v0.2)
│   ├── learning/              # Заглушка (v0.3+)
│   ├── statistics/            # Заглушка (v0.3+)
│   ├── tasbih/                # MVP-реализация счётчика
│   ├── hifz/                  # Заглушка
│   └── onboarding/            # Диалог выбора языка
├── l10n/                      # ARB + сгенерированные локализации
└── shared/widgets/            # Орнаменты, кнопки, общие компоненты
```

## Запуск

```bash
flutter pub get
dart run build_runner build    # генерация Drift и .g.dart
flutter gen-l10n               # генерация локализаций
flutter run
```

Сборка APK:
```bash
flutter build apk --debug
```

## Стек

- **Flutter 3.44** / Dart 3.12
- **State**: flutter_riverpod 2.6
- **Routing**: go_router 14.6
- **DB**: drift 2.21 + sqlite3_flutter_libs
- **Network**: dio 5.7
- **i18n**: flutter_localizations (ARB)
- **Fonts**: google_fonts (Amiri Quran, Cormorant Garamond, Inter)
- **Audio**: just_audio (заготовка для v0.2)

## Содержимое

Текст Корана и переводы загружаются из [Alquran.cloud](https://alquran.cloud/api) при первом запуске:
- `quran-uthmani` — текст в письме Усмани
- `ru.kuliev` — перевод Кулиева (русский)
- `en.sahih` — Sahih International (английский)

После первой загрузки приложение работает полностью офлайн.

## Что дальше

См. [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md), разделы MVP v0.2 (аудио), v0.3 (слова, тайминги) и Phase 2+ (Hifz, статистика, spaced repetition, sync).

## Code review (июнь 2026)

Проведён локальный review с 6 параллельными sub-agents (security / performance / business logic / deploy safety / duplication / dead code). Применены исправления:

**CRITICAL (data layer):**
- Drift schema v2: UNIQUE на `(translations.ayah_id, translator_id)`, `(bookmarks.surah_id, ayah_id)`, `(reading_history.date, surah_id)`. autoIncrement на `translations.id`, `tafsirs.id`, `bookmarks.id`, `notes.id`, `learning_words.id` — устранена PK-коллизия синтетического `id = ayah_id*10+translator_id`.
- `recordReading` — атомарный `INSERT … ON CONFLICT(date, surah_id) DO UPDATE` (был race-prone SELECT+UPDATE/INSERT).
- `bookmarkDao.insertBookmark` использует `insertOrIgnore` — защита от дублей.
- Полный набор FTS-триггеров: добавлены `words_ad`/`words_au` и `translations_ad`/`translations_au` (раньше FTS рассинхронизировался бы при update/delete).
- `bootstrap()` guarded через `isReady()` + `manifestRepository.apply()` после успеха.
- `onUpgrade` стратегия: для v1→v2 — recreate (на dev-сборках БД пуста).

**WARNING (логика и UX):**
- `Bookmarks` получил колонку `ayahNumber`; UI/навигация используют её вместо глобального `ayahId` (раньше для суры ≥2 показывался неправильный ая́т).
- Закладки-стрим сведён к одному `bookmarkedAyahIdsProvider` (был фан-аут по одному StreamProvider на аят × 286).
- `FutureBuilder` в reader'е заменён на `FutureProvider.autoDispose.family` (нет re-fetch'а на каждом rebuild).
- Search debounce 250 мс через `Future.delayed` (был search-storm на каждом keystroke).
- `positionStreamProvider` теперь лайв (`await for` вместо `.first`) — карточка «Продолжить» обновляется после чтения.
- Bounded-concurrency HTTP-загрузка (`_Semaphore`, 4 параллельных запроса вместо 343 последовательных).
- Bootstrap-импорт разбит на 3 транзакции (surahs / ayahs / translators+translations) — не блокирует reader-стримы.

**Cleanup (de duplication / dead code):**
- Создан общий `lib/shared/widgets/coming_soon.dart`, удалены дубли в `learn_screen.dart`, `statistics_screen.dart`, `hifz_screen.dart`.
- Удалён `placeholder_screens.dart` с мёртвыми классами `AudioPlaceholderLearn`, `AudioPlaceholderStats`, `TasbihScreen`.
- Удалён неиспользуемый `SettingsDao` (и провайдер из DI).
- Удалены неиспользуемые DAO-методы (`getBySurah`, `getById`, `getTranslators`, `getAvailableLanguages`, `findByAyah`, `getAll` в bookmark).
- `ManifestRepo`: синхронный `current()`, `isCompatible(appVersion)` через semver, `apply()` теперь зовётся из bootstrap.

**Метрики после фиксов:** `flutter analyze` — 0 ошибок, 27 info-warning (стиль, не критично). `flutter build apk --debug` — 165 MB, ✓.
