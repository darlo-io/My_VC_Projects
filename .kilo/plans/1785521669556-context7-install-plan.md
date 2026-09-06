# План установки и настройки Context7 MCP для quran_app

> Дата: 2026-07-31
> Цель: подключить `@upstash/context7-mcp` v3.2.5 как второй MCP-сервер в проекте (в дополнение к уже работающему `flutter-mcp-toolkit`).

---

## Предусловия (уже проверено)

| Проверка | Команда | Результат |
|----------|---------|-----------|
| Node.js в PATH | `node --version` | `v22.23.1` ✅ |
| npm в PATH | `npm --version` | `10.9.8` ✅ |
| npx в PATH | `npx --version` | `10.9.8` ✅ |
| Пакет в npm registry | `npm view @upstash/context7-mcp version` | `3.2.5` ✅ |
| Репозиторий | `repository.url` | `git+https://github.com/upstash/context7.git` ✅ |
| Сетевой доступ к npm/upstash/pub.dev/github.com | косвенно подтверждён (mp3quran.net, cdn.alislam.ru, pub.dev уже работают) | ✅ |

**Hard rule (из `AGENTS.md`):** Context7 — pure Node.js процесс, не зависит от `intentcall_platform` → Android Gradle **не сломается**. Установка безопасна.

---

## Шаги реализации

### Шаг 1. Обновить `.kilo/kilo.jsonc`

**Файл:** `F:\My_VC_Projects\quran_app\.kilo\kilo.jsonc`

**Текущее содержимое (13 строк):**
```jsonc
{
  "$schema": "https://app.kilo.ai/config.json",
  "mcp": {
    "flutter-mcp-toolkit": {
      "_comment": "Arenukvern/mcp_flutter v4.0.0-dev.6 — in-app integration через mcp_toolkit; бинарь собран из исходников (нет Windows release).",
      "type": "local",
      "command": ["F:\\My_VC_Projects\\mcp_flutter\\build\\flutter-mcp-toolkit-server.exe"],
      "args": ["--no-await-dnd"],
      "enabled": true,
      "timeout": 30000
    }
  }
}
```

**Новое содержимое (добавляем секцию `context7` после `flutter-mcp-toolkit`):**
```jsonc
{
  "$schema": "https://app.kilo.ai/config.json",
  "mcp": {
    "flutter-mcp-toolkit": {
      "_comment": "Arenukvern/mcp_flutter v4.0.0-dev.6 — in-app integration через mcp_toolkit; бинарь собран из исходников (нет Windows release).",
      "type": "local",
      "command": ["F:\\My_VC_Projects\\mcp_flutter\\build\\flutter-mcp-toolkit-server.exe"],
      "args": ["--no-await-dnd"],
      "enabled": true,
      "timeout": 30000
    },
    "context7": {
      "_comment": "Upstash Context7 v3.2.5 — свежие API-документация и примеры для Flutter-пакетов. Подтягивает сигнатуры just_audio/drift/audio_service прямо из источника.",
      "type": "local",
      "command": ["npx", "-y", "@upstash/context7-mcp"],
      "enabled": true,
      "timeout": 30000
    }
  }
}
```

**Изменения:**
- Добавлена запятая после закрывающей `}` блока `flutter-mcp-toolkit`.
- Добавлен блок `context7` с тем же шаблоном `type: "local"`, `enabled: true`, `timeout: 30000`.
- `command` — `npx -y @upstash/context7-mcp` (без `--` разделителя; формат совместим с текущим парсером Kilo).
- `_comment` — пояснение для будущих читателей (формат уже использован в `flutter-mcp-toolkit`).

**Важно:** `-y` в npx нужен, чтобы Kilo не блокировался на prompt «Need to install…». Если Kilo уже кешировал пакет — `-y` игнорируется без побочных эффектов.

---

### Шаг 2. Зафиксировать в `AGENTS.md`

**Файл:** `F:\My_VC_Projects\quran_app\AGENTS.md`

Добавить новый раздел сразу после раздела «MCP `flutter-mcp-toolkit` …» (после строки с hard rule «In-app `mcp_toolkit` пока не подключаем»).

**Вставить блок:**

```markdown
## MCP `context7` (Upstash) — документация и API Flutter-пакетов

**Active MCP** — `@upstash/context7-mcp` v3.2.5. Подтягивает актуальные сигнатуры
и примеры кода для LLM прямо из источника (Pub.dev, NPM, GitHub).

**Зачем:** снижает «API-hallucinations» агента при апгрейдах Flutter-пакетов
(`just_audio`, `drift`, `audio_service`, `riverpod`, и т.д.). Когда агент пишет
код под устаревший API — Context7 выдаёт текущую версию.

**Что НЕ делает:** не заменяет `flutter-mcp-toolkit` (разные пространства tool'ов).
Не требует in-app пакета → Android Gradle не ломается (pure Node.js процесс).

- **Пакет**: `npmjs.com/package/@upstash/context7-mcp`
- **MCP config** (`.kilo/kilo.jsonc`):
  ```jsonc
  "context7": {
    "type": "local",
    "command": ["npx", "-y", "@upstash/context7-mcp"],
    "enabled": true,
    "timeout": 30000
  }
  ```
- **Типичные tool'ы**: `resolve-library-id` (по имени пакета → Context7 ID),
  `get-library-docs` (по ID → markdown-документация + примеры).

### Использование

```text
# Агент по контексту сам понимает, когда звать Context7. Если нет — явно:
"Используй Context7, чтобы получить актуальный API just_audio 0.10.x"

# Или в коде:
"context7 resolve just_audio"           → получает Context7 ID (/just_audio/just_audio)
"context7 get-library-docs /just_audio/just_audio topic=audio_source"  → markdown
```

### Smoke test (без запуска приложения)

```powershell
$env:Path = "C:\Users\007\develop\flutter\bin;$env:Path"
# Проверяем, что npx скачает и запустит сервер:
npx -y @upstash/context7-mcp --help
# Ожидаем usage-инструкцию (не падение).
```

### Hard rules

- **Если `npx -y @upstash/context7-mcp` падает с `ENOTFOUND api.context7.com`** —
  проверь VPN/прокси (у нас активен Xray). Context7 не критичен для сборки
  (просто отключите `enabled: false` в `kilo.jsonc`).
- **Не вызывай `npx` без `-y`** — зависнет на prompt и заблокирует MCP-сессию.
- **`timeout: 30000`** в конфиге — соответствует дефолту Kilo. Если resolve идёт
  дольше (медленный интернет), подними до `60000`.
```

**Место вставки:** после раздела «## Maintenance» блока про `flutter-mcp-toolkit` и перед «## Using `flutter-mcp-toolkit` from Kilo» (если структура файла изменена — искать по заголовку `## Hard rules` первого MCP-блока).

---

### Шаг 3. Перезапустить Kilo-сессию

**Действие:** в текущей Kilo-сессии нажать `Ctrl+Shift+P` → «Kilo: Reload Window» (или закрыть/открыть сессию).

**Что произойдёт:**
1. Kilo прочитает обновлённый `.kilo/kilo.jsonc`.
2. Увидит две секции `mcp.*` → запустит оба сервера параллельно.
3. `flutter-mcp-toolkit` запустится из AOT-бинаря (мгновенно).
4. `context7` — `npx -y @upstash/context7-mcp` (5–15 сек на скачивание при первом запуске, далее из кеша npm).
5. В tool-palette Kilo появятся новые tool'ы с префиксом (например, `mcp_context7_resolve-library-id`).

**Если не появились:**
- Проверить `View → Output → Kilo` на ошибки парсинга `kilo.jsonc`.
- Убедиться, что запятая между блоками `mcp.*` корректна (trailing comma после последнего элемента JSONC допускается, но лучше без неё — текущая правка её не добавляет).

---

### Шаг 4. Smoke-test

**Тест 1 — без сети на устройство:**

В чате Kilo ввести:
```
Используй Context7, чтобы получить текущий API метода setAudioSource в just_audio
```

**Ожидаемый результат:**
- Kilo вызывает `resolve-library-id` (или сразу `get-library-docs`).
- Возвращает markdown-блок с актуальной сигнатурой `setAudioSource(AudioSource source, {bool? initialPos, ConcatenatingAudioSource? replaceAll})` или эквивалент для текущей версии.
- Код ниже использует именно эту сигнатуру, без deprecated `setUrl`.

**Тест 2 — проверка невмешательства в flutter-mcp-toolkit:**

В чате Kilo ввести:
```
Tap по кнопке play в mini_player (через flutter-mcp-toolkit)
```

**Ожидаемый результат:**
- Kilo использует `fmt_tap_widget` (от `flutter-mcp-toolkit`), не путает с Context7 tool'ами.
- Оба MCP сосуществуют без конфликтов.

**Тест 3 — изоляция при сбое:**

Отключить интернет → попросить Kilo «resolve audio_service через Context7».

**Ожидаемый результат:**
- Context7 tool вернёт ошибку ENOTFOUND / timeout.
- `flutter-mcp-toolkit` продолжает работать (он не зависит от сети для VM-service).
- Kilo корректно репортит ошибку, не падает целиком.

---

## Что НЕ нужно делать

| Действие | Почему |
|----------|--------|
| Добавлять `@upstash/context7_mcp` в `pubspec.yaml` | Context7 — server-side MCP, не Flutter-пакет. Зависимость на стороне Kilo, не приложения. |
| Менять `AndroidManifest.xml` / `build.gradle` | Pure Node.js процесс, не требует Android-разрешений. Не нарушает hard rule про `intentcall_platform`. |
| Обновлять `tools/dev/install-mcp-flutter.ps1` | Скрипт специфичен для `flutter-mcp-toolkit` (нужен AOT-бинарь). Context7 ставится on-demand через `npx`. |
| Добавлять Context7 в `flutter run` workflow | Не нужен debug-session. Достаточно одного `kilo.jsonc`. |

---

## Откат (если что-то пошло не так)

1. **Отключить без удаления:** в `.kilo/kilo.jsonc` поменять `"enabled": true` → `"enabled": false` в секции `context7`.
2. **Полный откат:** удалить весь блок `context7` из `.kilo/kilo.jsonc` и секцию из `AGENTS.md`. `flutter-mcp-toolkit` останется работать.
3. **Очистить npm-кеш:** `npm cache clean --force` (если подозрение на corruption скачанного пакета).

---

## Файлы, которые будут изменены

| Путь | Тип изменения | Размер diff |
|------|---------------|-------------|
| `F:\My_VC_Projects\quran_app\.kilo\kilo.jsonc` | edit (добавить 8 строк: блок `context7` + запятая) | ~280 байт |
| `F:\My_VC_Projects\quran_app\AGENTS.md` | edit (добавить ~60 строк: раздел про Context7) | ~1.7 KB |

**Файлы, которые НЕ будут тронуты:**
- `pubspec.yaml`, `lib/**`, `android/**`, `ios/**`, `test/**` — не нужны.
- `tools/dev/*.ps1` — специфичны для `flutter-mcp-toolkit`.
- `.gitignore` — `node_modules` от `npx` живут в `%LOCALAPPDATA%\npm-cache`, не в репо.

---

## Ожидаемый эффект

1. **Агент видит актуальный API** Flutter-пакетов — меньше итераций «написал → не компилируется → фикс».
2. **Ускорение фич с новыми пакетами** на 1–2 часа (TFLite, ML Kit, flutter_tts — когда понадобятся).
3. **Безопасный апгрейд** `just_audio` / `drift` / `audio_service` с авто-подсказками breaking changes.
4. **Нулевой риск для Android-сборки** (pure Node.js, не зависит от `intentcall_platform`).
5. **Нулевая стоимость** (npm-пакет бесплатен, MIT).

## Метрики для оценки через 1 неделю

| Метрика | Как измерить | Цель |
|---------|--------------|------|
| Кол-во «написал → не компилируется → фикс» на фичу | Считать циклы в Kilo-сессии | Снижение на ≥30% |
| Время на добавление нового Flutter-пакета | Хронометр от запроса до работающего `import` | Ускорение на 20–30% |
| Срабатывания Context7 tool'ов в неделю | `View → Output → Kilo` → grep `mcp_context7` | ≥20 (proof of value) |
| RAM overhead | `Get-Process -Name node` | ≤80 MB |

Если метрики не достигнуты за 2 недели — отключить (`enabled: false`) без удаления конфига.