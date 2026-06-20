import 'dart:async';

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
import '../../reader_settings/domain/reader_display_settings.dart';
import '../../reader_settings/presentation/reader_palette.dart';
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

  /// Стабильный [GlobalKey] для `_SingleScrollMushaf` — через
  /// `mushafKey.currentState` parent может дёргать
  /// `scrollToAyahByIndex(idx)` для deep-link scroll (Continue
  /// button → `/reader/1?ayah=5` ставит аят 5 в центр viewport'а).
  ///
  /// Ключ пересоздаётся на каждый `surahId` (через `ValueKey(surahId)`),
  /// чтобы избежать конфликтов при смене сурah'а — иначе старый
  /// `_SingleScrollMushafState` остался бы привязан к новому
  /// widget'у (типичный Flutter pitfall с `GlobalKey`).
  final GlobalKey _mushafKey = GlobalKey();

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
        // не загружены (StreamBuilder в loading), scroll
        // no-op'ом выйдет. Следующая загрузка в build() сама
        // вызовет scroll через [onAyahsLoaded] callback.
        final idx = _lastAyahs?.indexWhere(
              (a) => a.ayahNumber == widget.initialAyah,
            ) ??
            -1;
        if (idx >= 0) {
          // Определяем режим: lineByLine → `_SingleScrollMushaf`
          // (через GlobalKey), book → локальный `_scrollToAyah`.
          if (_readingMode == 'lineByLine') {
            // Defer scroll на **следующий** postFrame — иначе
            // `RenderBox` ещё не laid out. На самом первом
            // postFrame (этот) `Scrollable` уже создан, но
            // `_tileKeys[idx].currentContext` может быть null
            // (тайминг Flutter framework'а). На **следующем**
            // postFrame — гарантированно готов.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final state = _mushafKey.currentState;
              if (state is _SingleScrollMushafState) {
                state.scrollToAyahByIndex(idx);
              } else {
                const tileExtent = 220.0;
                final viewport = _pageCtrl.position.viewportDimension;
                final maxOffset = _pageCtrl.position.maxScrollExtent;
                final target = (idx * tileExtent - viewport / 2 + tileExtent / 2)
                    .clamp(0.0, maxOffset);
                _pageCtrl.jumpTo(target);
              }
            });
          } else {
            _scrollToAyah(idx);
          }
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
    final display = ref.watch(readerDisplaySettingsProvider);
    final readerKey = ReaderKey(
      surahId: widget.surahId,
      translationLang: prefs.translationLang,
    );
    final dataAsync = ref.watch(_readerDataProvider(readerKey));
    final ayahsAsync = ref.watch(_ayahsStreamProvider(widget.surahId));
    final bookmarkedIds =
        ref.watch(bookmarkedAyahIdsProvider).value ?? const <int>{};

    return Scaffold(
      // `themeVariant` влияет на фон зоны чтения, не на глобальную
      // тему (навигация остаётся тёмной). Через `ReaderPalette.of`.
      backgroundColor: ReaderPalette.of(display.themeVariant).background,
      body: Stack(
        children: [
          // Задний план: Mushaf (занимает весь экран). Тап по
          // нему → toggle панелей.
          //
          // `SafeArea(top: false, bottom: false)` — убраны
          // left/right safe-area (Android system insets для
          // notch/cutout). Это позволяет тексту при
          // `paddingHorizontal: 0` быть в самом краю экрана.
          // top/bottom safe-area остаются на top/bottom bar'ах
          // (см. ниже), чтобы статус-бар и навигация не
          // перекрывались.
          Positioned.fill(
            child: SafeArea(
              top: false,
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
                        // Раньше здесь был `GoldFrame` — декоративная
                        // золотая рамка с арабесками по углам
                        // (имитация печатной Mushaf). Убрано: рамка
                        // и ornament-звёзды визуально перегружали
                        // экран и не соответствовали современному
                        // минималистичному дизайну. `Padding`
                        // оставлен для отступов.
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
                                  // `fontFamily` в key — критично:
                                  // без него при смене шрифта в settings
                                  // Flutter переиспользует Element
                                  // _SingleScrollMushaf, и `widget.display`
                                  // обновляется, но `displaySettingsProvider`
                                  // notification может не дойти до
                                  // `AyahTile` (если _SingleScrollMushaf
                                  // не ребилдится по какой-то причине).
                                  // `ValueKey(fontFamily)` форсирует
                                  // пересоздание State, гарантируя
                                  // что AyahTile получает новый display.
                                  'mushaf-$_readingMode-${ayahs.length}-'
                                  '${display.fontFamily}',
                                ),
                                // `mushafKey` — стабильный `GlobalKey`
                                // для доступа к `scrollToAyahByIndex` из
                                // parent'а (через `mushafKey.currentState`).
                                // Без него parent не может приказать
                                // `Mushaf` прокрутиться к нужному аяту
                                // при deep-link (Continue button
                                // → `/reader/1?ayah=5`).
                                mushafKey: _mushafKey,
                                ayahs: ayahs,
                                translations:
                                    dataAsync.value?.translations ?? const {},
                                fontSize: display.fontSize,
                                display: display,
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
                                    if (idx >= 0) {
                                      // Точный scroll через RenderBox
                                      // (для lineByLine) или tileExtent
                                      // fallback (для book).
                                      if (_readingMode == 'lineByLine') {
                                        // Defer scroll на **следующий**
                                        // postFrame — иначе
                                        // `_tileKeys[idx].currentContext`
                                        // ещё null (RenderBox не laid out
                                        // при первом frame после mount).
                                        // `curves.linear` + `Duration.zero`
                                        // — мгновенный snap без анимации.
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                          if (!mounted) return;
                                          final state =
                                              _mushafKey.currentState;
                                          if (state
                                              is _SingleScrollMushafState) {
                                            state.scrollToAyahByIndex(idx);
                                          }
                                        });
                                      } else {
                                        _scrollToAyah(idx);
                                      }
                                    }
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
              readingModeTooltip: t.readingModeTooltip,
              onBack: () => context.pop(),
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
                unawaited(ref.read(appPreferencesProvider.notifier).setReadingMode(next));
                setState(() {
                  _readingMode = next;
                });
              },
              onSettings: () {
                // Сразу открываем **полный экран** настроек
                // отображения (`/reader-settings/display`) — он
                // содержит все 4 группы (Текст/Макет/Тема/
                // Дополнительно) и даёт sticky-preview с
                // live-обновлением. Bottom-sheet с quick-
                // настройками (размер арабского / режим / язык)
                // убран — все эти параметры либо уже в экране
                // (размер шрифта), либо доступны через bottom-nav
                // `/profile` (язык, режим чтения).
                //
                // `push` (не `go`): back возвращает в Reader
                // с уже применёнными изменениями; пользователь
                // остаётся в контексте чтения.
                context.push('/reader-settings/display');
              },
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
        // `IgnorePointer` — стандартный паттерн для hide/show
        // анимированных панелей. Без него панель **получает**
        // hit-test **во время анимации** скрытия (260ms), и тапы
        // по области Mushaf поглощаются панелью → Mushaf
        // GestureDetector не срабатывает. Это объясняет
        // нестабильный z-order: иногда тап на TopBar доходит
        // (Mushaf уже не перехватывает), иногда — нет (TopBar
        // ещё в hit-test).
        child: IgnorePointer(
          ignoring: !visible,
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
        child: IgnorePointer(
          ignoring: !visible,
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
                      onTap: () => context.push('/listen'),
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
    required this.display,
    this.mushafKey,
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

  /// Display-настройки (`ReaderDisplaySettings`) — lineHeight,
  /// letterSpacing, wordSpacing, fontFamily, padding, textWidth.
  /// Применяются к арабскому и переводу в обоих режимах
  /// (lineByLine / book) и к `ConstrainedBox` по ширине полосы.
  final ReaderDisplaySettings display;

  /// Опциональный [GlobalKey] для доступа к
  /// `scrollToAyahByIndex` из parent'а. Parent передаёт `_mushafKey`,
  /// через `currentState` может дёргать scroll к нужному аяту при
  /// deep-link (Continue → `/reader/:id?ayah=N`).
  final GlobalKey? mushafKey;  /// Callback, вызываемый при каждом изменении scroll-position
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

  /// Прокручивает Mushaf так, чтобы аят с индексом [index] оказался
  /// **в центре** viewport'а. Используется для deep-link scroll
  /// (Continue → `/reader/1?ayah=5`).
  ///
  /// Использует `Scrollable.ensureVisible` с `alignment: 0.5` —
  /// **стандартный** Flutter-механизм для scroll-to-element,
  /// который корректно учитывает padding'и scrollable-контейнера,
  /// `minScrollExtent`/`maxScrollExtent`, и обеспечивает попадание
  /// элемента **точно в центр** viewport'а (`alignment: 0.5`).
  /// Работает даже если `RenderBox` ещё не fully laid out —
  /// `Scrollable.ensureVisible` сам вызывает `postFrameCallback`.
  void scrollToAyahByIndex(int index) {
    if (index < 0 || index >= widget.ayahs.length) return;
    if (widget.lineByLine && index < _tileKeys.length) {
      // Проверяем, что Scrollable **уже привязан** к `scrollCtrl` —
      // иначе `widget.scrollCtrl.position` бросит assertion.
      if (!widget.scrollCtrl.hasClients) {
        // Scrollable ещё не привязан к controller (pre-mount).
        // Defer на следующий postFrame — к тому моменту
        // `Scrollable` уже будет attached.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          scrollToAyahByIndex(index);
        });
        return;
      }
      final tileCtx = _tileKeys[index].currentContext;
      if (tileCtx != null) {
        // Точный расчёт offset'а через `localToGlobal` —
        // устраняет дрейф `Scrollable.ensureVisible` (который
        // находит ближайший `Scrollable` через parent'овский
        // `Scaffold`/`Padding`, и из-за padding'ов аят оказывается
        // не в центре, а смещён).
        //
        // Алгоритм:
        //  1. Получаем **реальные** глобальные Y для tile'а и
        //     SingleChildScrollView.
        //  2. `tileTopInScroll = tileGlobalY - scrollGlobalY` — это
        //     позиция **верха** tile'а в **координатах scroll-контента**
        //     (т.е. offset'ы, которые нам нужно подать в `jumpTo`).
        //  3. `tileHeight` — реальная высота tile'а (через
        //     `RenderBox.size.height`).
        //  4. **Центр** tile'а: `tileTopInScroll + tileHeight/2`.
        //  5. Чтобы он совпал с центром viewport'а (на позиции
        //     `currentOffset + viewport/2` в scroll-контенте),
        //     нужно: `jumpTo(center - viewport/2)`.
        final scrollBox = _findScrollRenderBox();
        final tileBox = tileCtx.findRenderObject();
        if (scrollBox is RenderBox && tileBox is RenderBox) {
          final scrollGlobalY = scrollBox.localToGlobal(Offset.zero).dy;
          final tileGlobalY = tileBox.localToGlobal(Offset.zero).dy;
          final tileTopInScroll = tileGlobalY - scrollGlobalY;
          final tileHeight = tileBox.size.height;
          final viewport = widget.scrollCtrl.position.viewportDimension;
          final maxOffset = widget.scrollCtrl.position.maxScrollExtent;
          // Центр tile'а в координатах scroll-контента.
          final tileCenterInScroll = tileTopInScroll + tileHeight / 2;
          // Нужен offset, при котором tileCenterInScroll попадает
          // в центр viewport'а.
          final target = (tileCenterInScroll - viewport / 2)
              .clamp(0.0, maxOffset);
          widget.scrollCtrl.jumpTo(target);
        } else {
          // RenderBox не готов (pre-attach) — defer и retry.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            scrollToAyahByIndex(index);
          });
        }
        _lastReportedAyahId = widget.ayahs[index].id;
        return;
      }
    }
    // Fallback: book-режим (один Text-поток) или edge-case
    // (RenderBox ещё не attached). Используем tileExtent-эвристику
    // + центрирование.
    const tileExtent = 220.0;
    final viewport = widget.scrollCtrl.position.viewportDimension;
    final maxOffset = widget.scrollCtrl.position.maxScrollExtent;
    final target = (index * tileExtent - viewport / 2 + tileExtent / 2)
        .clamp(0.0, maxOffset);
    widget.scrollCtrl.jumpTo(target);
    _lastReportedAyahId = widget.ayahs[index].id;
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
            // Разделитель с номером аята — ставится **перед**
            // каждым аятом, включая первый. Это даёт **n**
            // разделителей для **n** аятов (требование UX),
            // и каждый ornament подписан номером своего аята.
            // Визуально: горизонтальная линия с разрывом
            // посередине, в разрыве — `۝N` (U+06DD + арабская
            // цифра). Стиль «классическая печатная Mushaf» —
            // ornament ۝N традиционно ставится в **начале**
            // аята, отделяя один аят от другого.
            _AyahSeparator(
              ayahNumber: widget.ayahs[i].ayahNumber,
              // `fontFamily` для глифа `۝` и арабской цифры —
              // пользовательский выбор шрифта. Без этого ornament
              // всегда Amiri, что «чужеродно» в Scheherazade /
              // Aref Ruqaa / Noto Naskh.
              fontFamily: widget.display.fontFamily,
              // Цифра = цвет основного текста Quran (из палитры
              // темы) — визуально связывает ornament с потоком.
              digitColor: ReaderPalette.of(widget.display.themeVariant).text,
            ),
            AyahTile(
              // `tileKey` прокидывается из `_tileKeys[i]` — см.
              // [_findActiveAyahByRenderBox]. Используется для
              // точного определения активного аята через
              // `RenderBox.localToGlobal`.
              tileKey: i < _tileKeys.length ? _tileKeys[i] : null,
              ayah: widget.ayahs[i],
              translation: widget.translations[widget.ayahs[i].id],
              fontSize: widget.fontSize,
              display: widget.display,
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
  /// `Text.rich`** через все аяты с inline-ornament'ом `_OrnamentGlyph`
  /// (глиф `۝` + цифра по центру) между ними. Перевод каждого
  /// аята — отдельным блоком **после** арабского потока, внизу.
  Widget _buildBookStyle() {
    final ayahs = widget.ayahs;

    // Собираем `InlineSpan`-ы: чередуем арабский текст и
    // `WidgetSpan` с `_OrnamentGlyph`. Цифра рендерится **по
    // центру** ornament-глифа (через Stack внутри `_OrnamentGlyph`)
    /// во всех 6 поддерживаемых Quran-шрифтах (Amiri, KFGQPC
    /// Uthman Taha, PDMS Saleem, QPC Hafs, Scheherazade New,
    /// Noto Naskh Arabic).
    final spans = <InlineSpan>[];
    for (var i = 0; i < ayahs.length; i++) {
      if (i > 0) {
        // U+2009 (THIN SPACE) — тонкий пробел между аятами.
        // Раньше был обычный `' '` — аяты визуально отстояли
        // друг от друга на полную ширину пробела, ornament
        // смотрелся «оторванным» от текста.
        spans.add(const TextSpan(text: '\u2009'));
      }
      spans.add(TextSpan(text: ayahs[i].textUthmani));
      // U+2009 между арабским и ornament `۝N` — расстояние
      // между словом и ornament минимальное. Снижает
      // визуальный разрыв между ornament и потоком текста.
      spans.add(const TextSpan(text: '\u2009'));
      // Ornament `۝N` — `WidgetSpan` с `_OrnamentGlyph`.
      // `alignment: PlaceholderAlignment.middle` — по центру
      // baseline строки.
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: _OrnamentGlyph(
          ayahNumber: ayahs[i].ayahNumber,
          fontFamily: widget.display.fontFamily,
          // Цифра ornament'а = цвет основного текста Quran
          // (из палитры темы) — визуально связывает ornament
          // с потоком арабского текста. Глиф `۝` остаётся
          // золотым по умолчанию.
          digitColor: ReaderPalette.of(widget.display.themeVariant).text,
        ),
      ));
    }

    return SingleChildScrollView(
      controller: widget.scrollCtrl,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        vertical: widget.display.paddingVertical,
        // `paddingHorizontal` — пользовательская настройка
        // (горизонтальные отступы по краям строки текста).
        // Раньше был только `paddingVertical`.
        horizontal: widget.display.paddingHorizontal,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pct = widget.display.textWidthPercent;
          final maxW = constraints.maxWidth.isFinite
              ? constraints.maxWidth * pct / 100.0
              : double.infinity;
          final content = Column(
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
          //   - fontFamily: динамический, выбирается пользователем
          //     (Amiri, Scheherazade New, Noto Naskh, Aref Ruqaa)
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
          // `Text.rich` + `WidgetSpan(_OrnamentGlyph)` — ornament
          // с цифрой по центру глифа `۝`. Раньше был `Text('۝N ')`
          // inline — цифра уезжала вниз в Scheherazade / Aref Ruqaa.
          Text.rich(
            TextSpan(
              children: spans,
              style: TextStyle(
                fontSize: widget.fontSize,
                // 2.4 — дефолт, `display.lineHeight` переопределяет.
                height: widget.display.lineHeight,
                letterSpacing: widget.display.letterSpacing,
                wordSpacing: widget.display.wordSpacing,
                color: ReaderPalette.of(widget.display.themeVariant).text,
                fontFamily: widget.display.fontFamily,
                fontWeight: FontWeight.w400,
              ),
            ),
            textDirection: TextDirection.rtl,
            // Арабский текст в book-mode выравнивается по центру —
            // пользовательская настройка (раньше был `justify` —
            // межсловные пробелы растягивались до полной ширины
            // строки, что в арабском выглядит неестественно).
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Ornament-разделитель убран (см. lineByLine выше).
          // Вместо `_AyahSeparator` — простой gap, который
          // визуально отбивает перевод от арабского блока.
          const SizedBox(height: 16),
          // Перевод каждого аята отдельным блоком, в порядке
          // возрастания `ayahNumber`. Стиль — мелкий, серая
          // типографика, имитирующая комментарии внизу страницы
          // печатной Mushaf. Номера аятов — в формате
          // «(N) перевод», чтобы можно было соотнести с
          // арабским оригиналом.
          for (var i = 0; i < ayahs.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            if (widget.translations[ayahs[i].id] != null &&
                (widget.display.showTranslation))
              _BookTranslationBlock(
                number: ayahs[i].ayahNumber,
                text: widget.translations[ayahs[i].id]!,
                display: widget.display,
              ),
          ],
            ],
          );
          if (pct >= 100.0) return content;
          // Без центрирования IntrinsicHeight+Center — они
          // конфликтуют с LayoutBuilder в AyahTile и ломают
          // рендеринг. Book-mode центрирование не критично.
          if (pct >= 100.0) return content;
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: content,
            ),
          );
        },
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
  const _BookTranslationBlock({
    required this.number,
    required this.text,
    this.display,
  });
  final int number;
  final String text;
  final ReaderDisplaySettings? display;

  @override
  Widget build(BuildContext context) {
    final d = display;
    final textColor = d != null
        ? ReaderPalette.of(d.themeVariant).text.withValues(alpha: 0.7)
        : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: RichText(
        // Перевод в book-mode выравнивается по центру —
        // соответствует выравниванию арабского потока выше.
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            // В book-mode перевод исторически был ~85% от
            // пользовательского `translationFontSize`, чтобы
            // длинный поток аятов оставался компактным. Default
            // 14 * 0.85 ≈ 12 px — соответствует legacy.
            fontSize: (d?.translationFontSize ?? 14) * 0.85,
            color: textColor,
            height: d != null ? d.lineHeight - 0.85 : 1.55,
            letterSpacing: d?.letterSpacing ?? 0.1,
            wordSpacing: d?.wordSpacing ?? 0,
          ),
          children: [
            // Ornament `۝N` — `WidgetSpan` с `_OrnamentGlyph`
            // (цифра по центру глифа во всех шрифтах). Размер
            // подогнан под `translationFontSize * 0.85` —
            // ornament не должен «раскалывать» строку перевода.
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _OrnamentGlyph(
                ayahNumber: number,
                fontFamily: d?.fontFamily,
                glyphSize: 18,
                digitSize: 9,
                // Цифра = цвет перевода (из палитры темы, с alpha
                // 0.7 для иерархии — ornament чуть менее яркий,
                // чем основной текст). Глиф `۝` остаётся золотым.
                digitColor: d != null
                    ? ReaderPalette.of(d.themeVariant).text
                        .withValues(alpha: 0.7)
                    : AppColors.textSecondary,
              ),
            ),
            // U+2009 (THIN SPACE) — расстояние между ornament
            // и переводом минимальное (раньше был обычный пробел).
            const TextSpan(text: '\u2009'),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

/// Горизонтальный декоративный разделитель аятов в построчном
/// режиме. Используется **только** в `lineByLine` — в `book`-режиме
/// (Mushaf-стиль) ornament не нужен, потому что аяты идут одним
/// непрерывным потоком.
///
/// Дизайн: тонкая горизонтальная линия с **разрывом посередине**,
/// в разрыве — `۝N` (U+06DD + арабская цифра номера аята).
/// Соответствует классической печатной Mushaf, где ornament
/// `۝N` ставится в **начале** каждого аята.
///
/// **Семантика**: один разделитель = один аят, ставится **перед**
/// каждым аятом (включая первый). Это даёт `n` разделителей
/// для `n` аятов (требование UX) — ornament подписан номером
/// **своего** аята.
///
/// **Размеры**: высота 28px, ширина — `double.infinity`
/// (растягивается на всю ширину). Ornament — горизонтально
/// центрирован. Глиф `۝` — 22px золотом, цифра — 11px в
/// цвете основного текста Quran (из палитры темы).
///
/// **Цвет**: линия — `AppColors.gold` с opacity 0.55 (как
/// раньше), глиф `۝` — золотой 0.85, цифра — **цвет основного
/// текста** (из палитры). Цифра визуально связывает ornament
/// с потоком арабского текста.
class _AyahSeparator extends StatelessWidget {
  const _AyahSeparator({
    required this.ayahNumber,
    required this.digitColor,
    this.fontFamily,
  });

  /// Номер аята, который отображается в центре (как `۝N`).
  final int ayahNumber;

  /// Цвет цифры = цвет основного текста Quran (из палитры).
  /// Обязательный параметр.
  final Color digitColor;

  /// Шрифт для глифа `۝` и арабской цифры. По умолчанию
  /// `Amiri` — в нём U+06DD имеет уникальный ornament-глиф
  /// (подвешен сверху), который визуально отличается от
  /// других шрифтов. Передавайте `display.fontFamily`,
  /// чтобы ornament соответствовал основному тексту.
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Линия под текстом (с разрывом под `۝N`).
          Positioned.fill(
            child: CustomPaint(
              painter: _AyahSeparatorPainter(),
              size: const Size(double.infinity, 28),
            ),
          ),
          // Ornament `۝N`: глиф `۝` и цифра рендерятся
          // **отдельными** `Text` в `Stack`, чтобы выровнять
          // цифру по **вертикальному центру** глифа, а не по
          // baseline. Глиф — золотой, цифра — в цвет основного
          // текста Quran.
          SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Глиф `۝` — крупный (size 22), центрирован
                // вертикально, золотой. У всех шрифтов проекта
                // U+06DD визуально занимает большую часть высоты
                // строки.
                Text(
                  '۝',
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.0,
                    color: AppColors.gold.withValues(alpha: 0.85),
                    fontFamily: fontFamily,
                  ),
                ),
                // Цифра — поверх глифа, отцентрована по
                // **вертикали** (`Padding(top: 2)` для точного
                // совпадения с центром глифа). Цвет = цвет
                // основного текста Quran (из палитры темы) —
                // визуально связывает ornament с потоком.
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    toArabicDigits(ayahNumber),
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.0,
                      color: digitColor,
                      fontFamily: fontFamily,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable ornament-глиф `۝N` с цифрой **точно по центру**
/// ornament-глифа. Используется в book-mode (внутри `Text.rich`
/// через `WidgetSpan`) и в `_BookTranslationBlock`.
///
/// **Проблема**: глиф U+06DD `۝` в шрифтах Scheherazade New,
/// Aref Ruqaa, Noto Naskh визуально занимает почти всю высоту
/// строки, и арабская цифра после него в `Text('۝N')` уезжает
/// вниз (baseline цифры не совпадает с центром глифа).
///
/// **Решение**: глиф и цифра — **отдельные** `Text` в `Stack`,
/// цифра центрируется по вертикали относительно глифа.
///
/// Используется в `WidgetSpan` внутри `Text.rich` — единственный
/// способ вставить inline-виджет в `Text`.
///
/// **Цвета**: глиф `۝` всегда золотой (выделяется как ornament),
/// цифра номера аята — **цвет основного текста Quran** (из
/// палитры темы). Это визуально связывает ornament с потоком
/// арабского текста.
class _OrnamentGlyph extends StatelessWidget {
  const _OrnamentGlyph({
    required this.ayahNumber,
    required this.digitColor,
    this.fontFamily,
    this.glyphSize = 26,
    this.digitSize = 13,
  });

  /// Номер аята.
  final int ayahNumber;

  /// Шрифт для глифа `۝` и арабской цифры.
  final String? fontFamily;

  /// Размер глифа `۝` (px). По умолчанию 26 (увеличен с 22 для
  /// лучшей видимости ornament-символа в потоке текста).
  final double glyphSize;

  /// Размер цифры (px). По умолчанию 13 — пропорционально глифу.
  final double digitSize;

  /// Цвет цифры номера аята. Обязательный параметр — должен
  /// совпадать с цветом основного текста Quran (из `ReaderPalette`
  /// для текущей темы). Это делает цифру «частью» текста, а не
  /// отдельным ornament-элементом.
  final Color digitColor;

  @override
  Widget build(BuildContext context) {
    final glyphC = AppColors.gold;
    return SizedBox(
      // Высота widget'а = высота глифа + немного запаса.
      height: glyphSize + 2,
      // Ширина подбирается под глиф + digit. `۝` в Amiri/Scheherazade
      // ~ 26x39, цифра ~ 14x20 — ornament у́же глифа + 4px (минимум
      // для overlap цифры поверх глифа). Раньше было `glyphSize + 10`
      // (лишние ~6px по бокам) — ornament визуально отстоял от
      // слова. Сейчас ornament **вплотную** к глифу, расстояние
      // между словом и ornament меньше.
      width: glyphSize + 4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Глиф `۝` — крупный, центрирован, всегда золотой.
          Text(
            '۝',
            style: TextStyle(
              fontSize: glyphSize,
              height: 1.0,
              color: glyphC,
              fontFamily: fontFamily,
            ),
          ),
          // Цифра поверх глифа, по **вертикальному центру**.
          // `top: 3` — для увеличенного глифа (fontSize 26)
          // цифру нужно чуть больше приподнять от геометрического
          // центра Stack'а, чтобы она визуально совпадала с
          // центром ornament-глифа (у глифа вертикальный центр
          // сдвинут чуть выше из-за типометрических особенностей).
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              toArabicDigits(ayahNumber),
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: digitSize,
                height: 1.0,
                // Цифра = цвет основного текста Quran (из палитры).
                color: digitColor,
                fontFamily: fontFamily,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AyahSeparatorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    // Золотой полупрозрачный цвет (как у других ornament'ов).
    final base = AppColors.gold.withValues(alpha: 0.55);
    // Линия потоньше для элегантности.
    final linePaint = Paint()
      ..color = base
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    // ── Линия с разрывом посередине ────────────────────
    // Разрыв = `_AyahSeparator.gapWidth` (должен совпадать
    // с padding текста + реальная ширина глифа `۝N`,
    // но мы рисуем линию **под** Stack'ом — точная ширина
    // разрыва не критична, потому что текст сверху закрывает
    // любой «зазор». Здесь используем `gapHalf = 28` —
    // с запасом для 1–2 цифр арабского номера.
    const lineInset = 16.0; // Отступ от краёв экрана.
    const gapHalf = 32.0; // Половина ширины разрыва.
    final cx = size.width / 2;
    final leftEnd = cx - gapHalf;
    final rightStart = cx + gapHalf;

    // Градиент на линии — затухание к краям экрана.
    // Левая половина: прозрачный → золотой.
    _drawGradientLine(
      canvas,
      Offset(lineInset, cy),
      Offset(leftEnd, cy),
      linePaint,
    );
    // Правая половина: золотой → прозрачный.
    _drawGradientLine(
      canvas,
      Offset(rightStart, cy),
      Offset(size.width - lineInset, cy),
      linePaint,
      reverse: true,
    );
  }

  /// Рисует линию с горизонтальным градиентом opacity —
  /// от прозрачного (на конце) к золоту (в середине).
  /// Это даёт эффект «затухания» линии к краям экрана.
  ///
  /// [reverse] — для правой половины: золото слева, прозрачный
  /// справа (зеркально).
  void _drawGradientLine(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint basePaint, {
    bool reverse = false,
  }) {
    final gradient = Paint()
      ..shader = LinearGradient(
        colors: reverse
            ? [
                basePaint.color,
                basePaint.color.withValues(alpha: 0.0),
              ]
            : [
                basePaint.color.withValues(alpha: 0.0),
                basePaint.color,
              ],
      ).createShader(Rect.fromPoints(from, to))
      ..strokeWidth = basePaint.strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, gradient);
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

