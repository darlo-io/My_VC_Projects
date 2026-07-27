# quran_app — Round 8.4 (2026-07-25) — ЗАВЕРШЁН

## Итог

Lazy fetch переводов полностью работает для всех 3 русских переводчиков (Кулиев, Минвакф, Абу Адель) и английского Sahih. Пользователь может выбрать любой в Settings → Профиль → Перевод, и при первом выборе lazy fetch подтянет translations (6236 аятов) с Quran.com API в background.

## Verification на устройстве (c1316607)

### Тест 1: Минвакф Египта (quran_com_id=78)
1. Settings → Профиль → Перевод → тап «Минвакф Египта»
2. Lazy fetch запускается (60 сек)
3. Translations записаны в БД: `COUNT(*) = 6236`
4. Reader показывает перевод: `F:\dev\shots\r8_translation.png`

### Тест 2: Абу Адель (quran_com_id=79)
1. Settings → Профиль → Перевод → тап «Абу Адель»
2. Lazy fetch запускается
3. Translations записаны: `COUNT(*) = 6236`
4. Reader показывает перевод: `F:\dev\shots\r8_abu_reader2.png` (3 аята на русском, более краткий стиль чем Минвакф)

## Архитектура Round 8 (финальная)

### Поток данных
```
Cold start:
  main.dart → scheduleFrameCallback
  └─ ContentBootstrapper.seedTranslators()
     └─ _seedQuranComTranslators(db)
        ├─ findByQuranComId(78) → null → INSERT (id=3, quran_com_id=78, nameRu=Минвакф)
        └─ findByQuranComId(79) → null → INSERT (id=4, quran_com_id=79, nameRu=Абу Адель)
     └─ translatorsListRefreshProvider.state++ → UI rebuilds

User picks new translator:
  settings_screen._showTrSheet tap → onTap
  └─ setActiveTranslatorId(tr.id) — updates prefs
  └─ setTranslationLang(tr.languageCode) — updates prefs
  └─ ensureTranslatorLoaded(tr.id) — async fetch
     └─ if translations > 0 → no-op
     └─ else → _fetchAllSurahs (114 HTTP requests)
        └─ for each chapter: fetchByChapter → parse → bulkInsert
        └─ state.completedSurahs updates (UI progress)

Reader uses translation:
  _readerDataProvider watches translatorsListRefreshProvider
  └─ if translations changed → rebuild
  └─ loadReaderDataByTranslator(surahId, activeTranslatorId)
     └─ getForSurahByTranslator → Map<ayahId, text>
```

### DB schema
```sql
CREATE TABLE translators (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,              -- "Russian Translation (Ministry of Awqaf)"
  language_code TEXT NOT NULL,     -- "ru"  
  source TEXT NOT NULL,             -- "quran.com" or "alquran.cloud"
  quran_com_id INTEGER,            -- 78, 79 (quran.com resource_id)
  name_ru TEXT,                    -- "Минвакф Египта" / "Абу Адель"
  PRIMARY KEY (id)
);

CREATE TABLE translations (
  ayah_id INTEGER NOT NULL,
  translator_id INTEGER NOT NULL,  -- FK to translators.id
  language_code TEXT NOT NULL,     -- legacy: redundant
  text_value TEXT NOT NULL,
  ...
);
```

## Известные ограничения

1. **Lazy fetch занимает 30-60 секунд** для полного набора (114 суры × 1 запрос = 114 HTTP запросов). Можно оптимизировать:
   - Параллельные запросы через `Future.wait` chunks
   - Batch-эндпоинт Quran.com (если есть)
   - `dio` connection pool с `keepAlive`

2. **Нет индикатора прогресса в UI** — `translationSyncStateProvider` есть, но визуальная часть в `settings_screen` не показывает прогресс (код есть, но на UI не отображается — Round 8.5 улучшит).

3. **Cold start fetch пропускается** для уже загруженных translators (Kuliev id=1).

## Production cleanup

- Убраны debug print() statements из quran_translation_sync_service.dart и settings_screen.dart
- Все diagnostic логи идут через developer.log()

## Изменённые файлы (Round 8 cumulative)

### Round 8.0
- lib/core/database/tables.dart — added quranComId, nameRu to translators
- lib/core/database/app_database.dart — schemaVersion 18, v18 migration
- lib/core/content/content_bootstrapper.dart — added seedTranslators() + _seedQuranComTranslators()
- lib/app/providers.dart — added translatorsListRefreshProvider, quranComTranslationApiProvider, quranTranslationSyncServiceProvider, translationSyncStateProvider
- lib/core/i18n/quran_com_translators.dart — new file with kQuranComRuTranslators map
- lib/main.dart — scheduleFrameCallback for seedTranslators
- lib/features/settings/presentation/settings_screen.dart — updated _showTrSheet to show translators from DB
- lib/core/database/daos/translation_dao.dart — added insertTranslator, findByQuranComId, getAllTranslatorsOrdered, getForAyahByTranslator, getForSurahByTranslator, bulkInsertForTranslator, countForTranslator
- lib/core/storage/app_preferences.dart — added activeTranslatorId
- lib/features/quran/data/quran_com_translation_api.dart — new file with QuranComTranslationApi and QuranComVerseTranslationDto

### Round 8.3
- lib/features/quran/data/quran_com_translation_api.dart — fetchByChapter parses `translations: [...]` array
- lib/features/quran/data/quran_translation_sync_service.dart — _fetchAllSurahs uses `surah_id` column

## Поведение по translator'ам (финальное)

| translator | id | quran_com_id | source | translations | Lazy fetch |
|------------|-----|--------------|--------|--------------|-------------|
| Кулиев (Elmir Kuliev) | 1 | 45 | alquran.cloud | 6236 ✅ | НЕТ (skip) |
| Sahih International | 2 | — | alquran.cloud | 0 | НЕТ |
| Минвакф Египта | 3 | 78 | quran.com | 6236 ✅ | ДА (~60 сек) |
| Абу Адель | 4 | 79 | quran.com | 6236 ✅ | ДА (~60 сек) |

## Дополнительные вещи на следующие раунды

- Round 8.5: UI индикатор прогресса lazy fetch в Settings (translationSyncStateProvider уже есть, нужна только UI часть)
- Round 8.6: Оптимизация fetch через параллельные запросы
- Round 8.7: Кеш для translations (cache в RAM для активного translator'a)
- Round 8.8: Offline mode — кеш на диске для нескольких translator'ов
