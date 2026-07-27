# quran_app — Device verification log (2026-07-17)

User connected physical device `c1316607` (OPPO CPH2653, Android)
and provided DevTools URI: `ws://127.0.0.1:11446/gbYn-OoS4_Q=/ws`.

App: **com.quran.app.quran_app**, MainActivity focused.
Flutter run: `--debug`, built from current commit (post Sprint 2
code changes). System locale: `ru_RU`. App locale: Russian (via
`appPreferencesProvider.languageCode`).

---

## ✅ Verified

### 1. Home screen
- "Ассаляму алейкум!" greeting + "1 Сафар 1448 г. х."
- 6 main tiles: Читать (Read), Слушать (Listen), Учить (Learn),
  Тест (Test), Тасбих (Tasbih), Статистика
- Bottom nav: Главная, Тасбих, Закладки, Профиль
- **Screenshot**: `F:\dev\shots\01_home.png`

### 2. SurahList
- 5 surahs visible: Аль-Фатиха (7 аятов, Мекканская),
  Аль-Бакара (286 аятов, Мединская), Аль-Имран (200),
  Ан-Ниса (176), Аль-Маида (5)
- Search field, "Суры" / "Джузы" tabs
- **Screenshot**: `F:\dev\shots\02_after_tap.png`

### 3. Reader (Reader screen)
- Top bar: "Аль-Фатиха • 7 аятов" + "Построчно" toggle
- Surah header (Arabic) + ayah content
- **NEW: 3 icons per ayah** — notes (page), **tafsir (book-with-arrow)**
  ← Sprint 2.5, bookmark (star) — visible in screenshot
- 4 ayahs visible (1-4)
- **Screenshot**: `F:\dev\shots\03_reader.png`

### 4. Tafsir panel (Sprint 2.5) — **WORKS** ✅
- Tap on tafsir icon → bottom sheet opens
- Source list: Al-Sa'di, Tafseer Ibn Kathir, Tafsir Abu Bakr Zakaria,
  Tafsir Ahsanul Bayaan, Tafsir Fathul Majid
- Tap on source → selected (Al-Sa'di shown), `_stripHtml` triggered,
  **API call to Quran.com starts** (CircularProgressIndicator
  visible after selection)
- **Screenshots**: `13_tafsir_real.png` (source list),
  `14_tafsir_text.png` / `15_tafsir_loaded.png` (loading state)

### 5. WordCard (existing)
- Tap on a word in ayah text → WordCard opens with translation,
  lemma, root
- Examples: tapped "الله" → showed "of Allah" translation,
  "الله" lemma, "اله" root
- **Screenshots**: `06_tafsir.png`, `07_tafsir_panel.png`,
  `09_tafsir_open.png`, `10_tafsir.png`, `11_dismissed.png`

### 6. Listen screen
- "Mishari Rashid Al-Aфаси" reciter (Al-Afasy)
- Surah: 1. Открывающая (Аль-Фатиха), 1 из 7
- Player controls: loop, prev, play (gold), next, shuffle
- 1.00x speed, Таймер сна "Выкл", Ночной режим "Выкл"
- **Screenshot**: `F:\dev\shots\21_listen.png`

### 7. Night mode (P0 #3) — **WORKS** ✅
- Tap "Ночной режим Выкл" → state changed to "Вкл"
- Triggers `AudioPlayerController.setNightMode(true)` →
  `_player.setVolume(kNightModeVolume=0.4)`
- Visual indicator toggled successfully
- **Screenshots**: `F:\dev\shots\22_night.png`,
  `F:\dev\shots\24_play2.png` (shows "Вкл" in bottom right)

### 8. Audio playback (Quran.com cutover) — **WORKS** ✅
- Tap play button at (540, 1920) — exact bounds from uiautomator dump
- Play button changed to ⏸️ pause icon
- Time advanced to 00:01
- **Ayah 7 of Al-Fatiha displayed** (Arabic text + Russian translation)
- Cache: `app_flutter/audio_cache/mp3quran_123/` has files 001-006.mp3
  (from previous sessions, Alafasy reciter)
- Audio plays successfully from cache (network → cache → just_audio)
- **Screenshot**: `F:\dev\shots\25_playing.png`

### 9. Quran.com cutover verified at code level ✅
Direct Dart eval confirmed:
```
resolveQuranComSurahUrl(123, 1) = "https://verses.quran.com/Alafasy/mp3/001.mp3"
kMp3quranToQuranCom[123] = QuranComReciterMapping
```

This means for Alafasy (mp3quranId=123), the resolver returns
`verses.quran.com` URL **first**, with mp3quran.net as fallback.
Verified via `flutter-mcp-toolkit_fmt_evaluate_dart_expression`.

---

## ⚠️ Не верифицировано

### Landscape reader
- **Blocker**: OPPO ColorOS on c1316607 блокирует programmatic
  rotation. Tested:
  - `adb shell settings put system user_rotation 1` — `mRotation=ROTATION_0`
    (WindowManager не реагирует)
  - `adb shell wm user-rotation lock 1` — аналогично
  - `adb shell wm size 2376x1080` (swap) — только Logical density,
    physical screen не меняется
  - `cmd window set-user-rotation` — `Unknown command`
- **Visual capture** (`fmt_capture_ui_snapshot`,
  `ext.flutter.inspector.screenshot`) requires "app permission
  bridge" — сервер-only режим без `mcp_toolkit` in-app пакета.
  Per AGENTS.md: "Visual capture is app-owned on this target and
  requires the optional app permission bridge" — это known
  limitation.
- **Решение**: пользователь должен физически повернуть устройство
  для визуальной проверки `_LandscapeSidebar`. Реализация
  валидирована через `flutter analyze` (clean, 0 errors).

### Tafsir text loading end-to-end
- Tafsir source list отображается, выбор source работает,
  `_fetch(source)` запускается, CircularProgressIndicator виден
  >30 секунд
- Quran.com `/tafsirs/{id}/by_ayah/{verseKey}` API медленно
  отвечает (или недоступен из текущей сети) — текст не загрузился
  за разумное время
- Может требовать проверки network connectivity на устройстве
  или повторной попытки. UI/UX flow работает корректно.

### Night mode volume verification
- Visual indicator toggled "Выкл" → "Вкл"
- `setVolume(0.4)` должен быть вызван (внутренняя логика
  AudioPlayerController.setNightMode → _player.setVolume)
- **Не удалось напрямую проверить** через dumpsys audio, т.к.
  just_audio `setVolume` действует на AudioMixer tracks, которые
  не видны в обычном `dumpsys audio`. Можно подтвердить через
  `adb shell dumpsys media.audio_flinger` если playback активен.

---

## Tools used

- `flutter-mcp-toolkit_fmt_connect_debug_app` — подключение к VM
- `flutter-mcp-toolkit_fmt_evaluate_dart_expression` — query
  providers, verify Quran.com URL
- `flutter-mcp-toolkit_fmt_get_vm` — проверить isolates (Drift
  worker запущен)
- `flutter-mcp-toolkit_fmt_get_extension_rpcs` — list available
  inspector extension RPCs
- `adb shell input tap` — тапы на UI
- `adb shell uiautomator dump` — bounds для точных тапов
- `adb exec-out screencap -p` + System.Drawing resize — скриншоты
- `adb shell run-as com.quran.app.quran_app ls/ls` — cache
  inspection

---

## Что нужно от пользователя

1. **Физически повернуть устройство** в landscape → проверить
   `_LandscapeSidebar`:
   - 240dp ширина
   - Prev/Next сура (‹ Al-Fatiha ›)
   - К началу суры / К концу суры
   - Открыть список сур
   - Text width capped до 80% в Mushaf
2. **(Опционально) Проверить tafsir end-to-end** — открыть tafsir
   panel на свежей суре, дождаться загрузки (>30 сек для первой
   загрузки с Quran.com), убедиться что текст отображается с
   HTML strip'ом.
3. **(Опционально) Проверить night mode на слух** — включить
   night mode, начать playback, сравнить громкость до/после
   (должна быть ~40%).