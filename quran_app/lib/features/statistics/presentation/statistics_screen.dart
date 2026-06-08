import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/database/daos/position_dao.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/screen_header.dart';

/// Read the [PositionDao] reading-history aggregates and render a
/// four-card summary plus a 7-day bar chart. Replaces the previous
/// "Coming soon" stub.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final dao = ref.watch(positionDaoProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 7-day window ends today (inclusive) and starts 6 days back.
    final weekStart = today.subtract(const Duration(days: 6));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ScreenHeader(
              title: t.statsTitle,
              onBack: () => contextSafeGoBack(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: t.statsToday,
                            stream: dao.watchAyahsInRange(today, today),
                            accent: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            title: t.statsThisWeek,
                            stream: dao.watchAyahsInRange(weekStart, today),
                            accent: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: t.statsAllTime,
                            stream: dao.watchTotalAyahs(),
                            accent: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StreakCard(
                            title: t.statsStreak,
                            stream: dao.watchStreakDays(now: now),
                            unit: t.statsDaysUnit,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _Last7DaysChart(
                      title: t.statsLast7Days,
                      stream: dao.watchByDateRange(weekStart, today),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // `go_router` doesn't expose a back-action helper, so we just
  // pop the route. This stays a no-op on the root.
  void contextSafeGoBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.stream,
    required this.accent,
  });

  final String title;
  final Stream<int> stream;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              final value = snapshot.data ?? 0;
              return Text(
                '$value',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.title,
    required this.stream,
    required this.unit,
  });

  final String title;
  final Stream<int> stream;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              final value = snapshot.data ?? 0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      unit,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 7-day bar chart. Each day's bar height is proportional to the
/// day's total ayahsRead. The `0` baseline is implicit at the
/// bottom of the bar; a 24px-tall placeholder bar is rendered for
/// days with no data so the bar grid is visually consistent.
class _Last7DaysChart extends StatelessWidget {
  const _Last7DaysChart({required this.title, required this.stream});

  final String title;
  final Stream<List<DailyReading>> stream;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textTertiary,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<DailyReading>>(
            stream: stream,
            builder: (context, snapshot) {
              final rows = snapshot.data ?? const <DailyReading>[];
              if (rows.isEmpty && snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const SizedBox(
                  height: 96,
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    t.statsNoData,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }
              return _Bars(rows: rows);
            },
          ),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.rows});

  final List<DailyReading> rows;

  @override
  Widget build(BuildContext context) {
    // Pivot the rows into a per-day total. The list is already
    // ordered chronologically by the DAO query.
    final byDate = <String, int>{};
    for (final r in rows) {
      byDate.update(r.date, (v) => v + r.ayahsRead,
          ifAbsent: () => r.ayahsRead);
    }
    final today = DateTime.now();
    final dates = List<DateTime>.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i)),
    );
    final maxValue =
        byDate.values.fold<int>(1, (a, b) => a > b ? a : b);
    const barAreaHeight = 96.0;
    return SizedBox(
      height: barAreaHeight + 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in dates)
            Expanded(
              child: _Bar(
                value: byDate[_iso(d)] ?? 0,
                max: maxValue,
                areaHeight: barAreaHeight,
                label: _shortDay(d),
              ),
            ),
        ],
      ),
    );
  }

  String _iso(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }

  String _shortDay(DateTime d) {
    const names = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return names[d.weekday - 1];
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.max,
    required this.areaHeight,
    required this.label,
  });

  final int value;
  final int max;
  final double areaHeight;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : value / max;
    final barHeight = (ratio * (areaHeight - 4)).clamp(2.0, areaHeight);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: areaHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: value == 0
                      ? AppColors.surfaceHigh
                      : AppColors.gold.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
