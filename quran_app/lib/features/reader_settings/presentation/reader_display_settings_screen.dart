import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../domain/reader_display_settings.dart';
import 'preview_ayah.dart';
import 'reader_palette.dart';
import 'widgets/choice_chips_row.dart';
import 'widgets/slider_row.dart';
import 'widgets/switch_row.dart';

/// Экран гибкой настройки отображения Reader'а.
///
/// Открывается через `context.push('/reader/display-settings')`
/// из bottom-sheet'а в Reader'е. Имеет собственную AppBar
/// (без bottom-nav) и **sticky preview** вверху, который
/// реактивно обновляется на любые slider-tick'и — но в
/// [AppPreferences] пишет только по `Готово`. Это позволяет
/// избежать дорогого ребилда Reader'а на каждый drag-pixel.
///
/// `Сброс` показывает дефолтное превью **без записи**; `Готово`
/// коммитит `_draft` в провайдер. `Системный back` (или тап
/// `←`) — если `_draft != _initial`, спрашивает подтверждение.
class ReaderDisplaySettingsScreen extends ConsumerStatefulWidget {
  const ReaderDisplaySettingsScreen({super.key});

  @override
  ConsumerState<ReaderDisplaySettingsScreen> createState() =>
      _ReaderDisplaySettingsScreenState();
}

/// Высота sticky-header (preview-карточка + её padding).
/// Используется как верхний padding для ListView (чтобы контент
/// стартовал **под** header'ом) и как `height: Positioned`.
///
/// Размер 280px подобран эмпирически: при экстремальных значениях
/// (fontSize 40 + lineHeight 2.6) внутри помещается:
///   1 строка арабского (104px) + 4 gap + 28 (۝) + 12 gap +
///   1 строка перевода (40px) + 16+16 padding (top+bottom) = 220px,
/// с запасом 60px на sub-pixel rendering и `TextOverflow.fade`.
const double kPreviewHeight = 280;

class _ReaderDisplaySettingsScreenState
    extends ConsumerState<ReaderDisplaySettingsScreen> {
  late ReaderDisplaySettings _initial;
  late ReaderDisplaySettings _draft;

  /// Scroll-контроллер для ListView с группами. Нужен для
  /// scroll-forwarding с preview (см. [_PreviewScrollForwarder]):
  /// свайп по preview прокручивает тело на ту же дельту Y.
  /// Без этого preview «поглощает» вертикальный drag — пользователь
  /// не может скроллить группы, начав свайп с области preview.
  final ScrollController _bodyScrollCtrl = ScrollController();

  /// Точка, в которой текущий drag начался (используется для
  /// определения, что свайп пошёл именно по preview).
  double? _dragStartY;

  @override
  void initState() {
    super.initState();
    _initial = ref.read(readerDisplaySettingsProvider);
    _draft = _initial;
  }

  @override
  void dispose() {
    _bodyScrollCtrl.dispose();
    super.dispose();
  }

  bool get _isDirty => _draft != _initial;

  void _update(ReaderDisplaySettings next) {
    setState(() => _draft = next);
  }

  Future<void> _save() async {
    // `displaySettingsProvider` — **изолированный** StateNotifier;
    // его `state =` триггерит ребилд ТОЛЬКО его dependents
    // (Reader, PreviewAyah) — не app-wide. Никакого
    // `ref.invalidate(appPreferencesProvider)` здесь не нужно,
    // и `context.pop()` снимает settings-роут без race-conditions
    // (нет app-wide rebuild, который GoRouter'у пришлось бы
    // пересчитывать).
    await ref.read(displaySettingsProvider.notifier).set(_draft);
    if (!mounted) return;
    context.pop();
  }

  Future<void> _resetToDefaults() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: t.displaySettingsResetConfirmTitle,
        body: t.displaySettingsResetConfirmBody,
        confirmLabel: t.displaySettingsReset,
        cancelLabel: t.displaySettingsCancel,
      ),
    );
    if (ok == true) {
      setState(() => _draft = ReaderDisplaySettings.defaults);
    }
  }

  Future<bool> _confirmDiscard() async {
    final t = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: t.displaySettingsDiscardTitle,
        body: t.displaySettingsDiscardBody,
        confirmLabel: t.displaySettingsDiscard,
        cancelLabel: t.displaySettingsCancel,
      ),
    );
    return ok == true;
  }

  Future<void> _onBack() async {
    if (_isDirty) {
      final discard = await _confirmDiscard();
      if (!discard) return;
    }
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundDeep,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundDeep,
          foregroundColor: AppColors.textPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: _onBack,
          ),
          title: Text(t.displaySettingsTitle),
          actions: [
            TextButton(
              onPressed: _resetToDefaults,
              child: Text(
                t.displaySettingsReset,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.backgroundDeep,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(
                  t.displaySettingsSave,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            // Sticky preview через `Stack` + `Positioned` —
            // НЕ `SliverPersistentHeader`. У `SliverPersistentHeader`
            // есть неприятная особенность: `SliverPersistentHeaderDelegate.
            // shouldRebuild(oldDelegate)` сравнивает **только** extent;
            // child ссылается на `widget`-замыкание, которое Flutter
            // **не пересоздаёт** при `setState` родителя. В итоге
            // `PreviewAyah` со свежим `_draft` рисуется только при
            // следующем layout-pass (scroll, rebuild viewport'а) —
            // пользователь видит, что preview «отстаёт» от slider'а
            // и обновляется только при свайпе.
            //
            // Решение: header рендерится обычным виджетом в `Stack`,
            // а ListView ниже имеет `padding.top == kPreviewHeight`
            // и скроллится под ним. `setState(_draft = ...)` →
            // header ребилдится напрямую, без delegate-кеша.
            children: [
              // ── Скроллируемый body (группы) ─────────────────
              ListView(
                controller: _bodyScrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24).copyWith(
                  top: kPreviewHeight + 12,
                ),
                children: [
                  // ── Текст ────────────────────────────────────
                  _GroupHeader(text: t.displaySettingsGroupText),
                  const SizedBox(height: 8),
                  _SettingsCard(
                    child: Column(
                      children: [
                        SliderRow(
                      label: t.displaySettingsFontSize,
                      value: _draft.fontSize,
                      min: 18,
                      max: 40,
                      divisions: 22,
                      valueLabel: '${_draft.fontSize.round()} ${t.displaySettingsUnitPx}',
                      onChanged: (v) => _update(_draft.copyWith(fontSize: v)),
                    ),
                    const _Divider(),
                    SliderRow(
                      label: t.displaySettingsLineHeight,
                      value: _draft.lineHeight,
                      min: 1.4,
                      max: 2.6,
                      divisions: 12,
                      valueLabel: _draft.lineHeight.toStringAsFixed(1),
                      onChanged: (v) => _update(_draft.copyWith(lineHeight: v)),
                    ),
                    const _Divider(),
                    SliderRow(
                      label: t.displaySettingsLetterSpacing,
                      value: _draft.letterSpacing,
                      min: 0,
                      max: 2,
                      divisions: 20,
                      valueLabel: _draft.letterSpacing.toStringAsFixed(1),
                      onChanged: (v) => _update(_draft.copyWith(letterSpacing: v)),
                    ),
                    const _Divider(),
                    SliderRow(
                      label: t.displaySettingsWordSpacing,
                      value: _draft.wordSpacing,
                      min: 0,
                      max: 4,
                      divisions: 8,
                      valueLabel: _draft.wordSpacing.toStringAsFixed(1),
                      onChanged: (v) => _update(_draft.copyWith(wordSpacing: v)),
                    ),
                    const _Divider(),
                    // Размер шрифта перевода — независим от
                    // арабского `fontSize`. Позволяет увеличить
                    // перевод (для слабовидящих), не увеличивая
                    // арабский. Default 14 px.
                    SliderRow(
                      label: t.displaySettingsTranslationFontSize,
                      value: _draft.translationFontSize,
                      min: 10,
                      max: 24,
                      divisions: 14,
                      valueLabel: '${_draft.translationFontSize.round()} ${t.displaySettingsUnitPx}',
                      onChanged: (v) =>
                          _update(_draft.copyWith(translationFontSize: v)),
                    ),
                    const _Divider(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Text(
                          t.displaySettingsFontFamily,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    ChoiceChipsRow<String>(
                      options: const [
                        (value: 'AmiriRegular', label: 'Amiri R'),
                        (value: 'AmiriBold', label: 'Amiri B'),
                      ],
                      selected: _draft.fontFamily,
                      onChanged: (v) => _update(_draft.copyWith(fontFamily: v)),
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Макет ─────────────────────────────────────────
              _GroupHeader(text: t.displaySettingsGroupLayout),
              const SizedBox(height: 8),
              _SettingsCard(
                child: Column(
                  children: [
                    SliderRow(
                      label: t.displaySettingsTextWidth,
                      value: _draft.textWidthPercent,
                      min: 70,
                      max: 100,
                      divisions: 6,
                      valueLabel: '${_draft.textWidthPercent.round()} ${t.displaySettingsUnitPercent}',
                      onChanged: (v) =>
                          _update(_draft.copyWith(textWidthPercent: v)),
                    ),
                    const _Divider(),
                    SliderRow(
                      label: t.displaySettingsPaddingHorizontal,
                      value: _draft.paddingHorizontal,
                      min: 8,
                      max: 32,
                      divisions: 6,
                      valueLabel: '${_draft.paddingHorizontal.round()} ${t.displaySettingsUnitPx}',
                      onChanged: (v) =>
                          _update(_draft.copyWith(paddingHorizontal: v)),
                    ),
                    const _Divider(),
                    SliderRow(
                      label: t.displaySettingsPaddingVertical,
                      value: _draft.paddingVertical,
                      min: 8,
                      max: 32,
                      divisions: 6,
                      valueLabel: '${_draft.paddingVertical.round()} ${t.displaySettingsUnitPx}',
                      onChanged: (v) =>
                          _update(_draft.copyWith(paddingVertical: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Тема ──────────────────────────────────────────
              _GroupHeader(text: t.displaySettingsGroupTheme),
              const SizedBox(height: 8),
              _SettingsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        t.displaySettingsBrightness,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SliderRow(
                      label: '',
                      value: _draft.brightness,
                      min: 60,
                      max: 100,
                      divisions: 8,
                      valueLabel: '${_draft.brightness.round()} ${t.displaySettingsUnitPercent}',
                      onChanged: (v) => _update(_draft.copyWith(brightness: v)),
                    ),
                    const _Divider(),
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Text(
                        '${t.displaySettingsGroupTheme}:',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    ChoiceChipsRow<String>(
                      options: [
                        (value: 'dark', label: t.displaySettingsThemeDark),
                        (value: 'sepia', label: t.displaySettingsThemeSepia),
                        (value: 'light', label: t.displaySettingsThemeLight),
                        (value: 'parchment', label: t.displaySettingsThemeParchment),
                      ],
                      selected: _draft.themeVariant,
                      onChanged: (v) => _update(_draft.copyWith(themeVariant: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // ── Дополнительно ────────────────────────────────
              _GroupHeader(text: t.displaySettingsGroupExtras),
              const SizedBox(height: 8),
              _SettingsCard(
                child: Column(
                  children: [
                    SwitchRow(
                      label: t.displaySettingsShowTranslation,
                      value: _draft.showTranslation,
                      onChanged: (v) =>
                          _update(_draft.copyWith(showTranslation: v)),
                    ),
                    // Параметры showWordByWord и keepScreenOn
                    // сохранены в [ReaderDisplaySettings] для
                    // будущего использования (когда обновим
                    // compileSdk до 34+ и подключим пакеты
                    // `wakelock_plus` / `screen_brightness` и
                    // наполним данные по словам). В UI временно
                    // не выводятся, чтобы не вводить пользователя
                    // в заблуждение тумблерами без эффекта.
                  ],
                ),
              ),
              ],
              ),
              // ── Sticky preview (поверх scroll) ───────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                // Фиксированная высота: padding (12 сверху) +
                // GroupHeader (~16) + SizedBox 8 + preview (~200) +
                // padding (8 снизу). Top = 0, body под ним.
                height: kPreviewHeight,
                // `Listener` ловит raw-pointer-события и прокидывает
                // вертикальный drag в `_bodyScrollCtrl`. Без этого
                // preview-поглощает свайп — пользователь не может
                // скроллить группы, начав жест с preview-области.
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (event) {
                    _dragStartY = event.position.dy;
                  },
                  onPointerMove: (event) {
                    if (_dragStartY == null) return;
                    final deltaY = event.delta.dy;
                    if (deltaY == 0) return;
                    final current = _bodyScrollCtrl.position.pixels;
                    final maxScroll =
                        _bodyScrollCtrl.position.maxScrollExtent;
                    final newOffset = (current + deltaY)
                        .clamp(0.0, maxScroll);
                    _bodyScrollCtrl.jumpTo(newOffset);
                  },
                  onPointerUp: (_) => _dragStartY = null,
                  onPointerCancel: (_) => _dragStartY = null,
                  child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundDeep,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GroupHeader(text: t.displaySettingsPreview),
                      const SizedBox(height: 8),
                      // `Flexible` — preview занимает оставшееся
                      // место; `PreviewAyah` не имеет bounded
                      // высоты и рендерит в свой натуральный размер.
                      Flexible(
                        child: PreviewAyah(
                          settings: _draft,
                          translationText: t.displaySettingsPreviewTranslation,
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 0.5),
      ),
      child: child,
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Divider(height: 1, color: AppColors.borderSubtle),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle, width: 0.5),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        body,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// Раньше здесь был `_StickyPreviewDelegate` на основе
// `SliverPersistentHeaderDelegate`. Удалён: у SliverPersistentHeader
// есть проблема с кешированием child'а — preview отставал от
// slider'ов на 1 frame и обновлялся только при scroll'е. Теперь
// header рендерится обычным `Positioned` в `Stack`, и `setState`
// родителя сразу его обновляет.
