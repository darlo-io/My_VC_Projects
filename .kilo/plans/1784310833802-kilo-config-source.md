# Kilo config: local vs global — разбор

**Дата**: 2026-07-17
**Сессия**: уточнение, какой `kilo.jsonc` активен в текущей сессии

## TL;DR

В текущей среде активен **глобальный конфиг** `C:\Users\007\.config\kilo\kilo.jsonc`.

Локальный `F:\My_VC_Projects\quran_app\.kilo\kilo.jsonc` существует, но
содержит только MCP-секцию (`flutter-mcp-toolkit`). Основные
permissions, agents, instructions и model — приходят из глобального.

По правилам Kilo: при наличии обоих — **локальный мержится в глобальный**
(git-style merge: ключи локального перекрывают соответствующие ключи
глобального). Эффективный конфиг = global ∪ local override.

## Глобальный конфиг — `C:\Users\007\.config\kilo\kilo.jsonc`

**Размер**: 84 строки, JSONC.

**Содержит:**

| Секция | Что в нём |
|---|---|
| `permission` | Плоский объект: `"bash": "allow"`, `"read": "allow"`, `"edit": "allow"`, `"glob": "allow"`, `"grep": "allow"`, `"list": "allow"`, `"task": "allow"`, `"external_directory": "allow"`, `"todowrite": "allow"`, `"webfetch": "allow"`, `"lsp": "allow"`, `"doom_loop": "allow"`, `"skill": "allow"`, `"todoread": "allow"` |
| `agent.architect` | mode `primary`, displayName «Architect», permissions: `read allow`, `edit` allow на всё + планы, `bash deny`, `question allow`, `mcp deny` |
| `agent.code` | Flutter-developer промпт (без permissions override) |
| `agent.debug` | Flutter-debug промпт |
| `agent.code-simplifier` | primary, refactor agent, `bash: allow`, `mcp: allow` |
| `agent.orchestrator` | `disable: true`, `hidden: true` |
| `agent.plan` | senior Flutter planning промпт |
| `instructions` | большой multi-line instruction list (Flutter/Dart rules) |
| `default_agent` | `"architect"` |
| `model` | `minimax-coding-plan/MiniMax-M3` |
| `small_model` | `minimax-coding-plan/MiniMax-M3` |
| `subagent_model` | `minimax-coding-plan/MiniMax-M3` |
| `subagent_variant_overrides` | `{"minimax-coding-plan/MiniMax-M3": "thinking"}` |
| `disabled_providers` | `[]` |
| `experimental.speech_to_text_model` | `openai/gpt-4o-mini-transcribe` |

## Локальный конфиг — `F:\My_VC_Projects\quran_app\.kilo\kilo.jsonc`

**Размер**: 13 строк.

**Содержит только:**

- `mcp.flutter-mcp-toolkit` — конфигурация MCP-сервера
  (Arenukvern/mcp_flutter v4.0.0-dev.6, бинарь по абсолютному пути,
  `--no-await-dnd`, timeout 30000).

Никаких `permission`, `agent`, `instructions` — всё это приходит
из глобального. Локальный файл нужен для project-specific MCP
(в `quran_app` это `flutter-mcp-toolkit`, см. также AGENTS.md).

## Что реально действует в этой сессии

Эффективный конфиг (global + local merge):

- **Permissions (плоские)**: `bash: allow`, `read: allow`,
  `edit: allow` и т.д. — все из глобального.
- **Agent mode**: `architect` (потому что `default_agent: "architect"`
  в global).
- **Architect permissions** (override на agent уровне):
  - `read: allow`
  - `edit`: allow на всё, плюс явно allow на `.kilo/plans/*.md`
    и `.opencode/plans/*.md`
  - `bash: deny` — **архитектор НЕ может запускать bash**
  - `question: allow`
  - `mcp: deny` — **архитектор НЕ может вызывать MCP `flutter-mcp-toolkit_fmt_*`**
- **Model**: `minimax-coding-plan/MiniMax-M3` с `thinking` variant.

## Почему `bash` через `background_process` был заблокирован

В моём предыдущем ответе я ошибочно предположил, что в конфиге
есть pattern-based permission с `action: "ask"`. **Это не так.**

Реальная причина отказа `background_process` — другая: policy-движок
Kilo посчитал `background_process` за bash-домен и применил
**agent-level override `bash: deny` для architect mode**.

То есть эта сессия работает в режиме `architect`, а у architect
явно запрещён bash. Чтобы запускать shell-команды, нужно либо:

1. Переключиться на другой agent (например, `code-simplifier`,
   у которого `bash: allow`) — но это зависит от того, как Kilo
   выбирает primary agent для сессии.
2. Временно отключить `bash: deny` в локальном `kilo.jsonc`.
3. Использовать только file-based tools (`read`, `write`, `edit`,
   `grep`, `glob`) — что и происходит сейчас.

## MCP-конфиг — где смотрим

`mcp` секция живёт **только в локальном** `quran_app/.kilo/kilo.jsonc`.
Если перенести проект на другую машину без этого файла — MCP
`flutter-mcp-toolkit` не поднимется (бинарь собирается локально
через `tools/dev/install-mcp-flutter.ps1`).

Рекомендация: задокументировать в README, что `.kilo/kilo.jsonc`
обязателен для quran_app.

## Hard rules (выводы из конфигов)

- **Architect не может bash/MCP** — это by design. Для runtime-работы
  использовать `code` или `code-simplifier` agents (см. global config),
  либо переопределить локально.
- **MCP `flutter-mcp-toolkit` живёт в локальном конфиге** — бинарь
  по абсолютному Windows-пути `F:\My_VC_Projects\mcp_flutter\build\…`.
  Не переносится между машинами без переустановки.
- **Модель зафиксирована** глобально на MiniMax-M3 — выбора нет.
- **`bash: deny` для architect** — главная причина, почему shell-проверка
  в этой сессии требует ручного запуска PowerShell через UI/CLI.

## TODO

- [x] Уточнить у пользователя, какой конфиг активен
- [ ] Если нужно проверять shell — переключиться на `code-simplifier`
      agent или снять `bash: deny` в локальном override
- [ ] Задокументировать в `quran_app/README.md`, что `.kilo/kilo.jsonc`
      обязателен для работы MCP
