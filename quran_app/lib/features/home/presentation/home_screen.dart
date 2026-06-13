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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// `true` после того, как пользователь явно закрыл панель
  /// "Продолжить чтение" через кнопку «Закрыть» на текущей
  /// сессии. Сбрасывается на cold start приложения (новая
  /// сессия = новая возможность показать панель снова).
  ///
  /// Хранится **только в памяти**, не в shared_prefs — иначе после
  /// reset-data панель осталась бы скрытой навсегда, пока
  /// пользователь не пройдёт через Settings.
  bool _continueCardDismissed = false;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context);
    final lastAsync = ref.watch(lastReadPositionProvider);
    final last = lastAsync.valueOrNull ?? const LastReadPosition.empty();
    // Панель показывается **только** если:
    //   1. `last.surahId != 0` — пользователь хоть раз открывал
    //      Reader и `setLast` записал позицию (а не дефолтный
    //      empty snapshot).
    //   2. `last.progress < 1.0` — сура прочитана **не до конца**.
    //   3. Пользователь не закрыл панель в этой сессии.
    final shouldShowContinue =
        last.surahId != 0 && last.progress < 1.0 && !_continueCardDismissed;
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
          // `AnimatedSize` + `AnimatedSwitcher` дают плавное
          // появление/скрытие: меняется высота контейнера +
          // opacity дочернего через fade-transition. Остальные
          // панели (`SizedBox(height: 24)` + `_FeatureGrid`)
          // плавно "съезжают" вниз за счёт того, что ListView
          // перераспределяет высоту между элементами — анимированно.
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: shouldShowContinue
                ? Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: _ContinueCard(
                      surahName: displaySurah,
                      ayahLabel: t.surahAndAyah(displaySurah, displayAyah),
                      progress: last.progress,
                      onContinue: () => context.go(
                        '/reader/${last.surahId}?ayah=${last.ayahNumber}',
                      ),
                      onDismiss: () => setState(() {
                        _continueCardDismissed = true;
                      }),
                      continueLabel: t.continueAction,
                      dismissLabel: t.cancel,
                    ),
                  )
                : const SizedBox.shrink(),
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

/// Панель «Продолжить чтение» — компактная, с двумя кнопками:
/// «Продолжить» (открывает Reader) и «Закрыть» (× — скрывает
/// панель через `_HomeScreenState._continueCardDismissed`).
class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.surahName,
    required this.ayahLabel,
    required this.progress,
    required this.onContinue,
    required this.onDismiss,
    required this.continueLabel,
    required this.dismissLabel,
  });

  final String surahName;
  final String ayahLabel;
  final double progress;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;
  final String continueLabel;
  final String dismissLabel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          // Миниатюра Корана
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.gold, width: 1.2),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Текстовый блок (`Expanded` занимает всё оставшееся
          // место между миниатюрой и кнопками) — текст
          // автоматически усекается, не перекрывая кнопки.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context).continueReading,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  ayahLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                _ProgressBar(value: progress),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Две кнопки справа: «Продолжить» (chevron-right) и
          // «Закрыть» (×). Вертикальный стек — компактнее
          // горизонтального, помещается на одной линии с прогрессом.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconChipButton(
                icon: Icons.chevron_right,
                background: AppColors.gold,
                foreground: AppColors.backgroundDeep,
                tooltip: continueLabel,
                onPressed: onContinue,
              ),
              const SizedBox(height: 6),
              _IconChipButton(
                icon: Icons.close_rounded,
                background: Colors.transparent,
                foreground: AppColors.textSecondary,
                border: AppColors.border,
                tooltip: dismissLabel,
                onPressed: onDismiss,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Маленькая иконочная кнопка-«чип»: 36×36 квадрат со скруглёнными
/// углами, иконка по центру. Используется для Continue/Close
/// действий на компактной панели «Продолжить чтение».
class _IconChipButton extends StatelessWidget {
  const _IconChipButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.tooltip,
    required this.onPressed,
    this.border,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? border;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: border != null
              ? BorderSide(color: border!, width: 1)
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: foreground, size: 20),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 4,
        backgroundColor: AppColors.borderSubtle,
        valueColor: const AlwaysStoppedAnimation(AppColors.gold),
      ),
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
