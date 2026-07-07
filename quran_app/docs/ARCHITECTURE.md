# QURAN APP — ARCHITECTURE v2.2

## 1. Vision

Создать современное Quran-приложение с архитектурой Offline First, ориентированное на:

* чтение Корана;
* прослушивание аудио;
* изучение арабского языка через Коран;
* заучивание (Hifz);
* поиск по Корану;
* работу без постоянного подключения к интернету.

Приложение должно оставаться полностью функциональным даже при отсутствии сети.

---

# 2. Core Principles

## Offline First

Все основные функции должны работать без интернета:

* текст Корана;
* переводы;
* тафсиры;
* поиск;
* закладки;
* прогресс чтения;
* статистика;
* словарь слов;
* воспроизведение ранее скачанного аудио.

---

## Content Decoupling

Контент отделён от приложения.

Обновление:

* переводов;
* тафсиров;
* словарей;
* таймингов;
* аудио-конфигураций;

не требует публикации новой версии приложения.

---

## Modular Architecture

Каждая функция развивается независимо.

---

## Cache First

Любой загруженный контент сохраняется локально и используется повторно без сети.

---

# 3. Technology Stack

## Frontend

* Flutter 3.x

## State Management

* Riverpod 3.x

## Routing

* go_router

## Networking

* Dio

## Database

* Drift
* SQLite

## Search

* SQLite FTS5

## Audio

* just_audio
* audio_service

## Background Tasks

* workmanager

## Local Preferences

* shared_preferences — для простых пользовательских настроек (тема, размер шрифта и т.д.)

## Analytics

* Firebase Analytics (optional)

## Sync

* Firebase Authentication (optional)
* Firebase Firestore (optional)

---

# 4. High Level Architecture

```text
UI
│
├── Riverpod Providers
│
├── Features
│
├── Repositories
│
├── Local Database (Drift)
│
├── Local Audio Cache
│
└── Remote Content Sources
```

---

# 5. Project Structure

```text
lib/
│
├── core/
│   ├── database/
│   ├── networking/
│   ├── audio/
│   ├── search/
│   ├── storage/
│   └── common/
│
├── features/
│
│   ├── quran/
│   ├── audio/
│   ├── bookmarks/
│   ├── notes/
│   ├── search/
│   ├── learning/
│   ├── hifz/
│   ├── statistics/
│   ├── tasbih/
│   └── settings/
│
├── shared/
│
└── main.dart
```

---

# 6. Local Storage

Используется единое хранилище Drift.

Простые пользовательские настройки (тема, размер шрифта, выбранный чтец) хранятся через shared_preferences.

## Database Schema Version

```dart
@DriftDatabase(version: 1)
```

При изменении схемы используются явные миграции через Drift MigrationStrategy.

---

## Database Tables

### surahs

```text
id
name_ar
name_en
name_transliteration
revelation_type
ayah_count
order_in_mushaf
```

---

### ayahs

```text
id
surah_id
ayah_number
page
juz
hizb
text_uthmani
text_normalized        -- текст без харакат, для поиска
```

---

### words

```text
id
ayah_id
position
arabic
normalized             -- нормализованная форма без харакат
translation            -- базовый перевод слова (язык по умолчанию)
lemma
root
```

---

### word_timings

```text
id
word_id
reciter_id
start_ms
end_ms
```

---

### reciters

```text
id
slug                   -- например: 'mishari', 'sudais'
name_ar
name_en
style                  -- 'murattal' | 'mujawwad'
is_downloaded
```

---

### translators

```text
id
name
language_code
source
```

---

### translations

```text
id
ayah_id
translator_id
language_code
text
```

---

### tafsir_sources

```text
id
slug
name_ar
name_en
language_code
```

---

### tafsirs

```text
id
ayah_id
tafsir_source_id
text
```

---

### bookmarks

```text
id
surah_id
ayah_id
label               -- опциональный ярлык
color               -- опциональный цвет маркера
created_at
```

---

### notes

```text
id
ayah_id
text
created_at
updated_at
```

---

### last_position

```text
surah_id
ayah_id
page
updated_at
```

Хранит единственную последнюю позицию чтения.

---

### reading_history

```text
id
date                -- дата (YYYY-MM-DD)
surah_id
ayahs_read          -- количество прочитанных аятов за сессию
```

Используется для подсчёта статистики и стрика.

---

### learning_words

```text
id
word_id
status              -- 'new' | 'learning' | 'review' | 'mastered'
ease_factor         -- коэффициент лёгкости (SM-2, default: 2.5)
interval_days       -- текущий интервал повторения в днях
repetitions         -- количество успешных повторений подряд
next_review_at      -- дата следующего повторения
last_review_at      -- дата последнего повторения
```

---

### audio_cache_metadata

```text
id
reciter_id
surah_id
file_path
file_size_bytes
downloaded_at
last_played_at      -- для LRU-вытеснения
```

---

### settings (EAV — только для расширяемых данных)

Простые настройки хранятся в shared_preferences.

Таблица settings используется только для хранения пользовательских данных, не описываемых фиксированной схемой (например, кастомные конфигурации):

```text
key
value
```

---

# 7. Search Architecture

Используется SQLite FTS5.

Поиск работает полностью офлайн.

## Арабский язык и нормализация

Арабский текст перед индексацией нормализуется:
* удаляются харакат (диакритические знаки);
* нормализуются формы букв (например, أ إ آ → ا);
* текст приводится к Unicode NFC.

Нормализованная форма хранится в `ayahs.text_normalized` и `words.normalized`.

## FTS5 таблицы

```sql
CREATE VIRTUAL TABLE ayahs_fts USING fts5(
  text_uthmani,
  text_normalized,
  content='ayahs',
  tokenize='unicode61'
);

CREATE VIRTUAL TABLE translations_fts USING fts5(
  text,
  content='translations',
  tokenize='unicode61'
);

CREATE VIRTUAL TABLE tafsirs_fts USING fts5(
  text,
  content='tafsirs',
  tokenize='unicode61'
);
```

## Поддерживаемые виды поиска

* арабскому тексту (с учётом нормализации);
* переводам;
* тафсирам;
* словам;
* корням;
* леммам.

Примеры:

```text
милость
терпение
جنة
رحم
```

---

# 8. Quran Module

## Возможности

* чтение Корана;
* навигация по сурам;
* навигация по джузам;
* навигация по страницам;
* выбор перевода;
* выбор тафсира;
* закладки;
* заметки;
* поиск.

---

## Работа со словами

Пользователь может нажать на любое арабское слово.

Открывается карточка слова:

```text
Слово
Перевод
Корень
Лемма

▶ Прослушать

Добавить в словарь
Найти все упоминания
```

---

# 9. Word Learning System

Для каждого слова доступны:

* перевод;
* корень;
* лемма;
* список вхождений;
* аудио слова.

---

## Алгоритм интервального повторения

Используется алгоритм SM-2:

```text
После ответа пользователя (0–5):
  если оценка < 3:
    repetitions = 0
    interval = 1
  иначе:
    если repetitions == 0: interval = 1
    если repetitions == 1: interval = 6
    иначе: interval = round(interval * ease_factor)
    repetitions += 1
  ease_factor = ease_factor + 0.1 - (5 - оценка) * 0.08
  ease_factor = max(1.3, ease_factor)
  next_review_at = today + interval
```

---

## Возможности

* личный словарь;
* избранные слова;
* интервальное повторение (SM-2);
* статистика изучения.

---

# 10. Audio Architecture

## Основная стратегия

1 MP3 = 1 сура

Пример:

```text
001.mp3
002.mp3
003.mp3
```

---

## Почему не по аятам

Преимущества:

* меньше файлов;
* быстрее загрузка;
* проще кеширование;
* меньше нагрузка на файловую систему.

---

# 11. Word Timings

Для каждой суры существует файл таймингов.

Пример:

```json
{
  "surah": 1,
  "reciter_id": "mishari",
  "ayahs": [
    {
      "ayah": 1,
      "start_ms": 0,
      "end_ms": 4500,
      "words": [
        {
          "index": 1,
          "start_ms": 0,
          "end_ms": 700
        }
      ]
    }
  ]
}
```

---

## Возможности

### Подсветка слов

Во время воспроизведения подсвечивается текущее слово.

---

### Воспроизведение слова

Пользователь нажимает слово.

Плеер:

```text
seek(start_ms)
play()
stop(end_ms)
```

---

### Повтор слова

```text
Repeat x3
Repeat x5
Repeat x10
```

---

### Повтор аята

Используются границы аята.

---

### A-B Repeat

Для заучивания.

---

# 12. Audio Sources

Архитектура не зависит от конкретного провайдера.

## Цепочка источников

```text
Primary CDN
↓
Backup CDN
↓
Archive.org
```

---

## Manifest Configuration

```json
{
  "audio_sources": [
    {
      "id": "primary",
      "url": "https://cdn.example.com/audio"
    },
    {
      "id": "backup",
      "url": "https://backup.example.com/audio"
    }
  ]
}
```

---

# 13. Progressive Download Audio Strategy

## Уточнение терминологии

Режим "Streaming" в данном приложении реализован как **Progressive Download**:

```text
Начать загрузку файла
↓
Как только буфер достаточен — начать воспроизведение
↓
Параллельно продолжать загрузку и кешировать
↓
По завершении загрузки файл сохраняется в кеш
```

Это позволяет начинать воспроизведение длинных сур (например, Аль-Бакара) без ожидания полной загрузки.

---

## Cache First алгоритм

```text
Проверить кеш
↓
Есть файл?
↓
Да → воспроизвести локально
↓
Нет
↓
Начать Progressive Download
↓
Воспроизвести по мере загрузки
↓
Сохранить в кеш по завершении
```

---

## Download Mode

Пользователь может заранее скачать:

* суру;
* джуз;
* чтеца;
* полный набор аудио.

---

# 14. Audio Cache Structure

```text
audio_cache/
│
├── mishari/
│   ├── 001.mp3
│   ├── 002.mp3
│   └── ...
│
└── sudais/
    ├── 001.mp3
    └── ...
```

---

## Storage Management

Управление дисковым пространством обязательно, так как полный набор аудио одного чтеца может занимать 500 MB — 2 GB.

```text
Настройки кеша:
- Максимальный размер аудио-кеша: настраивается пользователем
  (по умолчанию: 2 GB)
- Политика вытеснения: LRU по полю last_played_at
- При достижении лимита: автоматически удаляются наименее
  используемые файлы
```

UI экран управления загрузками отображает:

```text
Чтец          Размер        Действие
Мишари        512 MB        [Удалить]
Судайс        480 MB        [Удалить]
──────────────────────────────────────
Занято:       992 MB / 2 GB
```

---

# 15. Content Update System

## Manifest

```json
{
  "content_version": "2.2.0",
  "min_app_version": "1.0.0",
  "translations": [],
  "tafsirs": [],
  "audio_sources": [],
  "word_timings": []
}
```

Поле `min_app_version` позволяет избежать загрузки контента, несовместимого с текущей версией приложения.

---

## Update Flow

```text
Launch App
↓
Check Manifest
↓
New Content?
↓
Check min_app_version compatible?
↓
Download
↓
Verify SHA256
↓
Verify Signature (ED25519)
↓
Backup old version
↓
Activate
↓
[При ошибке активации] → Rollback к предыдущей версии
```

---

# 16. Security

## Integrity

Каждое обновление содержит:

```text
SHA256
```

---

## Signature

Используется:

```text
ED25519
```

---

## Проверка

```text
Download
↓
Verify SHA256
↓
Verify Signature
↓
Activate
```

---

## Rollback

При неуспешной верификации или ошибке активации:

```text
Удалить загруженный файл
↓
Восстановить предыдущую версию контента
↓
Уведомить пользователя
```

---

# 17. Error Handling

## Аудио

```text
Ошибка загрузки файла:
  → Переключиться на следующий источник в цепочке CDN
  → Если все источники недоступны → показать сообщение пользователю
  → Если есть кешированная версия → воспроизвести её

Повреждённый файл кеша:
  → Удалить файл из кеша
  → Повторить загрузку
```

## База данных

```text
Ошибка миграции:
  → Логировать ошибку
  → Предложить пользователю сброс данных (с предупреждением)

Недостаток места на устройстве:
  → Уведомить пользователя
  → Предложить очистить аудио-кеш
  → Остановить загрузку
```

## Cloud Sync

```text
Конфликт данных при синхронизации:
  Закладки и заметки → Merge (объединение, обе версии сохраняются)
  Настройки          → Last Write Wins (побеждает последнее изменение)
  Прогресс чтения    → Last Write Wins (сервер приоритетнее при конфликте)
  Словарь слов       → Merge (объединение)
```

---

# 18. Optional Cloud Sync

Не требуется для работы приложения.

---

## Синхронизируются

* закладки;
* заметки;
* прогресс чтения;
* словарь пользователя;
* настройки.

---

## Offline Mode

При отсутствии аккаунта приложение работает полностью локально.

---

# 19. Statistics

Подсчитываются:

* дни чтения;
* количество прочитанных аятов;
* количество изученных слов;
* количество прослушанного аудио;
* текущий стрик;
* самый длинный стрик.

Данные для статистики берутся из таблицы `reading_history`.

---

# 20. Hifz Module

Поддержка:

* повторов;
* A-B Repeat;
* тестирования;
* контроля прогресса.

---

# 21. Tasbih Module

Функции:

* цифровой тасбих;
* цели;
* история;
* статистика.

---

# 22. MVP Scope

MVP разбит на итерации для управляемой разработки.

## MVP v0.1 — Чтение (2–3 месяца)

* Mushaf (текст утхмани);
* 1 встроенный перевод;
* навигация по сурам и джузам;
* закладки;
* базовый поиск по тексту и переводу.

## MVP v0.2 — Аудио (+ 1–2 месяца)

* потоковое воспроизведение аудио;
* выбор чтеца;
* загрузка аудио для офлайн-воспроизведения;
* управление аудио-кешем.

## MVP v0.3 — Слова (+ 1–2 месяца)

* word timings и подсветка слов;
* карточки слов (перевод, корень, лемма);
* личный словарь;
* воспроизведение отдельного слова.

---

# 23. Future Roadmap

## Phase 2

* Hifz
* Statistics
* Cloud Sync

## Phase 3

* Spaced Repetition (SM-2)
* Advanced Learning

## Phase 4

* Community Features
* Shared Collections
* Study Groups

---

# 24. Summary

Архитектура строится вокруг принципов:

* Offline First
* Cache First (Progressive Download для аудио)
* Content Decoupling
* Word-Level Learning
* Drift + SQLite
* FTS5 Search с нормализацией арабского текста
* Audio Word Timings
* SM-2 Spaced Repetition
* LRU Audio Cache Management
* ED25519 + SHA256 Content Integrity
* Rollback при ошибках обновления контента

Цель приложения — не только чтение и прослушивание Корана, но и глубокое изучение каждого слова, арабского языка через контекст Корана, и поддержка заучивания наизусть.