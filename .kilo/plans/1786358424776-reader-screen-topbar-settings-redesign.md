# Reader screen: top bar, settings menu & preview redesign

## Context (grounded in current code)

- `lib/features/quran/presentation/reader_screen.dart` — `_AnimatedTopBar` is a
  `Positioned(top:0)` overlay (opaque card: margin `8/4/8/0`, padding `8/6`,
  radius 20→`AppRadius.lg`, gold border+glow) containing back button, Arabic
  glyph surah name (fontSize 24, `Surah Name V2` font) + Latin name + ayah
  count, reading-mode toggle, theme toggle, settings button. Effective height
  incl. `SafeArea` top inset ≈ **90–110dp**.
- `lib/features/quran/presentation/widgets/reader_widgets.dart` —
  `SurahHeader` renders **inside** the scrollable Mushaf content, starting at
  scroll-offset 0 with only `padding.top = 24`. It's a large ornamental frame
  (aspect ratio 600/230 ≈ 2.6 in portrait ⇒ on a 360dp-wide phone, height ≈
  **138dp**) with the surah name in a *second*, much bigger glyph (`Surah
  Name V4`, fontSize **70**), centered in the frame.
- **Root cause of complaint #1**: the floating top bar's ~100dp opaque card
  sits directly on top of the first ~70% of `SurahHeader`'s ornament for the
  first couple of seconds a surah is open (and again at surah boundaries
  while scrolling). The overlay repeats the surah name a second time in a
  different font, so the collision is both **visual** (obscured ornament)
  and **informational** (duplicate title).
- `lib/features/reader_settings/domain/reader_display_settings.dart` already
  has `showTranslation` (bool, default `true`) and `keepScreenOn` (bool,
  default `true`) fields — **no domain/DB migration is required** for
  anything in this plan.
- `lib/features/reader_settings/presentation/reader_display_settings_screen.dart`
  (current, palette-aware, instant-apply) has 4 groups (Текст / Макет / Тема /
  Перевод) but **lost the "Показывать перевод" toggle** during the last
  rewrite (the `switch_row.dart` import was dropped as "unused" — it is in
  fact needed). This is a regression to fix, not a new feature.
- `lib/features/reader_settings/presentation/preview_ayah.dart` — sticky
  preview is pinned at a fixed `kPreviewHeight = 280` regardless of content,
  rendering a full ayah + gold ayah-number badge (28dp) + translation line,
  sized to survive worst-case settings (fontSize 40, lineHeight 2.6,
  paddingHorizontal/Vertical up to 32 each). For default/typical settings
  this wastes most of the 280dp on empty space.
- `lib/features/reader_settings/presentation/reader_palette.dart` — 4
  palettes (`dark/sepia/light/parchment`), each exposing `background /
  surface / text / gold / border`. All redesigned widgets must stay
  palette-driven (no hardcoded `AppColors` in the reading-zone chrome).

No new dependencies are required except the already-deferred `wakelock_plus`
for `keepScreenOn` (optional follow-up, called out separately below).

---

## 1. Top bar redesign

### Problem
Opaque, full-width, ~100dp card duplicates the surah title and visually
covers the `SurahHeader` ornament right when it matters most (surah open).

### Recommended design — "Ghost Icon Dock" + scroll-aware title reveal

**Structure** (replaces current `_AnimatedTopBar` internals; `Positioned`
overlay mechanism, auto-hide-on-scroll-down and `_controlsVisible` plumbing
stay as-is):

- Drop the Arabic/Latin surah-name `Text` widgets from the overlay entirely.
  The ornament (`SurahHeader`) is now the *only* place the surah title is
  shown when the surah first opens — no duplication, no collision.
- Left: a single **standalone ghost circle** (back arrow), ~40dp.
- Right: a **compact pill cluster** (stadium shape, auto-width, ~40dp tall)
  grouping reading-mode toggle, theme-palette toggle, settings — separated by
  1px hairline dividers (`palette.gold` alpha 0.15) instead of `SizedBox`
  gaps, so it reads as one cohesive control instead of three loose buttons.
- Both elements float independently (no connecting card/background strip
  behind the empty space between them) — this alone removes the wide opaque
  band that used to sit over the ornament.
- Chrome: glass effect — `BackdropFilter` blur (sigma ≈ 12) +
  `palette.surface.withValues(alpha: 0.35–0.45)` fill + 0.6px `palette.gold`
  (alpha 0.25) hairline border. No hard black shadow; use a soft
  `palette.gold` alpha 0.10 glow (already the direction taken in the last
  round) so the dock never reads as a heavy block.
- **Target total footprint ≈ 40–44dp** (+ safe-area gap 8dp), vs. current
  ~56dp card + 4dp margin + safe area ⇒ roughly **40–50% less vertical
  space**, and — critically — nothing wide/opaque sits over the ornament.

**Scroll-aware title reveal** (genuine UX win, not just cosmetic):

- While the `SurahHeader` ornament is on screen, the dock stays icon-only
  (as above).
- Once the user scrolls **past** the ornament (simple, cheap check: scroll
  offset > measured/estimated `SurahHeader` height — the same
  aspect-ratio/width math `SurahHeader` already uses can be replicated or the
  offset threshold approximated from `_pageCtrl`/`_SingleScrollMushaf`'s
  existing scroll-delta plumbing), fade/slide in a small center pill chip
  showing the Latin surah name + ayah counter (small type, ellipsis) between
  the two icon clusters, via `AnimatedSwitcher`/`AnimatedSize`.
- This gives wayfinding for long surahs (e.g. Al-Baqara, 286 ayahs) once the
  decorative header has scrolled away — solving a real "where am I" problem
  — while guaranteeing the title never competes with the ornament for space.
- Reuses the existing scroll-delta callback (`onScrollDelta` /
  `_setControlsVisible`) infrastructure; only one new boolean derived state
  is needed in `_ReaderScreenState`.

**Motion**: keep `AnimatedSlide` + `AnimatedOpacity` for show/hide
(auto-hide on scroll-down), but give the *reveal* a subtle `Curves.
easeOutBack` (small overshoot, ~4–6dp) for a tactile "modern" feel; hide uses
a quicker `Curves.easeIn`. Duration stays ~200–260ms (matches current feel,
avoids jank).

### Alternatives considered (and why not chosen as primary)

- **`CustomScrollView` + `SliverAppBar`** (idiomatic Material 3 collapsing
  bar): would give scroll-linked collapse "for free", but requires
  converting `_SingleScrollMushaf`'s custom scroll/deep-link/position-
  recording logic (extensively commented, fragile, already has documented
  off-by-one/throttle workarounds) to sliver-based scrolling — high
  regression risk for a UI-only ask. Worth reconsidering later as a larger
  refactor, not now.
- **Move all controls to the bottom bar**: removes overlap by construction,
  but back-navigation is conventionally top-left on Android/iOS; moving it
  would hurt discoverability and violates predictable-navigation
  expectations. Rejected as primary; the recommended design already keeps
  back top-left and everything else minimal.

---

## 2. Settings menu — items to add / move / remove

### Fix first (regression)
- **Re-add "Показывать перевод" (`showTranslation`)** — the field already
  exists in the model and defaults to `true`; only the `SwitchRow` UI control
  was dropped in the last rewrite. This is the single most-used toggle and
  must come back.

### Proposed structure (4 groups → same 4 groups, re-balanced + 1 quick row)

**Quick-access row** (new, always visible, first thing under the AppBar —
*not* the sticky preview, just the first `ListView` child):
- Font-size stepper (–/A/+) — quick control mirroring the `fontSize` slider.
- "Показывать перевод" toggle — promoted here since it's the highest-value,
  most frequently toggled setting.
- Current-theme chip (small swatch dot + label) — tapping scrolls to / opens
  the Theme group; gives zero-scroll visibility into which theme is active.

**Группа «Арабский текст»** (renamed from "Текст" for precision, since
translation-specific settings move out — see below):
- Шрифт (family, with live sample — already implemented) — kept.
- Размер арабского шрифта — kept.
- Межстрочный интервал — kept.
- Расст. между словами — **demoted** into a collapsed `ExpansionTile`
  ("Дополнительно") inside this group, closed by default. Least-used slider;
  hiding it by default shortens the group without deleting the feature.

**Группа «Перевод»** (new home for everything translation-related,
consolidating what's currently scattered across "Текст"):
- Показывать перевод (toggle) — primary control of this group (also mirrored
  in the quick row above; both write the same provider field, so they can
  never disagree).
- Переводчик (existing shortcut row + bottom-sheet picker) — kept, moved
  here from its own group (was already logically "translation").
- Размер шрифта перевода — **moved here** from "Текст" (it was oddly grouped
  with Arabic-text sliders; this also shortens "Арабский текст").

**Группа «Макет страницы»** (renamed from "Макет"):
- Горизонтальный / вертикальный отступ — keep both sliders, but lay them out
  as **two compact side-by-side steppers in one row** instead of two
  full-width sliders, to save vertical space.
- Режим чтения (`SegmentedButton` row) — kept as-is.
- *(Optional follow-up, see below)* Экран не гаснет (`keepScreenOn`) toggle.

**Группа «Тема»** — unchanged structurally (swatch row); keep name as-is
(no confusion with "Оформление" — Russian "Тема" already reads as
"theme/appearance").

### Explicitly not adding (avoid scope/feature creep)
- Tajweed color-coding — no tajweed rule data exists anywhere in the
  codebase; this would be a new content feature, not a settings fix.
- Auto-scroll speed — no auto-scroll feature exists to configure.
- Ayah-number digit style (Arabic-Indic vs Western) — technically possible
  (`arabic_digits.dart` exists) but not requested; note as a future idea
  only, out of scope here.

### Optional follow-up (flagged, not blocking)
- **`keepScreenOn`**: field exists and defaults to `true`, but nothing wires
  it to the screen — no `wakelock_plus` (or similar) is integrated. Two
  choices:
  1. Wire `wakelock_plus` now (single-purpose plugin, minimal dependency
     footprint) and add the toggle — but AGENTS.md documents that this repo
     has been bitten before by plugin/Gradle interactions
     (`mcp_toolkit`/`intentcall_platform`); budget a dedicated smoke-test
     build before merging.
  2. Add the toggle now with a small "скоро" affordance and wire the plugin
     later, so the setting UI ships without functional risk today.
  Recommendation: **(1) if a build/test cycle is available in this task; (2)
  otherwise**, tracked as an explicit near-term follow-up either way.

---

## 3. Preview redesign (too large)

### Problem
Fixed `kPreviewHeight = 280`, always-on sticky header, sized for worst-case
settings — dominates the visible viewport (often 35–40%+ of usable body
height) even though most of that space is empty for default settings.

### Recommended design — compact sticky chip + tap-to-expand

- **Default (collapsed) state**: a single small card, **no separate
  "Предпросмотр" group-header row** (the live-updating text already signals
  its own purpose) — just the compact card itself with a tiny caption/eye
  icon in a corner.
  - Content: **one line** of the Arabic sample at current
    fontFamily/fontSize, `TextOverflow.ellipsis`, no ayah-number badge, no
    translation line.
  - Target height ≈ **64–72dp** (vs. 280dp today ⇒ ~75% reduction).
  - Flatter chrome: keep the rounded palette-colored container + hairline
    border, drop the heavy black `boxShadow` (dated skeuomorphism) in favor
    of the same soft gold-glow language used on the redesigned top bar.
- **Expanded state** (on tap): grows in place (`AnimatedSize`) to today's
  full preview — Arabic (multi-line, budget-calculated as now) + gold
  ayah-number badge + translation line — i.e. the existing `PreviewAyah`
  widget becomes the "expanded" renderer, reused unchanged. Tap again (or
  auto-collapse after ~4s idle) to shrink back.
- Stays **sticky** (fixed while the list scrolls beneath it) since
  always-visible live feedback while dragging sliders is the actual value of
  a preview — only its *height* changes, not its stickiness.
- Because the default line is single, fixed-height, ellipsis-only, the
  expensive `LayoutBuilder`/maxLines-budget math currently in `PreviewAyah`
  is only needed for the expanded state — simplifies the common path.

### Alternatives considered
- **Bottom-sheet preview opened via a button** (0dp permanent footprint):
  maximizes space savings but breaks the "live while dragging" value
  proposition (close sheet → adjust slider → reopen, repeatedly). Rejected.
- **Non-sticky preview living only in the "Арабский текст" group**: saves
  permanent space but gives no feedback while adjusting Theme/Translation
  settings further down the list. Rejected — theme swatches especially
  benefit from a visible-at-all-times preview.

---

## 4. Overall settings-screen visual polish ("beautiful, modern, easy to read")

Ties #2 and #3 together with screen-wide consistency work:

- **Group headers get a small icon badge** (gold-tinted, palette-aware) next
  to the label — e.g. text-fields icon for "Арабский текст", translate icon
  for "Перевод", layout icon for "Макет страницы", palette icon for "Тема" —
  faster visual scanning than text-only headers.
- **Progressive disclosure**: quick-access row (§2) + collapsed
  "Дополнительно" `ExpansionTile` for word-spacing (§2) together cut the
  number of always-visible controls by roughly a third.
- **Token sweep**: replace remaining hardcoded numeric literals in
  `_SettingsCard`, `_Divider`, `_ThemeSwatchRow`, `_FontFamilyMenu`,
  `_TranslatorRow`/`_TranslatorSheet`, `_ReadingModeRow`, `_FontSample` with
  the existing `AppSpacing`/`AppRadius` tokens (introduced earlier but not
  yet applied everywhere) — consistent rhythm across the whole screen.
  Standardize the repeated ad-hoc `SizedBox(height: 20)` between groups into
  one `AppSpacing` constant.
- **Micro-interactions**: `HapticFeedback.selectionClick()` on
  slider-division ticks and on theme-swatch taps (built-in Flutter API, zero
  new dependencies) — small but reinforces a modern, tactile feel.
- **Shadow language**: extend the palette-tinted soft-glow style (already
  used on the redesigned top bar) to `_SettingsCard` and the new compact
  preview, replacing any remaining generic `Colors.black` drop-shadows, for a
  cohesive "warm glass" look that matches the gold/Mushaf identity instead of
  generic Material defaults.
- **Accessibility floor**: keep every tap target (dock icons, steppers,
  swatches) ≥ 40dp even after the top-bar/preview size reductions — explicit
  constraint so implementation doesn't over-shrink for the sake of
  compactness.

---

## File-level change map

- `lib/features/quran/presentation/reader_screen.dart`
  - Rework `_AnimatedTopBar` into the ghost-dock structure (§1): drop title
    text, split into back-circle + pill-cluster, glass chrome, new
    scroll-derived "past header" boolean feeding an `AnimatedSwitcher`
    title-chip. No changes required to `_SingleScrollMushaf` or
    `SurahHeader` — the fix is entirely in the overlay, not the content.
- `lib/features/reader_settings/presentation/reader_display_settings_screen.dart`
  - Re-add `showTranslation` `SwitchRow` (re-import `widgets/switch_row.dart`).
  - New `_QuickAccessRow` widget at top of the `ListView`.
  - Move `translationFontSize` slider into a (new) "Перевод" group section
    alongside `showTranslation` + the existing translator shortcut.
  - Wrap `wordSpacing` slider in a collapsed `ExpansionTile`.
  - Pair horizontal/vertical padding into one compact stepper row.
  - Optional: add `keepScreenOn` `SwitchRow` (see §2 follow-up).
  - Token sweep (`AppSpacing`/`AppRadius`) + haptics on change handlers.
- `lib/features/reader_settings/presentation/preview_ayah.dart`
  - Keep existing full renderer as the "expanded" state; add a compact
    single-line collapsed renderer + local expand/collapse toggle (small
    self-contained `StatefulWidget`/`ValueNotifier`, no new global provider
    needed) driving an `AnimatedSize` between `kPreviewHeightCollapsed`
    (~72dp) and `kPreviewHeightExpanded` (~200–220dp, likely shrinkable from
    280 once the badge/shadow are trimmed).
- No changes to `reader_display_settings.dart` (domain model), no DB
  migration, no new providers — both fields this plan needs
  (`showTranslation`, `keepScreenOn`) already exist.

## Risks / tradeoffs

- Scroll-past-header detection is approximate (offset threshold vs. exact
  `RenderBox` measurement); start with the cheap offset approximation and
  only add `GlobalKey` measurement if QA shows visible mistiming.
- Compact preview hides translation/badge by default; mitigated by
  tap-to-expand — acceptable given the explicit "too large" complaint.
- Demoting word-spacing to "Дополнительно" slightly reduces its
  discoverability; acceptable as it's the least-used of the text sliders.
- `wakelock_plus` wiring (if attempted) touches Android Gradle/manifest,
  which this repo's AGENTS.md flags as historically sensitive — needs its
  own smoke-test build; keep it decoupled from the rest of this plan so it
  can slip to a follow-up without blocking §1/§3/§4.

---

## Implementation-ready specification (verified against current code)

Grounded by re-reading, line-accurate, the current state of: `reader_screen.dart`
(`_ReaderScreenState` fields/`initState`/`dispose`/call site at the time of
writing — lines 75, 115, 148, 194, 322, 342, 689-731, 761, 843-987, 1187-1246,
1339-1400, 1706-1779), `reader_widgets.dart::SurahHeader` (lines 628-719),
`preview_ayah.dart` (full file), `reader_display_settings.dart` (full file —
confirms `showTranslation` and `keepScreenOn` already exist, defaults `true`),
`reader_palette.dart` (full file), `common_widgets.dart::CircleIconButton`
(current fields: `icon, onTap, size=44, iconSize=22, background, borderColor,
iconColor`), `app_tokens.dart` (`AppSpacing.{xs,sm,md,lg,xl,xxl,xxxl} =
4/8/12/16/20/24/32`, `AppRadius.{sm,md,lg,xl} = 12/16/20/28`),
`widgets/switch_row.dart` and `widgets/slider_row.dart` (both plain
`AppColors`-based, no palette param yet — see note below).

Confirmed facts that de-risk this plan:
- `SurahHeader` is rendered **twice** in `_SingleScrollMushafState`
  (`_buildLineByLine` line ~1730 and `_buildBookStyle` line ~1920) — i.e. it
  appears at scroll-offset 0 in **both** reading modes, so the scroll-aware
  title-reveal logic below is valid regardless of `readingMode`.
- The scrollable that hosts `SurahHeader` is driven by `widget.scrollCtrl`,
  which **is** `_ReaderScreenState._pageCtrl` (passed straight through, see
  `scrollCtrl: _pageCtrl` at the `_SingleScrollMushaf(...)` call site) — so
  `_pageCtrl.offset` can be read directly from `_ReaderScreenState` without
  any new plumbing through `_SingleScrollMushaf`.
- `SurahHeader`'s own sizing math (for the offset-threshold estimate):
  outer `Padding(EdgeInsets.fromLTRB(4, 24, 4, 16))`, then
  `aspectRatio = isLandscape ? 600/120 : 600/230` where
  `isLandscape = MediaQuery.sizeOf(context).width >= 600`, and
  `height = availableWidth / aspectRatio`.

### A. `common_widgets.dart` — new reusable `GlassContainer`

Add alongside `GlassCard` (needs `import 'dart:ui';` for `ImageFilter`):

```
GlassContainer({
  required Widget child,
  BorderRadius borderRadius = const BorderRadius.all(Radius.circular(20)),
  Color? color,          // e.g. palette.surface.withValues(alpha: 0.4)
  Color? borderColor,    // e.g. palette.gold.withValues(alpha: 0.25)
  double blurSigma = 10, // modest — 3 small bounded regions, not full-screen
  EdgeInsetsGeometry? padding,
})
// build(): ClipRRect(borderRadius) > BackdropFilter(ImageFilter.blur(sigmaX/Y:
//   blurSigma)) > Container(padding, decoration: BoxDecoration(color,
//   borderRadius, border: borderColor == null ? null : Border.all(borderColor,
//   width: 0.6)), child: child)
```

Reused by: top-bar back circle, top-bar pill cluster, top-bar title chip
(§B), and the compact preview chip (§C). One implementation, four call
sites — matches "reusable UI components" and avoids four bespoke blur
containers.

### B. `reader_screen.dart` — Ghost Icon Dock

**Imports**: remove `import '../../../core/i18n/surah_name_glyph.dart';`
(line 15) — its only two call sites (`surahNameGlyph(...)` at the old
`_AnimatedTopBar(` call site, `surahNameV2FontFamily` inside the old
`_AnimatedTopBar.build`) are both deleted by this redesign; nothing else in
the file references either symbol (verified by grep — 4 total matches, all
inside the code being replaced/removed, plus the 2 `SurahHeader(` sites
which use the *unrelated* V4 glyph internally and don't need this import).

**`_ReaderScreenState` — new field** (add next to `bool _controlsVisible =
true;` at line 115):
```
/// True once the user has scrolled past the `SurahHeader` ornament for
/// the current surah — drives the dock's center title-chip reveal (see
/// `_AnimatedTopBar.titleRevealed`). Recomputed on every `_pageCtrl`
/// scroll tick via `_updateTitleReveal`; reset implicitly whenever a new
/// `_SingleScrollMushaf` mounts (surah change) because `_pageCtrl.offset`
/// starts back at 0 for the new content.
bool _titleRevealed = false;
```

**`_ReaderScreenState` — new methods** (add near `_checkScrollEnd`, e.g.
right after it, ~line 295):
```
double _estimateSurahHeaderThreshold() {
  final size = MediaQuery.sizeOf(context);
  final isLandscape = size.width >= 600; // mirrors SurahHeader's own check
  final aspect = isLandscape ? 600 / 120 : 600 / 230;
  final contentWidth = size.width - 8; // SurahHeader's outer Padding(4,·,4,·)
  final ornamentHeight = contentWidth / aspect;
  return ornamentHeight + 24 + 16; // + SurahHeader's own top/bottom padding
}

void _updateTitleReveal() {
  if (!_pageCtrl.hasClients) return;
  final revealed = _pageCtrl.offset > _estimateSurahHeaderThreshold();
  if (revealed != _titleRevealed) {
    setState(() => _titleRevealed = revealed);
  }
}
```

**Wire the listener** — `initState` line 148, add immediately after the
existing line: `_pageCtrl.addListener(_checkScrollEnd);` →
`_pageCtrl.addListener(_updateTitleReveal);`. **Dispose** — line 322, add
immediately after: `_pageCtrl.removeListener(_checkScrollEnd);` →
`_pageCtrl.removeListener(_updateTitleReveal);` (before `_pageCtrl.dispose()`
at line 342).

**Call site** (lines 689-731) — replace the whole `_AnimatedTopBar(...)`
invocation: **drop** `surahNameAr` (and its `surahNameGlyph(...)` glyph
computation/comment) and `ayahsCount` (unused by the new widget) and
`readingModeLabel` (and its ternary — the pill becomes icon-only with a
`Tooltip`, see below); **add** `titleRevealed: _titleRevealed`. Keep
`surahNameLatin`, `ayahsCountLabel`, `readingMode`, `readingModeTooltip`,
`palette`, `onThemeToggle`, `onBack`, `onToggleReadingMode`, `onSettings`
exactly as-is (same callbacks, same provider writes already fixed in the
previous round — `displaySettingsProvider.notifier`).

**`_AnimatedTopBar` — new constructor/fields**:
```
required bool visible
required bool titleRevealed
required String surahNameLatin
required String ayahsCountLabel
required String readingMode
required String readingModeTooltip
required ReaderPalette palette
required VoidCallback? onThemeToggle
required VoidCallback onBack
required VoidCallback onToggleReadingMode
required VoidCallback onSettings
```
(drops `surahNameAr`, `ayahsCount`, `readingModeLabel` from the previous
version).

**`_AnimatedTopBar.build` — new structure** (replaces the single opaque
card): keep the existing outer `AnimatedSlide` (`Offset(0,-1)` ↔
`Offset.zero`, 260ms, `Curves.easeOutCubic`) → `AnimatedOpacity` (200ms) →
`IgnorePointer(ignoring: !visible)` → `SafeArea(bottom: false)` wrapper
unchanged (this is the existing, working auto-hide-on-scroll mechanism —
no change needed there). Replace the inner `Container` card with:
```
Padding(EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      GlassContainer(              // back circle, ~40×40
        borderRadius: BorderRadius.circular(20),
        color: palette.surface.withValues(alpha: 0.4),
        borderColor: palette.gold.withValues(alpha: 0.25),
        child: _DockIconButton(icon: Icons.arrow_back_ios_new, iconSize: 16,
          tooltip: <use existing back/"Назад" semantics — MaterialLocalizations
          .of(context).backButtonTooltip>, onTap: onBack, palette: palette,
          boxSize: 40),
      ),
      Expanded(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            child: titleRevealed
                ? _TitleChip(key: const ValueKey('shown'), palette: palette,
                    text: '$surahNameLatin • $ayahsCountLabel')
                : const SizedBox.shrink(key: ValueKey('hidden')),
          ),
        ),
      ),
      GlassContainer(               // pill cluster, ~40 tall, auto width
        borderRadius: BorderRadius.circular(20),
        color: palette.surface.withValues(alpha: 0.4),
        borderColor: palette.gold.withValues(alpha: 0.25),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _DockIconButton(
            icon: readingMode == 'lineByLine'
                ? Icons.view_column_outlined : Icons.menu_book,
            tooltip: readingModeTooltip, onTap: onToggleReadingMode,
            palette: palette, boxSize: 40),
          _DockDivider(palette: palette),
          if (onThemeToggle != null) ...[
            _DockIconButton(icon: Icons.palette_outlined,
              tooltip: <displaySettingsGroupTheme or a short "Тема" label>,
              onTap: onThemeToggle!, palette: palette, boxSize: 40),
            _DockDivider(palette: palette),
          ],
          _DockIconButton(icon: Icons.tune,
            tooltip: <displaySettingsTitle or short "Настройки">,
            onTap: onSettings, palette: palette, boxSize: 40),
        ]),
      ),
    ],
  ),
)
```

**New small private widgets** (in `reader_screen.dart`, replacing the old
`_ReadingModeToggle` class — which is deleted, since nothing else
references it — confirmed by grep: only its class definition and the one
call site being replaced):
- `_DockIconButton` — `Tooltip` > `InkWell(customBorder: CircleBorder())` >
  `SizedBox(width/height: boxSize)` > `Center(child: Icon(icon, size:
  iconSize, color: palette.gold))`. `boxSize` default 40 (accessibility
  floor from §4).
- `_DockDivider` — `Container(width: 1, height: 20, margin:
  EdgeInsets.symmetric(horizontal: 2), color: palette.gold.withValues(alpha:
  0.15))`.
- `_TitleChip` — `GlassContainer(borderRadius: BorderRadius.circular(14),
  color: palette.surface.withValues(alpha: 0.5), borderColor:
  palette.gold.withValues(alpha: 0.2), padding: EdgeInsets.symmetric(
  horizontal: AppSpacing.sm, vertical: 4), child: Text(text, maxLines: 1,
  overflow: TextOverflow.ellipsis, softWrap: false, style: TextStyle(
  fontSize: 12, fontWeight: FontWeight.w600, color: palette.text.withValues(
  alpha: 0.9))))`.

Net effect: dock height ≈ 40dp (+`AppSpacing.sm`=8dp top gap) vs. previous
~56dp card + 4dp margin + safe area; **no opaque element wider than the
back-circle/pill spans the ornament** — the middle zone (where
`SurahHeader` sits) is either empty or holds only the small centered title
chip, and only once the ornament has already scrolled out of view.

### C. `reader_display_settings_screen.dart` + `preview_ayah.dart`

(Same file/class map as the original plan above — kept unchanged, already
precise enough: re-add `SwitchRow` for `showTranslation`, new
`_QuickAccessRow`, move `translationFontSize` into "Перевод", wrap
`wordSpacing` in `ExpansionTile`, pair padding sliders into one row, token
sweep, haptics, and the compact/expand `PreviewAyah` split reusing
`GlassContainer` from §A for the collapsed chip's chrome instead of a
bespoke `Container`+`boxShadow`.)

One correction based on this pass: `SwitchRow`/`SliderRow` (in
`widgets/switch_row.dart` / `widgets/slider_row.dart`) currently hardcode
`AppColors.textPrimary` / `AppColors.gold` / `AppColors.borderSubtle`
directly — they are **not** palette-aware yet, unlike the rest of the
redesigned settings screen. If left as-is they'll look correct only on
whichever palette happens to visually match `AppColors`' fixed light
values. Implementation should either (a) add an optional `palette:
ReaderPalette?` param to both and fall back to `AppColors` when null (safe,
non-breaking for any other call sites), or (b) confirm no other screen uses
these two widgets and make `palette` required. Recommend (a) — cheaper,
zero risk to unrelated call sites — as part of the §4 token/palette sweep.

