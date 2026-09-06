# Plan: Fix horizontal padding stacking on Reader screen in landscape

## Problem

On the Reader screen (quran reading screen), in landscape orientation, the text has **extra horizontal padding on left and right** that does not match the user-configured `paddingHorizontal` setting.

User-visible result with `paddingHorizontal = N`:
- **lineByLine mode**: actual padding ≈ **2 × N** (extra ≈ N on each side)
- **book mode**: actual padding ≈ **3 × N** (extra ≈ 2 × N on each side)

In landscape the wasted space is more obvious because the screen is wider, so the user notices that even with `paddingHorizontal = 0` there is still ~16 dp of dead space on each side in lineByLine, and ~32 dp in book mode.

## Root cause

In `lib/features/quran/presentation/reader_screen.dart`, the helper
`_ReaderScreenState._buildMushafBody(...)` wraps the Mushaf content in
**two stacked `Padding` widgets**, both using
`effectiveDisplay.paddingHorizontal`:

1. **Outer** (lines 403–409):
   ```dart
   Padding(
     padding: EdgeInsets.fromLTRB(
       effectiveDisplay.paddingHorizontal, 0,
       effectiveDisplay.paddingHorizontal, 4,
     ),
     child: _AnimatedControlsFrame(child: dataAsync.when(...)),
   )
   ```
2. **Inner** (lines 428–434):
   ```dart
   Padding(
     padding: EdgeInsets.fromLTRB(
       effectiveDisplay.paddingHorizontal, 8,
       effectiveDisplay.paddingHorizontal, 8,
     ),
     child: ayahsAsync.when(
       ...
       data: (ayahs) => _SingleScrollMushaf(... display: effectiveDisplay ...),
     ),
   )
   ```

Then `_SingleScrollMushaf` adds **another** layer of horizontal padding:

3. **`_SingleScrollMushaf._buildBookStyle()`** (`reader_screen.dart` lines 1846–1855):
   `SingleChildScrollView(padding: EdgeInsets.symmetric(horizontal: widget.display.paddingHorizontal, ...))`
   — only in `book` mode.
4. **`AyahTile`** (`reader_widgets.dart` lines 116–143):
   `Padding(padding: EdgeInsets.symmetric(horizontal: widget.display?.paddingHorizontal ?? 16, ...))`
   — only in `lineByLine` mode (applied per-ayah).

So the **effective horizontal margin** (per side) becomes:

| Mode        | Layers stacked                                     | Effective padding per side |
|-------------|----------------------------------------------------|----------------------------|
| lineByLine  | outer + AyahTile                                   | **2 × paddingHorizontal**  |
| book        | outer + inner + scroll-view                        | **3 × paddingHorizontal**  |

This was added in commit `4289c08` (2026-07-27) — the same commit introduced both wrappers in `_buildMushafBody` without removing the pre-existing padding inside `_SingleScrollMushaf` / `AyahTile`.

The landscape cap at line 395–397 only caps `textWidthPercent` (to 80 %); it does not affect paddingHorizontal.

## Goal

Make the **actual** horizontal padding equal to the user setting
`paddingHorizontal`, in **both** orientations and **both** reading modes.

## Decision

Keep a **single source of truth** for the horizontal padding: the
`Padding` inside `_SingleScrollMushaf` / `AyahTile` (which already
exists and is the most semantically correct location — it sits next to
the actual text).

Remove the duplicate paddings in `_buildMushafBody`.

### Layout to apply

| Mode        | Outer Padding in `_buildMushafBody`                     | Inner Padding in `_buildMushafBody`           | Inside `_SingleScrollMushaf` / `AyahTile` |
|-------------|----------------------------------------------------------|------------------------------------------------|------------------------------------------|
| lineByLine  | only `bottom: 4` (no horizontal)                         | only `vertical: 8` (no horizontal)             | `AyahTile` keeps `horizontal: paddingHorizontal` |
| book        | only `bottom: 4` (no horizontal)                         | only `vertical: 8` (no horizontal)             | `_SingleScrollMushaf._buildBookStyle` keeps `horizontal: paddingHorizontal` |

In landscape we additionally want to **cap** the padding at a small
constant (e.g. 16 dp) to keep text centered on a very wide screen,
independent of the user's setting. This mirrors the existing
`textWidthPercent` cap at 80 %. The cap will be applied at the
`effectiveDisplay` level (same place the textWidthPercent cap lives).

### Recommended cap value

`min(paddingHorizontal, isLandscape ? 16 : 32)`.

Rationale: the `paddingHorizontal` slider goes up to 32; in landscape
a 32-dp inner padding on a 600+ dp wide screen still leaves
≥ 536 dp of text — plenty. Capping to 16 mirrors typical Mushaf print
margins and matches the existing aesthetic in `_LandscapeSidebar` /
top-bar (`margin: EdgeInsets.fromLTRB(8, 4, 8, 0)`).

## Files to change

### 1. `lib/features/quran/presentation/reader_screen.dart`

**a) Extend the landscape cap** (line 395–397):

```dart
final effectiveDisplay = isLandscape
    ? display.copyWith(
        textWidthPercent:
            display.textWidthPercent > 80 ? 80.0 : display.textWidthPercent,
        // Cap paddingHorizontal in landscape so a 32-dp setting does
        // not waste ~12% of a wide tablet / foldable screen on each
        // side. 16 dp matches the existing `AyahTile` fallback
        // (`paddingHorizontal ?? 16`) and the top-bar margin.
        paddingHorizontal:
            display.paddingHorizontal > 16 ? 16.0 : display.paddingHorizontal,
      )
    : display;
```

**b) Replace outer Padding** (lines 403–409):

```dart
return GestureDetector(
  behavior: HitTestBehavior.translucent,
  onTap: _toggleControls,
  child: Padding(
    // Bottom-only safety margin so AyahTile's bottom ornament
    // descenders are not clipped by viewport. Horizontal padding is
    // applied inside `_SingleScrollMushaf` / `AyahTile` — see
    // [ReaderDisplaySettings.paddingHorizontal].
    padding: const EdgeInsets.only(bottom: 4),
    child: _AnimatedControlsFrame(
      visible: _controlsVisible,
      child: dataAsync.when(...),
    ),
  ),
);
```

**c) Replace inner Padding** (lines 428–434):

```dart
return Padding(
  // Vertical-only breathing room above the first ayah (ornament
  // header / basmala). Horizontal padding is owned by
  // `_SingleScrollMushaf` / `AyahTile`.
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: ayahsAsync.when(
    ...
    data: (ayahs) => _SingleScrollMushaf(... display: effectiveDisplay ...),
  ),
);
```

No other edits are needed inside `reader_screen.dart`; the existing
`Padding` inside `_SingleScrollMushaf._buildBookStyle` (lines 1846–1855)
and `AyahTile` (`reader_widgets.dart` lines 116–143) already apply
`display.paddingHorizontal` correctly.

### 2. `lib/features/reader_settings/domain/reader_display_settings.dart`

Update the doc comment for `paddingHorizontal` (lines 174–177) to
reflect that:

- the setting is applied exactly once, inside the reader (not 2–3
  times as today);
- in landscape the effective value is capped at 16 dp.

Also update `defaults.paddingHorizontal` doc comment (line 137) if
needed (default value itself does not change).

### 3. `lib/features/quran/presentation/widgets/reader_widgets.dart`

No code change required — the existing `AyahTile` Padding already
correctly applies `widget.display.paddingHorizontal` horizontally.
Just tighten the inline comment (lines 137–142) to point out that
this is now the **single source** of horizontal padding for the
lineByLine reader.

## Verification

After the change, the actual horizontal margin from screen edge to
text must equal the value shown in the settings preview (within
≤ 1 dp for SafeArea / scroll-view rounding), in **all** combinations
of: orientation (portrait / landscape) × mode (lineByLine / book).

### Manual test plan (using `flutter-mcp-toolkit` on device `c1316607`)

1. `flutter run --debug`; connect via `fmt_connect_debug_app`.
2. Open settings → display → set `paddingHorizontal` slider to **0**.
3. Return to Reader, capture snapshot (`fmt_capture_ui_snapshot`).
4. Inspect the leftmost text x-coordinate via
   `fmt_evaluate_dart_expression` against
   `ReaderDisplaySettings.paddingHorizontal` (read directly from prefs).
5. Switch to landscape (rotate device), repeat 3–4.
6. Set `paddingHorizontal = 16` (and 32), repeat 3–5 in both modes.
7. Expected: actual left margin equals `paddingHorizontal`
   (±1 dp) in portrait; equals `min(paddingHorizontal, 16)` in
   landscape.

### Unit-style check (optional, low cost)

A small widget test that pumps `ReaderScreen` inside
`MediaQuery(data: MediaQueryData(size: Size(800, 400)))` (landscape
phone), then asserts via `find.byType(AyahTile)` → `tester.getSize`
→ `tester.getTopLeft` that the leftmost tile starts at
`16 dp` when `paddingHorizontal = 32`. Skipped if we have no
existing widget test infra for Reader — manual verification above
is enough.

## Out of scope

- Refactoring `_buildMushafBody` to split into portrait / landscape
  variants (current helper is fine; only paddings change).
- Changing `paddingHorizontal` slider range in settings.
- Touching `textWidthPercent` landscape cap (already correct at 80 %).
- Touching top-bar / bottom-bar paddings (intentional design).