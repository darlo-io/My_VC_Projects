import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/i18n/localized_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Quick-settings bottom-sheet, открываемый из верхней панели
/// Reader'а (кнопка `Icons.tune`).
///
/// В отличие от полного `SettingsScreen` (через `/profile`),
/// здесь собраны **только** те настройки, которые влияют на
/// текущее чтение: размер шрифта, режим отображения (построчно /
/// книгой), язык перевода и язык интерфейса. Кнопка «Все
/// настройки» внизу ведёт на полный `SettingsScreen` — `go` вместо
/// `push`, потому что `/profile` лежит в `ShellRoute` и `push` на
/// такой роут из Reader'а рендерит пустую страницу (известная
/// особенность GoRouter 14.x при `push` в `ShellRoute` снаружи
/// самого `ShellRoute`).
class ReaderSettingsSheet extends ConsumerWidget {
  const ReaderSettingsSheet({
    required this.readingMode,
    required this.onReadingModeChange,
    super.key,
  });

  /// Текущий режим отображения (`'lineByLine'` или `'book'`).
  final String readingMode;

  /// При смене режима из шторки — вызывающий код выставляет
  /// локальный `_readingMode` и пишет в preferences.
  final ValueChanged<String> onReadingModeChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final prefs = ref.watch(appPreferencesProvider);
    final lang = ref.watch(languageProvider);
    const fontSizes = [20.0, 24.0, 28.0, 32.0, 36.0];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // «Ручка» шторки — визуальный affordance.
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              t.settings,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _SectionLabel(text: t.settingsFontSize),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fontSizes
                  .map(
                    (s) => _ChoiceChip(
                      label: '${s.round()}',
                      selected: prefs.fontSize == s,
                      onTap: () async {
                        await ref
                            .read(appPreferencesProvider)
                            .setFontSize(s);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            _SectionLabel(text: t.readingModeTooltip),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _ChoiceChip(
                    label: t.readingModeLineByLine,
                    selected: readingMode == 'lineByLine',
                    fullWidth: true,
                    onTap: () {
                      onReadingModeChange('lineByLine');
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ChoiceChip(
                    label: t.readingModeBook,
                    selected: readingMode == 'book',
                    fullWidth: true,
                    onTap: () {
                      onReadingModeChange('book');
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionLabel(text: t.settingsLanguage),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['ru', 'en', 'ar']
                  .map(
                    (code) => _ChoiceChip(
                      label: _langLabel(t, code),
                      selected: lang == code,
                      onTap: () async {
                        await ref
                            .read(appPreferencesProvider)
                            .setLanguageCode(code);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            // Ссылка на полные настройки отображения Reader'а.
            // Используем `push` (не `go`) — экран настроек
            // отображения живёт в собственном route (НЕ в
            // `ShellRoute`), и `push` корректно открывает его
            // **поверх** Reader'а с back-кнопкой в AppBar.
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // Сначала `push` (открываем экран настроек
                  // **поверх** bottom-sheet), затем `pop` sheet'а.
                  // Порядок важен: после `Navigator.pop` текущий
                  // `context` (sheet's) становится невалиден, и
                  // следующий `context.push` бросает / молча
                  // игнорируется. С `push` первым — новый роут
                  // кладётся в стек **до** закрытия sheet'а, и
                  // пользователь видит экран настроек, а не
                  // обратно Reader.
                  //
                  // `try/catch` — `context.push` может бросить
                  // `Object` (нет подходящего GoError), если
                  // `context` уже невалиден; ловим широко.
                  try {
                    // ignore: avoid_print
                    print('READER: pushing /reader-settings/display');
                    context.push('/reader-settings/display');
                    // ignore: avoid_print
                    print('READER: push done, popping sheet');
                  } catch (e, st) {
                    // ignore: avoid_print
                    print('READER: push failed: $e\n$st');
                  }
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.tune, size: 18),
                label: Text(t.displaySettingsTitle),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(
                    color: AppColors.gold,
                    width: 1,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _langLabel(AppLocalizations t, String code) {
    switch (code) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return code;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final chip = Material(
      color: selected
          ? AppColors.gold
          : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppColors.backgroundDeep
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
    if (fullWidth) {
      return SizedBox(width: double.infinity, child: chip);
    }
    return chip;
  }
}
