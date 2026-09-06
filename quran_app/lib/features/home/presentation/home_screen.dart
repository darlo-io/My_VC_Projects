import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/models/last_read_position.dart';
import '../../../../core/i18n/hijri_calendar.dart';
import '../../../../core/i18n/localized_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Пути к PNG-иконкам главного экрана (см. `assets/icons/home/`).
/// Извлечены из макета, валидированы визуально.
const String _kIconRead = 'assets/icons/home/read.webp';
const String _kIconListen = 'assets/icons/home/listen.webp';
const String _kIconLearn = 'assets/icons/home/learn.webp';
const String _kIconTest = 'assets/icons/home/test.webp';
const String _kIconTasbih = 'assets/icons/home/tasbih.webp';
const String _kIconStats = 'assets/icons/home/stats.webp';
const String _kIconQuranRehal = 'assets/icons/home/quran_rehal.webp';
const String _kIconSettings = 'assets/icons/home/settings.webp';

/// WebP-фон главного экрана: мечеть в правом верхнем углу, левая
/// половина — кремовая (`AppColors.background`). Генерируется из
/// `docs/images/background.webp` скриптом `tool/build_home_background.py`.
const String _kHomeBackground =
    'assets/images/backgrounds/home_background.webp';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _continueCardDismissed = false;

  /// `true` только при первой отрисовке `HomeScreen` после запуска
  /// приложения. На следующем фрейме переключается в `false`, поэтому
  /// при возврате с экрана Reader (внутри приложения) карточка
  /// «Продолжить чтение» уже не появляется — пользователь сам
  /// управляет навигацией.
  bool _showContinueOnFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _showContinueOnFirstLoad = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final loc = Localizations.localeOf(context);
    final lastAsync = ref.watch(lastReadPositionProvider);
    final last = lastAsync.valueOrNull ?? const LastReadPosition.empty();
    final shouldShowContinue =
        last.surahId != 0 &&
        !last.isCompleted &&
        !_continueCardDismissed &&
        _showContinueOnFirstLoad;
    final isEmpty = last.surahId == 0;
    final displaySurah = isEmpty
        ? t.homeFallbackSurahName
        : t.surahName(last.surahId, fallback: last.surahName);
    final displayAyah = isEmpty ? 1 : last.ayahNumber;

    return Stack(
      children: [
        // WebP-фон с мечетью в правом верхнем углу. `BoxFit.cover`
        // держит пропорции на любых экранах; `alignment: topRight`
        // гарантирует, что мечеть остаётся в правом верхнем углу.
        // Левая половина картинки — кремовая (`AppColors.background`),
        // так что под иконки/текст попадает «пустое» пространство.
        // НЕ ставим сюда непрозрачный `ColoredBox` — он перекрыл бы
        // изображение. Цвет фона уже заложен в самой WebP-картинке.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_kHomeBackground),
                fit: BoxFit.cover,
                alignment: Alignment.topRight,
              ),
            ),
          ),
        ),
        SafeArea(
          // Round 9.9: `top: false` — не дублировать status bar (он уже
          // учтён в AppBar/Container), `bottom: false` — не дублировать
          // bottomNavigationBar (учтён в `MainScaffold` через свой
          // SafeArea(top: false)). Остаются **left/right** insets — они
          // критичны для **landscape с 3-button nav bar справа**:
          // без них контент уходит за nav bar и Flutter выбрасывает
          // `BOTTOM OVERFLOWED BY 25 PIXELS` на grid'е категорий.
          // См. `plans/1783541431192-insets-fix.md`.
          top: false,
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            children: [
              _Header(),
              const SizedBox(height: 8),
              _Greeting(
                greeting: t.greetingAssalamu,
                dateLine: formatHijriDate(
                  hijriFromGregorian(DateTime.now()),
                  loc.languageCode,
                ),
              ),
              // Без `_OrnamentDivider` и лишних SizedBox — они
              // «съедали» ~64 px вертикали и нижний ряд плиток
              // уезжал за навигацию. Разделитель с ромбом остался
              // на скриншоте как часть фоновой текстуры.
              const SizedBox(height: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.topCenter,
                child: shouldShowContinue
                    ? _ContinueCard(
                        surahName: displaySurah,
                        ayahLabel: t.surahAndAyah(displaySurah, displayAyah),
                        progress: last.progress,
                        onContinue: () => context.push(
                          '/reader/${last.surahId}?ayah=${last.ayahNumber}',
                        ),
                        onDismiss: () => setState(() {
                          _continueCardDismissed = true;
                        }),
                        continueLabel: t.continueAction,
                        dismissLabel: t.cancel,
                      )
                    : const SizedBox.shrink(),
              ),
              if (shouldShowContinue) const SizedBox(height: 20),
              _FeatureGrid(
                cards: [
                  _FeatureItem(
                    iconAsset: _kIconRead,
                    title: t.cardRead,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.tileMintLight, AppColors.tileMintDark],
                    ),
                    onTap: () => context.go('/read'),
                  ),
                  _FeatureItem(
                    iconAsset: _kIconListen,
                    title: t.cardListen,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.tileSkyLight, AppColors.tileSkyDark],
                    ),
                    onTap: () => context.push('/listen'),
                  ),
                  _FeatureItem(
                    iconAsset: _kIconLearn,
                    title: t.cardLearn,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.tileLavenderLight,
                        AppColors.tileLavenderDark,
                      ],
                    ),
                    onTap: () => context.push('/learn'),
                  ),
                  _FeatureItem(
                    iconAsset: _kIconTest,
                    title: t.cardTest,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.tileSandLight, AppColors.tileSandDark],
                    ),
                    onTap: () => context.push('/test'),
                  ),
                  _FeatureItem(
                    iconAsset: _kIconTasbih,
                    title: t.cardTasbih,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.tileMintLight, AppColors.tileMintDark],
                    ),
                    onTap: () => context.push('/tasbih'),
                  ),
                  _FeatureItem(
                    iconAsset: _kIconStats,
                    title: t.cardStats,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.tileSkyLight, AppColors.tileSkyDark],
                    ),
                    onTap: () => context.push('/statistics'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go('/profile'),
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Padding(
              padding: const EdgeInsets.all(10),
              // cacheWidth декодирует битмап в размере отображения
              // (исходные PNG 370×350 px), экономя память и время
              // декода на главном экране.
              child: Image.asset(
                _kIconSettings,
                fit: BoxFit.contain,
                cacheWidth:
                    (20 * MediaQuery.devicePixelRatioOf(context)).round(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.greeting, required this.dateLine});
  final String greeting;
  final String dateLine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Крупный заголовок — две строки (как на макете: «Ассаляму»
        // на первой строке, «алейкум!» на второй). Разбиваем по
        // первому пробелу — работает для русской и арабской локалей.
        Text(
          greeting.contains(' ') ? greeting.replaceFirst(' ', '\n') : greeting,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
            fontFamily: 'CormorantGaramond',
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.accentOlive,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                dateLine,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

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
    // Процент прогресса в виде строки «45%» — отображается справа
    // от шкалы, чтобы пользователь видел точные цифры.
    final pct = (progress.clamp(0.0, 1.0) * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Реалистичная иллюстрация rehal — извлечена из макета.
              SizedBox(
                width: 56,
                height: 56,
                child: Image.asset(
                  _kIconQuranRehal,
                  fit: BoxFit.contain,
                  cacheWidth:
                      (56 * MediaQuery.devicePixelRatioOf(context)).round(),
                ),
              ),
              const SizedBox(width: 12),
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
                    const SizedBox(height: 1),
                    Text(
                      ayahLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _ContinueProgressBar(value: progress)),
                        const SizedBox(width: 8),
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentOlive,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Обе кнопки одинаковой ширины (`flex: 1` у каждой через
          // `Expanded`). Никаких `flex: 2` — раньше «Продолжить» был
          // вдвое шире «Отмена», что ломало визуальный баланс.
          Row(
            children: [
              Expanded(
                child: _ContinueTextButton(
                  label: dismissLabel,
                  onPressed: onDismiss,
                  filled: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ContinueTextButton(
                  label: continueLabel,
                  icon: Icons.chevron_right,
                  onPressed: onContinue,
                  filled: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContinueProgressBar extends StatelessWidget {
  const _ContinueProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 3,
        backgroundColor: AppColors.progressBarTrack,
        valueColor: const AlwaysStoppedAnimation(AppColors.accentOlive),
      ),
    );
  }
}

class _ContinueTextButton extends StatelessWidget {
  const _ContinueTextButton({
    required this.label,
    required this.onPressed,
    required this.filled,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? AppColors.accentDeepGreen : AppColors.background;
    final fg = filled ? Colors.white : AppColors.textSecondary;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: filled
              ? Colors.transparent
              : AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 3),
                Icon(icon, color: fg, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.iconAsset,
    required this.title,
    required this.gradient,
    required this.onTap,
  });
  final String iconAsset;
  final String title;
  final Gradient gradient;
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
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        // aspectRatio = ширина / высота. 0.9 → плитка чуть выше
        // ширины. 0.85 обрезало 3-й ряд навигацией на 1080×2376
        // (~50 px не хватало — header+greeting реально занимает
        // больше, чем 250 px). 0.9 — гарантированно все 6 плиток
        // помещаются, расстояние от нижнего ряда до навигации
        // ≈ `mainAxisSpacing` (12 px).
        childAspectRatio: 1.1,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) {
        final c = cards[i];
        return _LightFeatureCard(item: c);
      },
    );
  }
}

class _LightFeatureCard extends StatelessWidget {
  const _LightFeatureCard({required this.item});
  final _FeatureItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: item.gradient,
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Stack(
            children: [
              // Тонкий краповый паттерн (как на макете — слегка
              // текстурированный фон).
              Positioned.fill(child: CustomPaint(painter: _CracklePainter())),
Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  // `min` — Column занимает ровно столько, сколько
                  // нужно детям. При `max` (по умолчанию) он тянулся
                  // на всю высоту плитки и при недостатке места
                  // выбрасывал `BOTTOM OVERFLOWED BY 14 PIXELS`.
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Белая «тарелка» под иконкой — как на макете
                    // (белый круг на цветном фоне плитки). PNG-иконка
                    // уже с прозрачным фоном вокруг объекта, так что
                    // `Color` подложки даёт ровно ту «тарелку», что
                    // на эталоне. 64×64 — крупные, но не вызывают
                    // `BOTTOM OVERFLOWED` при `aspectRatio: 0.9`.
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        item.iconAsset,
                        fit: BoxFit.contain,
                        // Иконка показывается в ~44 dp (64 − padding 2×10).
                        cacheWidth:
                            (44 * MediaQuery.devicePixelRatioOf(context))
                                .round(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // `center` вместо `end` — при длинных заголовках
                    // («Статистика») текст и chevron иначе «съезжали»
                    // бы вниз. Шрифт 18 — крупный, как в эталоне.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'CormorantGaramond',
                              color: AppColors.textPrimary,
                              height: 1.0,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.accentOlive,
                          size: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Тонкая кракле-сетка поверх плитки — повторяет лёгкую текстуру
/// макета. Не перегружает UI, добавляет «бумажность».
class _CracklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x12000000)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    final r = Paint()
      ..color = const Color(0x18000000)
      ..style = PaintingStyle.stroke;

    // Случайные мелкие «трещинки». Детерминированный seed → один
    // и тот же паттерн на каждом билде.
    final rng = _SeededRandom(42);
    for (var i = 0; i < 28; i++) {
      final x = rng.next() * size.width;
      final y = rng.next() * size.height;
      canvas.drawCircle(Offset(x, y), 1.2 + rng.next() * 1.5, r);
    }
    for (var i = 0; i < 16; i++) {
      final x1 = rng.next() * size.width;
      final y1 = rng.next() * size.height;
      final len = 6 + rng.next() * 18;
      canvas.drawLine(Offset(x1, y1), Offset(x1 + len, y1 + len * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Минимальный детерминированный LCG, чтобы паттерн не «прыгал»
/// между билдами (иначе `Random()` дал бы новый паттерн после
/// hot reload — выглядело бы как мерцание).
class _SeededRandom {
  _SeededRandom(int seed) : _state = seed;
  int _state;
  double next() {
    _state = (_state * 1103515245 + 12345) & 0x7FFFFFFF;
    return _state / 0x7FFFFFFF;
  }
}
