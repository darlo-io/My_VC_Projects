import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/common_widgets.dart';
import '../../../../shared/widgets/screen_header.dart';
import 'widgets.dart';

class SurahListScreen extends ConsumerStatefulWidget {
  const SurahListScreen({super.key});

  @override
  ConsumerState<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends ConsumerState<SurahListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _showJuz = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: t.searchByNameOrNumber,
                prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                suffixIcon: IconButton(
                  onPressed: _searchCtrl.clear,
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
                    active: !_showJuz,
                    onTap: () => setState(() => _showJuz = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentButton(
                    label: t.tabJuz,
                    icon: Icons.bookmark_outline,
                    active: _showJuz,
                    onTap: () => setState(() => _showJuz = true),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _showJuz
                ? const JuzList()
                : StreamBuilder<List<Surah>>(
                    stream: dao.watchAll(),
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? const <Surah>[];
                      final q = _query.toLowerCase();
                      final filtered = _query.isEmpty
                          ? items
                          : items.where((s) {
                              // Search by every language we ship:
                              // transliteration (Latin), English,
                              // Arabic, and numeric id. ARB
                              // translation is deliberately not
                              // searched here — it's already
                              // derived from these three.
                              return s.nameTransliteration
                                      .toLowerCase()
                                      .contains(q) ||
                                  s.nameEn.toLowerCase().contains(q) ||
                                  s.nameAr.contains(_query) ||
                                  s.id.toString() == _query;
                            }).toList();
                      if (filtered.isEmpty) {
                        return Center(
                          child: Text(
                            t.searchResultsEmpty,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => SurahRow(surah: filtered[i]),
                      );
                    },
                  ),
          ),
        ],
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
