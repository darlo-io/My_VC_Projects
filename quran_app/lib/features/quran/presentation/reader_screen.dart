import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/data/reader_data.dart';
import '../../../core/database/app_database.dart';
import '../../../core/i18n/localized_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../../shared/widgets/ornaments.dart';
import '../../../shared/widgets/screen_header.dart';
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
  // (см. `docs/images/read line by line.png`). `initialScrollOffset`
  // — в логических пикселях, не в аятах, поэтому `ayah` → `offset`
  // вычисляется через item-extent в [_SingleScrollMushaf].
  // (TODO: если будет желание — поддержать deep-link scroll.)
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
    });
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
                                  'mushaf-${_readingMode}-${ayahs.length}',
                                ),
                                ayahs: ayahs,
                                translations:
                                    dataAsync.value?.translations ?? const {},
                                fontSize: prefs.fontSize,
                                bookmarkedIds: bookmarkedIds,
                                scrollCtrl: _pageCtrl,
                                lineByLine: _readingMode == 'lineByLine',
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

  @override
  void initState() {
    super.initState();
    widget.scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // После первого frame'а сообщаем о первом аяте (deep-link
      // на суру начинается с него).
      if (widget.ayahs.isNotEmpty) {
        widget.onAyahVisible(widget.ayahs.first);
      }
    });
  }

  @override
  void dispose() {
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

    final offset = widget.scrollCtrl.offset;
    final viewport = widget.scrollCtrl.position.viewportDimension;
    final centerY = offset + viewport / 2;

    // Активный аят — тот, у которого `startY <= centerY < endY`.
    // `startY` берём из RenderBox'а через globalToLocal —
    // проще через `NotificationListener<ScrollNotification>`,
    // но мы внутри `addListener`, где нет контекста. Поэтому
    // итерируем и сравниваем accumulated height по
    // `AyahTile.estimatedExtent` (≈ 220 лог. пикс. при
    // fontSize=28). Для точного срабатывания нужен
    // GlobalKey, но throttling + estimated extent даёт
    // ±1 аят, что для записи прогресса вполне достаточно.
    var cumulative = 0.0;
    final tileExtent = 220.0;
    for (final a in widget.ayahs) {
      final next = cumulative + tileExtent;
      if (centerY >= cumulative && centerY < next) {
        if (_lastReportedAyahId != a.id) {
          _lastReportedAyahId = a.id;
          _lastReportAt = now;
          widget.onAyahVisible(a);
        }
        return;
      }
      cumulative = next;
    }
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
      ayahNumberStrings.add('(${_toArabicDigits(a.ayahNumber)})');
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

  /// Конвертирует латинские цифры (1, 2, 3...) в арабские
  /// (١, ٢, ٣) для Mushaf-вёрстки. Используется только в
  /// «книжном» режиме, потому что в «построчном» номер
  /// рендерится как визуальная 8-звёздная плашка.
  String _toArabicDigits(int n) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final s = n.toString();
    final result = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      final idx = c.codeUnitAt(0) - 0x30;
      result.write(
        (idx >= 0 && idx <= 9) ? arabicDigits[idx] : c,
      );
    }
    return result.toString();
  }
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
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String toArabic(int n) {
      final s = n.toString();
      final r = StringBuffer();
      for (var i = 0; i < s.length; i++) {
        final c = s[i];
        final idx = c.codeUnitAt(0) - 0x30;
        r.write((idx >= 0 && idx <= 9) ? arabicDigits[idx] : c);
      }
      return r.toString();
    }

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
              text: '(${toArabic(number)}) ',
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
