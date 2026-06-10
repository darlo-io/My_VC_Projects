import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/i18n/localized_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final bookmarksRepo = ref.watch(bookmarksRepositoryProvider);
    final quranRepo = ref.watch(quranRepositoryProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              t.navBookmarks,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Bookmark>>(
              stream: bookmarksRepo.watchAll(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <Bookmark>[];
                if (items.isEmpty) {
                  return _EmptyState(
                    title: t.bookmarksEmpty,
                    hint: t.bookmarksEmptyHint,
                  );
                }
                return StreamBuilder<List<Surah>>(
                  stream: quranRepo.watchAllSurahs(),
                  builder: (context, surahSnap) {
                    final surahs = {
                      for (final s in surahSnap.data ?? const <Surah>[])
                        s.id: s,
                    };
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final bm = items[i];
                        final surah = surahs[bm.surahId];
                        return _BookmarkTile(
                          bookmark: bm,
                          surahId: bm.surahId,
                          surahName: surah?.nameTransliteration ?? '',
                          surahNameAr: surah?.nameAr ?? '',
                          onOpen: () => context.go(
                            '/reader/${bm.surahId}?ayah=${bm.ayahNumber}',
                          ),
                          onDelete: () => bookmarksRepo.dao.deleteByAyah(bm.ayahId),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    required this.bookmark,
    required this.surahId,
    required this.surahName,
    required this.surahNameAr,
    required this.onOpen,
    required this.onDelete,
  });

  final Bookmark bookmark;
  final int surahId;
  final String surahName;
  final String surahNameAr;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
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
              const Icon(Icons.bookmark, color: AppColors.gold, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.surahName(surahId, fallback: surahName),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.ayahLabel(bookmark.ayahNumber),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                surahNameAr,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                  fontFamily: 'Amiri',
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textTertiary,
                ),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.hint});
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bookmark_border,
            color: AppColors.textTertiary,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
