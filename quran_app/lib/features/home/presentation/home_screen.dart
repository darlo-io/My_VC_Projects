import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/models/last_read_position.dart';
import '../../../../core/i18n/hijri_calendar.dart';
import '../../../../core/i18n/localized_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/common_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context);
    final lastAsync = ref.watch(lastReadPositionProvider);
    final last = lastAsync.valueOrNull ?? const LastReadPosition.empty();
    final isEmpty = last.surahId == 0;
    // In Arabic UI we keep the Arabic name as the primary visible
    // label; in any other locale we look up the ARB translation
    // (which uses the transliteration for ru, English name for en)
    // and only fall back to the raw transliteration if ARB is
    // missing the entry.
    final displaySurah = isEmpty
        ? t.homeFallbackSurahName
        : t.surahName(last.surahId, fallback: last.surahName);
    final displayAyah = isEmpty ? 1 : last.ayahNumber;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _Header(),
          const SizedBox(height: 24),
          _Greeting(
            greeting: t.greetingAssalamu,
            dateLine: formatHijriDate(
              hijriFromGregorian(DateTime.now()),
              loc.languageCode,
            ),
          ),
          const SizedBox(height: 24),
          _ContinueCard(
            surahName: displaySurah,
            ayahLabel: t.surahAndAyah(displaySurah, displayAyah),
            progress: last.progress,
            onContinue: () => context.go(
              '/reader/${isEmpty ? 1 : last.surahId}?ayah=${isEmpty ? 1 : last.ayahNumber}',
            ),
            ctaLabel: t.continueAction,
          ),
          const SizedBox(height: 24),
          _FeatureGrid(
            cards: [
              _FeatureItem(
                icon: Icons.menu_book_rounded,
                title: t.cardRead,
                color: AppColors.cardRead,
                onTap: () => context.go('/read'),
              ),
              _FeatureItem(
                icon: Icons.headphones_rounded,
                title: t.cardListen,
                color: AppColors.cardListen,
                onTap: () => context.go('/listen'),
              ),
              _FeatureItem(
                icon: Icons.school_rounded,
                title: t.cardLearn,
                color: AppColors.cardLearn,
                onTap: () => context.go('/learn'),
              ),
              _FeatureItem(
                icon: Icons.assignment_turned_in_rounded,
                title: t.cardTest,
                color: AppColors.cardTest,
                onTap: () => context.go('/test'),
              ),
              _FeatureItem(
                icon: Icons.bubble_chart_rounded,
                title: t.cardTasbih,
                color: AppColors.cardRead,
                onTap: () => context.go('/tasbih'),
              ),
              _FeatureItem(
                icon: Icons.insights_rounded,
                title: t.cardStats,
                color: AppColors.cardListen,
                onTap: () => context.go('/statistics'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        CircleIconButton(
          icon: Icons.settings_outlined,
          onTap: () => context.go('/profile'),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting, required this.dateLine});
  final String greeting;
  final String dateLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEDE6D3),
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateLine,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Декоративная иллюстрация мечети (плейсхолдер)
        Container(
          width: 130,
          height: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A4034), Color(0xFF0E2A22)],
            ),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const _MosqueSilhouette(),
              Positioned(
                top: 14,
                right: 30,
                child: Icon(
                  Icons.brightness_3,
                  color: AppColors.gold.withValues(alpha: 0.7),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MosqueSilhouette extends StatelessWidget {
  const _MosqueSilhouette();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(130, 150),
      painter: _MosquePainter(),
    );
  }
}

class _MosquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()..color = AppColors.gold;
    final fill = Paint()..color = const Color(0xFFB5862C).withValues(alpha: 0.45);

    // Полумесяц
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.32), 6, gold);
    canvas.drawCircle(
      Offset(size.width * 0.65 + 3, size.height * 0.32),
      5,
      Paint()..color = const Color(0xFF0E2A22),
    );

    // Купол
    final dome = Path()
      ..moveTo(size.width * 0.2, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.32,
        size.width * 0.8,
        size.height * 0.7,
      )
      ..close();
    canvas.drawPath(dome, fill);

    // Минарет
    final minaret = Rect.fromLTWH(
      size.width * 0.78,
      size.height * 0.4,
      8,
      size.height * 0.35,
    );
    canvas.drawRect(minaret, fill);
    canvas.drawCircle(
      Offset(minaret.center.dx, minaret.top),
      6,
      fill,
    );
  }

  @override
  bool shouldRepaint(_MosquePainter old) => false;
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.surahName,
    required this.ayahLabel,
    required this.progress,
    required this.onContinue,
    required this.ctaLabel,
  });

  final String surahName;
  final String ayahLabel;
  final double progress;
  final VoidCallback onContinue;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
      child: Row(
        children: [
          // Миниатюра Корана на подставке
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.gold, width: 1.2),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.gold,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).continueReading,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ayahLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                _ProgressBar(value: progress),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GoldPillButton(
            label: ctaLabel,
            icon: Icons.chevron_right,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.borderSubtle,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(value * 100).round()}%',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gold,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.cards});
  final List<_FeatureItem> cards;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        return FeatureCard(
          icon: c.icon,
          title: c.title,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              c.color,
              Color.lerp(c.color, Colors.black, 0.35) ?? c.color,
            ],
          ),
          onTap: c.onTap,
        );
      },
    );
  }
}

/// Снимок последней позиции чтения для главной. Moved to
/// `lib/core/database/models/last_read_position.dart` and exposed
/// via the `lastReadPositionProvider` in `app/providers.dart`.
/// Kept this comment as a breadcrumb in case a future reader
/// greps for the old class name.
