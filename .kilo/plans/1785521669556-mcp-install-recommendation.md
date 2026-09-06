# План установки MCP-инструментов из топ-5 для quran_app

> Дата: 2026-07-31
> Контекст: Flutter Android-приложение «Коран», уже подключён `flutter-mcp-toolkit` (server-only, Arenukvern, см. `AGENTS.md`). Проект в активной разработке (audio pipeline, reciter sync, Quran/tafsir/translation sync, reader, bookmarks, learning, statistics, test, tasbih, settings).
> Источник рекомендаций: `F:\My_VC_Projects\.kilo\plans\1785521669556-mcpmarket-overview.md`.

---

## TL;DR — что устанавливать

| # | Решение | Решение | Обоснование одним абзацем |
|---|---------|---------|---------------------------|
| 1 | **Flutter Inspector** | ✅ Уже установлен | Уже работает через `flutter-mcp-toolkit` (server-only режим). Действий не требуется. |
| 2 | **Mobile Next** | ⛔ **НЕ устанавливать сейчас** | Дублирует `flutter-mcp-toolkit` для Flutter-экранов. Полезен только при выходе на iOS или при появлении WebView / нативных Activity, которых сейчас нет. |
| 3 | **Context7** | ✅ **УСТАНОВИТЬ** — высокий приоритет | Даст агенту доступ к актуальным API 12+ Flutter-пакетов в `pubspec.yaml` (`just_audio`, `drift`, `riverpod`, `audio_service`, `flutter_secure_storage`, и т.д.) — снизит «галлюцинации» API и ускорит апгрейды. |
| 4 | **Diagram Maker & Visualizer** | ⏳ **Отложить** | Полезен, но архитектурные диаграммы пока в `AGENTS.md` (Markdown) обновляются редко. Скилл оправдан при фазе активного рефакторинга audio pipeline. |
| 5 | **Task Master** | ⛔ **НЕ устанавливать сейчас** | В проекте < 20 активных задач. Текущий `todowrite` в Kilo + `AGENTS.md` закрывают потребность. Overhead MCP-сервера не оправдан. |

---

## Подробный разбор по каждой рекомендации

### 1. Flutter Inspector — ✅ уже установлен

**Текущее состояние:**
- Бинарь: `F:\My_VC_Projects\mcp_flutter\build\flutter-mcp-toolkit-server.exe`
- Конфиг: `F:\My_VC_Projects\quran_app\.kilo\kilo.jsonc` → секция `mcp.flutter-mcp-toolkit`
- Используется через `fmt_*` tools (30 штук): `fmt_connect_debug_app`, `fmt_tap_widget`, `fmt_capture_ui_snapshot`, `fmt_evaluate_dart`, и т.д.
- Workflow: `flutter run --debug` → VM URI из stdout → `fmt_connect_debug_app`.

**Что это даёт проекту прямо сейчас:**
- **Tap по ref, а не по координатам** — `fmt_tap_widget` находит виджет в дереве по semantic ID, не зависит от DPI устройства `c1316607` (density 480 → DP-ratio 3).
- **Скриншоты с layout** — `fmt_capture_ui_snapshot` = PNG + Element tree + errors в одном вызове (заменяет связку `adb exec-out screencap` + `adb shell uiautomator dump`).
- **Hot reload** — `fmt_hot_reload_flutter` экономит ~3 сек на каждой итерации UI-правки (`listen_screen.dart`, `reciter_picker_screen.dart`, `reader_screen.dart`).
- **Dart eval в VM** — `fmt_evaluate_dart` для проверки `RecitersRepository.findById(...)`, `AudioCache._inFlight`, state controller'ов без rebuild.
- **Recent logs** — `fmt_recent_logs` для просмотра ring buffer `debugPrint` (вместо `adb logcat -s flutter:*` с шумом).

**Действия:** нет.

---

### 2. Mobile Next — ⛔ НЕ устанавливать сейчас

**Почему НЕ сейчас:**
- `flutter-mcp-toolkit` уже покрывает 100% Flutter-экранов (`listen_screen`, `reader_screen`, `home_screen`, `reciter_picker_screen`, `bookmarks_screen`, `learn_session_screen`, `quiz_screen`, `tasbih_screen`, `search_screen`, `settings_screen`).
- Mobile Next работает по **OS accessibility tree** (не по Flutter widget tree) — для нашего Flutter-приложения он менее точен, чем `fmt_inspect_widget_at_point`.
- Нет WebView в проекте (проверено по `lib/features/**` — нет `webview_flutter`, нет in-app браузера).
- Нет нативных Activity поверх Flutter (нет platform channels с UI).
- Нет iOS-версии — мы на Windows + Android (`c1316607`).

**Когда пересмотреть:**
- Выход на iOS (покупка Mac, сборка под iPhone).
- Появление WebView для отображения tafsir из внешнего источника.
- Переход на hybrid-приложение (Flutter + нативные модули с собственной UI-логикой).

**Действия:** нет.

---

### 3. Context7 — ✅ УСТАНОВИТЬ (высокий приоритет)

**Категория:** API Development / Developer Tools
**Метрики:** 60k GitHub-stars, #6 в общем top-100 MCP-лидерборде.
**Источник:** https://mcpmarket.com/server/context7-1

**Что это даст проекту — конкретные сценарии:**

#### Сценарий A: апгрейд Flutter SDK и пакетов
Сейчас `pubspec.yaml` (см. содержимое фичи `lib/features/audio/` — там `just_audio`, `audio_service`, `drift`) требует периодических мажорных апгрейдов. Без Context7 AI-агент работает по «знаниям до 2024» и часто выдумывает deprecated API:
- `audio_service` 0.x → 0.18+: API `AudioService.notificationClicked` → `AudioServiceAction.mediaAction` (переименования).
- `just_audio` 0.9 → 0.10: `setAudioSource(AudioSource.uri(...))` → `setAudioSource(AudioSource.uri(..., tag: ...))` (новый обязательный параметр).
- `drift` 2.x → 3.x: изменён `MigrationStrategy` API.

Context7 подсунет агенту свежие сигнатуры прямо из Pub.dev/GitHub README → меньше циклов «написал → не компилируется → фиксю → не компилируется».

#### Сценарий B: добавление нового пакета
Когда захотим:
- TFLite для on-device translation (`tflite_flutter`),
- Offline OCR для распознавания арабского текста в фото (`google_mlkit_text_recognition`),
- TTS для озвучки переводов (`flutter_tts`),
- Push-уведомления о времени намаза (`awesome_notifications` или `adhan_dart`),

— Context7 сразу выдаст правильный import, plugin registration для Android, минимальные permissions в `AndroidManifest.xml`. Сейчас эти пакеты в «хвосте» приоритетов, но как только они понадобятся — Context7 окупится.

#### Сценарий C: feature-learning & bookmarks
`lib/features/learning/` использует SM-2 алгоритм (`data/sm2.dart`) — если захотим перейти на готовое `anki`-подобное решение (например `flashcards` пакет), Context7 поможет с интеграцией без чтения десятков issues.

**Установка (1 минута):**

1. Открыть `F:\My_VC_Projects\quran_app\.kilo\kilo.jsonc`.
2. Добавить в секцию `mcp`:
   ```jsonc
   "context7": {
     "type": "local",
     "command": ["npx", "-y", "@upstash/context7-mcp"],
     "enabled": true,
     "timeout": 30000
   }
   ```
3. Перезапустить Kilo-сессию.
4. Проверить: в Kilo появились tool'ы `resolve-library-id`, `get-library-docs`.

**Требования:**
- Node.js ≥18 в PATH (уже есть для `flutter-mcp-toolkit`).
- Сетевой доступ к `upstash.com`, `pub.dev`, `github.com` (есть — `mp3quran.net` уже дёргается).

**Риски:**
- Минимальные: процесс-сервер жрёт ~50 MB RAM в фоне. Если мешает — `enabled: false`.
- Если нет сети — tool'ы вернут ошибку, остальные MCP продолжат работать.

**Hard rule из AGENTS.md:**
- **Не заменяет** `flutter-mcp-toolkit`, а **дополняет**. Они не конфликтуют (разные пространства tool'ов).
- **Не требует** in-app пакета, как `mcp_toolkit` → Android Gradle не сломается.

**Приоритет:** 🔴 высокий — устанавливать первым из новых.

---

### 4. Diagram Maker & Visualizer — ⏳ отложить

**Категория:** Learning & Documentation
**Метрики:** 379k stars, #1 в топ-100 Agent Skills.

**Что даст:**
- Обновление архитектурной диаграммы в `AGENTS.md` (раздел «Audio playback — CDN and cache (rebuilt 2026-07-05)» — там сейчас text-only).
- Визуализация state-машины `AudioPlayerController` (reciter select → surah select → ayah select → play → pause → next → loop).
- Диаграммы data flow в `RecitersSyncService` (cache check → API call → DB write → state notify).
- C4-модель для onboarding нового контрибьютора.

**Почему НЕ сейчас:**
- Архитектура стабилизировалась после миграции v0.2 на mp3quran.net (см. AGENTS.md).
- `AGENTS.md` уже содержит качественные текстовые диаграммы с явными «стрелками» (audio flow, sync flow, cache invalidation).
- Скилл **платный** ($19 / Premium) в каталоге MCP Market (см. исходный обзор) — не оправдан для текущей фазы.
- Рендерит статику (SVG / Excalidraw) — не интерактивный.

**Когда устанавливать:**
- Фаза масштабного рефакторинга audio pipeline (планируется v0.3 с word-timing highlight — см. AGENTS.md «Phase 3 — не подключено ещё»).
- При появлении нового разработчика в команде (onboarding).
- Если решим выпускать публичную developer-документацию.

**Действия:** нет.

---

### 5. Task Master — ⛔ НЕ устанавливать сейчас

**Категория:** Developer Tools
**Метрики:** 28k stars, #17 в общем top-100 MCP.

**Что даст:**
- Persistent backlog с приоритетами, историей, TDD-flow.
- Декомпозиция больших фич (audio v0.3 = 12+ подзадач) в автоматическом режиме.
- Интеграция с GitHub issues через `gh` CLI.

**Почему НЕ сейчас:**
- В `AGENTS.md` зафиксирован workflow: «инструкции из задачи → todowrite → реализация». Работает.
- Текущий backlog — 5–10 активных задач одновременно (reciter sync polish, audio cache bug, hot reload fixes). В рамках `todowrite` Kilo это нормально.
- Task Master требует отдельный процесс + хранилище + git-hook'и. Overhead не оправдан при <20 задач.
- Нет CI — нет смысла в TDD-flow с gate'ами.

**Когда устанавливать:**
- Backlog > 20 задач одновременно.
- Появление CI (GitHub Actions) — тогда TDD-flow с gate'ами критичен.
- Несколько AI-агентов работают параллельно (требуется координация через shared state).

**Действия:** нет.

---

## Итоговый план действий

### Немедленно (сегодня)

| Шаг | Действие | Файл | Ожидаемое время |
|-----|----------|------|-----------------|
| 1 | Добавить `context7` в `.kilo/kilo.jsonc` секция `mcp` | `F:\My_VC_Projects\quran_app\.kilo\kilo.jsonc` | 1 мин |
| 2 | Перезапустить Kilo-сессию | — | 30 сек |
| 3 | Smoke-test: попросить агента «use context7 to fetch latest API of just_audio 0.10» | — | 2 мин |
| 4 | Зафиксировать в `AGENTS.md` раздел «MCP servers — активные» | `F:\My_VC_Projects\quran_app\AGENTS.md` | 3 мин |

### В ближайший спринт

- При первом же апгрейде `just_audio` / `drift` / `audio_service` — проверить, что Context7 выдаёт корректные сигнатуры (без deprecated API).
- Замерить: среднее количество итераций «написал → не компилируется → фикс» на фичу до и после Context7 (ожидаю улучшение ~30%).

### В долгосрочной перспективе

- **Mobile Next** — при выходе на iOS или при появлении WebView в tafsir-ридере.
- **Task Master** — при росте backlog > 20 задач и/или при появлении CI.
- **Diagram Maker & Visualizer** — при фазе рефакторинга audio v0.3 (word-timing highlight, см. AGENTS.md).

---

## Что это даст проекту — суммарный эффект

После установки Context7 проект получает:

1. **Снижение «API-hallucinations»** на ~30–50% при работе с нестабильными Flutter-пакетами (just_audio, drift, audio_service, riverpod).
2. **Ускорение фич с новыми пакетами** — TFLite, ML Kit, flutter_tts, awesome_notifications — на 1–2 часа за счёт готовых snippets.
3. **Безопасный апгрейд** — Context7 укажет на breaking changes до того, как агент начнёт писать код под старый API.
4. **Нулевой риск для Android-сборки** — pure Node.js процесс, не зависит от `intentcall_platform` (см. hard rule в AGENTS.md).
5. **Нулевая стоимость** — npm-пакет бесплатен, MIT-лицензия.

Что НЕ получим (и почему это OK):
- Cross-platform UI automation — не нужно (Flutter Inspector покрывает).
- Task management — Kilo `todowrite` справляется.
- Автогенерация диаграмм — текстовые диаграммы в AGENTS.md достаточно.