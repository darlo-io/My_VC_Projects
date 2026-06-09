import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/data/juz_mapping.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/i18n/localized_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'surah_list_screen.dart';

class SegmentButton extends StatelessWidget {
  const SegmentButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? AppColors.surfaceElevated
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? AppColors.gold : AppColors.borderSubtle,
              width: active ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: active ? AppColors.gold : AppColors.textTertiary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.gold : AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SurahRow extends StatelessWidget {
  const SurahRow({required this.surah, super.key});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isMeccan = surah.revelationType.toLowerCase() == 'meccan';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/reader/${surah.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CustomPaint(
                  painter: const NumberOrnamentPainter(),
                  child: Center(
                    child: Text(
                      '${surah.id}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.surahName(surah.id, fallback: surah.nameTransliteration),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${t.ayahsCount(surah.ayahCount)} • ${isMeccan ? t.revelationMeccan : t.revelationMedinan}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                surah.nameAr,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                  fontFamily: 'Amiri',
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.gold, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class JuzList extends ConsumerWidget {
  const JuzList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: 30,
      itemBuilder: (_, i) {
        final juzNumber = i + 1;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              // Resolve the first ayah of this Juz from the
              // database via [AyahDao.watchByJuz]. We previously
              // used the hardcoded [kJuzStarts] table for
              // this; now that the DAO computes the range from
              // the same in-memory boundaries (and the column is
              // backfilled by the post-create migration), the
              // tap target reflects whatever seed or future
              // corrections a developer might have applied.
              //
              // `watchByJuz` returns a Stream; we only need the
              // first emission. If the DB is empty (still
              // seeding) the stream is empty and we fall back
              // to the hardcoded table so the tap never breaks
              // the UI.
              final first = await ref
                  .read(ayahDaoProvider)
                  .watchByJuz(juzNumber, limit: 1)
                  .first;
              if (!context.mounted) return;
              if (first.isNotEmpty) {
                final a = first.first;
                context.go('/reader/${a.surahId}?ayah=${a.ayahNumber}');
              } else {
                final start = juzStart(juzNumber);
                context.go(
                  '/reader/${start.surahId}?ayah=${start.ayahNumber}',
                );
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t.juzNumber(i + 1),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
