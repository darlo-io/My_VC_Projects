import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/i18n/localized_names.dart';
import '../../../../core/search/arabic_normalizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/screen_header.dart';
import 'widgets.dart';

/// Search mode selected by the segment switcher under the search bar.
enum _SearchScope { surah, juz }

class SurahListScreen extends ConsumerStatefulWidget {
  const SurahListScreen({super.key});

  @override
  ConsumerState<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends ConsumerState<SurahListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _SearchScope _scope = _SearchScope.surah;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    if (_query == value) return;
    setState(() => _query = value);
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _onQueryChanged('');
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
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: t.searchByNameOrNumber,
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: t.clear,
                        onPressed: _clearSearch,
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textTertiary,
                        ),
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
                    onTap: () => setState(() => _scope = _SearchScope.surah),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentButton(
                    label: t.tabJuz,
                    icon: Icons.bookmark_outline,
                    active: _scope == _SearchScope.juz,
                    onTap: () => setState(() => _scope = _SearchScope.juz),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: switch (_scope) {
              _SearchScope.juz => const JuzList(),
              _SearchScope.surah => _SurahList(
                  query: _query,
                  stream: ref.watch(quranRepositoryProvider).watchAllSurahs(),
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _SurahList extends StatelessWidget {
  const _SurahList({required this.query, required this.stream});

  final String query;
  final Stream<List<Surah>> stream;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    return StreamBuilder<List<Surah>>(
      stream: stream,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <Surah>[];
        final q = query.trim();
        if (q.isEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => SurahRow(surah: items[i]),
          );
        }
        final qLower = q.toLowerCase();
        // Арабская нормализация запроса применяется **всегда**:
        // даже если пользователь набирает латиницей/кириллицей,
        // она просто остаётся как есть. Но для арабского ввода
        // (с огласовками или вариантами алефа) сравнение с
        // `s.nameAr` идёт по нормализованной форме.
        final qArabicNorm = ArabicNormalizer.normalize(q);

        // Названия на языке интерфейса приложения: для `ru` —
        // `surahMeaningRu`, для `en` — `surahEn`, для прочих
        // локалей — `null` (поиск по значению скрывается).
        final localizedMeaning = (int id) =>
            LocalizedNames.surahMeaning(id, locale)?.toLowerCase();

        // Название на текущей локали через ARB (`surahName{id}`):
        // в `ru` локали это **кириллическая транслитерация**
        // (`Аль-Бакара`), в `en` — английское значение (`The Cow`).
        // Для арабской локали ARB-значение пустое (арабские
        // пользователи используют `nameAr` из БД).
        final localizedName = (int id) =>
            t.surahName(id, fallback: '').toLowerCase();

        // Дополнительно всегда индексируем русское значение
        // и русскую транслитерацию — даже в EN/AR локали
        // пользователь может искать «Корова» или «Аль-Бакара»,
        // потому что это короткие узнаваемые слова (и в БД их
        // нет — переводы хранятся в коде и в ARB).
        final ruMeaning = (int id) =>
            LocalizedNames.surahMeaningRu[id]?.toLowerCase();
        final ruTransliteration = (int id) =>
            LocalizedNames.surahTransliterationRu[id]?.toLowerCase() ?? '';

        final filtered = items.where((s) {
          // 1. Точное совпадение по номеру (для быстрого `5` → Бакара).
          if (s.id.toString() == q) return true;

          // 2. Латинская транслитерация (`Al-Baqara`).
          if (s.nameTransliteration.toLowerCase().contains(qLower)) {
            return true;
          }

          // 3. Английское название (`The Cow`).
          if (s.nameEn.toLowerCase().contains(qLower)) return true;

          // 4. Арабское название — через нормализацию, чтобы
          //    «البقره» тоже находило «البقرة».
          if (qArabicNorm.isNotEmpty &&
              ArabicNormalizer.normalize(s.nameAr).contains(qArabicNorm)) {
            return true;
          }

          // 5. Локализованное название: для ru → кириллическая
          //    транслитерация (`Аль-Бакара`), для en → значение
          //    (`The Cow`). ARB-ключ `surahName{id}` для ru
          //    специально задаётся как русская транслитерация.
          final ln = localizedName(s.id);
          if (ln.isNotEmpty && ln.contains(qLower)) return true;

          // 6. Значение на языке интерфейса (для ru → «Корова»,
          //    для en → «The Cow»).
          final lm = localizedMeaning(s.id);
          if (lm != null && lm.contains(qLower)) return true;

          // 7. Fallback: русская транслитерация (`Аль-Бакара`).
          //    Работает в **любой** локали — пользователь может
          //    набрать кириллицу даже в EN/AR-интерфейсе.
          final rt = ruTransliteration(s.id);
          if (rt.isNotEmpty && rt.contains(qLower)) return true;

          // 8. Fallback: русское значение (`Корова`).
          final rm = ruMeaning(s.id);
          if (rm != null && rm.contains(qLower)) return true;

          return false;
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