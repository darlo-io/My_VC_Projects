import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/data/reader_data.dart';
import '../../../core/database/app_database.dart';
import '../../../core/i18n/arabic_digits.dart';
import '../../../core/i18n/localized_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/ornaments.dart';
import 'widgets/reader_widgets.dart';

/// Surah + translations для конкретного открытия. Закэшировано до смены
/// (surahId, translationLang), поэтому FutureBuilder в build не нужен.
final _readerDataProvider = FutureProvider.autoDispose
    .family<ReaderData, ReaderKey>((ref, key) async {
  return ref.read(quranRepositoryProvider).loadReaderData(
        surahId: key.surahId,
        translationLang: key.translationLang,
      );
});

class ReaderKey {
  const ReaderKey({required this.surahId, required this.translationLang});
  final int surahId;
  final String translationLang;

  @override
  bool operator ==(Object other) =>
      other is ReaderKey &&
      other.surahId == surahId &&
      other.translationLang == translationLang;

  @override
  int get hashCode => Object.hash(surahId, translationLang);
}

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    required this.surahId,
    required this.initialAyah,
    super.key,
  });

  final int surahId;
  final int initialAyah;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  // SingleChildScrollView controller — заменил PageController,
  // потому что теперь все аяты в одной Mushaf-рамке
  // (см. `docs/images/read line by line.png`).
  //
  // Deep-link scroll (route `?ayah=N`): реализован в
  // [_scrollToAyah] через `addPostFrameCallback` в `initState`.
  // Алгоритм: `ayah_index × tileExtent` (см. комментарий в
  // [_scrollToAyah]). Приближение — `tileExtent` оценивается
  // как 220 лог. пикселей, что соответствует средней высоте
  // одного `AyahTile`. Для сур с 286+ аятами off-by-one ±1 аят
  // визуально неотличим от «идеального» scroll'а.
  final ScrollController _pageCtrl = ScrollController();

  // Видимость control-панелей (верхняя + нижняя). По умолчанию
  // `true` — пользователь сразу видит заголовок суры. Тап по
  // Mushaf-области → toggle. Auto-hide при scroll-down — через
  // listener в [_SingleScrollMushaf].
  bool _controlsVisible = true;

  /// Локальный mirror `appPreferencesProvider.readingMode`.
  /// Инициализируется в `initState` из prefs (там же, где
  /// `recordLastRead`). Обновляется через `setState` при тапе
  /// по toggle'у — **без участия Riverpod**, чтобы избежать
  /// re-evaluation'а `redirect` в go_router (что в этой версии
  /// всё ещё выкидывает Reader в Home, несмотря на убранный
  /// `languageProvider` listener). На каждом mount / refresh
  /// провайдера `_readingMode` снова берётся из prefs.
  late String _readingMode;

  @override
  void initState() {
    super.initState();
    // Initial reading mode from prefs. Не через `ref.watch` —
    // см. комментарий в `_readingMode`.
    _readingMode = ref.read(appPreferencesProvider).readingMode;
    // Persist the "last position" and the daily reading-history
    // increment once per screen-mount, after the first frame so
    // we don't block the initial paint. Both are UPSERTs so
    // re-running on the same (date, surah, ayah) is a no-op for
    // history and an idempotent update for the last position.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final repo = ref.read(quranRepositoryProvider);
      // Resolve the DB row id for the route's initialAyah. The
      // stream provider hasn't been read yet at this point, so we
      // issue a direct query. If it fails (e.g. ayah number out
      // of range) we fall back to the route's value — better to
      // record something than to crash before the first frame.
      final ayahRow = await repo.getAyahBySurahAndNumber(
        widget.surahId,
        widget.initialAyah,
      );
      if (!mounted) return;
      final ayahId = ayahRow?.id ?? widget.initialAyah;
      await repo.recordLastRead(surahId: widget.surahId, ayahId: ayahId);
      // PageView НЕ вызывает `onPageChanged` для initialPage, поэтому
      // первый аят (на который пользователь попадает по deep-link)
      // учитывается здесь. Дальнейшие переходы — см. onPageChanged.
      await repo.recordAyahRead(surahId: widget.surahId);

      // Deep-link scroll: прокрутить к `widget.initialAyah`
      // (если он > 1). Для коротких сур (Al-Fatiha, 7 аятов) —
      // scroll не делаем: вся сура и так видна. Для длинных —
      // indexWhere находит ayah в widget.ayahs (он доступен из
      // StreamBuilder'а в build()), и _scrollToAyah делает
      // jumpTo по `index × tileExtent`.
      //
      // См. [_scrollToAyah] для подробностей про tileExtent.
      if (widget.initialAyah > 1) {
        // Ищем ayah по number в текущем кеше. Если ayahs ещё
        // не загружены (StreamBuilder в loading), _scrollToAyah
        // no-op'ом выйдет. Следующая загрузка в build() сама
        // вызовет scroll через [onAyahsLoaded] callback.
        final idx = _lastAyahs?.indexWhere(
              (a) => a.ayahNumber == widget.initialAyah,
            ) ??
            -1;
        if (idx >= 0) {
          _scrollToAyah(idx);
        }
      }
    });
  }

  /// Кэш последних загруженных ayahs из [ayahsAsync]. Используется
  /// в [initState] для deep-link scroll, когда ayahs приходят
  /// **раньше** первого frame'а (т.е. до того, как StreamBuilder в
  /// build'е получил данные). После первого frame'а этот кэш
  /// обновляется через `_lastAyahs = ...` в `_SingleScrollMushaf`'s
  /// build, и deep-link scroll работает.
  List<Ayah>? _lastAyahs;

  /// Прокрутить [SingleChildScrollView] к аяту с индексом [index]
  /// в списке аятов. Вызывается из initState (deep-link scroll
  /// при загрузке) и из build (когда ayahsAsync приходит с
  /// данными).
  ///
  /// Алгоритм: `index × tileExtent` (220 лог. пикс. — оценка
  /// высоты одного аята с translation + arabic + ornament divider).
  /// Это приближение: для длинных сур off-by-one ±1 аят
  /// незаметен, а для коротких (Al-Fatiha) — корректный индекс
  /// даёт правильный scroll-position.
  ///
  /// Если scroll position за пределами контента — clamp через
  /// `maxScrollExtent`. Если [_pageCtrl] ещё не attached к
  /// viewport (mounted в build'е) — no-op.
  void _scrollToAyah(int index) {
    const tileExtent = 220.0;
    final target = (index * tileExtent).clamp(
      0.0,
      _pageCtrl.position.maxScrollExtent,
    );
    _pageCtrl.jumpTo(target);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  /// Tap на Mushaf-зоне — toggle верхней/нижней панели. Срабатывает
  /// ТОЛЬКО если тап НЕ пришёл от `WordSpan` (тап по слову
  /// открывает WordCard, а не сворачивает панели). Внутри
  /// `AyahTile._ArabicText` тап на слове поглощается до того,
  /// как дойдёт до этого GestureDetector (т.к. WordCard открывается
  /// в `showModalBottomSheet`, который сразу выходит в стек).
  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
  }

  /// Вызывается из [_SingleScrollMushaf._onScroll] при скролле
  /// вниз — панели сворачиваются, чтобы не загораживать текст.
  /// Скролл вверх — панели возвращаются.
  void _setControlsVisible(bool visible) {
    if (_controlsVisible == visible) return;
    setState(() => _controlsVisible = visible);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final prefs = ref.watch(appPreferencesProvider);
    final readerKey = ReaderKey(
      surahId: widget.surahId,
      translationLang: prefs.translationLang,
    );
    final dataAsync = ref.watch(_readerDataProvider(readerKey));
    final ayahsAsync = ref.watch(_ayahsStreamProvider(widget.surahId));
    final bookmarkedIds =
        ref.watch(bookmarkedAyahIdsProvider).value ?? const <int>{};

    return Scaffold(
      body: Stack(
        children: [
          // Задний план: Mushaf (занимает весь экран). Тап по
          // нему → toggle панелей.
          Positioned.fill(
            child: SafeArea(
              bottom: false,
              child: GestureDetector(
                // `behavior: translucent` — тап доходит **и** к
                // нам, **и** к ребёнку. Без этого:
                //   - `opaque` поглощает тап и `WordSpan` / `IconButton`
                //     / `SelectableText` внутри Mushaf **не**
                //     получают тап вообще (тап по слову не открывает
                //     WordCard);
                //   - `deferToChild` (по умолчанию) не ловит тап,
                //     если под пальцем текст (`SelectableText` /
                //     `Wrap` поглощают), а toggle не работает
                //     поверх текста.
                // `translucent` — компромисс: тап по слову
                // открывает WordCard И триггерит toggle; тап по
                // пустому пространству триггерит только toggle.
                // WordCard — модальное окно, после его закрытия
                // панели будут в новом состоянии (это ожидаемо).
                behavior: HitTestBehavior.translucent,
                onTap: _toggleControls,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: _AnimatedControlsFrame(
                    visible: _controlsVisible,
                    child: dataAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('$e')),
                      data: (data) {
                        final surah = data.surah;
                        if (surah == null) {
                          return Center(
                            child: Text(
                              t.searchResultsEmpty,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return GoldFrame(
                          padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                          borderWidth: 1.4,
                          radius: 28,
                          showCornerArabesques: true,
                          child: ayahsAsync.when(
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (e, _) => Center(child: Text('$e')),
                            data: (ayahs) {
                              if (ayahs.isEmpty) {
                                return Center(
                                  child: Text(
                                    t.searchResultsEmpty,
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              }
                              return _SingleScrollMushaf(
                                key: ValueKey(
                                  // `lineByLine` часть `Key` —
                                  // когда режим меняется, Flutter
                                  // размонтирует старый `_SingleScrollMushaf`
                                  // (с `scrollCtrl.removeListener` в
                                  // `dispose()`) и монтирует новый.
                                  // Без этого `ScrollController`
                                  // остаётся привязанным к старому
                                  // `SingleChildScrollView`, и при
                                  // rebuild с другим деревом (book
                                  // vs lineByLine) Flutter framework
                                  // бросает assertion
                                  // `controller is being used by
                                  // multiple scrollables`, который в
                                  // dev-режиме сбрасывает navigation
                                  // stack на Home.
                                  'mushaf-$_readingMode-${ayahs.length}',
                                ),
                                ayahs: ayahs,
                                translations:
                                    dataAsync.value?.translations ?? const {},
                                fontSize: prefs.fontSize,
                                bookmarkedIds: bookmarkedIds,
                                scrollCtrl: _pageCtrl,
                                lineByLine: _readingMode == 'lineByLine',
                                onInitialLoad: (loaded) {
                                  // Сохраняем последний список ayahs
                                  // для deep-link scroll в initState
                                  // (если он сработал до того, как
                                  // StreamBuilder в build() получил
                                  // данные). Также делаем scroll
                                  // здесь — это второй шанс, если
                                  // initState не смог найти аят.
                                  _lastAyahs = loaded;
                                  if (widget.initialAyah > 1) {
                                    final idx = loaded.indexWhere(
                                      (a) =>
                                          a.ayahNumber ==
                                          widget.initialAyah,
                                    );
                                    if (idx >= 0) _scrollToAyah(idx);
                                  }
                                },
                                onAyahVisible: (Ayah a) {
                                  final repo =
                                      ref.read(quranRepositoryProvider);
                                  unawaited(repo.recordLastRead(
                                    surahId: a.surahId,
                                    ayahId: a.id,
                                  ));
                                  unawaited(repo.recordAyahRead(
                                    surahId: a.surahId,
                                  ));
                                },
                                // Финальная запись при выходе с
                                // экрана (через `dispose()` в
                                // `_SingleScrollMushaf`). Гарантирует,
                                // что **последний видимый** аят
                                // попадёт в БД, даже если
                                // scroll-tick не успел записать
                                // из-за throttle 200ms или если
                                // пользователь не скроллил
                                // (тогда `_lastReportedAyahId`
                                // ещё `null` — пишем
                                // `widget.initialAyah`).
                                onFinalAyah: (int ayahId) {
                                  final repo =
                                      ref.read(quranRepositoryProvider);
                                  unawaited(repo.recordLastRead(
                                    surahId: widget.surahId,
                                    ayahId: ayahId,
                                  ));
                                },
                                onToggleBookmark:
                                    (Ayah a, bool isBookmarked) =>
                                        toggleBookmark(
                                  ref,
                                  ayah: a,
                                  isCurrentlyBookmarked: isBookmarked,
                                ),
                                // При скролле вниз панели
                                // сворачиваются; вверх — появляются.
                                onScrollDelta: (delta) {
                                  // Скролл вниз (контент идёт вверх,
                                  // delta > 0) — панель сворачивается,
                                  // чтобы не загораживать текст.
                                  // Скролл вверх (delta < 0) — НЕ
                                  // возвращает панель: пользователь
                                  // может скроллить обратно без
                                  // того, чтобы top-bar каждый раз
                                  // «выскакивал». Панель появляется
                                  // только по явному тапу.
                                  if (delta > 4) {
                                    _setControlsVisible(false);
                                  }
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Передний план: верхняя control-панель (заголовок
          // суры + reading-mode toggle + settings). Анимировано
          // через `AnimatedSlide + AnimatedOpacity`. Позиция
          // `top: 0, left: 0, right: 0` + `SafeArea top` —
          // панель стартует под системным status-bar.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _AnimatedTopBar(
              visible: _controlsVisible,
              surahNameAr:
                  dataAsync.value?.surah?.nameAr ?? '',
              surahNameLatin: dataAsync.value?.surah == null
                  ? '…'
                  : t.surahName(
                      dataAsync.value!.surah!.id,
                      fallback: dataAsync.value!.surah!.nameTransliteration,
                    ),
              ayahsCount: dataAsync.value?.surah?.ayahCount ?? 0,
              ayahsCountLabel:
                  dataAsync.value?.surah == null
                      ? ''
                      : t.ayahsCount(dataAsync.value!.surah!.ayahCount),
              readingMode: _readingMode,
              readingModeLabel: _readingMode == 'lineByLine'
                  ? t.readingModeLineByLine
                  : t.readingModeBook,
              onBack: () => context.go('/read'),
              onToggleReadingMode: () {
                // Пишем в SharedPreferences и обновляем **локальный**
                // `_readingMode` state через `setState` ниже — без
                // участия Riverpod, чтобы не триггерить redirect в
                // go_router. `appPreferencesProvider` снова
                // иммутабельный `Provider`, и `setReadingMode` —
                // fire-and-forget. На следующем mount / refresh
                // провайдер отдаст свежее значение.
                final next = _readingMode == 'lineByLine'
                    ? 'book'
                    : 'lineByLine';
                unawaited(ref.read(appPreferencesProvider).setReadingMode(next));
                setState(() {
                  _readingMode = next;
                });
              },
              onSettings: () {
                // Открываем settings через dialog/bottom-sheet —
                // пока пусть проксирует на /settings (как раньше).
                context.go('/settings');
              },
              readingModeTooltip: t.readingModeTooltip,
            ),
          ),
          // Передний план: нижняя control-панель — mini-player.
          // Отрисовывается только если идёт воспроизведение
          // (`state.surah != null`). Анимируется синхронно с top
          // bar через тот же `_controlsVisible` флаг.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _AnimatedBottomBar(visible: _controlsVisible),
          ),
          // НЕ ставим `Positioned.fill` с `GestureDetector` поверх
          // top bar / bottom bar — это перехватывает тапы по их
          // кнопкам (`IconButton`, `InkWell`), и toggle-иконка
          // `view_column` / `menu_book` перестаёт работать.
          //
          // Вместо этого `onTap: _toggleControls` стоит ВНУТРИ
          // Mushaf-обёртки (см. выше). При тапе на Mushaf —
          // toggle срабатывает; при тапе на кнопки top bar / bottom
          // bar — HitTest идёт от ребёнка к родителю, и `InkWell`
          // / `IconButton` (по умолчанию opaque) поглощают тап раньше,
          // чем он дошёл бы до Mushaf-GestureDetector.
        ],
      ),
    );
  }
}

/// Mushaf-рамка с анимацией прозрачности/масштаба при появлении
/// панелей (когда панели появляются, рамка слегка уменьшается,
/// давая визуальный отклик; когда скрываются — растягивается
/// обратно). Очень тонкий эффект — 0.5% масштаба, чисто для
/// "дыхания" UI.
class _AnimatedControlsFrame extends StatelessWidget {
  const _AnimatedControlsFrame({required this.visible, required this.child});
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: visible ? 1.0 : 0.995,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: child,
    );
  }
}

/// Верхняя панель управления Mushaf-экрана.
/// Включает: кнопку «назад» (стрелка), заголовок суры
/// (арабский + транслитерация + кол-во аятов), кнопку
/// переключения режима чтения (lineByLine ↔ book), иконку
/// настроек. Появляется/скрывается через `AnimatedSlide +
/// AnimatedOpacity` — синхронизировано с `_controlsVisible`.
class _AnimatedTopBar extends StatelessWidget {
  const _AnimatedTopBar({
    required this.visible,
    required this.surahNameAr,
    required this.surahNameLatin,
    required this.ayahsCount,
    required this.ayahsCountLabel,
    required this.readingMode,
    required this.readingModeLabel,
    required this.readingModeTooltip,
    required this.onBack,
    required this.onToggleReadingMode,
    required this.onSettings,
  });

  final bool visible;
  final String surahNameAr;
  final String surahNameLatin;
  final int ayahsCount;
  final String ayahsCountLabel;
  final String readingMode;
  final String readingModeLabel;
  final String readingModeTooltip;
  final VoidCallback onBack;
  final VoidCallback onToggleReadingMode;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final isLineByLine = readingMode == 'lineByLine';
    return AnimatedSlide(
      // `Offset(0, -1)` сдвигает панель на всю высоту вверх —
      // полностью за пределы экрана. `Offset.zero` — панель
      // полностью видна.
      offset: visible ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              // Полупрозрачный dark-green фон, имитирующий
              // системный app-bar. `surfaceTint` отсутствует —
              // матовая заливка под стеклом, как в Material 3.
              color: AppColors.background.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.35),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleIconButton(
                  icon: Icons.arrow_back_ios_new,
                  iconSize: 18,
                  onTap: onBack,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surahNameAr.isEmpty ? surahNameLatin : surahNameAr,
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                          fontFamily: 'Amiri',
                          height: 1.1,
                        ),
                      ),
                      Text(
                        '$surahNameLatin • $ayahsCountLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _ReadingModeToggle(
                  isLineByLine: isLineByLine,
                  tooltip: readingModeTooltip,
                  label: readingModeLabel,
                  onTap: onToggleReadingMode,
                ),
                const SizedBox(width: 4),
                CircleIconButton(
                  icon: Icons.tune,
                  iconSize: 20,
                  onTap: onSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Нижняя control-панель: mini-player. Отрисовывается только
/// если `state.surah != null` (идёт воспроизведение). Слайд
/// вниз при `visible == false`, opacity 0. Анимация
/// синхронизирована с [_AnimatedTopBar] через общий
/// `_controlsVisible` flag родительского `_ReaderScreenState`.
///
/// Не использует `ConsumerWidget` — берёт audio-state через
/// `Consumer`-замыкание в build'е, чтобы избежать rebuild'а
/// всего stack'а на каждый position-tick плеера (текущий
/// mini-player в MainScaffold делает то же самое через
/// `ref.watch(audioPlayerControllerProvider)` — там это
/// безопасно, потому что он отдельный widget; здесь мы
/// держим рендеринг плеера внутри `Builder`, чтобы
/// зависимость от audio-state не раздувала rebuild Reader'а).
class _AnimatedBottomBar extends ConsumerWidget {
  const _AnimatedBottomBar({required this.visible});
  final bool visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Empty placeholder пока ничего не играет — иначе анимация
    // дала бы пустой визуальный «провал» в нижней части экрана
    // при первом mount, до того как юзер нажал play.
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Builder(builder: (innerCtx) {
              // Изолированный `Consumer`-смотритель `audioPlayerController`
              // — ребилдит **только** mini-player, а не весь
              // Reader-экран. Позиция плеера обновляется
              // ~60 раз/сек; если бы он сидел на верхнем
              // уровне, `_ReaderScreenState.build()` пересобирался
              // бы так же часто — бессмысленная работа.
              return Consumer(
                builder: (ctx, ref, _) {
                  final state = ref.watch(audioPlayerControllerProvider);
                  if (state.surah == null) return const SizedBox.shrink();
                  final hasError = state.error != null;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go('/listen'),
                      borderRadius: BorderRadius.circular(20),
                      child: Ink(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.surfaceElevated,
                              AppColors.surface,
                            ],
                          ),
                          border: Border.all(
                            color: hasError
                                ? AppColors.error
                                : AppColors.gold.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (hasError ? AppColors.error : AppColors.gold)
                                      .withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding:
                            const EdgeInsets.fromLTRB(12, 10, 8, 10),
                        child: Row(
                          children: [
                            GoldIconBadge(
                              icon: hasError
                                  ? Icons.error_outline
                                  : (state.playing
                                      ? Icons.graphic_eq
                                      : Icons.music_note),
                              size: 40,
                              iconSize: 20,
                              background: Colors.transparent,
                              borderColor: hasError
                                  ? AppColors.error
                                  : AppColors.gold,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppLocalizations.of(ctx).surahName(
                                      state.surah!.id,
                                      fallback: state.surahName,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hasError
                                        ? AppLocalizations.of(ctx).playerError
                                        : (state.reciter == null
                                            ? ''
                                            : AppLocalizations.of(ctx)
                                                .reciterName(
                                                state.reciter!.id,
                                                fallback:
                                                    state.reciter!.nameEn,
                                              )),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: hasError
                                          ? AppColors.error
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (hasError) {
                                  ref
                                      .read(audioPlayerControllerProvider
                                          .notifier)
                                      .clearError();
                                  if (state.reciter != null) {
                                    ref
                                        .read(
                                            audioPlayerControllerProvider
                                                .notifier)
                                        .playSurah(
                                          reciterId: state.reciter!.id,
                                          surahId: state.surah!.id,
                                        );
                                  }
                                } else {
                                  ref
                                      .read(quranAudioHandlerProvider)
                                      .play();
                                }
                              },
                              icon: Icon(
                                hasError
                                    ? Icons.refresh
                                    : (state.playing
                                        ? Icons.pause
                                        : Icons.play_arrow),
                                color: hasError
                                    ? AppColors.error
                                    : AppColors.gold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref
                                  .read(quranAudioHandlerProvider)
                                  .stop(),
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Pill-кнопка «построчно / книга». Иконка переключается
/// между `view_column` (построчно) и `menu_book` (книга);
/// внизу — подпись (label) в маленьком моноширинном стиле,
/// чтобы было понятно без tooltip'а.
class _ReadingModeToggle extends StatelessWidget {
  const _ReadingModeToggle({
    required this.isLineByLine,
    required this.tooltip,
    required this.label,
    required this.onTap,
  });

  final bool isLineByLine;
  final String tooltip;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLineByLine ? Icons.view_column_outlined : Icons.menu_book,
                color: AppColors.gold,
                size: 18,
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// (вызов `onAyahVisible`). Throttle 200ms — на быстром
/// скролле запись в БД не должна срабатывать чаще раза в
/// 200ms (UPSERT-ы всё равно идемпотентны, но debounce
/// уменьшает I/O).
class _SingleScrollMushaf extends StatefulWidget {
  const _SingleScrollMushaf({
    super.key,
    required this.ayahs,
    required this.translations,
    required this.fontSize,
    required this.bookmarkedIds,
    required this.scrollCtrl,
    required this.onAyahVisible,
    required this.onToggleBookmark,
    required this.lineByLine,
    this.onScrollDelta,
    this.onInitialLoad,
    this.onFinalAyah,
  });

  final List<Ayah> ayahs;
  final Map<int, String> translations;
  final double fontSize;
  final Set<int> bookmarkedIds;
  final ScrollController scrollCtrl;
  final void Function(Ayah ayah) onAyahVisible;
  final Future<bool> Function(Ayah ayah, bool isCurrentlyBookmarked)
      onToggleBookmark;
  final bool lineByLine;

  /// Callback, вызываемый при каждом изменении scroll-position
  /// (в пикселях). Положительные значения = scroll down
  /// (контент идёт вверх, пользователь читает сверху вниз);
  /// отрицательные = scroll up. Используется родительским
  /// `_ReaderScreen` для auto-hide верхней панели.
  final void Function(double delta)? onScrollDelta;

  /// Callback, вызываемый один раз при mount с полным списком
  /// ayahs. Используется родительским `_ReaderScreen` для
  /// deep-link scroll (`route ?ayah=N`): как только ayahs
  /// становятся доступны, родитель делает `jumpTo` к нужному
  /// индексу.
  final void Function(List<Ayah> ayahs)? onInitialLoad;

  /// Callback, вызываемый в `dispose()` с `id` последнего
  /// видимого аята. Позволяет родителю сделать **финальную**
  /// запись `recordLastRead` даже если последний scroll-tick
  /// не успел записать из-за throttle 200ms или быстрого
  /// fling'а (когда `_onScroll` зовётся редко, и `_lastReportedAyahId`
  /// может отставать от фактического положения).
  final void Function(int ayahId)? onFinalAyah;

  @override
  State<_SingleScrollMushaf> createState() => _SingleScrollMushafState();
}

class _SingleScrollMushafState extends State<_SingleScrollMushaf> {
  // «Key» аята, который мы в последний раз считали активным.
  // Используется для throttle — `onAyahVisible` зовётся не на
  // каждый scroll-tick, а только при смене аята.
  int? _lastReportedAyahId;
  DateTime _lastReportAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Последнее значение offset'а — нужно для вычисления дельты
  // scroll'а (используется родительским `_ReaderScreen` для
  // auto-hide панелей). -1 = ещё не сэмплировано.
  double _lastOffset = -1;

  // [GlobalKey] для каждого `AyahTile` в `lineByLine` режиме.
  // Используется в [_onScroll] через `findRenderObject` →
  // `localToGlobal(Offset.zero)` для **точного** определения
  // позиции аята в viewport'е. В `book` режиме (арабский поток
  // в одном `Text`) ключи не создаются, fallback на
  // `tileExtent`-эвристику.
  late List<GlobalKey> _tileKeys;

  @override
  void initState() {
    super.initState();
    _tileKeys = List.generate(widget.ayahs.length, (_) => GlobalKey());
    widget.scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Не вызываем `onAyahVisible(ayahs.first)` здесь — родитель
      // уже сделал корректный `recordLastRead(ayahId: initialAyah.id)`
      // в своём initState (см. `_ReaderScreenState.initState`).
      // Дополнительный вызов с `ayahs.first` (= id=1 для Аль-Фатиха)
      // перезаписывал бы правильный `last_position` на первый аят
      // — пользователь возвращался бы на Home и видел "ayah 1"
      // вместо "ayah 7" (или того, на который был deep-link).
      //
      // Сообщаем родителю о полном списке ayahs — для
      // deep-link scroll (см. _scrollToAyah).
      if (widget.ayahs.isNotEmpty) {
        widget.onInitialLoad?.call(widget.ayahs);
      }
    });
  }

  @override
  void dispose() {
    // Финальная запись `last_position`: если пользователь дочитал
    // до аята X и сразу вышел (например, нажал `KEYCODE_BACK`
    // или тапнул в bottom-nav), последний scroll-tick мог **не**
    // записать X из-за throttle 200ms. Здесь мы знаем
    // `_lastReportedAyahId` — записываем его явно.
    //
    // **Fallback**: если `_lastReportedAyahId == null` (пользователь
    // не скроллил вообще — открыл Reader и сразу вышел), пишем
    // `widget.initialAyah`. В этом случае `_lastReportedAyahId`
    // остаётся `null` потому что scroll-tick'и не сработали;
    // но `recordLastRead(ayahId: initialAyah.id)` уже сделал
    // parent'овский initState (см. `_ReaderScreenState.initState`),
    // — **дополнительная** запись в `dispose()` не повредит:
    // она просто повторит то же значение, что безопасно
    // (если `last_position` уже записан, `insertOnConflictUpdate`
    // просто обновит timestamp).
    final fallbackAyahId = _lastReportedAyahId;
    if (fallbackAyahId != null && widget.onFinalAyah != null) {
      widget.onFinalAyah!(fallbackAyahId);
    }
    widget.scrollCtrl.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (widget.ayahs.isEmpty) return;

    // Auto-hide панелей по scrollDelta. `addListener` зовётся
    // после того, как `controller.offset` уже обновлён, поэтому
    // нам нужно хранить предыдущее значение, чтобы вычислить
    // дельту. `_lastOffset` инициализируется -1 — это «ещё не
    // знаем», первая дельта игнорируется.
    final currentOffset = widget.scrollCtrl.offset;
    if (_lastOffset >= 0 && widget.onScrollDelta != null) {
      widget.onScrollDelta!(currentOffset - _lastOffset);
    }
    _lastOffset = currentOffset;

    // Throttle: не чаще раза в 200 ms.
    final now = DateTime.now();
    if (now.difference(_lastReportAt).inMilliseconds < 200) return;

    // Определяем активный аят по **реальным** координатам
    // RenderBox'ов (если есть GlobalKey'и). В `lineByLine`-режиме
    // ключи `_tileKeys[i]` ведут на `AyahTile` с i-м аятом;
    // используем `localToGlobal(Offset.zero)` чтобы узнать
    // верхнюю глобальную Y каждого аята, и сравниваем с
    // `bottomY` viewport'а.
    final viewport = widget.scrollCtrl.position.viewportDimension;
    final found = _findActiveAyahByRenderBox(currentOffset, viewport);
    if (found == null) return;
    if (found.id != _lastReportedAyahId) {
      _lastReportedAyahId = found.id;
      _lastReportAt = now;
      widget.onAyahVisible(found);
    }
  }

  /// Возвращает аят, у которого `topY <= bottomY < bottomY + viewport`.
  /// Использует `GlobalKey.findRenderObject` + `RenderBox.localToGlobal`
  /// для **точных** координат (в отличие от эвристики `tileExtent = 220`).
  /// Если ключи не привязаны (book-режим) — fallback на
  /// `tileExtent`-эвристику.
  Ayah? _findActiveAyahByRenderBox(double currentOffset, double viewport) {
    if (widget.lineByLine && _tileKeys.isNotEmpty) {
      // Скролл-контейнер находится **выше** экрана (его origin
      // в глобальных координатах отрицательный, потому что
      // `SingleChildScrollView` смещён вверх на `currentOffset`).
      //
      // `currentOffset` — это **локальный** Y скролла в его
      // собственном координатном пространстве (top = 0,
      // bottom = scrollableHeight). `viewport` — высота видимой
      // части. `bottomY = currentOffset + viewport` — Y нижней
      // границы viewport'а в координатах scrollable-контента.
      //
      // Чтобы перевести `bottomY` в **глобальные** координаты
      // (с которыми работает `localToGlobal`), используем
      // RenderBox самого `SingleChildScrollView`:
      //   `bottomY_global = scrollBox.globalY + viewport`
      //
      // Затем для каждого tile: `tile.globalY < bottomY_global` —
      // tile **в viewport'е** (его верхняя граница выше нижней
      // границы viewport'а).
      final scrollBox = _findScrollRenderBox();
      if (scrollBox == null) return null;
      final scrollGlobalY = scrollBox.localToGlobal(Offset.zero).dy;
      final bottomYGlobal = scrollGlobalY + viewport;

      // Проходим по tile'ам в обратном порядке (от конца) и
      // возвращаем **первый**, чей верх (`topY < bottomYGlobal`).
      // Это даёт **последний видимый** аят — пользователь только
      // что читал его (или дочитывает сейчас).
      for (var i = _tileKeys.length - 1; i >= 0; i--) {
        final key = _tileKeys[i];
        final ctx = key.currentContext;
        if (ctx == null) continue;
        final box = ctx.findRenderObject();
        if (box is! RenderBox) continue;
        final tileTopGlobalY = box.localToGlobal(Offset.zero).dy;
        if (tileTopGlobalY < bottomYGlobal) {
          return widget.ayahs[i];
        }
      }
      // Ни один tile не попал в viewport (например, все tile'ы
      // выше top'а scroll'а) — возвращаем первый.
      return widget.ayahs.first;
    }
    // Fallback: book-режим (один Text-поток) или edge-case.
    // Используем `tileExtent`-эвристику как раньше.
    var cumulative = 0.0;
    const tileExtent = 220.0;
    final centerY = currentOffset + viewport / 2;
    for (final a in widget.ayahs) {
      final next = cumulative + tileExtent;
      if (centerY >= cumulative && centerY < next) {
        return a;
      }
      cumulative = next;
    }
    return null;
  }

  /// Ищет [RenderBox] для `SingleChildScrollView` в subtree текущего
  /// widget'а. Используется для вычисления глобальной Y нижней
  /// границы viewport'а.
  RenderBox? _findScrollRenderBox() {
    final ctx = context;
    RenderBox? result;
    void visitor(Element el) {
      final ro = el.renderObject;
      if (ro is RenderBox && el.widget is SingleChildScrollView) {
        result = ro;
        return;
      }
      el.visitChildren(visitor);
    }

    ctx.visitChildElements(visitor);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lineByLine) {
      return _buildLineByLine();
    }
    return _buildBookStyle();
  }

  /// «Построчный» режим: каждый аят в своём [AyahTile], между
  /// ними ornament-разделитель. Внутри аята — центрированный
  /// арабский текст + перевод. Соответствует референсу
  /// `docs/images/read line by line.png`.
  Widget _buildLineByLine() {
    return SingleChildScrollView(
      controller: widget.scrollCtrl,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.ayahs.length; i++) ...[
            // Без первого divider'а — он визуально «свисает» с
            // первого аята. Это 1:1 с референсом, где первый
            // аят идёт сразу после ornament-рамочки заголовка.
            if (i > 0) const _AyahSeparator(),
            AyahTile(
              // `tileKey` прокидывается из `_tileKeys[i]` — см.
              // [_findActiveAyahByRenderBox]. Используется для
              // точного определения активного аята через
              // `RenderBox.localToGlobal`.
              tileKey: i < _tileKeys.length ? _tileKeys[i] : null,
              ayah: widget.ayahs[i],
              translation: widget.translations[widget.ayahs[i].id],
              fontSize: widget.fontSize,
              isBookmarked: widget.bookmarkedIds.contains(
                widget.ayahs[i].id,
              ),
              onToggleBookmark: () => widget.onToggleBookmark(
                widget.ayahs[i],
                widget.bookmarkedIds.contains(widget.ayahs[i].id),
              ),
              lineByLine: true,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// «Книжный» режим: арабский текст идёт **одним непрерывным
  /// `SelectableText`** через все аяты с inline-номерами в
  /// круглых скобках `(١)` между ними. Между аятами — ornament
  /// divider. Перевод каждого аята — отдельным блоком **после**
  /// арабского потока, внизу. Соответствует запросу: «арабский
  /// текст перетекает от края до края, перевод — после».
  Widget _buildBookStyle() {
    // Собираем арабский текст с inline-нумерацией. Круглые
    // скобки и арабские цифры (U+0660..U+0669) — стандартная
    // Mushaf-вёрстка: «(١) بِسْمِ ٱللَّهِ ... (٢) ٱلْحَمْدُ ...».
    final ayahs = widget.ayahs;
    final ayahNumberStrings = <String>[];
    for (final a in ayahs) {
      ayahNumberStrings.add('(${toArabicDigits(a.ayahNumber)})');
    }

    // Конкатенация через пробелы между номерами и текстами.
    // `SelectableText` с `TextAlign.justify` — поток идёт
    // полной шириной, `textDirection: rtl` — арабский RTL.
    final arabicBuffer = StringBuffer();
    for (var i = 0; i < ayahs.length; i++) {
      if (i > 0) arabicBuffer.write(' ');
      arabicBuffer.write(ayahs[i].textUthmani);
      arabicBuffer.write(' ');
      arabicBuffer.write(ayahNumberStrings[i]);
    }

    return SingleChildScrollView(
      controller: widget.scrollCtrl,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Непрерывный арабский поток: все аяты подряд с
          // номерами в круглых скобках между ними. Текст
          // `justify` — строки тянутся от левого до правого
          // края (как в печатной Mushaf). Параметры:
          //   - textDirection: rtl — арабский текст и номера
          //     читаются справа-налево
          //   - textAlign: justify — межсловные пробелы
          //     растягиваются до полной ширины строки
          //   - textHeight: 2.4 — комфортное вертикальное
          //     «дыхание» для длинного потока
          //   - fontFamily: 'Amiri' — печатный Naskh
          //
          // ВАЖНО: используется `Text`, а не `SelectableText`:
          //   - `SelectableText` перехватывает тапы для cursor /
          //     выделения — тап НЕ доходит до Mushaf-GestDetector
          //     (даже с `translucent`), и toggle не работает
          //     поверх текста в book-режиме;
          //   - выделение текста в Mushaf — спорная функция
          //     (в печатной Mushaf текст тоже нельзя выделить),
          //     и сейчас она перевешивает toggle;
          //   - `Text` не поглощает HitTest — тап проходит
          //     сквозь к родителю.
          Text(
            arabicBuffer.toString(),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: widget.fontSize,
              height: 2.4,
              color: AppColors.textPrimary,
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(height: 16),
          // Ornament-разделитель между арабским блоком и
          // переводами — визуально «отбивает» начало секции
          // переводов, как в печатной Mushaf.
          const _AyahSeparator(),
          const SizedBox(height: 16),
          // Перевод каждого аята отдельным блоком, в порядке
          // возрастания `ayahNumber`. Стиль — мелкий, серая
          // типографика, имитирующая комментарии внизу страницы
          // печатной Mushaf. Номера аятов — в формате
          // «(N) перевод», чтобы можно было соотнести с
          // арабским оригиналом.
          for (var i = 0; i < ayahs.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            if (widget.translations[ayahs[i].id] != null)
              _BookTranslationBlock(
                number: ayahs[i].ayahNumber,
                text: widget.translations[ayahs[i].id]!,
              ),
          ],
        ],
      ),
    );
  }

  /// Конвертация цифр в арабские вынесена в
  /// `core/i18n/arabic_digits.dart` — единая утилита для всех
  /// мест, где нужна Mushaf-вёрстка с арабскими цифрами.
}

/// Блок перевода для «книжного» режима. Аят-номер в круглых
/// скобках арабскими цифрами (соответствует inline-номеру в
/// арабском оригинале) + сам перевод. Имитирует формат
/// печатной Mushaf, где под основным текстом идёт
/// расширенный комментарий переводчика.
class _BookTranslationBlock extends StatelessWidget {
  const _BookTranslationBlock({required this.number, required this.text});
  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.55,
            letterSpacing: 0.1,
          ),
          children: [
            TextSpan(
              text: '(${toArabicDigits(number)}) ',
              style: const TextStyle(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

/// Декоративный горизонтальный разделитель с центральной
/// 8-конечной звездой — ornament между аятами внутри Mushaf
/// (см. `docs/images/read line by line.png` — там между
/// каждым аятом длинная линия со звездой посередине).
class _AyahSeparator extends StatelessWidget {
  const _AyahSeparator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: CustomPaint(
        size: const Size(double.infinity, 18),
        painter: _AyahSeparatorPainter(),
      ),
    );
  }
}

class _AyahSeparatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.55)
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;
    final cy = size.height / 2;
    final halfW = size.width / 2;
    // Линия слева от звезды (отступ 16, длина до звезды - 12)
    canvas.drawLine(
      Offset(16, cy),
      Offset(halfW - 16, cy),
      paint,
    );
    // Линия справа
    canvas.drawLine(
      Offset(halfW + 16, cy),
      Offset(size.width - 16, cy),
      paint,
    );
    // 8-конечная звезда по центру
    const outerR = 5.0;
    const innerR = 2.2;
    final cx = halfW;
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = i * math.pi / 8 - math.pi / 2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
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
  bool shouldRepaint(_AyahSeparatorPainter old) => false;
}

/// Поток аятов одной суры. Не смотрит всю таблицу `ayahs`, только
/// нужные строки (Drift сам эмитит при изменениях).
final _ayahsStreamProvider = StreamProvider.autoDispose.family<List<Ayah>, int>(
  (ref, surahId) {
    return ref.watch(ayahDaoProvider).watchBySurah(surahId);
  },
);
