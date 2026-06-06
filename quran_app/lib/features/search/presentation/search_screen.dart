import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/database/app_database.dart';
import '../../../core/search/arabic_normalizer.dart';
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

/// Поиск с debounce 250 мс и кешем по ключу (query, lang, surahOnly).
class _SearchResults extends ConsumerStatefulWidget {
  const _SearchResults({required this.query, required this.surahOnly});

  final String query;
  final bool surahOnly;

  @override
  ConsumerState<_SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends ConsumerState<_SearchResults> {
  Future<List<SearchHit>>? _future;

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
    // Debounce: откладываем запуск на 250 мс, чтобы не спамить запросами
    // на каждом keystroke.
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      if (widget.query != q || widget.surahOnly != surahOnly) return;
      final db = ref.read(appDatabaseProvider);
      final lang = ref.read(appPreferencesProvider).translationLang;
      setState(() {
        _future = _runSearch(db, q, lang, surahOnly);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final future = _future;
    if (future == null) return const SizedBox.shrink();
    return FutureBuilder<List<SearchHit>>(
      future: future,
      builder: (context, snap) {
        final hits = snap.data ?? const <SearchHit>[];
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
              onTap: () => context.go(
                '/reader/${h.surahId}?ayah=${h.ayahNumber}',
              ),
            );
          },
        );
      },
    );
  }
}

Future<List<SearchHit>> _runSearch(
  AppDatabase db,
  String query,
  String lang,
  bool surahOnly,
) async {
  final q = query.trim();
  if (q.isEmpty) return const [];
  final qNorm = ArabicNormalizer.normalize(q);

  if (surahOnly) {
    final rows = await db.customSelect(
      '''
      SELECT id, name_ar, name_transliteration, name_en
      FROM surahs
      WHERE LOWER(name_transliteration) LIKE ? OR LOWER(name_en) LIKE ? OR name_ar LIKE ?
      LIMIT 30
      ''',
      variables: [
        Variable.withString('${q.toLowerCase()}%'),
        Variable.withString('${q.toLowerCase()}%'),
        Variable.withString('$q%'),
      ],
      readsFrom: {db.surahs},
    ).get();
    return rows
        .map(
          (r) => SearchHit(
            surahId: r.read<int>('id'),
            ayahNumber: 1,
            surahName: (r.readNullable<String>('name_transliteration')) ?? '',
            arabic: r.read<String>('name_ar'),
            translation: (r.readNullable<String>('name_en')) ?? '',
          ),
        )
        .toList();
  }

  final ayahRows = await db.customSelect(
    '''
    SELECT a.id, a.surah_id, a.ayah_number, a.text_uthmani, s.name_transliteration
    FROM ayahs_fts f
    JOIN ayahs a ON a.id = f.rowid
    JOIN surahs s ON s.id = a.surah_id
    WHERE ayahs_fts MATCH ?
    LIMIT 50
    ''',
    variables: [Variable.withString('$qNorm*')],
    readsFrom: {db.ayahs, db.surahs},
  ).get();
  return ayahRows
      .map(
        (r) => SearchHit(
          surahId: r.read<int>('surah_id'),
          ayahNumber: r.read<int>('ayah_number'),
          surahName: (r.readNullable<String>('name_transliteration')) ?? '',
          arabic: r.read<String>('text_uthmani'),
          translation: '',
        ),
      )
      .toList();
}

class SearchHit {
  const SearchHit({
    required this.surahId,
    required this.ayahNumber,
    required this.surahName,
    required this.arabic,
    required this.translation,
  });

  final int surahId;
  final int ayahNumber;
  final String surahName;
  final String arabic;
  final String translation;
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit, required this.onTap});
  final SearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              Text(
                '${hit.surahName} • ${hit.ayahNumber}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hit.arabic,
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
              if (hit.translation.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  hit.translation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
        mainAxisSize: MainAxisSize.min,
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
