# MCPMarket.com — Обзор релевантных MCP-инструментов для quran_app

> Дата обзора: 2026-07-31
> Источник: [mcpmarket.com](https://mcpmarket.com) — каталог MCP-серверов и Agent Skills (334 110 скиллов, 41 251 сервер, обновлено в момент обзора).
> Контекст проекта: Flutter Android-приложение «Коран» с фичами audio playback (mp3quran.net), локальной БД (SQLite), двуязычным UI (ru/en/ar), уже подключённым `flutter-mcp-toolkit` (Arenukvern/mcp_flutter) в server-only режиме (см. `AGENTS.md`).

---

## 1. Методология отбора

Фильтры релевантности:
1. **Прямое соответствие домену проекта** — Flutter / Mobile / Dev workflow / Audio / Database.
2. **Метрики популярности** — GitHub-stars, позиция в top-100, упоминания на главной и в категориях.
3. **Готовность к интеграции** — наличие Windows-бинаря / npm / pip / Docker, активный репозиторий.
4. **Минимизация рисков** — не ломает Android-сборку (см. hard rule про `intentcall_platform` в `AGENTS.md`).

Из ~41k серверов и ~334k скиллов отобрано **15** наиболее релевантных (10 серверов + 5 скиллов), из которых **5** выделены как рекомендуемые.

---

## 2. Топ-15 релевантных решений

### 2.1 MCP-серверы

#### 1. **Flutter Inspector** (Arenukvern) — ⭐ РЕКОМЕНДОВАН
- **Категория:** Mobile Development / API Development / Developer Tools
- **Функционал:** Подключает Flutter-приложения к AI-ассистентам через MCP. Анализ widget tree, навигации, layout-проблем; скриншоты, RPC-методы, process discovery.
- **Преимущества / сценарии:**
  - У нас **уже используется** в server-only режиме (см. `AGENTS.md` → `flutter-mcp-toolkit`). 30 `fmt_*` tools в работе каждый день.
  - Заменяет adb input tap / screencap на widget-aware взаимодействие (ref-based).
  - Ускоряет отладку на устройстве `c1316607` в 5–10×.
- **Метрики:** 358 stars; единственный Flutter-специфичный сервер в top-категории Mobile Development.
- **Совместимость:** Flutter 3.x, Windows / macOS / Linux (AOT-бинарь `flutter-mcp-toolkit-server.exe`), Android debug-build.
- **Риски:**
  - In-app пакет `mcp_toolkit` ломает Android Gradle из-за upstream-бага в `intentcall_platform` (см. AGENTS.md, hard rule).
  - Release-mode игнорируется — только `flutter run --debug`.
  - In-memory `_inFlight` карты в `AudioCache` сбрасываются только через `am force-stop` (см. AGENTS.md «Stale state vs hot reload»).

#### 2. **Mobile Next** (mobile-next) — ⭐ РЕКОМЕНДОВАН
- **Категория:** Mobile Development / Web Scraping / Security & Testing
- **Функционал:** Платформо-агностичная автоматизация iOS/Android через accessibility snapshot + координаты со скриншотов. Без необходимости в CV-модели.
- **Преимущества / сценарии:**
  - Готовая альтернатива нашим `tools/dev/adb-helpers.ps1` для cross-platform автотестов.
  - Snapshot-driven: совместимо с подходом `flutter-mcp-toolkit` (ref → action).
  - NPM-пакет `@mobilenext/mobile-mcp` — ставится за 1 команду.
- **Метрики:** 5.7k stars; #89 в общем top-100 MCP.
- **Совместимость:** iOS + Android, Windows / macOS / Linux, Node.js ≥18.
- **Риски:**
  - Требует подключённого устройства с включённой accessibility-службой.
  - Не заточен под Flutter-семантику (работает по accessibility tree ОС) — для Flutter лучше `flutter-mcp-toolkit`, но как fallback на WebView / нативных экранах — отлично.

#### 3. **Appium** (appium) — для будущих E2E-тестов
- **Категория:** Mobile Development / Security & Testing / Developer Tools
- **Функционал:** Кросс-платформенная мобильная автоматизация Android + iOS (UiAutomator2, XCUITest), интерактивные сессии, AI-генерация локаторов, POM-шаблоны, генерация Java/TestNG тестов из естественного языка.
- **Преимущества / сценарии:**
  - Когда вырастем до CI-тестов: Appium в GitHub Actions на эмуляторе + MCP-обёртка = «AI пишет E2E, AI его запускает».
  - 120 GitHub-stars у самой обёртки `appium-mcp`, но Appium сам — индустриальный стандарт мобильного тестирования.
- **Метрики:** 443 stars на MCP-обёртке; npm `appium-mcp`.
- **Совместимость:** iOS + Android, macOS (для iOS), Windows / Linux для Android.
- **Риски:** Тяжёлая зависимость (Appium server, драйверы, Java JDK); избыточна для текущего размера проекта.

#### 4. **Android Control** (minhalvp) — кандидат на замену adb-helpers
- **Категория:** Mobile Development / Developer Tools / Security & Testing
- **Функционал:** Программный контроль Android через ADB: скриншоты, UI-анализ, выполнение команд, управление пакетами.
- **Преимущества / сценарии:**
  - Если `flutter-mcp-toolkit` не подключён — это fallback для «тапнуть / ввести текст / скриншот» через MCP.
  - Совместимо с нашим `adb -s c1316607` deviceId.
- **Метрики:** 789 stars; #10 в категории Mobile Development.
- **Совместимость:** Android only, Windows / macOS / Linux (нужен ADB в PATH).
- **Риски:** Дублирует функционал `adb-helpers.ps1`; имеет смысл только как MCP-обёртка для AI-агента.

#### 5. **iOS Simulator** (joshuayoes) — для будущей iOS-версии
- **Категория:** Mobile Development
- **Функционал:** Взаимодействие с iOS-симулятором: UI-инспекция, скриншоты, тапы.
- **Преимущества / сценарии:** Когда дойдём до iOS-сборки — автоматическая UI-проверка через AI.
- **Метрики:** 2.1k stars; #8 в Mobile Development.
- **Совместимость:** macOS only (Xcode-зависимость).
- **Риски:** Не применим на Windows-хосте; релевантен только при переезде на Mac.

#### 6. **Context7** (upstash) — ⭐ РЕКОМЕНДОВАН
- **Категория:** API Development / Developer Tools
- **Функционал:** Подтягивает актуальную документацию и примеры кода для LLM прямо из источника (Pub.dev, NPM, GitHub).
- **Преимущества / сценарии:**
  - Решает проблему «AI выдумывает API Flutter-пакетов»: подсовывает свежие сигнатуры.
  - Полезно при апгрейдах Flutter SDK, переезде на новые версии `just_audio` / `drift` / `riverpod`.
- **Метрики:** 60k stars; #6 в общем top-100 MCP.
- **Совместимость:** Любой MCP-клиент, npm `npx -y @upstash/context7-mcp`.
- **Риски:** Требует сетевого доступа к источникам; результат зависит от качества исходной документации.

#### 7. **GitHub** (github)
- **Категория:** API Development / Developer Tools
- **Функционал:** REST API GitHub: PR, issues, releases, CI workflows — через MCP.
- **Преимущества / сценарии:**
  - Автоматизация code review, выпуск релизов, ведение changelog.
  - В связке со скиллом `GH Issues Auto-Fixer` (см. ниже) — закрывает «issue → branch → fix → PR» без участия человека.
- **Метрики:** 32k stars; #13 в top-100.
- **Совместимость:** Любой MCP-клиент; нужны `GITHUB_TOKEN` права.
- **Риски:** Security — токен в конфиге; минимальные scopes обязательны.

#### 8. **Sentry** (MCP-100) — для production-мониторинга
- **Категория:** Developer Tools / Analytics & Monitoring / Deployment & DevOps
- **Функционал:** Чтение issues, stacktrace’ов, debugging-инфы из Sentry.io.
- **Преимущества / сценарии:**
  - Если внедрим Sentry (Flutter Sentry SDK), AI-агент сможет автоматически триажить креши на устройстве юзера.
- **Метрики:** 22 stars (молодой), но Sentry как продукт — стандарт.
- **Совместимость:** Sentry.io SaaS / self-hosted; любой MCP-клиент.
- **Риски:** Низкая зрелость MCP-обёртки; рекомендую подождать форка от Sentry-official.

#### 9. **Task Master** (eyaltoledano) — для AI-driven планирования
- **Категория:** Developer Tools
- **Функционал:** Структурированное управление задачами в AI-driven workflow: декомпозиция, TDD, приоритеты, интеграция с Claude.
- **Преимущества / сценарии:**
  - Когда задач станет больше 20 — заменит наш самопальный `todowrite` в Kilo полноценным task-board с историей.
- **Метрики:** 28k stars; #17 в top-100; #1 в категории Featured.
- **Совместимость:** Node.js, MCP-совместимый клиент.
- **Риски:** Overhead для маленького проекта; полезен с 30+ задач в backlog.

#### 10. **Playwright** (microsoft / executeautomation) — для web-части
- **Категория:** Developer Tools
- **Функционал:** Браузерная автоматизация для LLM: скриншоты, JS-выполнение, навигация.
- **Преимущества / сценарии:**
  - Не для текущего Flutter-приложения, но пригодится, если появится web-версия / admin-панель mp3quran-метаданных.
- **Метрики:** 36k stars (microsoft) / 5.6k (executeautomation) — оба в top-100.
- **Совместимость:** Chromium / Firefox / WebKit, Windows / macOS / Linux.
- **Риски:** Тяжёлая зависимость (~200MB браузеры); не релевантен сейчас.

---

### 2.2 Agent Skills

#### 11. **Diagram Maker & Visualizer** (openclaw) — ⭐ РЕКОМЕНДОВАН
- **Категория:** Learning & Documentation
- **Функционал:** Генерит SVG / HTML / Excalidraw диаграммы для архитектуры, потоков, обучающих концептов.
- **Преимущества / сценарии:**
  - В `AGENTS.md` уже есть диаграмма `tools/dev/` pipeline — этот скилл позволит обновлять её на лету через AI.
  - Полезен при ревью архитектуры `lib/features/audio/` (reciter sync, cache, player state machine).
- **Метрики:** 379k — #1 в top-100 Skills.
- **Совместимость:** Claude / Cursor / Codex.
- **Риски:** Результат — статичная картинка; не подменяет кодовую документацию.

#### 12. **GH Issues Auto-Fixer** (openclaw)
- **Категория:** Collaboration Tools
- **Функционал:** Автоматизирует полный цикл issue → sub-agent → fix → PR → review.
- **Преимущества / сценарии:**
  - В связке с `GitHub` MCP — закрывает мелкие баг-репорты без участия разработчика.
- **Метрики:** 330k — #2 в top-100.
- **Совместимость:** GitHub CLI; Claude / Cursor.
- **Риски:** Требует жёстких code-review gates (CODEOWNERS), иначе AI зальёт некачественный код.

#### 13. **React Code Fix & Linter** (facebook)
- **Категория:** Developer Tools
- **Функционал:** Авто-форматирование + lint перед коммитом.
- **Преимущества / сценарии:** Не применим напрямую (мы не на React), но концептуально — аналог для Flutter (`dart fix` + `flutter analyze` + `dart format`).
- **Метрики:** 243k — #4 в top-100.
- **Совместимость:** React-проекты; концепт переносим.
- **Риски:** Не релевантен проекту; упоминается как бенчмарк зрелости.

#### 14. **Ad Creative Engine** (Growth Lab, Premium $19)
- **Категория:** Marketing
- **Функционал:** Генерация рекламных креативов: углы, варианты, headlines, CTA, ranking test plan.
- **Преимущества / сценарии:**
  - Когда/если запустим монетизацию (Koran-приложение) — готовые ad-варианты под Meta / TikTok.
- **Метрики:** Premium $19; featured.
- **Совместимость:** Claude.
- **Риски:** Платный; не приоритет для MVP.

#### 15. **Parallel Agent Dispatch** (Shippers Studio, Premium $19)
- **Категория:** Productivity & Workflow
- **Функционал:** Fan-out 2+ независимых задач в параллельные subagents с merge-gate.
- **Преимущества / сценарии:**
  - Идеально для нашего `Kilo` workflow: 3+ подзадач = параллельный запуск вместо последовательного.
- **Метрики:** Premium $19; featured.
- **Совместимость:** Claude / Cursor.
- **Риски:** Платный; требует чётких contract'ов между subagent'ами.

---

## 3. Топ-5 рекомендаций с обоснованием

| # | Решение | Почему именно оно для quran_app |
|---|---------|--------------------------------|
| **1** | **Flutter Inspector** (Arenukvern) | Уже подключён и используется каждый день. Без него MCP-инспекция на устройстве `c1316607` невозможна. Закрывает 80% операционных задач: tap, скриншот, layout-debug, semantic snapshot, hot reload. Альтернатив нет. |
| **2** | **Mobile Next** | Лучший **fallback** для не-Flutter экранов (WebView в админке, нативные Android-диалоги). Кросс-платформенный (пригодится при выходе на iOS), accessibility-based — стабильнее координат. |
| **3** | **Context7** | Решает «AI-агент выдумывает API» при апгрейдах Flutter SDK и сторонних пакетов. 60k stars, #6 в top-100 — production-grade. Один `npx` — и ассистент видит свежий `just_audio` / `drift` / `riverpod` API. |
| **4** | **Diagram Maker & Visualizer** | #1 среди скиллов (379k). Обновляет архитектурные диаграммы (audio pipeline, reciter sync, MCP-интеграция) на лету через AI. Бесплатен, без зависимостей. |
| **5** | **Task Master** | Когда задач > 20 и понадобится persistent backlog с TDD-flow, приоритезацией и историей. 28k stars, проверен в продакшне. Заменяет ручной `todowrite` в Kilo структурированной системой. |

### Что НЕ рекомендую сейчас
- **Appium** — избыточен, пока нет CI-тестов; добавим при выходе на стадию «pre-release testing».
- **Sentry MCP** — обёртка слишком молодая (22 stars); ждём official или переходим на self-hosted Crashlytics.
- **iOS Simulator** — не на Mac, не применим.
- **Playwright** — нет web-части; вебморды для админки пока в планах.
- **Ad Creative Engine / Parallel Agent Dispatch** — платные; не критичны для текущей фазы.

---

## 4. Источники и ссылки

| Тип | URL |
|-----|-----|
| Главная каталога | https://mcpmarket.com |
| Каталог серверов (100 стр.) | https://mcpmarket.com/server |
| Top-100 серверов | https://mcpmarket.com/leaderboards |
| Top-100 скиллов | https://mcpmarket.com/tools/skills/leaderboard |
| Категория Mobile Development | https://mcpmarket.com/categories/mobile-development |
| Категория Developer Tools | https://mcpmarket.com/categories/developer-tools |
| Agent Skills | https://mcpmarket.com/tools/skills |
| Что такое MCP-сервер | https://mcpmarket.com/what-is-an-mcp-server |
| Flutter Inspector | https://mcpmarket.com/server/flutter-inspector |
| Mobile Next | https://mcpmarket.com/server/mobile-next |
| Appium | https://mcpmarket.com/server/appium |
| Android Control | https://mcpmarket.com/server/android-control |
| iOS Simulator | https://mcpmarket.com/server/ios-simulator |
| Context7 | https://mcpmarket.com/server/context7-1 |
| GitHub | https://mcpmarket.com/server/github-15 |
| Sentry | https://mcpmarket.com/server/sentry |
| Task Master | https://mcpmarket.com/server/task-master |
| Playwright (MS) | https://mcpmarket.com/server/playwright-5 |
| Diagram Maker & Visualizer | https://mcpmarket.com/tools/skills/diagram-maker-visualizer |
| GH Issues Auto-Fixer | https://mcpmarket.com/tools/skills/gh-issues-auto-fixer |
| React Code Fix & Linter | https://mcpmarket.com/tools/skills/react-code-fix-linter |
| Ad Creative Engine | https://mcpmarket.com/tools/skills/mp-ad-creative-engine-b43536f7 |
| Parallel Agent Dispatch | https://mcpmarket.com/tools/skills/mp-parallel-agent-dispatch-507d1582 |
| MCP Market Hub | https://mcpmarket.com/hub |
| Официальный протокол | https://modelcontextprotocol.io |

---

## 5. Следующие шаги (опционально)

1. **Подключить Context7** через `.kilo/kilo.jsonc` → ускорит работу AI по обновлению зависимостей.
2. **Оценить Mobile Next** в режиме совмещения с `flutter-mcp-toolkit` (для WebView / нативных диалогов).
3. **Спланировать миграцию** с `todowrite` Kilo на Task Master при достижении 20+ задач в backlog.
4. **Отслеживать** зрелость Sentry MCP — переключиться, как только появится official-версия.
