import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/ornaments.dart';

class LanguagePickerScreen extends ConsumerWidget {
  const LanguagePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final current = ref.watch(languageProvider);
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: ArabesqueBackground(opacity: 0.05)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.firstLaunchTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEDE6D3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.firstLaunchSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB7A98F),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _LangTile(
                    title: t.languageRussian,
                    isSelected: current == 'ru',
                    onTap: () => _set(context, ref, 'ru'),
                  ),
                  const SizedBox(height: 12),
                  _LangTile(
                    title: t.languageEnglish,
                    isSelected: current == 'en',
                    onTap: () => _set(context, ref, 'en'),
                  ),
                  const SizedBox(height: 12),
                  _LangTile(
                    title: t.languageArabic,
                    isSelected: current == 'ar',
                    onTap: () => _set(context, ref, 'ar'),
                  ),
                  const Spacer(),
                  GoldPillButton(
                    label: t.firstLaunchAction,
                    onPressed: () => context.go('/'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _set(BuildContext context, WidgetRef ref, String code) async {
    await ref.read(languageProvider.notifier).set(code);
  }
}

class _LangTile extends StatelessWidget {
  const _LangTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFD4A84A)
                    : const Color(0x33D4A84A),
                width: 2,
              ),
              color: isSelected
                  ? const Color(0xFFD4A84A)
                  : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 14, color: Color(0xFF1A1408))
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Color(0xFFEDE6D3),
            ),
          ),
        ],
      ),
    );
  }
}
