# Проверка bash/shell в текущей среде Kilo

**Дата**: 2026-07-17
**Сессия**: проверка наличия и работы shell-инструментов в Kilo

## Что проверяли

Способность запускать shell-команды (bash / PowerShell / pwsh) из текущей
сессии Kilo для типичных dev-задач quran_app:
flutter / dart / adb / git / node / python / ripgrep.

## Результаты проверки

### Доступные shell-инструменты в сессии

В tool-surface текущей сессии **нет** инструмента с именем `bash`,
`shell` или `run_command`. Прямого shell-выполнения из чата Kilo нет.

Доступные замены для shell-операций:

| Задача | Инструмент |
|---|---|
| Чтение файлов | `read` |
| Запись/правка файлов | `write`, `edit` |
| Поиск по тексту | `grep` |
| Поиск файлов | `glob` |
| Длинные процессы (dev-server, watchers) | `background_process` |
| ADB/Flutter операции | `flutter-mcp-toolkit_fmt_*` + `tools/dev/*.ps1` через PowerShell пользователя |
| История прошлых сессий | `kilo_local_recall` |
| Webfetch | `webfetch` |

### Попытка запустить PowerShell через `background_process`

```
$ powershell -NoProfile -Command "$PSVersionTable.PSVersion; ..."
```

Получили:

```
The user has specified a rule which prevents you from using this
specific tool call. ... {"permission":"bash","action":"ask", ...}
```

Kilo применил policy-правило `bash` → `ask` для `background_process`,
потому что env-meta пометил `background_process` как относящийся к
bash-домену. Это пользовательская permission-policy из
`.kilo/kilo.jsonc` — **не баг среды**.

Правило в permission-policy:

```jsonc
{ "permission": "bash", "pattern": "*", "action": "ask" }
{ "permission": "bash", "action": "allow", "pattern": "..." }
```

То есть shell через `background_process` доступен, но требует явного
подтверждения пользователя (`ask`) для каждого вызова, и для ряда
паттернов сразу `allow` (cat, ls, grep, rg, etc.).

### Вывод

Bash/shell в этой среде **работает**, но:

1. **Нет dedicated `bash`-тула** — нужно использовать `background_process`
   с разрешения пользователя.
2. **Пользовательская policy** `.kilo/kilo.jsonc` ставит `action: "ask"`
   на большинство shell-командочек → каждая требует ручного подтверждения.
3. **Whitelist `allow`** покрывает базовые read-only команды (cat, ls,
   grep, pwd, etc.) — они работают без подтверждения.
4. **Для quran_app** стандартный workflow уже налажен через:
   - `tools/dev/*.ps1` PowerShell-скрипты (adb-helpers, flutter-supervisor)
   - `flutter run --debug` вручную
   - MCP `flutter-mcp-toolkit` для inspect/reload

## План дальнейших действий

### Опция A — оставить как есть (Recommended)

Текущая настройка (ask на bash) — самая безопасная. Чтобы запустить
shell-команду, пользователь подтверждает в UI. Это защищает от
случайного выполнения опасных команд (`rm -rf`, `flutter clean`
без нужды, etc.).

**Tradeoff**: лишний клик на каждую команду. Для длинных workflow
(установка зависимостей, миграции БД) это утомительно.

### Опция B — расширить whitelist

Добавить в `.kilo/kilo.jsonc` allow-правила для типовых команд
quran_app:

```jsonc
{
  "permission": "bash",
  "pattern": "flutter *",
  "action": "allow"
},
{
  "permission": "bash",
  "pattern": "dart *",
  "action": "allow"
},
{
  "permission": "bash",
  "pattern": "adb *",
  "action": "allow"
},
{
  "permission": "bash",
  "pattern": "git *",
  "action": "allow"
},
{
  "permission": "bash",
  "pattern": "powershell *",
  "action": "allow"
},
{
  "permission": "bash",
  "pattern": "pwsh *",
  "action": "allow"
}
```

Это покрывает 95% обычных dev-задач и убирает необходимость
подтверждения.

**Tradeoff**: чуть менее безопасно — `git push --force`, `flutter
clean`, `adb uninstall` пройдут без подтверждения. Но эти команды
редки и обратимы.

### Опция C — перейти на `allow *`

```jsonc
{ "permission": "bash", "pattern": "*", "action": "allow" }
```

Максимально гладкая работа. **Не рекомендую** — стирает защиту.

## Hard rules для shell в этой среде

- **`flutter run --debug`** — обязательно для работы MCP `flutter-mcp-toolkit`
  (release-mode отключает VM extensions).
- **`dart compile exe` без debug** упадёт с "Debug builds cannot be
  AOT compiled". Перед сборкой — `flutter clean`.
- **`adb forward` всегда на tcp:22080** (фиксированный supervisor-порт).
  10808 занят Xray VPN.
- **`am force-stop com.quran.app.quran_app`** — только если supervisor
  остановлен, иначе будет гонка.

## Что хотел пользователь (уточнить)

Если пользователь хотел **проверить, что shell вообще работает** —
следующий шаг: он подтверждает один shell-вызов через UI, я вижу
вывод и могу дальше работать. Пример минимального вызова для
sanity-check:

```bash
node --version
git --version
adb --version
flutter --version
```

Если пользователь хотел **настроить policy** — см. Опцию B выше.

Если пользователь хотел **найти, почему shell не работает** —
причина: нет dedicated `bash`-тула, есть `background_process` под
ask-policy. Дополнительная диагностика — посмотреть
`.kilo/kilo.jsonc` permission-блок.

## TODO (после уточнения)

- [ ] Уточнить у пользователя, какая из опций A/B/C нужна
- [ ] Если B — подготовить diff для `.kilo/kilo.jsonc`
- [ ] Если A — оставить как есть, документировать workflow подтверждений