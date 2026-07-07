# AGENTS.md — Quran App Working Agreement

> Strict operating manual for any AI agent (including the author of this file)
> that contributes code, docs, or tooling to this repository.
>
> Комментарии-подсказки написаны на русском — чтобы упростить онбординг
> русскоязычной команде. Все правила, заголовки и формулировки — на английском.

---

## 0. Response Language (locked)

0.1. **All agent-to-user prose output in this terminal is in Russian** —
including status reports, plan summaries, file-edit rationales, error
diagnoses, and question prompts.

0.2. Code, identifiers, file paths, log lines, library names, and code
comments stay in English (or whatever language the existing code uses).
The Russian requirement covers the *conversational* layer between the
agent and the user, not the artifacts the agent produces.

0.3. Inline code identifiers, logs, file paths, and stack traces quoted
in the answer remain untranslated even if they contain non-Russian
text.

0.4. If the user switches to a different language mid-session, the
agent follows the most recent explicit user instruction (overrides
0.1 for the rest of that session).

  // Подсказка: фиксация именно здесь — рядом со Scope and Authority,
  // чтобы правило читалось первым при онбординге. Этот языковой
  // приоритет уже был запрошен пользователем в чате и теперь
  // кодифицирован в файле.

---

## 1. Scope and Authority

1.1. This file overrides any conflicting instruction in chat, generic templates,
or sub-agent prompts. If a higher-level command from the user conflicts with a
rule below, STOP and ask the user explicitly before proceeding.

1.2. Sources of truth, in priority order:
  1. `docs/ARCHITECTURE.md` — architectural vision and contracts.
  2. `.kilo/plans/1782332762533-quran-app-master-plan.md` — phased delivery plan.
  3. `quran_app/pubspec.yaml` — concrete dependency versions.
  4. This file — day-to-day workflow rules.

  // Подсказка: если правила плана и этого файла противоречат — следуй плану,
  // но фиксируй расхождение в PR-описании.

1.3. The Flutter project lives in the `quran_app/` subfolder. All paths in this
file are relative to the repository root unless stated otherwise.

---

## 2. Technology Stack (locked)

The current `pubspec.yaml` is authoritative for versions. Do not bump major
versions without an explicit task.

| Concern             | Package                          | Version        |
| ------------------- | -------------------------------- | -------------- |
| Language SDK        | Dart                             | `^3.12.0`      |
| State management    | `flutter_riverpod`               | `^2.6.1`       |
| Routing             | `go_router`                      | `^14.6.2`      |
| Networking          | `dio`                            | `^5.7.0`       |
|                     | `http`                           | `^1.2.0`       |
| Database            | `drift`                          | `^2.21.0`      |
|                     | `sqlite3_flutter_libs`           | `^0.5.24`      |
| Paths               | `path_provider`, `path`          | `^2.1.5`, `^1.9.0` |
| Preferences         | `shared_preferences`             | `^2.3.3`       |
| Localization        | `flutter_localizations`, `intl`  | sdk, `^0.20.2` |
| Audio playback      | `just_audio`                     | `^0.9.42`      |
|                     | `audio_service`                  | `^0.18.18`     |
| Cryptography        | `crypto`                         | `^3.0.5`       |
|                     | `cryptography`                   | `^2.7.0`       |
| Dev — codegen       | `drift_dev`, `build_runner`      | `^2.21.2`, `^2.4.13` |
| Dev — testing       | `flutter_test`, `test`           | sdk, `^1.25.0` |
| Dev — linting       | `flutter_lints`                  | `^6.0.0`       |

  // Подсказка: архитектура упоминает "Riverpod 3.x", но в pubspec зафиксирован
  // 2.6.1 — это сознательный downgrade для стабильности. Не "модернизируй"
  // до 3.x без явного запроса.

---

## 3. Architectural Rules (non-negotiable)

3.1. **Offline First.** Every primary feature must work after a single online
bootstrap. No silent network calls on the read path.

3.2. **Cache First.** Any fetched byte is persisted to disk; subsequent reads
serve the local copy. Audio: check local cache → progressive download → save
on completion.

3.3. **Content Decoupling.** Translations, tafsirs, audio sources, word
timings are delivered through the content update system (manifest + SHA-256 +
ED25519) and never via app store release.

3.4. **Feature-first layout.** A new capability belongs under
`lib/features/<feature>/{data,domain,presentation}`. Shared infrastructure
goes under `lib/core/`. Cross-feature widgets go under `lib/shared/widgets/`.

3.5. **No horizontal slices.** Do not place feature code directly under
`lib/`. The only allowed top-level `lib/` directories are `app/`, `core/`,
`features/`, `shared/`, `l10n/`, `main.dart`.

3.6. **Riverpod-only state.** No `setState` for cross-screen state. Widget-local
`setState` is allowed only for ephemeral UI (form focus, animation flag, etc.).

3.7. **Repositories are the only DB callers.** Widgets and Riverpod controllers
talk to repositories in `lib/core/data/` or `lib/features/<x>/data/`. Direct
Drift DAO access from UI is forbidden.

3.8. **Drift schema discipline.**
  - The schema version constant lives in `lib/core/database/app_database.dart`.
  - Every schema change ships with a migration step in
    `MigrationStrategy.onUpgrade`.
  - Never delete a column without a migration; never rename a column without
    a migration that copies data.
  - Run `dart run build_runner build --delete-conflicting-outputs` after
    editing `tables.dart`.

3.9. **Search uses FTS5 with normalization.** Arabic inputs are normalized via
`lib/core/search/arabic_normalizer.dart` before being written to FTS shadow
tables. Do not bypass the normalizer.

3.10. **Audio model is "1 surah = 1 MP3".** Do not propose per-ayah files.

3.11. **Audio cache has a hard LRU limit** (default 2 GB, configurable).
Cache GC runs whenever a new file would push the cache past the limit.
Files are evicted by `last_played_at` ascending.

3.12. **SM-2 is pure.** Spaced repetition logic in
`lib/features/learning/data/sm2.dart` has zero Flutter or Riverpod imports.
Keep it that way — it must stay unit-testable on plain Dart.

3.13. **Content security.**
  - All downloaded content packages are verified with SHA-256.
  - All packages are verified with ED25519 (`cryptography` package).
  - Failed verification triggers rollback to the previous version and a
    user-visible notification. Never silently activate an unverified bundle.

3.14. **Error handling contracts.** See `docs/ARCHITECTURE.md` §17 for the
mandatory fallback chains (audio sources, DB migration, cloud sync). Do not
invent new failure modes.

---

## 4. Folder Layout and Naming

4.1. **File names** — `snake_case.dart`. One public top-level symbol per file
is preferred, but not mandatory for closely related helpers.

4.2. **Classes / enums / typedefs** — `PascalCase`. File name matches the
primary symbol (e.g. `SurahDao` → `surah_dao.dart`).

4.3. **Variables, methods, parameters** — `camelCase`.

4.4. **Constants** — `lowerCamelCase` with `const`; not `SCREAMING_SNAKE_CASE`
(existing codebase uses `lowerCamelCase` — stay consistent).

4.5. **Database tables** — plural `snake_case` (e.g. `surahs`, `ayahs`,
`word_timings`). DAO classes are singular: `SurahDao`.

4.6. **Routes** — kebab-case paths (`/reader/surah/2`), screen file
`surah_reader_screen.dart`.

4.7. **Generated files** — `*.g.dart` for Drift and `app_localizations*.dart`
under `lib/l10n/generated/`. Treat as build artifacts; never hand-edit.

4.8. **Feature folder pattern.**

```
lib/features/<feature>/
├── data/        // repositories, dtos, remote/local sources
├── domain/      // entities, value objects, usecases (no Flutter imports)
└── presentation/// screens, widgets, riverpod controllers
```

Empty subfolders are deleted, not left as placeholders.

4.9. **Core subfolders** (use the existing names):
`audio/`, `content/`, `data/`, `database/`, `i18n/`, `networking/`,
`search/`, `storage/`, `theme/`.

  // Подсказка: в текущем репозитории уже есть `lib/core/database/daos/`,
  // `lib/core/data/`, `lib/core/content/`, `lib/core/audio/` и т. д. —
  // не создавай дублирующие «features-level» DAO.

---

## 5. Build, Test, and Codegen Commands

All commands are run from `quran_app/` unless stated otherwise.

5.1. **Install deps.**
  - `flutter pub get`

5.2. **Codegen (Drift).** Run after any edit to `tables.dart` or
`lib/core/database/**`:
  - `dart run build_runner build --delete-conflicting-outputs`
  - Watch mode for active development:
    `dart run build_runner watch --delete-conflicting-outputs`

5.3. **Static analysis.**
  - `flutter analyze`

5.4. **Unit and widget tests.**
  - `flutter test`
  - Targeted run: `flutter test test/path/to/file_test.dart`

5.5. **Run on device / emulator.**
  - `flutter run -d <deviceId>`
  - List devices: `flutter devices`

5.6. **Build artifacts.**
  - Debug APK: `flutter build apk --debug`
  - Release APK: `flutter build apk --release`
  - iOS (macOS host only): `flutter build ios --release`

5.7. **Localization regeneration.** The project uses ARB-based
`flutter gen-l10n`. Triggered automatically by `flutter pub get` / `flutter
build`. To force:
  - `flutter gen-l10n`

5.8. **Dependency hygiene.** Never hand-edit the lockfile. If a dep must
change, use `flutter pub add|remove|upgrade <pkg>` and commit the resulting
`pubspec.yaml` + `pubspec.lock`.

5.9. **Pre-commit checklist** (mentally walk through before finishing):
  1. `flutter analyze` clean.
  2. `flutter test` green.
  3. Codegen up to date.
  4. No stray `print(` / `debugPrint(` left behind.
  5. No commented-out code blocks larger than 5 lines.

---

## 6. Token-Economy: Folders to Ignore

The following paths must be excluded from agent scans (file search, grep,
content reads) to conserve context. Do not list or recurse into them.

6.1. **Build and dependency caches.**
  - `quran_app/build/`
  - `quran_app/.dart_tool/`
  - `quran_app/.flutter-plugins`
  - `quran_app/.flutter-plugins-dependencies`
  - `quran_app/.packages`
  - `quran_app/android/.gradle/`
  - `quran_app/android/app/build/`
  - `quran_app/android/build/`
  - `quran_app/ios/Pods/`
  - `quran_app/ios/Flutter/Flutter.framework`
  - `quran_app/ios/Flutter/Flutter.podspec`
  - `quran_app/ios/.symlinks/`
  - `quran_app/ios/Runner.xcworkspace/xcuserdata/`
  - `quran_app/ios/Runner.xcodeproj/xcuserdata/`
  - `quran_app/macos/Pods/`, `quran_app/macos/build/`
  - `quran_app/windows/`, `quran_app/linux/` build outputs

6.2. **Generated code (read only when explicitly debugging codegen).**
  - `quran_app/lib/**/*.g.dart`
  - `quran_app/lib/l10n/generated/`
  - `quran_app/.dart_tool/build/`

6.3. **Editor / IDE metadata.**
  - `.idea/`
  - `.vscode/` (except `.vscode/settings.json` when explicitly debugging
    workspace settings — never read the whole tree)
  - `*.iml`

6.4. **Documentation screenshots and assets** unless the task is about UI
documentation:
  - `docs/images/`

6.5. **Test coverage artifacts.**
  - `quran_app/coverage/`
  - `**/lcov.info`

6.6. **Local content caches and secrets.**
  - `quran_app/.content_cache/`
  - `quran_app/.keys/` (ED25519 private keys live here)
  - `**/*.env`
  - `**/google-services.json`
  - `**/GoogleService-Info.plist`

  // Подсказка: если возникла ошибка "файл не найден" в сгенерированном коде,
  // сначала проверь, что ты не находишься в исключённой папке. Если
  // действительно нужно прочитать .g.dart — прочитай только нужный фрагмент.

6.7. **Plans and agent metadata are NOT to be ignored.**
  - `.kilo/` is part of the project; read `.kilo/agents/AGENTS.md` and the
    plan files when needed for context.

---

## 7. Coding Conventions

7.1. **Imports.** Group order, separated by blank lines:
  1. Dart core / `dart:`.
  2. Flutter (`package:flutter/...`).
  3. Third-party packages.
  4. Project relative imports.

7.2. **No wildcard imports.** Use explicit `import 'package:foo/foo.dart';`.

7.3. **Riverpod providers.** Prefer `Provider`/`FutureProvider`/
`StreamProvider`/`NotifierProvider`. Use `code-generation` providers only when
the team has agreed to add `riverpod_generator` to `dev_dependencies` — do
not introduce it unilaterally.

7.4. **Async correctness.** Use `AsyncValue` and `.when(...)` at the UI
boundary. Do not `await` inside `build()`.

7.5. **Strings.** All user-facing strings go through ARB files under
`quran_app/lib/l10n/`. No hard-coded literals in widgets.

7.6. **Logging.** Use the project logger (currently `debugPrint` wrapper or
the team-chosen logger). Never log user data, full paths, or tokens.

7.7. **Tests.** Every new public function in `domain/` ships with a unit
test. Every new screen ships with at least one widget test that boots it.

7.8. **Comments.** Comments explain *why*, not *what*. Russian comments are
acceptable for domain-specific Quran / Arabic concepts; English otherwise.

  // Подсказка: доменные термины (харакат, хизб, джуз, утхмани) часто проще
  // комментировать по-русски — это допускается в `//`-комментариях.

---

## 8. What Agents Must NOT Do

8.1. Do not introduce a new top-level package without an explicit user task.

8.2. Do not delete or rename a Drift table, column, or DAO without writing
the corresponding migration step.

8.3. Do not change `pubspec.yaml` versions outside of an explicit task.

8.4. Do not write to `lib/l10n/generated/` by hand — it is regenerated.

8.5. Do not commit secrets, signing keys, or `google-services.json`.

8.6. Do not bypass `core/search/arabic_normalizer.dart` for Arabic text
queries.

8.7. Do not call DAOs from widget code; always go through a repository.

8.8. Do not create new architectural patterns (e.g. Cubit, GetIt, BloC,
Redux) — the project uses Riverpod only.

8.9. Do not invent new failure modes for audio downloads; follow the
primary → backup → archive.org chain defined in the architecture.

8.10. Do not push to remote, create commits, or open PRs unless the user
explicitly asks. Local work only by default.

  // Подсказка: «не пушить» — стандартное правило. Если пользователь просит
  // «закоммить и отправь», это явный запрос и ограничение снимается.

---

## 9. Minimal Change Protocol

When asked to implement a feature:

1. **Read** this file, `docs/ARCHITECTURE.md`, the relevant slice of the
   master plan, and the existing code in the target feature folder.
2. **Locate** the smallest viable change set. Reuse existing DAOs,
   repositories, widgets, and providers whenever possible.
3. **Plan** the schema impact. If Drift changes are needed, write the
   migration first.
4. **Implement** following §3, §4, §7.
5. **Verify** with §5.9 checklist.
6. **Report** what changed, which files were touched, which commands were
   run, and any deviations from the plan (with rationale).

If any of the above cannot be satisfied, STOP and surface the blocker to
the user. Do not paper over architectural debt to make tests green.

---

## 10. Escalation

If a request:
- contradicts `docs/ARCHITECTURE.md`,
- contradicts this file,
- would require a new external dependency,
- would require a major-version dependency bump, or
- would touch files in §6,

  then ask the user for explicit confirmation before proceeding. Provide
  the conflict and the proposed resolution; do not silently pick a side.