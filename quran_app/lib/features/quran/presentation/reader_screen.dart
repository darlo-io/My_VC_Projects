import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/safe_pop.dart';

import '../../../app/providers.dart';
import '../../../core/data/reader_data.dart';
import '../../../core/database/app_database.dart';
import '../../../core/i18n/arabic_digits.dart';
import '../../../core/i18n/bismillah.dart';
import '../../../core/i18n/localized_names.dart';
import '../../../core/i18n/surah_name_glyph.dart';
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
    // Дополнительный listener на `_pageCtrl` для **финальной**
    // проверки scroll position. Это **не throttle'd** — срабатывает
    // на каждом изменении offset'а (включая окончательное «замирание»
    // scroll'а в конце). В нём мы **только** проверяем, близок ли
    // scroll к концу (в пределах 1 viewport'а), и если да — записываем
    // `ayahs.last.id`. Это гарантирует финальную запись даже если
    // scroll-tick'и из `_onScroll` пропустили последний кадр (из-за
    // throttle или быстрого fling'а).
    _pageCtrl.addListener(_checkScrollEnd);
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

  /// Номер **последнего аята в суре** (например, 7 для Аль-Фатиха,
  /// 286 для Аль-Бакара). Нужен для проверки «аят в пределах 5
  /// от конца» в `onAyahVisible` callback. Обновляется в
  /// `onInitialLoad` — **до** первого `onAyahVisible`.
  int? _ayahsCount;

  /// Номер **последнего аята**, который был записан в `last_position`
  /// через `onAyahVisible` callback. Используется в [dispose] для
  /// **финальной записи** `last_position` — если последний видимый
  /// аят находится в пределах 5 аятов от конца суры, считаем, что
  /// пользователь дочитал до конца, и записываем `ayahs.last.id`
  /// (см. комментарий в [dispose]).
  int? _lastReportedAyahNumber;

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

/// Дополнительный listener на `_pageCtrl` — срабатывает на
  /// каждом изменении offset'а (включая окончательное «замирание»
  /// scroll'а). В нём проверяем, близок ли scroll к концу, и
  /// если да — записываем `ayahs.last.id`. Это гарантирует
  /// финальную запись даже если scroll-tick'и из `_onScroll`
  /// пропустили последний кадр.
  void _checkScrollEnd() {
    if (!_pageCtrl.hasClients) return;
    if (_lastAyahs == null || _lastAyahs!.isEmpty) return;
    final position = _pageCtrl.position;
    // Условие: scroll в пределах 1 viewport'а от конца. Это
    // гарантирует, что **последний аят** находится на экране.
    if (position.maxScrollExtent > 0 &&
        position.maxScrollExtent - _pageCtrl.offset <
            position.viewportDimension) {
      final lastAyah = _lastAyahs!.last;
      // Записываем, только если **изменился** последний записанный
      // аят (избегаем лишних записей при каждом scroll-event'е).
      if (_lastReportedAyahNumber != lastAyah.ayahNumber) {
        _lastReportedAyahNumber = lastAyah.ayahNumber;
        final repo = ref.read(quranRepositoryProvider);
        unawaited(repo.recordLastRead(
          surahId: widget.surahId,
          ayahId: lastAyah.id,
        ));
      }
    }
  }

  @override
  void dispose() {
    // ── Финальная запись `last_position` при выходе с экрана ─────
    // Если пользователь дочитал суру до конца, `last_position`
    // должна указывать на последний аят, чтобы `progress = 1.0`
    // и панель «Продолжить чтение» скрылась.
    //
    // Используем **комбинированную** эвристику для надёжности:
    //
    // 1. **По scroll position**: если scroll в конце (`offset >=
    //    maxScrollExtent - 8`), записываем `ayahs.last.id`.
    //    Это работает, когда пользователь явно доскроллил до конца.
    //
    // 2. **По номеру последнего видимого аята** (если scroll
    //    position недоступна — например, `_pageCtrl.hasClients`
    //    уже false в момент dispose): если последний видимый аят
    //    (`_lastReportedAyahNumber`) находится в пределах 5 аятов
    //    от конца, считаем, что пользователь дочитал суру
    //    (scroll-tick записал почти-последний аят, и финальная
    //    запись обновит на последний).
    //
    // Допуск 5 аятов подобран так, чтобы покрыть случай, когда
    // пользователь вручную проскроллил к самому концу длинной
    // суры, но последний scroll-tick не успел записать
    // `ayahs.last` из-за throttle (200ms) или медленного скролла.
    _pageCtrl.removeListener(_checkScrollEnd);
    final repo = ref.read(quranRepositoryProvider);
    if (_lastAyahs != null && _lastAyahs!.isNotEmpty) {
      final lastAyah = _lastAyahs!.last;
      // Проверка 1: scroll position
      final scrollAtEnd = _pageCtrl.hasClients &&
          _pageCtrl.position.maxScrollExtent > 0 &&
          _pageCtrl.offset >= _pageCtrl.position.maxScrollExtent - 8;
      // Проверка 2: номер последнего видимого аята близок к концу
      final lastReportedNumber = _lastReportedAyahNumber;
      final ayahNearEnd = lastReportedNumber != null &&
          lastAyah.ayahNumber - lastReportedNumber <= 5 &&
          lastReportedNumber >= lastAyah.ayahNumber - 5;
      if (scrollAtEnd || ayahNearEnd) {
        unawaited(repo.recordLastRead(
          surahId: widget.surahId,
          ayahId: lastAyah.id,
        ));
      }
    }
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
          // SafeArea с `left: false, right: false` — горизонтальные
          // system insets (notch/cutout) не добавляют отступов.
          // `paddingHorizontal` из настроек — единственный
          // источник горизонтального отступа: при `0` текст
          // вплотную к краям экрана.
          // top/bottom safe-area остаются на top/bottom bar'ах
          // (см. ниже), чтобы статус-бар и навигация не
          // перекрывались.
          Positioned.fill(
            child: SafeArea(
              left: false,
              right: false,
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
                  // `display.paddingHorizontal` — единый источник
                  // горизонтального отступа. При `0` текст идёт
                  // вплотную к краям экрана.
                  padding: EdgeInsets.fromLTRB(
                    display.paddingHorizontal,
                    0,
                    display.paddingHorizontal,
                    4,
                  ),
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
                          // `display.paddingHorizontal` — единый источник
                          // горизонтального отступа (см. строки выше).
                          padding: EdgeInsets.fromLTRB(
                            display.paddingHorizontal,
                            8,
                            display.paddingHorizontal,
                            8,
                          ),
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
                                // Номер суры для ornament-header
                                // (`SurahHeader`). Арабское название
                                // само подтягивается glyph-строкой
                                // из `Surah Name V2.ttf` по этому id.
                                surahNumber: dataAsync.value?.surah?.id ?? 0,
                                onInitialLoad: (loaded) {
                                  // Сохраняем последний список ayahs
                                  // для deep-link scroll в initState
                                  // (если он сработал до того, как
                                  // StreamBuilder в build() получил
                                  // данные). Также делаем scroll
                                  // здесь — это второй шанс, если
                                  // initState не смог найти аят.
                                  _lastAyahs = loaded;
                                  // Сохраняем количество аятов в суре
                                  // для проверки «близко к концу» в
                                  // `onAyahVisible` callback.
                                  _ayahsCount = loaded.length;
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
                                  // Сохраняем номер последнего видимого
                                  // аята для **финальной** записи в
                                  // [dispose]. Если пользователь дочитал
                                  // почти до конца, но scroll-tick не
                                  // успел записать `ayahs.last` (из-за
                                  // throttle 200ms или быстрого
                                  // back-button), dispose() использует
                                  // это значение для эвристики
                                  // «близко к концу» и запишет
                                  // `ayahs.last.id`.
                                  _lastReportedAyahNumber = a.ayahNumber;
                                  final repo =
                                      ref.read(quranRepositoryProvider);
                                  // **Дополнительная эвристика для
                                  // конца суры**: если видимый аят
                                  // находится в пределах 5 аятов от
                                  // конца суры, считаем, что пользователь
                                  // дочитал её, и записываем **последний**
                                  // аят. Это покрывает случай, когда:
                                  //   - `_findActiveAyahByRenderBox` для
                                  //     book-mode возвращает предпоследний
                                  //     аят из-за `tileExtent`-эвристики;
                                  //   - пользователь **сразу** переходит на
                                  //     home screen (GoRouter **не** размонтирует
                                  //     `_ReaderScreenState`, поэтому
                                  //     `dispose()` не вызывается);
                                  //   - или scroll-tick записал аят N-3
                                  //     из-за медленного scroll'а.
                                  //
                                  // Допуск 5 аятов покрывает обычные
                                  // случаи (последний абзац суры может
                                  // содержать 1-3 аята).
                                  //
                                  // Используем `_ayahsCount` (не
                                  // `_lastAyahs`) — потому что `onAyahVisible`
                                  // может вызваться **раньше** `onInitialLoad`,
                                  // когда `_lastAyahs` ещё null. А
                                  // `_ayahsCount` обновляется тем же
                                  // `onInitialLoad` callback'ом, **до**
                                  // первого `onAyahVisible`.
                                  if (_ayahsCount != null &&
                                      _ayahsCount! - a.ayahNumber <= 50 &&
                                      a.ayahNumber != _ayahsCount) {
                                    // Записываем `ayahs.last.id`
                                    // (последний аят суры).
                                    // Нужен `id` последнего аята — ищем
                                    // в `_lastAyahs` (если он уже есть)
                                    // или вычисляем по `a.surahId` и
                                    // `_ayahsCount`.
                                    if (_lastAyahs != null &&
                                        _lastAyahs!.isNotEmpty) {
                                      final lastAyah = _lastAyahs!.last;
                                      if (lastAyah.ayahNumber ==
                                          _ayahsCount) {
                                        unawaited(repo.recordLastRead(
                                          surahId: a.surahId,
                                          ayahId: lastAyah.id,
                                        ));
                                        _lastReportedAyahNumber =
                                            lastAyah.ayahNumber;
                                      } else {
                                        // Fallback: записываем текущий аят.
                                        unawaited(repo.recordLastRead(
                                          surahId: a.surahId,
                                          ayahId: a.id,
                                        ));
                                      }
                                    } else {
                                      // `_lastAyahs` ещё null — fallback.
                                      unawaited(repo.recordLastRead(
                                        surahId: a.surahId,
                                        ayahId: a.id,
                                      ));
                                    }
                                  } else {
                                    // Иначе записываем текущий аят.
                                    unawaited(repo.recordLastRead(
                                      surahId: a.surahId,
                                      ayahId: a.id,
                                    ));
                                  }
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
              surahNameAr: dataAsync.value?.surah == null
                  ? ''
                  : // Арабское название суры в верхней панели —
                    // glyph-строка из `Surah Name V2.ttf` (PUA).
                    // `surah001` → U+E001 и т.д. В V2 шрифте
                    // стиль глифа отличается от V4 (используется
                    // в списке сур) — здесь чуть иная отрисовка.
                    surahNameGlyph(dataAsync.value!.surah!.id),
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
              onBack: () => safePop(context),
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
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                          // Арабское название суры рендерится
                          // glyph-шрифтом `Surah Name V2.ttf` —
                          // glyph `surah001` → U+E001 и т.д.
                          // (см. `surahNameGlyph`). Сюда уже
                          // приходит пред-вычисленная glyph-строка
                          // от parent'а (см. `_AnimatedTopBar.наверху`).
                          fontFamily: surahNameV2FontFamily,
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
    required this.surahNumber,
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

  /// Номер суры 1..114 — для ornament-header (`SurahHeader`).
  /// Само арабское название читается glyph-строкой из
  /// `Surah Name V2.ttf` внутри painter'а (`surah001` → U+E001),
  /// отдельно передавать строку не нужно.
  final int surahNumber;

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

    // ── Финальная позиция при чтении до конца ──────────────
    // Проверяем **до** `_findActiveAyahByRenderBox`, потому что
    // если scroll достиг `maxScrollExtent`, то «правильный»
    // активный аят — **последний** (`widget.ayahs.last`).
    // `_findActiveAyahByRenderBox` для длинных сур в book-режиме
    // использует `tileExtent`-эвристику (line 1305) и при
    // overshoot scroll'а может вернуть **предпоследний** аят.
    //
    // Поэтому: если scroll дошёл до конца, **немедленно**
    // записываем `ayahs.last` (это даёт `progress = 1.0` →
    // панель «Продолжить чтение» скрывается на главной).
    //
    // **Условие `maxScrollExtent > 0`**: для **коротких** сур
    // (Аль-Фатиха, Аль-Ихлас) вся сура помещается в viewport
    // без скролла, `maxScrollExtent = 0`. В этом случае мы **не**
    // принудительно записываем `ayahs.last.id` — пользователь
    // мог просто открыть суру и выйти, не дочитав (deep-link на
    // аят 1).
    //
    // Допуск 4 пикселя учитывает floating-point неточности
    // `position.maxScrollExtent` (subpixel layout) и rubber-band
    // overshoot в iOS-style.
    final position = widget.scrollCtrl.position;
    // Условие `currentOffset >= maxScrollExtent - 220` (≈ tileExtent).
    // Это покрывает случай, когда scroll остановился в пределах
    // одного «тайла» от конца (например, после `_findActiveAyahByRenderBox`
    // вернул предпоследний аят в book-mode из-за tileExtent-эвристики).
    // Допуск 220 (а не 8) гарантирует, что **когда пользователь
    // проскроллил до конца** (или очень близко к нему), мы запишем
    // `ayahs.last` в `last_position`.
    if (position.maxScrollExtent > 0 &&
        currentOffset >= position.maxScrollExtent - 220 &&
        widget.ayahs.isNotEmpty) {
      final lastAyah = widget.ayahs.last;
      if (_lastReportedAyahId != lastAyah.id) {
        _lastReportedAyahId = lastAyah.id;
        _lastReportAt = now;
        widget.onAyahVisible(lastAyah);
        return;
      }
    }

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

    // Финальная проверка scroll-end через `addPostFrameCallback`.
    // Гарантирует, что **после** `_findActiveAyahByRenderBox` и
    // рендера мы проверим scroll position **точно** — даже если
    // scroll больше не двигался. Это **единственный** способ
    // поймать момент, когда scroll дошёл до конца и остановился.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _checkScrollEndPostFrame(currentOffset);
    });
  }

  /// Дополнительная проверка scroll-end **после** рендера.
  /// Использует `currentOffset` (фиксированный в момент scroll-tick'а).
  void _checkScrollEndPostFrame(double currentOffset) {
    if (!widget.scrollCtrl.hasClients) return;
    if (widget.ayahs.isEmpty) return;
    final position = widget.scrollCtrl.position;
    // Условие: scroll в пределах 1 viewport'а от конца. Это значит,
    // что **последний аят** находится на экране, и пользователь
    // **видел** его. Записываем `ayahs.last.id`.
    if (position.maxScrollExtent > 0 &&
        position.maxScrollExtent - currentOffset <
            position.viewportDimension) {
      final lastAyah = widget.ayahs.last;
      if (_lastReportedAyahId != lastAyah.id) {
        _lastReportedAyahId = lastAyah.id;
        _lastReportAt = DateTime.now();
        widget.onAyahVisible(lastAyah);
      }
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
    //
    // **`tileExtent = 360`** (вместо старых 220) — намеренно
    // **завышенное** значение: для длинных сур (286 аятов)
    // `cumulative[285] = 285 * 360 = 102600 > maxScrollExtent`,
    // и цикл **ни разу** не вернёт аят. Тогда срабатывает edge-case
    // ниже (возвращает `ayahs.last`). Это гарантирует, что при
    // достижении **видимого конца** (когда последний аят на экране)
    // `_findActiveAyahByRenderBox` возвращает `ayahs.last`.
    //
    // Для коротких сур (Аль-Фатиха, 7 аятов) `tileExtent = 360`
    // даёт `cumulative[6] = 6 * 360 = 2160` — это **примерно равно
    // высоте viewport'а**, поэтому для коротких сур эвристика
    // может вернуть последний аят уже при обычном scroll'е.
    var cumulative = 0.0;
    const tileExtent = 360.0;
    final centerY = currentOffset + viewport / 2;
    for (final a in widget.ayahs) {
      final next = cumulative + tileExtent;
      if (centerY >= cumulative && centerY < next) {
        return a;
      }
      cumulative = next;
    }
    // **Edge-case**: scroll близок к концу, но `tileExtent`-эвристика
    // не дошла до последнего аята (она возвращает предпоследний,
    // потому что `centerY` попадает в диапазон tileExtent для
    // предпоследнего аята). В этом случае возвращаем **последний**
    // аят — пользователь **видит** его (он в viewport'е), и это
    // правильное значение для `_onScroll`.
    //
    // **Условие `maxScrollExtent - currentOffset < viewport`**:
    // scroll находится в пределах одного viewport'а от конца.
    // Это означает, что последний аят **точно виден** на экране
    // (иначе viewport не прокручен так близко к концу).
    if (widget.ayahs.isNotEmpty) {
      final position = widget.scrollCtrl.position;
      if (position.maxScrollExtent > 0 &&
          position.maxScrollExtent - currentOffset < viewport) {
        return widget.ayahs.last;
      }
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
      // Padding: горизонтальный `horizontal: 4` (минимальный
      // отступ от краёв экрана, чтобы ornament не «лип» к краю),
      // вертикальный — `vertical: 8` для запаса по краям viewport
      // (AppBar сверху, bottom-nav снизу). Сам ornament в
      // `_AyahSeparator` имеет `height: 24` и `clipBehavior:
      // Clip.none` — глиф визуально свисает ~2-3px за нижнюю границу
      // SizedBox (Uthmani descender), и `vertical: 8` гарантирует,
      // что для крайних аятов ornament не обрежется границей
      // viewport. Строки текста при этом располагаются плотно.
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.ayahs.length; i++) ...[
            // Заголовок суры в стиле бумажной Mushaf — ornament-header
            // с арабским названием и номером суры. Рендерится **только
            // один раз**, перед первым аятом. Соответствует канону
            // печатной Mushaf: каждая сура начинается с ornament-блока,
            // затем идёт текст.
            if (i == 0)
              SurahHeader(
                surahNumber: widget.surahNumber,
                textColor:
                    ReaderPalette.of(widget.display.themeVariant).text,
              ),
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
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// «Книжный» режим: арабский текст идёт **одним непрерывным
  /// `Text.rich`** через все аяты с inline-ornament'ом `_OrnamentGlyph`
  /// (глиф `۝` + цифра по центру) между ними. Перевод каждого
  /// аята — отдельным блоком **после** арабского потока, внизу.
  ///
  /// **Басмала**: если первый аят суры **начинается** с басмалы
  /// (`بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ`), префикс-басмала
  /// выносится из общего потока и рендерится **отдельным
  /// centered-заголовком** строго по центру экрана **над** текстом
  /// суры (соответствует канону печатной Mushaf). Перевод басмалы
  /// показывается сразу под ней как «(1) …». Сура начинается с новой
  /// строки, с **остатка** первого аята (если он был: «الم» для
  /// Аль-Бакары, «قُلْ هُوَ ٱللَّهُ أَحَدٌ» для Аль-Ихлас), или со
  /// 2-го аята (для Аль-Фатиха, где весь 1-й аят — басмала). Для
  /// суры 9 (ат-Тауба) басмала отсутствует, и текст идёт общим
  /// потоком без заголовка.
  Widget _buildBookStyle() {
    final ayahs = widget.ayahs;

    // Детекция басмалы в первом аяте. [Bismillah.split] корректно
    // обрабатывает **оба** варианта хранения в данных:
    //   - Аль-Фатиха: первый аят == басмала → `(basmala, rest: null)`
    //   - Остальные суры: первый аят = басмала + остаток →
    //     `(basmala, rest: 'الم' | 'قُلْ هُوَ ٱللَّهُ أَحَدٌ' | ...)`
    //   - Сура 9: первый аят не начинается с басмалы →
    //     `(basmala: null, rest: text)`
    final split = ayahs.isNotEmpty
        ? Bismillah.split(ayahs.first.textUthmani)
        : (basmala: null, rest: null);
    final basmalaText = split.basmala;
    final firstAyahRest = split.rest;
    final hasBasmala = basmalaText != null;

    // Строим **виртуальный** список аятов для Arabic-flow. Это
    // упрощает логику spans: каждый span идёт «один аят → один
    // ornament», без специальных случаев.
    //
    // Нумерация ornament'ов в Mushaf:
    // - **Аль-Фатиха (сура 1)**: басмала = аят 1, ornament `۝١`
    //   ставится **на** басмале. Затем `۝٢` на `الْحَمْدُ`, и т.д.
    //   Весь поток имеет ornament'ы ۝١..۝٧.
    // - **Остальные суры с басмалой** (2–114, кроме 9): басмала
    //   **не нумеруется**, ornament `۝١` ставится на **остатке**
    //   первого аята (после басмалы), затем `۝٢`, `۝٣`, …
    // - **Сура 9** (без басмалы): ornament `۝١` на 1-м аяте, и т.д.
    //
    // Реализация:
    // - Аль-Фатиха: 1-й «аят» в flow = виртуальный с текстом басмалы
    //   и `ayahNumber = 1`, остальные = аяты 2..N. Это даёт ornament
    //   `۝١` на басмале (как в печатной Mushaf).
    // - Остальные суры с басмалой: 1-й «аят» = виртуальный с
    //   `textUthmani = firstAyahRest` (тот же `ayahNumber = 1`, но
    //   ornament'а у самой басмалы нет — он стоит на rest).
    // - Сура 9 (нет басмалы): flow = все аяты как есть.
    final List<Ayah> flowAyahs;
    if (hasBasmala && firstAyahRest == null) {
      // Аль-Фатиха: 1-й аят = вся басмала, ornament `۝١` стоит на ней.
      // Создаём виртуальный аят 1 = эталонная басмала с тем же
      // id/surahId/ayahNumber(1), что и оригинальный 1-й аят
      // (который в БД == басмала).
      flowAyahs = [
        ayahs.first.copyWith(textUthmani: basmalaText),
        ...ayahs.sublist(1),
      ];
    } else if (hasBasmala && firstAyahRest != null) {
      // Остальные суры с басмалой + остаток: 1-й «аят» = виртуальный
      // с `textUthmani = firstAyahRest`. Басмала вынесена в заголовок
      // и ornament'а не имеет; ornament `۝١` стоит на rest.
      flowAyahs = [
        ayahs.first.copyWith(textUthmani: firstAyahRest),
        ...ayahs.sublist(1),
      ];
    } else {
      // Сура 9: нет басмалы, flow = все аяты как есть.
      flowAyahs = ayahs;
    }

    // Собираем `InlineSpan`-ы: чередуем арабский текст и
    // `WidgetSpan` с `_OrnamentGlyph`. Цифра рендерится **по
    // центру** ornament-глифа (через Stack внутри `_OrnamentGlyph`)
    /// во всех 6 поддерживаемых Quran-шрифтах (Amiri, KFGQPC
    /// Uthman Taha, PDMS Saleem, QPC Hafs, Scheherazade New,
    /// Noto Naskh Arabic).
    final spans = <InlineSpan>[];
    for (var i = 0; i < flowAyahs.length; i++) {
      if (i > 0) {
        // U+2009 (THIN SPACE) — тонкий пробел между аятами.
        // Раньше был обычный `' '` — аяты визуально отстояли
        // друг от друга на полную ширину пробела, ornament
        // смотрелся «оторванным» от текста.
        spans.add(const TextSpan(text: '\u2009'));
      }
      spans.add(TextSpan(text: flowAyahs[i].textUthmani));
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
          ayahNumber: flowAyahs[i].ayahNumber,
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
          final palette = ReaderPalette.of(widget.display.themeVariant);
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Заголовок суры в стиле бумажной Mushaf — ornament-рамка
              // с арабским названием. Рендерится **в обоих** режимах
              // (lineByLine / book) на самом верху — как и в печатной
              // Mushaf. Содержимое (название + номер) внутри одной
              // ornament-рамки, см. `SurahHeader` в `widgets/reader_widgets.dart`.
              SurahHeader(
                surahNumber: widget.surahNumber,
                textColor:
                    ReaderPalette.of(widget.display.themeVariant).text,
              ),
              // Басмала: centered-заголовок над текстом суры.
              // Рендерится **только** если первый аят начинается
              // с басмалы. Текст — крупный (1.15× от fontSize), того же
              // Quran-шрифта, золотого цвета (как ornament).
              // Расположение — строго по центру (crossAxisAlignment
              // родительского Column = stretch, поэтому
              // центрируем через Align внутри). Сура начинается
              // с новой строки (визуально отделена SizedBox 20px).
              //
              // Заголовок-басмала показывается **только** для сур,
              // где басмала **не нумеруется** как аят (т.е. для
              // всех сур, **кроме Аль-Фатихи**). В Аль-Фатихе
              // басмала = аят 1, она уже включена в `flowAyahs`
              // как виртуальный 1-й аят с ornament `۝١`, и
              // дублировать её в виде отдельного заголовка
              // нельзя — будет «(1) Бисмиллях…» и в заголовке,
              // и в потоке, и перевод дважды.
              if (basmalaText != null && firstAyahRest != null) ...[
                Align(
                  alignment: Alignment.center,
                  child: _BasmalaHeader(
                    text: basmalaText,
                    fontSize: widget.fontSize * 1.15,
                    fontFamily: widget.display.fontFamily,
                    color: AppColors.gold,
                  ),
                ),
                // Весь перевод суры (включая перевод 1-го аята)
                // идёт **единым блоком под арабским потоком**,
                // отделённым от текста золотой ornament-линией.
                // Это соответствует канону печатной Mushaf: перевод
                // печатается внизу страницы, а не вкраплениями
                // сверху.
                const SizedBox(height: 20),
              ],
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
              // `flowAyahs` уже учитывает отделение басмалы:
              // для Аль-Фатиха — это аяты 2..N, для остальных сур
              // с басмалой — `firstAyahRest` уже отрисован inline
              // перед первым ornament ۝1, а здесь идёт остальной
              // поток (аяты 1..N).
              Text.rich(
                TextSpan(
                  children: spans,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    // 2.4 — дефолт, `display.lineHeight` переопределяет.
                    height: widget.display.lineHeight,
                    letterSpacing: widget.display.letterSpacing,
                    wordSpacing: widget.display.wordSpacing,
                    color: palette.text,
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
              // Ornament-разделитель между арабским блоком и
              // переводами: тонкая золотая линия с малым орнаментом
              // (U+06DD — «end of ayah», визуально играет роль
              // звёздочки) ровно по центру. Соответствует печатной
              // Mushaf, где арабский поток и перевод разделены
              // горизонтальной линией с центральным ornament'ом.
              const SizedBox(height: 24),
              _BookTranslationDivider(
                color: AppColors.gold.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 16),
              // Перевод каждого аята отдельным блоком, в порядке
              // возрастания `ayahNumber`. Стиль — мелкий, серая
              // типографика, имитирующая комментарии внизу страницы
              // печатной Mushaf. Номера аятов — в формате
              // «(N) перевод», чтобы можно было соотнести с
              // арабским оригиналом.
              //
              // Нумерация переводов соответствует нумерации ornament'ов
              // в арабском потоке (см. формирование `flowAyahs` выше):
              // - Аль-Фатиха: перевод 1-го аята (басмалы) идёт **первым**
              //   с номером «۝‎١», затем переводы 2..N.
              // - Остальные суры с басмалой: перевод 1-го аята идёт
              //   первым с номером «۝‎١» (тот же аят, что и ornament
              //   `۝١` на `firstAyahRest`).
              // - Сура 9: перевод 1-го аята идёт первым с номером «۝‎١».
              for (var i = 0; i < flowAyahs.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                if (widget.translations[flowAyahs[i].id] != null &&
                    (widget.display.showTranslation))
                  _BookTranslationBlock(
                    number: flowAyahs[i].ayahNumber,
                    text: widget.translations[flowAyahs[i].id]!,
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

/// Горизонтальный разделитель между арабским потоком и блоком
/// переводов в book-режиме.
///
/// Состоит из:
/// - Тонкой горизонтальной золотой линии (`height: 0.5`),
///   растянутой на всю ширину родителя.
/// - По центру линии — ornament-глиф `۝` (U+06DD, «end of
///   ayah») в золотом цвете, **на** линии (Stack с двумя
///   слоями: линия позади, глиф поверх).
///
/// Соответствует визуальной традиции печатной Mushaf, где
/// арабский текст и перевод разделяются тонкой ornament-линией.
/// Линия не отвлекает от чтения (прозрачность 0.45), но визуально
/// отбивает блоки.
class _BookTranslationDivider extends StatelessWidget {
  const _BookTranslationDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Линия во всю ширину, по вертикальному центру.
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                height: 0.5,
                child: ColoredBox(color: color),
              ),
            ),
          ),
          // Глиф `۝` поверх линии (line посередине глифа).
          // `Padding(top: 2)` — чуть опускаем глиф, чтобы он
          // визуально сидел на линии, а не над ней.
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              '۝',
              style: TextStyle(
                fontSize: 14,
                height: 1.0,
                color: AppColors.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }
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

/// Заголовок-«басмала» — крупная центрированная надпись
/// `بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ`, которая отображается
/// **строго по центру** экрана над текстом суры в book-режиме.
///
/// Соответствует канону печатной Mushaf, где басмала печатается
/// отдельной строкой по центру страницы, и сура начинается с
/// новой строки. Используется в `_buildBookStyle`.
///
/// **Стилизация**: тот же Quran-шрифт, что и арабский поток
/// (`fontFamily`), чуть крупнее основного текста (`fontSize * 1.15`)
/// и золотого цвета (`AppColors.gold`) — визуально связывает
/// басмалу с ornament-глифами `۝N` в потоке (они тоже золотые).
///
/// `lineHeight` 1.4 — компактнее, чем у основного потока
/// (2.0–2.4), чтобы басмала занимала **минимум вертикали** и
/// выглядела именно как заголовок, а не как часть текста.
class _BasmalaHeader extends StatelessWidget {
  const _BasmalaHeader({
    required this.text,
    required this.fontSize,
    required this.fontFamily,
    required this.color,
  });

  /// Текст басмалы (обычно `Bismillah.standardText`).
  final String text;

  /// Базовый размер арабского шрифта (Quran-потока). Басмала
  /// рендерится в 1.15× от этого значения, чтобы визуально
  /// выделяться как заголовок.
  final double fontSize;

  /// Quran-шрифт из настроек пользователя. Без него басмала
  /// рендерилась бы системным Amiri по умолчанию, что
  /// расходилось бы с выбранным шрифтом арабского потока.
  final String? fontFamily;

  /// Цвет текста басмалы. По умолчанию — золотой
  /// (`AppColors.gold`), но параметризован для будущих тем.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.4,
        letterSpacing: 0,
        color: color,
        fontFamily: fontFamily,
        fontWeight: FontWeight.w500,
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
/// Компактный горизонтальный разделитель аятов в построчном
/// режиме чтения: **только тонкая золотая линия** (без ornament'а
/// `۝N`), минимальная высота для максимально плотной вёрстки.
///
/// Раньше здесь был ornament `۝N` (глиф + арабская цифра в центре),
/// но он занимал 24px по высоте (из-за fontSize 22 + Uthmani-descender),
/// что снижало плотность вёрстки. Номер аята уже отображается
/// слева в `_AyahHeader` современной цифрой, поэтому ornament в
/// центре избыточен. Линия выполняет декоративную функцию —
/// визуально отделяет один аят от другого.
///
/// **Высота**: 2 (минимум, чтобы линия была видима как
/// горизонтальная черта). Раньше была 24 — экономия ~22px на
/// каждом аяте; на 7 аятах Аль-Фатихи это ~154px → помещается
/// **ещё один аят** на экран.
///
/// **Цвет**: линия — `AppColors.gold` с opacity 0.4 (прозрачнее,
/// чем раньше 0.55, чтобы не отвлекать от текста; ornament уже
/// не «притягивает» взгляд).
class _AyahSeparator extends StatelessWidget {
  const _AyahSeparator({
    required this.ayahNumber,
    required this.digitColor,
    this.fontFamily,
  });

  /// Номер аята — не используется визуально (раньше рендерился
  /// внутри ornament'а), но оставлен в API для совместимости
  /// с вызывающим кодом. Сохраняем, чтобы будущая фича
  /// (например, маленькая цифра на линии) могла его использовать.
  final int ayahNumber;

  /// Цвет цифры (legacy, больше не используется).
  final Color digitColor;

  /// Шрифт ornament'а (legacy, больше не используется).
  final String? fontFamily;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 2,
      child: CustomPaint(
        painter: _AyahSeparatorPainter(),
        size: const Size(double.infinity, 2),
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
    const glyphC = AppColors.gold;
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
    // Золотой полупрозрачный цвет — декоративная линия, не должна
    // отвлекать от текста, поэтому opacity 0.4 (раньше было 0.55
    // с разрывом — теперь без ornament'а линию можно сделать
    // прозрачнее).
    final linePaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.4)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    // Непрерывная линия от края до края (раньше был разрыв посередине
    // под ornament `۝N` — теперь ornament убран, линия сплошная).
    const lineInset = 16.0; // Отступ от краёв экрана.
    canvas.drawLine(
      Offset(lineInset, cy),
      Offset(size.width - lineInset, cy),
      linePaint,
    );
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

