import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../app/router/safe_pop.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/i18n/bismillah.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../domain/reader_display_settings.dart';
import '../presentation/reader_palette.dart';
import 'preview_ayah.dart';
import 'widgets/slider_row.dart';
import 'widgets/switch_row.dart';

/// Высоты sticky preview в свёрнутом и развёрнутом состоянии.
const double kPreviewHeightCollapsed = 72;
const double kPreviewHeightExpanded = 240;

class ReaderDisplaySettingsScreen extends ConsumerWidget {
  const ReaderDisplaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final display = ref.watch(displaySettingsProvider);
    final palette = ReaderPalette.of(display.themeVariant);

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: palette.background,
          foregroundColor: palette.text,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 20, color: palette.text),
            onPressed: () => safePop(context),
          ),
          title: Text(t.displaySettingsTitle, style: TextStyle(color: palette.text)),
          actions: [
            TextButton(
              onPressed: () {
                final current = ref.read(displaySettingsProvider);
                ref
                    .read(displaySettingsProvider.notifier)
                    .set(ReaderDisplaySettings.defaults);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t.displaySettingsResetDone),
                    action: SnackBarAction(
                      label: t.displaySettingsUndo,
                      onPressed: () {
                        ref
                            .read(displaySettingsProvider.notifier)
                            .set(current);
                      },
                    ),
                  ),
                );
              },
              child: Text(
                t.displaySettingsReset,
                style:
                    TextStyle(color: palette.gold, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _SettingsBody(),
        ),
      ),
    );
  }
}

class _SettingsBody extends ConsumerStatefulWidget {
  const _SettingsBody();

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  bool _previewExpanded = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final display = ref.watch(displaySettingsProvider);
    final palette = ReaderPalette.of(display.themeVariant);
    final previewHeight =
        _previewExpanded ? kPreviewHeightExpanded : kPreviewHeightCollapsed;

    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 24)
              .copyWith(top: previewHeight + AppSpacing.md),
          children: [
            // ── Арабский текст ─────────────────────────────
            _GroupHeader(palette: palette, icon: Icons.abc_outlined, text: t.displaySettingsGroupText),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(palette: palette,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        t.displaySettingsFontFamily,
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  _FontFamilyMenu(
                    current: display.fontFamily,
                    palette: palette,
                    onChanged: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .set(display.copyWith(fontFamily: v)),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SliderRow(
                    label: t.displaySettingsFontSize,
                    value: display.fontSize,
                    min: 18,
                    max: 40,
                    divisions: 22,
                    valueLabel: '${display.fontSize.round()}',
                    palette: palette,
                    onChanged: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .setLocal(display.copyWith(fontSize: v)),
                    onChangeEnd: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .set(display.copyWith(fontSize: v)),
                  ),
                  _Divider(palette: palette),
                  SliderRow(
                    label: t.displaySettingsLineHeight,
                    value: display.lineHeight,
                    min: 1.4,
                    max: 2.6,
                    divisions: 12,
                    valueLabel: display.lineHeight.toStringAsFixed(1),
                    palette: palette,
                    onChanged: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .setLocal(display.copyWith(lineHeight: v)),
                    onChangeEnd: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .set(display.copyWith(lineHeight: v)),
                  ),
                  _Divider(palette: palette),
                  // Редкие параметры текста спрятаны в раскрывающуюся
                  // секцию, чтобы не загромождать группу.
                  _AdditionalSection(
                    palette: palette,
                    label: t.displaySettingsAdvanced,
                    children: [
                      SliderRow(
                        label: t.displaySettingsWordSpacing,
                        value: display.wordSpacing,
                        min: 0,
                        max: 4,
                        divisions: 8,
                        valueLabel: display.wordSpacing.toStringAsFixed(1),
                        palette: palette,
                        onChanged: (v) => ref
                            .read(displaySettingsProvider.notifier)
                            .setLocal(display.copyWith(wordSpacing: v)),
                        onChangeEnd: (v) => ref
                            .read(displaySettingsProvider.notifier)
                            .set(display.copyWith(wordSpacing: v)),
                      ),
                      SliderRow(
                        label: t.displaySettingsLetterSpacing,
                        value: display.letterSpacing,
                        min: 0,
                        max: 2,
                        divisions: 4,
                        valueLabel: display.letterSpacing.toStringAsFixed(1),
                        palette: palette,
                        onChanged: (v) => ref
                            .read(displaySettingsProvider.notifier)
                            .setLocal(display.copyWith(letterSpacing: v)),
                        onChangeEnd: (v) => ref
                            .read(displaySettingsProvider.notifier)
                            .set(display.copyWith(letterSpacing: v)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // ── Перевод ────────────────────────────────────
            _GroupHeader(palette: palette, icon: Icons.translate, text: t.displaySettingsGroupTranslation),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(palette: palette,
              child: Column(
                children: [
                  SwitchRow(
                    label: t.displaySettingsShowTranslation,
                    value: display.showTranslation,
                    palette: palette,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      ref
                          .read(displaySettingsProvider.notifier)
                          .set(display.copyWith(showTranslation: v));
                    },
                  ),
                  _Divider(palette: palette),
                  _TranslatorRow(palette: palette),
                  _Divider(palette: palette),
                  SliderRow(
                    label: t.displaySettingsTranslationFontSize,
                    value: display.translationFontSize,
                    min: 10,
                    max: 24,
                    divisions: 14,
                    valueLabel: '${display.translationFontSize.round()}',
                    palette: palette,
                    onChanged: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .setLocal(display.copyWith(translationFontSize: v)),
                    onChangeEnd: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .set(display.copyWith(translationFontSize: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // ── Макет страницы ────────────────────────────
            _GroupHeader(palette: palette, icon: Icons.dashboard_customize_outlined, text: t.displaySettingsGroupLayout),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(palette: palette,
              child: Column(
                children: [
                  _ReadingModeRow(display: display, palette: palette),
                  _Divider(palette: palette),
                  SliderRow(
                    label: t.displaySettingsTextWidth,
                    value: display.textWidthPercent,
                    min: 70,
                    max: 100,
                    divisions: 6,
                    valueLabel: '${display.textWidthPercent.round()}%',
                    palette: palette,
                    onChanged: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .setLocal(display.copyWith(textWidthPercent: v)),
                    onChangeEnd: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .set(display.copyWith(textWidthPercent: v)),
                  ),
                  _Divider(palette: palette),
                  SliderRow(
                    label: t.displaySettingsPaddingHorizontal,
                    value: display.paddingHorizontal,
                    min: 0,
                    max: 32,
                    divisions: 16,
                    valueLabel: '${display.paddingHorizontal.round()}',
                    palette: palette,
                    onChanged: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .setLocal(display.copyWith(paddingHorizontal: v)),
                    onChangeEnd: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .set(display.copyWith(paddingHorizontal: v)),
                  ),
                  _Divider(palette: palette),
                  SliderRow(
                    label: t.displaySettingsPaddingVertical,
                    value: display.paddingVertical,
                    min: 8,
                    max: 32,
                    divisions: 12,
                    valueLabel: '${display.paddingVertical.round()}',
                    palette: palette,
                    onChanged: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .setLocal(display.copyWith(paddingVertical: v)),
                    onChangeEnd: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .set(display.copyWith(paddingVertical: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // ── Чтение ─────────────────────────────────────
            _GroupHeader(palette: palette, icon: Icons.auto_stories_outlined, text: t.displaySettingsGroupReading),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(palette: palette,
              child: Column(
                children: [
                  SwitchRow(
                    label: t.displaySettingsKeepScreenOn,
                    value: display.keepScreenOn,
                    palette: palette,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      ref
                          .read(displaySettingsProvider.notifier)
                          .set(display.copyWith(keepScreenOn: v));
                    },
                  ),
                  _Divider(palette: palette),
                  SliderRow(
                    label: t.displaySettingsAutoScrollSpeed,
                    value: display.autoScrollSpeed,
                    min: 10,
                    max: 60,
                    divisions: 10,
                    valueLabel:
                        '×${(display.autoScrollSpeed / 10).toStringAsFixed(1)}',
                    palette: palette,
                    onChanged: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .setLocal(display.copyWith(autoScrollSpeed: v)),
                    onChangeEnd: (v) => ref
                        .read(displaySettingsProvider.notifier)
                        .set(display.copyWith(autoScrollSpeed: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            // ── Тема ───────────────────────────────────────
            _GroupHeader(palette: palette, icon: Icons.palette_outlined, text: t.displaySettingsGroupTheme),
            const SizedBox(height: AppSpacing.sm),
            _SettingsCard(palette: palette,
              child: _ThemeSwatchRow(display: display, palette: palette),
            ),
          ],
        ),
        // ── Sticky preview ───────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _StickyPreview(
              display: display,
              palette: palette,
              translationText: t.displaySettingsPreviewTranslation,
              expanded: _previewExpanded,
              onToggle: () =>
                  setState(() => _previewExpanded = !_previewExpanded),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdditionalSection extends StatelessWidget {
  const _AdditionalSection({
    required this.label,
    required this.palette,
    required this.children,
  });

  final String label;
  final ReaderPalette palette;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 4),
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: palette.gold,
        collapsedIconColor: palette.gold,
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: palette.gold,
            fontWeight: FontWeight.w600,
          ),
        ),
        // Между детьми — тонкие разделители в стиле карточки.
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) _Divider(palette: palette),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Sticky превью: компактная карточка (одна строка арабского) по
/// умолчанию, tap — разворачивает до полного превью через [AnimatedSize].
class _StickyPreview extends StatelessWidget {
  const _StickyPreview({
    required this.display,
    required this.palette,
    required this.translationText,
    required this.expanded,
    required this.onToggle,
  });

  final ReaderDisplaySettings display;
  final ReaderPalette palette;
  final String translationText;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Material(
      color: palette.background,
      child: Container(
        decoration: BoxDecoration(
          color: palette.background,
          border: Border.all(color: palette.gold.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: palette.gold.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: expanded ? _expanded(t) : _collapsed(),
      ),
    );
  }

  Widget _collapsed() {
    final isLineByLine = display.readingMode == 'lineByLine';
    return InkWell(
      onTap: onToggle,
      child: SizedBox(
        height: kPreviewHeightCollapsed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  Bismillah.standardText,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  style: TextStyle(
                    fontFamily: display.fontFamily,
                    fontSize: display.fontSize.clamp(16.0, 24.0),
                    height: 1.4,
                    color: palette.text,
                  ),
                ),
              ),
              // Мини-индикатор режима чтения: пользователь видит,
              // в каком режиме показан предпросмотр.
              Icon(
                isLineByLine ? Icons.view_column_outlined : Icons.menu_book,
                color: palette.gold.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Icon(Icons.expand_more, color: palette.gold, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _expanded(AppLocalizations t) {
    final isLineByLine = display.readingMode == 'lineByLine';
    return SizedBox(
      height: kPreviewHeightExpanded,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 8, AppSpacing.lg, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _GroupHeader(palette: palette, icon: Icons.visibility_outlined, text: t.displaySettingsPreview),
                const Spacer(),
                // Чип режима: превью перерисовывается этим же
                // рендером, режим виден без похода в «Макет».
                Icon(
                  isLineByLine
                      ? Icons.view_column_outlined
                      : Icons.menu_book,
                  color: palette.gold.withValues(alpha: 0.8),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isLineByLine ? t.readingModeLineByLine : t.readingModeBook,
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.text.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: onToggle,
                  child: Icon(Icons.expand_less, color: palette.gold, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: PreviewAyah(
                settings: display,
                translationText: translationText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.text, required this.palette, this.icon});

  final String text;
  final IconData? icon;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: palette.gold),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: palette.text.withValues(alpha: 0.75),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child, required this.palette});
  final Widget child;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: palette.border, width: 0.5),
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.palette});
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Divider(height: 1, color: palette.gold.withValues(alpha: 0.15)),
    );
  }
}

class _ThemeSwatchRow extends ConsumerWidget {
  const _ThemeSwatchRow({
    required this.display,
    required this.palette,
  });

  final ReaderDisplaySettings display;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: ReaderDisplaySettings.themeVariants.map((v) {
        final p = ReaderPalette.of(v);
        final selected = display.themeVariant == v;
        // Semantics(button+selected): скринридер объявляет
        // «Тёмная, выбрано» / «Сепия, не выбрано».
        return Semantics(
          button: true,
          selected: selected,
          label: p.label(t),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              ref
                  .read(displaySettingsProvider.notifier)
                  .set(display.copyWith(themeVariant: v));
            },
            borderRadius: BorderRadius.circular(AppRadius.sm),
            // padding 8 → тап-таргет свотча ≥ 48 dp по ширине.
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ThemeVariantSwatch(
                    palette: p,
                    size: 40,
                    borderWidth: selected ? 3 : 1.5,
                    borderColor: selected
                        ? palette.gold
                        : p.gold.withValues(alpha: 0.4),
                    check: selected,
                    checkColor: palette.gold,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.label(t),
                    style: TextStyle(
                      fontSize: 11,
                      color: palette.text.withValues(alpha: selected ? 1.0 : 0.7),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FontFamilyMenu extends StatelessWidget {
  const _FontFamilyMenu({
    required this.current,
    required this.palette,
    required this.onChanged,
  });

  final String current;
  final ReaderPalette palette;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentIndex = ReaderDisplaySettings.fontFamilyIndex(current);
    final currentLabel = ReaderDisplaySettings.fontFamilyLabels[currentIndex];
    final currentFamily = ReaderDisplaySettings.fontFamilies[currentIndex];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: palette.gold.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Material(
        color: palette.surface.withValues(alpha: 0.6),
        child: Semantics(
          button: true,
          label: AppLocalizations.of(context).displaySettingsFontFamily,
          value: currentLabel,
          child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () async {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox?;
            if (overlay == null) return;
            final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);

            final selected = await showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                topLeft.dx,
                topLeft.dy + box.size.height,
                overlay.size.width - topLeft.dx - box.size.width,
                overlay.size.height - topLeft.dy - box.size.height,
              ),
              color: palette.surface,
              items: [
                for (var i = 0; i < ReaderDisplaySettings.fontFamilies.length; i++)
                  PopupMenuItem<String>(
                    value: ReaderDisplaySettings.fontFamilies[i],
                    child: Row(
                      children: [
                        if (i == currentIndex)
                          Icon(Icons.check, color: palette.gold, size: 18)
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 12),
                        Text(
                          ReaderDisplaySettings.fontFamilyLabels[i],
                          style: TextStyle(
                            fontFamily: ReaderDisplaySettings.fontFamilies[i],
                            fontSize: 14,
                            color: palette.text,
                            fontWeight:
                                i == currentIndex ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
            if (selected != null) onChanged(selected);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Text(
                  currentLabel,
                  style: TextStyle(
                    fontFamily: currentFamily,
                    fontSize: 14,
                    color: palette.text,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: palette.gold),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _TranslatorRow extends ConsumerWidget {
  const _TranslatorRow({required this.palette});

  final ReaderPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final prefs = ref.watch(appPreferencesProvider);
    final translatorsAsync = ref.watch(translatorsListProvider);

    return translatorsAsync.when(
      data: (translators) {
        // Пустой список возможен на fresh install до завершения seed в
        // postFrameCallback (или при сбое seed). Без guard'а
        // `firstWhere` бросал StateError прямо в build.
        if (translators.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.translate, color: palette.gold, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.displaySettingsTranslatorError,
                    style: TextStyle(
                        color: palette.text.withValues(alpha: 0.6),
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }
        final current = translators.firstWhere(
          (tr) => tr.id == prefs.activeTranslatorId,
          orElse: () => translators.first,
        );
        return InkWell(
          onTap: () => unawaited(
            _showTranslatorSheet(context, ref, translators, current, palette),
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: palette.gold.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                Icon(Icons.translate, color: palette.gold, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        current.nameRu?.isNotEmpty == true
                            ? current.nameRu!
                            : current.name,
                        style: TextStyle(
                            color: palette.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${current.languageCode.toUpperCase()} • ${t.displaySettingsTranslatorHint}',
                        style: TextStyle(
                            color: palette.text.withValues(alpha: 0.6),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: palette.gold, size: 16),
              ],
            ),
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: palette.gold)),
      ),
      error: (_, _) => Text(
        t.displaySettingsTranslatorError,
        style: TextStyle(color: palette.text.withValues(alpha: 0.7)),
      ),
    );
  }

  Future<void> _showTranslatorSheet(
    BuildContext context,
    WidgetRef ref,
    List<Translator> translators,
    Translator current,
    ReaderPalette palette,
  ) async {
    final prefs = ref.read(appPreferencesProvider);
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => _TranslatorSheet(
        translators: translators,
        currentId: prefs.activeTranslatorId,
        palette: palette,
      ),
    );
    if (selected != null && selected != prefs.activeTranslatorId) {
      unawaited(HapticFeedback.selectionClick());
      await ref.read(appPreferencesProvider.notifier).setActiveTranslatorId(selected);
    }
  }
}

class _TranslatorSheet extends ConsumerWidget {
  const _TranslatorSheet({
    required this.translators,
    required this.currentId,
    required this.palette,
  });

  final List<Translator> translators;
  final int currentId;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: palette.gold.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              t.displaySettingsTranslatorTitle,
              style: TextStyle(
                  color: palette.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: translators.length,
              itemBuilder: (ctx, i) {
                final tr = translators[i];
                final selected = tr.id == currentId;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(tr.id),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                            color: palette.gold.withValues(alpha: 0.1),
                            width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (selected)
                          Icon(Icons.check_circle, color: palette.gold, size: 20)
                        else
                          Icon(Icons.radio_button_unchecked,
                              color: palette.text.withValues(alpha: 0.3),
                              size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            tr.nameRu?.isNotEmpty == true
                                ? tr.nameRu!
                                : tr.name,
                            style: TextStyle(
                              color: selected ? palette.gold : palette.text,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        Text(
                          tr.languageCode.toUpperCase(),
                          style: TextStyle(
                            color: palette.text.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ReadingModeRow extends ConsumerWidget {
  const _ReadingModeRow({
    required this.display,
    required this.palette,
  });

  final ReaderDisplaySettings display;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isLineByLine = display.readingMode == 'lineByLine';
    return Row(
      children: [
        Icon(Icons.menu_book, color: palette.gold, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.displaySettingsReadingMode,
                style: TextStyle(
                    color: palette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                isLineByLine ? t.readingModeLineByLine : t.readingModeBook,
                style: TextStyle(
                    color: palette.text.withValues(alpha: 0.6), fontSize: 12),
              ),
            ],
          ),
        ),
        SegmentedButton<String>(
          // Иначе M3-цвета по умолчанию чужеродны на palette-driven
          // экране (выбранный сегмент — золото темы, фон прозрачный).
          style: SegmentedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: palette.text.withValues(alpha: 0.7),
            selectedBackgroundColor: palette.gold.withValues(alpha: 0.15),
            selectedForegroundColor: palette.gold,
            side: BorderSide(color: palette.border),
          ),
          // Сегменты только с иконками: текстовые подписи
          // («Построчно»/«Книга») не помещались по ширине и
          // ломались в вертикальную колонку. Текущий режим и так
          // подписан текстом слева.
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: 'lineByLine',
              label: SizedBox.shrink(),
              icon: Icon(Icons.view_column_outlined, size: 18),
            ),
            ButtonSegment(
              value: 'book',
              label: SizedBox.shrink(),
              icon: Icon(Icons.menu_book, size: 18),
            ),
          ],
          selected: {display.readingMode},
          onSelectionChanged: (selected) {
            HapticFeedback.selectionClick();
            final next = selected.first;
            ref
                .read(displaySettingsProvider.notifier)
                .set(display.copyWith(readingMode: next));
          },
        ),
      ],
    );
  }
}