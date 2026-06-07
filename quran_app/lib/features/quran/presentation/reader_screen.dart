import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/ornaments.dart';
import '../../../shared/widgets/screen_header.dart';
import 'widgets/reader_widgets.dart';

/// Surah + translations для конкретного открытия. Закэшировано до смены
/// (surahId, translationLang), поэтому FutureBuilder в build не нужен.
final _readerDataProvider = FutureProvider.autoDispose
    .family<ReaderData, ReaderKey>((ref, key) async {
      final surah = await ref.read(surahDaoProvider).getById(key.surahId);
      if (surah == null) {
        return const ReaderData(surah: null, translations: {});
      }
      final rows = await ref
          .read(translationDaoProvider)
          .getForSurah(surahId: key.surahId, languageCode: key.translationLang);
      final map = <int, String>{for (final r in rows) r.ayahId: r.text};
      return ReaderData(surah: surah, translations: map);
    });

class ReaderKey {
  const ReaderKey({required this.surahId, required this.translationLang});
  final int surahId;
  final String translationLang;

  @override
  bool operator ==(Object other) =>
      other is ReaderKey &&
      other.surahId == surahId &&
      other.translationLang == translationLang;

  @override
  int get hashCode => Object.hash(surahId, translationLang);
}

class ReaderData {
  const ReaderData({required this.surah, required this.translations});
  final Surah? surah;
  final Map<int, String> translations;
}

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    required this.surahId,
    required this.initialAyah,
    super.key,
  });

  final int surahId;
  final int initialAyah;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final prefs = ref.watch(appPreferencesProvider);
    final readerKey = ReaderKey(
      surahId: widget.surahId,
      translationLang: prefs.translationLang,
    );
    final dataAsync = ref.watch(_readerDataProvider(readerKey));
    final ayahsAsync = ref.watch(_ayahsStreamProvider(widget.surahId));
    final bookmarkedIds =
        ref.watch(bookmarkedAyahIdsProvider).value ?? const <int>{};

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: t.cardRead,
              onBack: () => context.go('/read'),
              actions: [
                CircleIconButton(
                  icon: Icons.search,
                  onTap: () => context.go('/search'),
                ),
                CircleIconButton(
                  icon: Icons.bookmark_outline,
                  onTap: () => context.go('/bookmarks'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            dataAsync.when(
              loading: () => const SizedBox(
                height: 80,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              error: (e, _) =>
                  SizedBox(height: 80, child: Center(child: Text('$e'))),
              data: (data) {
                final surah = data.surah;
                if (surah == null) return const SizedBox(height: 80);
                return SurahTitleFrame(
                  arabicName: surah.nameAr,
                  transliteration: surah.nameTransliteration,
                  subtitle: t.ayahsCount(surah.ayahCount),
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ayahsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (ayahs) {
                  if (ayahs.isEmpty) {
                    return Center(
                      child: Text(
                        t.searchResultsEmpty,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: ayahs.length,
                    separatorBuilder: (_, _) => const OrnateDivider(),
                    itemBuilder: (_, i) {
                      final a = ayahs[i];
                      return AyahTile(
                        ayah: a,
                        translation: dataAsync.value?.translations[a.id],
                        fontSize: prefs.fontSize,
                        isBookmarked: bookmarkedIds.contains(a.id),
                        onToggleBookmark: () => toggleBookmark(
                          ref,
                          ayah: a,
                          isCurrentlyBookmarked: bookmarkedIds.contains(a.id),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Поток аятов одной суры. Не смотрит всю таблицу `ayahs`, только
/// нужные строки (Drift сам эмитит при изменениях).
final _ayahsStreamProvider = StreamProvider.autoDispose.family<List<Ayah>, int>(
  (ref, surahId) {
    return ref.watch(ayahDaoProvider).watchBySurah(surahId);
  },
);
