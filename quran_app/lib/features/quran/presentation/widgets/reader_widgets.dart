import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/ornaments.dart';

class AyahTile extends ConsumerWidget {
  const AyahTile({
    required this.ayah,
    required this.translation,
    required this.fontSize,
    required this.isBookmarked,
    required this.onToggleBookmark,
    super.key,
  });

  final Ayah ayah;
  final String? translation;
  final double fontSize;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AyahNumberBadge(number: ayah.ayahNumber),
              const Spacer(),
              IconButton(
                onPressed: onToggleBookmark,
                icon: BookmarkStar(filled: isBookmarked, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            ayah.textUthmani,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: fontSize,
              height: 2.0,
              color: AppColors.textPrimary,
              fontFamily: 'Amiri',
            ),
          ),
          if (translation != null) ...[
            const SizedBox(height: 12),
            Text(
              translation!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Один стрим на весь экран: множество ID аятов с закладками.
final bookmarkedAyahIdsProvider = StreamProvider<Set<int>>((ref) {
  return ref.watch(bookmarkDaoProvider).watchBookmarkedAyahIds();
});

Future<void> toggleBookmark(
  WidgetRef ref, {
  required Ayah ayah,
  required bool isCurrentlyBookmarked,
}) async {
  final dao = ref.read(bookmarkDaoProvider);
  if (isCurrentlyBookmarked) {
    await dao.deleteByAyah(ayah.id);
  } else {
    await dao.insertBookmark(
      BookmarksCompanion.insert(
        surahId: ayah.surahId,
        ayahId: ayah.id,
        ayahNumber: ayah.ayahNumber,
      ),
    );
  }
}
