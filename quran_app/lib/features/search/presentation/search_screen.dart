import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/database/daos/ayah_dao.dart';
import '../../../core/database/daos/surah_dao.dart';
import '../../../core/database/daos/translation_dao.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/screen_header.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  bool _searchInSurahOnly = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: t.search,
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
              controller: _ctrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: t.searchHint,
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: AppColors.gold),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'all', label: Text(t.searchAll)),
                ButtonSegment(value: 'surah', label: Text(t.searchSurahOnly)),
              ],
              selected: {_searchInSurahOnly ? 'surah' : 'all'},
              onSelectionChanged: (s) => setState(
                () => _searchInSurahOnly = s.first == 'surah',
              ),
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(AppColors.surface),
                foregroundColor: WidgetStatePropertyAll(AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _query.trim().isEmpty
                ? const _EmptyState()
                : _SearchResults(
                    query: _query,
                    surahOnly: _searchInSurahOnly,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Sealed hit model. Exactly one of the three payload fields is set
/// per scope:
///   - surah scope   -> [SurahSearchHit]
///   - all + ar UI   -> [AyahSearchHit]
///   - all + other   -> deduped mix of [TranslationSearchHit] and
///                       [AyahSearchHit] (translation wins)
sealed class _SearchHit {
  const _SearchHit();

  int get surahId;
  int get ayahNumber;
  String get headerLabel;
  void openReader(BuildContext context);
}

class _SurahHit extends _SearchHit {
  const _SurahHit(this.data);
  final SurahSearchHit data;

  @override
  int get surahId => data.surahId;

  @override
  int get ayahNumber => 1;

  @override
  String get headerLabel => 'Surah ${data.surahId}';

  @override
  void openReader(BuildContext context) =>
      context.go('/reader/${data.surahId}?ayah=1');
}

class _AyahHit extends _SearchHit {
  const _AyahHit(this.data);
  final AyahSearchHit data;

  @override
  int get surahId => data.surahId;

  @override
  int get ayahNumber => data.ayahNumber;

  @override
  String get headerLabel =>
      '${data.surahNameAr} • ${data.surahId} • ${data.ayahNumber}';

  @override
  void openReader(BuildContext context) =>
      context.go('/reader/${data.surahId}?ayah=${data.ayahNumber}');
}

class _TranslationHit extends _SearchHit {
  const _TranslationHit(this.data);
  final TranslationSearchHit data;

  @override
  int get surahId => data.surahId;

  @override
  int get ayahNumber => data.ayahNumber;

  @override
  String get headerLabel =>
      '${data.surahNameAr} • ${data.surahId} • ${data.ayahNumber}';

  @override
  void openReader(BuildContext context) =>
      context.go('/reader/${data.surahId}?ayah=${data.ayahNumber}');
}

/// Поиск с debounce 250 мс. Routes through the FTS5-backed DAO
/// methods; no inline SQL. Normalization is delegated to
/// `buildFtsPrefixQuery` in `core/search/fts_query.dart` so this
/// screen and the FTS DAOs stay in lock-step on what characters
/// are safe in a user-typed query.
class _SearchResults extends ConsumerStatefulWidget {
  const _SearchResults({required this.query, required this.surahOnly});

  final String query;
  final bool surahOnly;

  @override
  ConsumerState<_SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends ConsumerState<_SearchResults> {
  Future<List<_SearchHit>>? _future;

  @override
  void initState() {
    super.initState();
    _scheduleSearch();
  }

  @override
  void didUpdateWidget(covariant _SearchResults old) {
    super.didUpdateWidget(old);
    if (old.query != widget.query || old.surahOnly != widget.surahOnly) {
      _scheduleSearch();
    }
  }

  void _scheduleSearch() {
    final q = widget.query;
    final surahOnly = widget.surahOnly;
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (widget.query != q || widget.surahOnly != surahOnly) return;
      setState(() {
        _future = _runSearch(q, surahOnly);
      });
    });
  }

  Future<List<_SearchHit>> _runSearch(String query, bool surahOnly) async {
    if (surahOnly) {
      final hits = await ref.read(surahDaoProvider).searchByText(query);
      return hits.map(_SurahHit.new).toList();
    }
    final ayahDao = ref.read(ayahDaoProvider);
    final translationDao = ref.read(translationDaoProvider);
    final lang = ref.read(appPreferencesProvider).translationLang;
    final includeTranslation = lang != 'ar';
    final results = await Future.wait<Object>([
      ayahDao.searchByText(query),
      if (includeTranslation)
        translationDao.search(query: query, languageCode: lang),
    ]);
    final ayahs = results[0] as List<AyahSearchHit>;
    final translations = includeTranslation
        ? results[1] as List<TranslationSearchHit>
        : const <TranslationSearchHit>[];
    final byAyah = <int, _SearchHit>{};
    for (final t in translations) {
      byAyah[t.ayahId] = _TranslationHit(t);
    }
    for (final a in ayahs) {
      byAyah.putIfAbsent(a.ayahId, () => _AyahHit(a));
    }
    final merged = byAyah.values.toList()
      ..sort((a, b) {
        final s = a.surahId.compareTo(b.surahId);
        if (s != 0) return s;
        return a.ayahNumber.compareTo(b.ayahNumber);
      });
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final future = _future;
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<List<_SearchHit>>(
      future: future,
      builder: (context, snap) {
        final hits = snap.data ?? const <_SearchHit>[];
        if (hits.isEmpty) {
          return _EmptyState(
            title: t.searchResultsEmpty,
            hint: t.searchResultsEmptyHint,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: hits.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final h = hits[i];
            return _HitTile(
              hit: h,
              onTap: () => h.openReader(context),
            );
          },
        );
      },
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit, required this.onTap});
  final _SearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context, t),
              const SizedBox(height: 8),
              _body(context, t),
              if (hit case _TranslationHit(:final data)) ...[
                const SizedBox(height: 6),
                Text(
                  data.translatorName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, AppLocalizations t) {
    return switch (hit) {
      _SurahHit() => Text(
          '${t.surahLabel} ${hit.surahId}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gold,
            fontWeight: FontWeight.w600,
          ),
        ),
      _AyahHit() || _TranslationHit() => Text(
          hit.headerLabel,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gold,
            fontWeight: FontWeight.w600,
          ),
        ),
    };
  }

  Widget _body(BuildContext context, AppLocalizations t) {
    return switch (hit) {
      _SurahHit(:final data) => Row(
          children: [
            Expanded(
              child: Text(
                data.nameTransliteration,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              data.nameAr,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 22,
                color: AppColors.gold,
                fontFamily: 'Amiri',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      _AyahHit(:final data) => Text(
          data.textUthmani,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 20,
            height: 1.6,
            fontFamily: 'Amiri',
            color: AppColors.textPrimary,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      _TranslationHit(:final data) => Text(
          data.text,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.title, this.hint});
  final String? title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, color: AppColors.textTertiary, size: 56),
          const SizedBox(height: 16),
          Text(
            title ?? t.search,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(
              hint!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
