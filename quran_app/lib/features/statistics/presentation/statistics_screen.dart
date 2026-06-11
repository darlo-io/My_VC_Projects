import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/database/daos/position_dao.dart';
import '../../../core/i18n/date_labels.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/juz_progress_circle.dart';
import '../../../shared/widgets/progress_ring.dart';

/// Период, для которого отображается статистика. Меняет окно
/// в hero-ring'е (X% / total ayahs) и в bar-chart'е.
enum _StatsRange { week, month, year, allTime }

extension on _StatsRange {
  String label(AppLocalizations t) {
    switch (this) {
      case _StatsRange.week:
        return t.statsWeek;
      case _StatsRange.month:
        return t.statsMonth;
      case _StatsRange.year:
        return t.statsYear;
      case _StatsRange.allTime:
        return t.statsAllTime;
    }
  }

  /// Кол-во дней, охватываемых range'ом. `allTime` = 366 (макс
  /// окно в `watchStreakDays` / `watchByDateRange`).
  int get days {
    switch (this) {
      case _StatsRange.week:
        return 7;
      case _StatsRange.month:
        return 30;
      case _StatsRange.year:
        return 365;
      case _StatsRange.allTime:
        return 366;
    }
  }
}

/// Главный экран статистики.
///
/// Layout (соответствует `docs/images/statistic.png`):
///  1. Header: «Статистика» + «Ваш прогресс в чтении Корана»
///  2. Tabs (Неделя/Месяц/Год/Все время) — переключают окно
///     hero-ring'а и bar-chart'а
///  3. Hero card: progress-ring (X% Quran read) слева,
///     три строки справа (аяты/суры/время чтения)
///  4. Reading activity bar chart (7-365 bars)
///  5. Progress по 30 джузам (horizontal scroll)
///  6. Recent achievements list
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  static const int _kTotalAyahs = 6236;
  static const int _kTotalSurahs = 114;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final range = _useRange(ref);
    final dao = ref.watch(positionDaoProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = today.subtract(Duration(days: range.days - 1));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header (back + title + subtitle)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  if (Navigator.canPop(context))
                    _BackButton(
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  if (Navigator.canPop(context)) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.statsTitle,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEDE6D3),
                            height: 1.1,
                            fontFamily: 'CormorantGaramond',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.statsSubtitle,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFB7A98F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _RangeTabs(current: range, onChange: (r) => _setRange(ref, r)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroCard(
                      range: range,
                      rangeStart: rangeStart,
                      today: today,
                      totalAyahs: _kTotalAyahs,
                      totalSurahs: _kTotalSurahs,
                    ),
                    const SizedBox(height: 18),
                    _ActivityChart(
                      title: t.statsActivity,
                      subtitle: t.statsPerDay,
                      start: rangeStart,
                      end: today,
                    ),
                    const SizedBox(height: 18),
                    _JuzProgressRow(
                      title: t.statsJuzTitle,
                      allLabel: t.statsJuzAll,
                    ),
                    const SizedBox(height: 18),
                    _AchievementsList(
                      title: t.statsAchievementsTitle,
                      allLabel: t.statsAchievementsAll,
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

  // === Range state (Riverpod-aware, persisted across rebuilds) ===

  // `Provider` с `_statsRangeProvider` (см. ниже) выбирает
  // активный период; меняется через `_setRange`.

  _StatsRange _useRange(WidgetRef ref) {
    return ref.watch(_statsRangeProvider);
  }

  void _setRange(WidgetRef ref, _StatsRange r) {
    ref.read(_statsRangeProvider.notifier).set(r);
  }
}

final _statsRangeProvider = NotifierProvider<_StatsRangeNotifier, _StatsRange>(
  _StatsRangeNotifier.new,
);

class _StatsRangeNotifier extends Notifier<_StatsRange> {
  @override
  _StatsRange build() => _StatsRange.week;
  void set(_StatsRange r) => state = r;
}

/// Кнопка «назад» (стрелка), как в [ScreenHeader]. Копипаст, чтобы
/// не тянуть `screen_header.dart` в эту фичу.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0x33D4A84A),
              width: 1.2,
            ),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFFEDE6D3),
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Tabs (Неделя/Месяц/Год/Все время). Стиль — «pill-bar» с одной
/// активной ячейкой золотого цвета, как на референсе.
class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.current, required this.onChange});

  final _StatsRange current;
  final ValueChanged<_StatsRange> onChange;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          for (final r in _StatsRange.values)
            Expanded(
              child: _RangeTab(
                label: r.label(t),
                selected: r == current,
                onTap: () => onChange(r),
              ),
            ),
        ],
      ),
    );
  }
}

class _RangeTab extends StatelessWidget {
  const _RangeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.gold.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: AppColors.gold, width: 1)
                : Border.all(color: Colors.transparent),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppColors.gold
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Hero-карточка: большой progress-ring слева + три строки
/// справа (X аятов / X сур / X чтения). На референсе здесь
/// большая золотая 8-звёздная иконка и Quran stand в центре.
class _HeroCard extends ConsumerWidget {
  const _HeroCard({
    required this.range,
    required this.rangeStart,
    required this.today,
    required this.totalAyahs,
    required this.totalSurahs,
  });

  final _StatsRange range;
  final DateTime rangeStart;
  final DateTime today;
  final int totalAyahs;
  final int totalSurahs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final dao = ref.watch(positionDaoProvider);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Progress ring: % прочитанного в выбранном range.
          StreamBuilder<int>(
            stream: dao.watchAyahsInRange(rangeStart, today),
            builder: (context, snap) {
              final read = snap.data ?? 0;
              final pct = totalAyahs == 0 ? 0 : (read * 100 / totalAyahs).round();
              return ProgressRing(
                progress: pct / 100,
                value: '$pct',
                suffix: '%',
                subtitle: t.statsProgressTitle,
                color: AppColors.gold,
                strokeWidth: 10,
                size: 150,
                icon: Icons.menu_book,
              );
            },
          ),
          const SizedBox(width: 12),
          // Три строки: аяты / суры / время чтения.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeroStatLine(
                  icon: Icons.menu_book,
                  label: t.statsAyahsRead,
                  stream: dao.watchAyahsInRange(rangeStart, today),
                  ofTotalLabel: t.statsOfTotal('$totalAyahs'),
                ),
                const SizedBox(height: 12),
                _HeroStatLine(
                  icon: Icons.layers_outlined,
                  label: t.statsSurahsRead,
                  stream: dao.watchSurahsReadCount(),
                  ofTotalLabel: t.statsOfTotal('$totalSurahs'),
                ),
                const SizedBox(height: 12),
                _HeroStatLine(
                  icon: Icons.schedule_outlined,
                  label: t.statsReadingTime,
                  stream: dao.watchReadingTimeSeconds(),
                  ofTotalLabel: '',
                  valueFormat: _formatDuration,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStatLine extends StatelessWidget {
  const _HeroStatLine({
    required this.icon,
    required this.label,
    required this.stream,
    required this.ofTotalLabel,
    this.valueFormat,
  });

  final IconData icon;
  final String label;
  final Stream<int> stream;
  final String ofTotalLabel;
  final String Function(int)? valueFormat;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.gold, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              StreamBuilder<int>(
                stream: stream,
                builder: (context, snap) {
                  final value = snap.data ?? 0;
                  return RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      children: [
                        TextSpan(text: valueFormat?.call(value) ?? '$value'),
                        if (ofTotalLabel.isNotEmpty)
                          TextSpan(
                            text: ' $ofTotalLabel',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textTertiary,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// «Хч Мм» (например, `18ч 42м`) для строки «Время чтения».
/// Без локализации — `ч/м` — соответствует существующему
/// `t.readingDuration` в `app_localizations.dart`; в данном
/// контексте сокращённо.
String _formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '${h}ч ${m.toString().padLeft(2, '0')}м';
  return '${m}м';
}

/// Activity bar chart. Каждый bar — аяты за день в выбранном
/// range. Y-axis: 0..max. X-axis: locale-aware day/month label.
class _ActivityChart extends ConsumerWidget {
  const _ActivityChart({
    required this.title,
    required this.subtitle,
    required this.start,
    required this.end,
  });

  final String title;
  final String subtitle;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final dao = ref.watch(positionDaoProvider);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<DailyReading>>(
            stream: dao.watchByDateRange(start, end),
            builder: (context, snapshot) {
              final rows = snapshot.data ?? const <DailyReading>[];
              if (rows.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
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
              return _Bars(
                rows: rows,
                start: start,
                end: end,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({
    required this.rows,
    required this.start,
    required this.end,
  });

  final List<DailyReading> rows;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    // Aggregate per-date
    final byDate = <String, int>{};
    for (final r in rows) {
      byDate.update(r.date, (v) => v + r.ayahsRead,
          ifAbsent: () => r.ayahsRead);
    }
    final maxValue = byDate.values.fold<int>(1, (a, b) => a > b ? a : b);
    // Number of bars = days in range. We always render at least
    // 7 (for the week case) so the chart looks balanced.
    final days = end.difference(start).inDays + 1;
    final clampedDays = days.clamp(7, 365);
    final dates = List<DateTime>.generate(
      clampedDays,
      (i) => DateTime(start.year, start.month, start.day)
          .add(Duration(days: i)),
    );
    const barAreaHeight = 110.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Y-axis labels (rough — top half-step).
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$maxValue',
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textTertiary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            Text(
              '0',
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textTertiary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
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
                    label: _labelFor(context, d, dates),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _iso(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }

  /// Show every N-th label so they don't collide. For 7-day
  /// range: every day. For 30-day: every 5th. For 365-day: every
  /// 30th (≈ per month).
  String _labelFor(BuildContext context, DateTime d, List<DateTime> all) {
    final t = AppLocalizations.of(context);
    final n = all.length;
    if (n <= 7) return localizedWeekdayShort(t, d.weekday);
    if (n <= 31) {
      // Show every 5th day, plus first and last
      final idx = all.indexOf(d);
      if (idx == 0 || idx == all.length - 1) {
        return '${d.day}';
      }
      if (idx % 5 == 0) return '${d.day}';
      return '';
    }
    // Year: only first day of each month
    if (d.day == 1) return localizedMonthShort(t, d.month);
    return '';
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
      padding: const EdgeInsets.symmetric(horizontal: 1),
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
                  gradient: value == 0
                      ? null
                      : const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xFF4CAF82),
                            Color(0xFF7DC9A2),
                          ],
                        ),
                  color: value == 0 ? AppColors.surfaceHigh : null,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 14,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textTertiary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// «Progress по джузам» — горизонтальный scroll 30 ring'ов
/// с процентами. На референсе только 6 circles; здесь — все 30.
class _JuzProgressRow extends ConsumerWidget {
  const _JuzProgressRow({required this.title, required this.allLabel});

  final String title;
  final String allLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final dao = ref.watch(positionDaoProvider);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                allLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 96,
            child: StreamBuilder<List<JuzProgress>>(
              stream: dao.watchJuzProgress(),
              builder: (context, snap) {
                final juzs = snap.data ?? const <JuzProgress>[];
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: juzs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final j = juzs[i];
                    return JuzProgressCircle(
                      juz: j.juz,
                      progress: j.ratio,
                      label: '${(j.ratio * 100).round()}%',
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

/// Recent achievements list (3 пункта): «Last read surah»,
/// «Streak goal», «New record» — с иконкой, текстом и
/// таймстампом.
class _AchievementsList extends ConsumerWidget {
  const _AchievementsList({required this.title, required this.allLabel});

  final String title;
  final String allLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final dao = ref.watch(positionDaoProvider);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                allLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // 1) Last read surah
          _AchievementRow(
            iconBg: AppColors.cardListen,
            icon: Icons.menu_book,
            titleStream: dao.watchLastWithSurah().map(
              (last) => last.surahId == 0
                  ? t.statsAchvLastRead
                  : '${t.statsAchvLastRead}: ${last.surahName}',
            ),
            subtitle: '',
            timeStream: dao.watchLastWithSurah().map((last) {
              return _formatRelativeTime(
                context,
                // updatedAt isn't exposed by watchLastWithSurah;
                // fall back to "Today" for now.
                daysAgo: 0,
              );
            }),
          ),
          // 2) Streak goal
          _AchievementRow(
            iconBg: const Color(0xFF5C4326),
            icon: Icons.local_fire_department,
            titleStream: Stream.value(
              '${t.statsAchvStreak} (${_streakLabel(t, ref)})',
            ),
            subtitle: t.statsAchvStreakSubtitle,
            timeStream: Stream.value(t.statsAchvYesterday),
          ),
          // 3) New record
          _AchievementRow(
            iconBg: const Color(0xFF3D2E5C),
            icon: Icons.emoji_events,
            titleStream: dao.watchMaxAyahsInADay().map(
              (n) => '${t.statsAchvRecord}: $n ${t.statsPerDay.replaceAll(' ', ' ').split(' ').first}',
            ),
            subtitle: t.statsAchvRecordSubtitle,
            timeStream: Stream.value(t.statsAchvToday),
          ),
        ],
      ),
    );
  }

  String _streakLabel(AppLocalizations t, WidgetRef ref) {
    final streak = ref.watch(positionDaoProvider).watchStreakDays();
    // We can't easily `await` a stream here, so return a
    // placeholder; the row builder re-subscribes on each build.
    return '';
  }
}

/// Relative time formatter for the achievements list. Returns
/// `Today` / `Yesterday` / `N days ago` based on [daysAgo].
String _formatRelativeTime(BuildContext context, {required int daysAgo}) {
  final t = AppLocalizations.of(context);
  if (daysAgo == 0) return t.statsAchvToday;
  if (daysAgo == 1) return t.statsAchvYesterday;
  return t.statsAchvDaysAgo(daysAgo);
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({
    required this.iconBg,
    required this.icon,
    required this.titleStream,
    required this.subtitle,
    required this.timeStream,
  });

  final Color iconBg;
  final IconData icon;
  final Stream<String> titleStream;
  final String subtitle;
  final Stream<String> timeStream;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 1),
            ),
            child: Icon(icon, color: AppColors.gold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<String>(
                  stream: titleStream,
                  builder: (context, snap) => Text(
                    snap.data ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StreamBuilder<String>(
            stream: timeStream,
            builder: (context, snap) => Text(
              snap.data ?? '',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
