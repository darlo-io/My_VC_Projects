import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/safe_pop.dart';

import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../domain/reader_display_settings.dart';
import 'preview_ayah.dart';
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
/// Round 9.6 (code review #C8): 280px подобран эмпирически для
/// экстремальных значений (fontSize 40 + lineHeight 2.6):
///   1 строка арабского (104px) + 4 gap + 28 () + 12 gap +
///   1 строка перевода (40px) + 16+16 padding (top+bottom) = 220px,
/// с запасом 60px на sub-pixel rendering и `TextOverflow.fade`.
///
/// TODO: вычислить динамически через [MediaQuery.textScalerOf(context)]
/// × [ReaderDisplaySettings.fontSize] вместо hardcoded значения.
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
    safePop(context);
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
    if (mounted) safePop(context);
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
                  // ── «Показывать перевод» в самом верху ────────
                  // Самый частый toggle — вынесли наверх для
                  // быстрого доступа, без скролла к группе
                  // «Дополнительно» в самом низу.
                  _SettingsCard(
                    child: SwitchRow(
                      label: t.displaySettingsShowTranslation,
                      value: _draft.showTranslation,
                      onChanged: (v) =>
                          _update(_draft.copyWith(showTranslation: v)),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                    // Слайдер «Расст. между буквами» (letterSpacing)
                    // убран по запросу пользователя. Поле
                    // [letterSpacing] сохранено в [ReaderDisplaySettings]
                    // для будущего использования (пока — фиксированное
                    // значение 0.1 в `defaults`).
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
                    // DropdownMenuItem-стиль выпадающего списка,
                    // реализованный через `showMenu` (НЕ DropdownButton
                    // — последний создаёт overlay route, который
                    // конфликтует с GoRouter Navigator в нашем
                    // Stack+Positioned preview).
                    //
                    // Кнопка показывает текущий выбор, по тапу
                    // открывает `showMenu` со списком 4 шрифтов.
                    _FontFamilyMenu(
                      current: _draft.fontFamily,
                      onChanged: (v) =>
                          _update(_draft.copyWith(fontFamily: v)),
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
                    // Слайдер «ширина полосы» (textWidthPercent) убран
                    // по запросу пользователя. Текст в Reader всегда
                    // занимает полную ширину экрана (100% по
                    // умолчанию). Поле [textWidthPercent] сохранено
                    // в [ReaderDisplaySettings] (defaults: 100.0) на
                    // случай будущего использования.
                    SliderRow(
                      label: t.displaySettingsPaddingHorizontal,
                      value: _draft.paddingHorizontal,
                      // Начало диапазона: 0 (текст вплотную к
                      // краям экрана) — было 8.
                      min: 0,
                      max: 32,
                      divisions: 8,
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
                    // Ползунок «яркость экрана» убран: требует
                    // плагин `screen_brightness`, который не
                    // подключён (см. AGENTS.md / комментарии
                    // ниже про compileSdk).
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
              // ── Дополнительно (скрыта) ──────────────────────
              // `showTranslation` вынесен наверх (отдельной
              // карточкой над «Текст»). `keepScreenOn` сохранён
              // в [ReaderDisplaySettings] для будущего использования
              // (когда обновим compileSdk до 34+ и подключим
              // `wakelock_plus`). В UI временно не выводится, чтобы
              // не вводить пользователя в заблуждение тумблером
              // без эффекта. Раньше здесь упоминался и
              // `showWordByWord` — удалён 2026-07-17 (мёртвый
              // код, см. комментарий у `readingMode` в
              // `reader_display_settings.dart`).
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

/// Выпадающий список шрифтов в виде "menu button" —
/// кнопка показывает текущий шрифт, по тапу открывает
/// popupmenu со всеми 4 вариантами.
///
/// **Почему не `DropdownButton`**: он создаёт overlay route
/// через Navigator, что конфликтует с GoRouter в нашем
/// `Stack+Positioned` preview (assertion `keyReservation`
/// в `navigator.dart:4068`). `showMenu` использует тот же
/// механизм overlay, но не регистрирует route в Navigator,
/// а использует `Overlay.of(context).insert` напрямую.
class _FontFamilyMenu extends StatelessWidget {
  const _FontFamilyMenu({
    required this.current,
    required this.onChanged,
  });

  final String current;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final currentIndex =
        ReaderDisplaySettings.fontFamilyIndex(current);
    final currentLabel = ReaderDisplaySettings
        .fontFamilyLabels[currentIndex];
    final currentFamily = ReaderDisplaySettings
        .fontFamilies[currentIndex];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            // Получаем позицию кнопки для всплывающего меню.
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final overlay = Overlay.of(context).context
                .findRenderObject() as RenderBox?;
            if (overlay == null) return;
            final topLeft = box.localToGlobal(
              Offset.zero,
              ancestor: overlay,
            );

            final selected = await showMenu<String>(
              context: context,
              position: RelativeRect.fromLTRB(
                topLeft.dx,
                topLeft.dy + box.size.height,
                overlay.size.width - topLeft.dx - box.size.width,
                overlay.size.height -
                    topLeft.dy -
                    box.size.height,
              ),
              color: AppColors.surfaceElevated,
              items: [
                for (var i = 0;
                    i < ReaderDisplaySettings.fontFamilies.length;
                    i++)
                  PopupMenuItem<String>(
                    value: ReaderDisplaySettings.fontFamilies[i],
                    child: Row(
                      children: [
                        if (i == currentIndex)
                          const Icon(
                            Icons.check,
                            color: AppColors.gold,
                            size: 18,
                          )
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 12),
                        Text(
                          ReaderDisplaySettings.fontFamilyLabels[i],
                          style: TextStyle(
                            fontFamily: ReaderDisplaySettings
                                .fontFamilies[i],
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            fontWeight: i == currentIndex
                                ? FontWeight.w600
                                : FontWeight.w400,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            child: Row(
              children: [
                Text(
                  currentLabel,
                  style: TextStyle(
                    fontFamily: currentFamily,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_drop_down,
                  color: AppColors.gold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
