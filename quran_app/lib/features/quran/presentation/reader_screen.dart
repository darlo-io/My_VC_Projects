import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/i18n/localized_names.dart';
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
  late final PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    // PageView is 0-indexed; the route's `?ayah=` is 1-indexed.
    _pageCtrl = PageController(
      initialPage: (widget.initialAyah - 1).clamp(0, 1 << 30),
    );
    // Persist the "last position" and the daily reading-history
    // increment once per screen-mount, after the first frame so
    // we don't block the initial paint. Both are UPSERTs so
    // re-entering the same (date, surah, ayah) is a no-op for
    // history and an idempotent update for the last position.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final dao = ref.read(positionDaoProvider);
      // Resolve the DB row id for the route's initialAyah. The
      // stream provider hasn't been read yet at this point, so we
      // issue a direct query. If it fails (e.g. ayah number out
      // of range) we fall back to the route's value — better to
      // record something than to crash before the first frame.
      final initialAyah = widget.initialAyah;
      final ayahRow = await ref
          .read(ayahDaoProvider)
          .getBySurahAndNumber(widget.surahId, initialAyah);
      if (!mounted) return;
      final ayahId = ayahRow?.id ?? initialAyah;
      await dao.setLast(surahId: widget.surahId, ayahId: ayahId);
      await dao.recordReading(
        date: DateTime.now(),
        surahId: widget.surahId,
        ayahsRead: 1,
      );
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
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
    // Adjacent surahs for the prev/next sticky bars. Disabled on
    // the first and last surah respectively.
    final prevSurahId = widget.surahId > 1 ? widget.surahId - 1 : null;
    final nextSurahId = widget.surahId < 114 ? widget.surahId + 1 : null;

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
                return Column(
                  children: [
                    SurahTitleFrame(
                      arabicName: surah.nameAr,
                      transliteration: t.surahName(surah.id,
                          fallback: surah.nameTransliteration),
                      subtitle: t.ayahsCount(surah.ayahCount),
                    ),
                    if (prevSurahId != null) ...[
                      const SizedBox(height: 8),
                      _SurahNavChip(
                        direction: _NavDirection.prev,
                        targetSurahId: prevSurahId,
                      ),
                    ],
                  ],
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
                  return PageView.builder(
                    controller: _pageCtrl,
                    itemCount: ayahs.length,
                    onPageChanged: (i) {
                      // Persist the new "last position" on every
                      // page change. PageView fires this once per
                      // settled page, so we don't need a debounce.
                      // The DAO is an UPSERT so re-entering the
                      // same ayah is a no-op.
                      final a = ayahs[i];
                      ref
                          .read(positionDaoProvider)
                          .setLast(surahId: a.surahId, ayahId: a.id);
                    },
                    itemBuilder: (_, i) {
                      final a = ayahs[i];
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          8,
                          20,
                          nextSurahId == null ? 16 : 16,
                        ),
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: AyahTile(
                              ayah: a,
                              translation:
                                  dataAsync.value?.translations[a.id],
                              fontSize: prefs.fontSize,
                              isBookmarked: bookmarkedIds.contains(a.id),
                              onToggleBookmark: () => toggleBookmark(
                                ref,
                                ayah: a,
                                isCurrentlyBookmarked:
                                    bookmarkedIds.contains(a.id),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            if (nextSurahId != null)
              _SurahNavChip(
                direction: _NavDirection.next,
                targetSurahId: nextSurahId,
              ),
          ],
        ),
      ),
    );
  }
}

enum _NavDirection { prev, next }

/// Sticky bar that links to the prev/next surah. Loads the target
/// surah's name asynchronously and shows a localized fallback until
/// the lookup completes. Tapping pushes the new route; the
/// `_readerDataProvider` is `autoDispose.family` so it re-fetches
/// for the new surahId without a manual cache clear.
class _SurahNavChip extends ConsumerWidget {
  const _SurahNavChip({
    required this.direction,
    required this.targetSurahId,
  });

  final _NavDirection direction;
  final int targetSurahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final isPrev = direction == _NavDirection.prev;
    final label = isPrev ? t.readerPrevSurah : t.readerNextSurah;
    final isEdge = (isPrev && targetSurahId == 1) ||
        (!isPrev && targetSurahId == 114);
    final fallbackName = isEdge
        ? (isPrev ? t.readerFirstSurah : t.readerLastSurah)
        : null;
    final surahAsync = ref.watch(_surahNameProvider(targetSurahId));
    final targetName = surahAsync.value?.nameTransliteration ?? fallbackName;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, isPrev ? 0 : 0, 20, isPrev ? 0 : 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.go('/reader/$targetSurahId?ayah=1'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                if (isPrev) ...[
                  const Icon(Icons.chevron_left, color: AppColors.gold),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: isPrev
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        targetName ?? '…',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isPrev) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: AppColors.gold),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cached lookup of a single surah by id. Used by [_SurahNavChip]
/// for the prev/next labels.
final _surahNameProvider = FutureProvider.autoDispose
    .family<Surah?, int>((ref, id) => ref.watch(surahDaoProvider).getById(id));

/// Поток аятов одной суры. Не смотрит всю таблицу `ayahs`, только
/// нужные строки (Drift сам эмитит при изменениях).
final _ayahsStreamProvider = StreamProvider.autoDispose.family<List<Ayah>, int>(
  (ref, surahId) {
    return ref.watch(ayahDaoProvider).watchBySurah(surahId);
  },
);
