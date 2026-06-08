import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/ayah_dao.dart';
import '../../../../core/database/daos/surah_dao.dart';
import '../../../../core/database/daos/translation_dao.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/screen_header.dart';
import 'widgets.dart';

/// Search mode selected by the segment switcher under the search bar.
enum _SearchScope { surah, ayah, juz }

class SurahListScreen extends ConsumerStatefulWidget {
  const SurahListScreen({super.key});

  @override
  ConsumerState<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends ConsumerState<SurahListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _SearchScope _scope = _SearchScope.surah;

  // Debounce timer for FTS-backed search so we don't query on every
  // keystroke. 250 ms feels instant but coalesces typing bursts.
  Timer? _debounce;
  // The query that was last actually submitted to the DAO. Used to
  // guard against overlapping results when the user types fast.
  String _submittedQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();
    if (_scope != _SearchScope.surah) {
      // FTS-backed scopes need debouncing; the surah list is in-memory
      // filtering on a 114-row stream so it's free to do per-keystroke.
      _debounce = Timer(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _submittedQuery = value.trim());
      });
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final dao = ref.watch(surahDaoProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: t.cardRead,
            subtitle: t.chooseSurah,
            actions: [
              CircleIconButton(
                icon: Icons.bookmark_outline,
                onTap: () => context.go('/bookmarks'),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: t.searchByNameOrNumber,
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                suffixIcon: IconButton(
                  onPressed: () {
                    _searchCtrl.clear();
                    _onQueryChanged('');
                  },
                  icon: const Icon(Icons.tune, color: AppColors.gold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: SegmentButton(
                    label: t.tabSurahs,
                    icon: Icons.menu_book_rounded,
                    active: _scope == _SearchScope.surah,
                    onTap: () => setState(() {
                      _scope = _SearchScope.surah;
                      _submittedQuery = '';
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentButton(
                    label: t.tabAyahs,
                    icon: Icons.search,
                    active: _scope == _SearchScope.ayah,
                    onTap: () => setState(() {
                      _scope = _SearchScope.ayah;
                      _submittedQuery = _query.trim();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentButton(
                    label: t.tabJuz,
                    icon: Icons.bookmark_outline,
                    active: _scope == _SearchScope.juz,
                    onTap: () => setState(() {
                      _scope = _SearchScope.juz;
                      _submittedQuery = '';
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: switch (_scope) {
              _SearchScope.juz => const JuzList(),
              _SearchScope.surah => _SurahList(query: _query, dao: dao),
              _SearchScope.ayah => _AyahSearchResults(
                  query: _submittedQuery,
                  ayahDao: ref.watch(ayahDaoProvider),
                  translationDao: ref.watch(translationDaoProvider),
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList({required this.query, required this.dao});

  final String query;
  final SurahDao dao;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return StreamBuilder<List<Surah>>(
      stream: dao.watchAll(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Surah>[];
        final q = query.toLowerCase();
        final filtered = query.isEmpty
            ? items
            : items.where((s) {
                // Search by every language we ship: transliteration
                // (Latin), English, Arabic, and numeric id. ARB
                // translation is deliberately not searched here —
                // it's already derived from these three.
                return s.nameTransliteration.toLowerCase().contains(q) ||
                    s.nameEn.toLowerCase().contains(q) ||
                    s.nameAr.contains(query) ||
                    s.id.toString() == query;
              }).toList();
        if (filtered.isEmpty) {
          return _EmptyMessage(text: t.searchResultsEmpty);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: filtered.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => SurahRow(surah: filtered[i]),
        );
      },
    );
  }
}

class _AyahSearchResults extends StatelessWidget {
  const _AyahSearchResults({
    required this.query,
    required this.ayahDao,
    required this.translationDao,
  });

  final String query;
  final AyahDao ayahDao;
  final TranslationDao translationDao;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (query.isEmpty) {
      return _EmptyMessage(text: t.searchAyahHint);
    }
    final loc = Localizations.localeOf(context);
    // Translation search is only meaningful for non-Arabic locales
    // (we ship Russian Kuliev/Porohova + English Sahih). For Arabic
    // we surface the Arabic-original FTS results instead, so the
    // user always sees *something* matching their query.
    final isArabic = loc.languageCode == 'ar';
    return FutureBuilder<List<Object>>(
      future: _runSearch(
        query: query,
        ayahDao: ayahDao,
        translationDao: translationDao,
        includeTranslation: !isArabic,
        languageCode: isArabic ? 'en' : loc.languageCode,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          );
        }
        final results = snapshot.data ?? const <Object>[];
        if (results.isEmpty) {
          return _EmptyMessage(text: t.searchResultsEmpty);
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: results.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = results[i];
            if (r is AyahSearchHit) {
              return _AyahHitRow(hit: r);
            }
            if (r is TranslationSearchHit) {
              return _TranslationHitRow(hit: r);
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Future<List<Object>> _runSearch({
    required String query,
    required AyahDao ayahDao,
    required TranslationDao translationDao,
    required bool includeTranslation,
    required String languageCode,
  }) async {
    final arabicHits = await ayahDao.searchByText(query);
    if (!includeTranslation) return List<Object>.from(arabicHits);
    final translationHits = await translationDao.search(
      query: query,
      languageCode: languageCode,
    );
    // Merge: dedupe by ayahId, prefer translation over arabic (the
    // user typed in a non-Arabic locale and is more likely to want
    // the readable hit first), keep list stable on surah/ayah order.
    final byAyah = <int, Object>{};
    for (final h in translationHits) {
      byAyah[h.ayahId] = h;
    }
    for (final h in arabicHits) {
      byAyah.putIfAbsent(h.ayahId, () => h);
    }
    final merged = byAyah.values.toList()
      ..sort((a, b) {
        final sa = a is AyahSearchHit ? a.surahId : (a as TranslationSearchHit).surahId;
        final sb = b is AyahSearchHit ? b.surahId : (b as TranslationSearchHit).surahId;
        if (sa != sb) return sa.compareTo(sb);
        final na = a is AyahSearchHit ? a.ayahNumber : (a as TranslationSearchHit).ayahNumber;
        final nb = b is AyahSearchHit ? b.ayahNumber : (b as TranslationSearchHit).ayahNumber;
        return na.compareTo(nb);
      });
    return merged;
  }
}

class _AyahHitRow extends StatelessWidget {
  const _AyahHitRow({required this.hit});
  final AyahSearchHit hit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () =>
            context.go('/reader/${hit.surahId}?ayah=${hit.ayahNumber}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${hit.surahNameAr} • ${t.surahLabel} ${hit.surahId} • ${hit.ayahNumber}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                hit.textUthmani,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  height: 1.7,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TranslationHitRow extends StatelessWidget {
  const _TranslationHitRow({required this.hit});
  final TranslationSearchHit hit;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () =>
            context.go('/reader/${hit.surahId}?ayah=${hit.ayahNumber}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${hit.surahNameAr} • ${t.surahLabel} ${hit.surahId} • ${hit.ayahNumber}',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    hit.translatorName,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                hit.text,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

/// 16-конечная звезда-орнамент для номера суры.
class NumberOrnamentPainter extends CustomPainter {
  const NumberOrnamentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2 - 2;
    const points = 16;
    for (var i = 0; i < points; i++) {
      final a = i * 2 * math.pi / points;
      final rr = i.isEven ? r : r * 0.92;
      final x = cx + rr * math.cos(a);
      final y = cy + rr * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(NumberOrnamentPainter old) => false;
}
