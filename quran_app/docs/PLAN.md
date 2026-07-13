# План развития quran_app — 3 спринта

Создан: 2026-07-13. План пересмотрен после обсуждения с пользователем.

## Sprint 1 (1-2 недели) — Базовая гигиена + content source

| # | Задача | Цель |
|---|---|---|
| 1 | Подключить **Quran.com API** для аудио | Заменить mp3quran.net (HTML парсинг). Official API, structured metadata, тайминги аятов для подсветки, 30+ ректоров HD |
| 2 | **Sentry** crash reporting | Заменить `developer.log` в release (где он не работает). Production crash visibility |
| 3 | **GitHub Actions** с `subosito/flutter-action` | CI гигиена: APK build + analyze + tests на каждый PR |
| 4 | **riverpod_generator** migration | Mechanical refactor: убрать boilerplate `final fooProvider = Provider(...)` → `@riverpod` annotation |

## Sprint 2 (2-4 недели) — Content depth + infra

| # | Задача | Цель |
|---|---|---|
| 5 | **Quran.com Tafsir API** (90 источников) | Кнопка "тафсир" в AyahPanel, отображение Ibn Kathir / Jalalayn / Maududi на 16 языках |
| 6 | **sqlite-fts5** virtual table | Полнотекстовый поиск с BM25 ranking — заменить `LIKE '%query%'` |
| 7 | **OneSignal** push (verse-of-the-day) | Daily ayah push notification в удобное время |
| 8 | **slang** миграция (или skip) | Type-safe localization вместо gen-l10n |

## Sprint 3 (4-8 недель) — intelligent features

| # | Задача | Цель |
|---|---|---|
| 9 | **Mushaf PDF rendering** через `pdfx` | Отрисовка страниц KFGQPC Mushaf Madinah |
| 10 | **FSRS memorization** engine | Anki-style spaced repetition для заучивания сур |
| 11 | **Tarteel AI** recitation verification | Real-time распознавание чтения пользователя |
| 12 | **ObjectBox** миграция (если FTS5 не хватит) | В 10x быстрее drift на больших объёмах |

## Текущий стек (baseline)

- Flutter 3.44.3 + Dart 3.12.2
- flutter_riverpod 2.6.1, go_router 14.6.2
- dio 5.7.0, drift 2.21.0
- just_audio 0.9.42, audio_service 0.18.18
- flutter_skill (deprecated, replaced by Arenukvern/mcp_flutter server-only)
- mp3quran.net (HTML парсинг) — заменяем в Sprint 1

## Дополнительные рекомендации (см. полный список в чате)

| Tier | Категория | Рекомендация |
|---|---|---|
| Tier 1 | Audio | **Quran.com API** ✅ Sprint 1 |
| Tier 1 | Monitoring | **Sentry** ✅ Sprint 1 |
| Tier 1 | CI/CD | **GitHub Actions** ✅ Sprint 1 |
| Tier 1 | Tafsir | **Quran.com Tafsir API** ✅ Sprint 2 |
| Tier 2 | State | **riverpod_generator** ✅ Sprint 1 |
| Tier 2 | Search | **sqlite-fts5** ✅ Sprint 2 |
| Tier 2 | i18n | **slang** (опционально) — Sprint 2 |
| Tier 3 | Mushaf | **pdfx** + KFGQPC PDF — Sprint 3 |
| Tier 3 | AI | **Tarteel AI** (premium) — Sprint 3 |
| Tier 3 | Mem | **FSRS** algorithm — Sprint 3 |
| Backlog | Analytics | PostHog (self-hostable) |
| Backlog | Push | OneSignal ✅ Sprint 2 |
| Backlog | Backend | Supabase (если multi-device sync) |

## Прогресс

См. todo в чате для актуального статуса. Создан 2026-07-13, обновляется по мере выполнения.
