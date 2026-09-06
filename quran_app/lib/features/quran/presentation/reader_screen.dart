import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/router/safe_pop.dart';

import '../../../app/providers.dart';
import '../../../core/data/quran_repository.dart';
import '../../../core/data/reader_data.dart';
import '../../../core/database/app_database.dart';
import '../../../core/i18n/arabic_digits.dart';
import '../../../core/i18n/bismillah.dart';
import '../../../core/i18n/localized_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/ornaments.dart';
import '../../reader_settings/domain/reader_display_settings.dart';
import '../../reader_settings/presentation/reader_palette.dart';
import 'widgets/reader_widgets.dart';

/// Surah + translations для конкретного открытия. Закэшировано до смены
/// (surahId, activeTranslatorId), поэтому FutureBuilder в build не нужен.
final _readerDataProvider = FutureProvider.autoDispose
    .family<ReaderData, ReaderKey>((ref, key) async {
  // Round 8: invalidation-hook для round 8 — после lazy fetch
  // translations для нового translator'a (`translatorsListRefreshProvider`
  // инкрементируется в main.dart после seed), UI обновится автоматически.
  // Игнорируем возвращаемое значение, нужно только side-effect watch.
  ref.watch(translatorsListRefreshProvider);
  return ref.read(quranRepositoryProvider).loadReaderDataByTranslator(
        surahId: key.surahId,
        translatorId: key.activeTranslatorId,
      );
});

class ReaderKey {
  const ReaderKey({
    required this.surahId,
    required this.translationLang,
    required this.activeTranslatorId,
  });
  final int surahId;
  final String translationLang;
  final int activeTranslatorId;

  @override
  bool operator ==(Object other) =>
      other is ReaderKey &&
      other.surahId == surahId &&
      other.translationLang == translationLang &&
      other.activeTranslatorId == activeTranslatorId;

  @override
  int get hashCode => Object.hash(surahId, translationLang, activeTranslatorId);
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

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with TickerProviderStateMixin {
  // **Round 5 bugfix**: ориентация теперь управляется глобально
  // через [OrientationGuard], привязанный к top-route (см.
  // `lib/app/orientation_guard.dart` и listener в
  // `app_router.dart`). Per-widget `initState`/`dispose` в Reader
  // НЕ вызывал `SystemChrome.setPreferredOrientations` надёжно —
  // `unawaited` в `dispose` ставил Future после `super.dispose()`,
  // который мог race-condition с Android Activity. Listener по
  // top-route более стабилен (см. user feedback 2026-07-22:
  // "после выхода с экрана чтения, поворот экрана срабатывает и
  // на других экранах").
  //
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

  // ── Автоскролл ────────────────────────────────────────────────
  // Ticker даёт ~кадровую частоту (vsync): каждый тик прибавляем к
  // позиции `speed px/s × dt` → плавный ход без рывков
  // animateTo-цепочек. Останавливается сам в конце суры или при
  // ручном скролле пользователя (см. NotificationListener в build).
  bool _autoScrollActive = false;
  Ticker? _autoScrollTicker;
  double _autoScrollLastElapsedMs = 0;

  // ── Keep screen on ────────────────────────────────────────────
  /// Актуальное состояние wake-lock'а, чтобы дёргать платформу
  /// только при реальном изменении `keepScreenOn`.
  bool _wakeLockOn = false;

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

  /// `true`, когда пользователь проскроллил декоративный
  /// [SurahHeader] (orn ament). В этом состоянии в ghost-dock
  /// появляется компактный чип с названием суры и счётчиком аятов —
  /// ориентир для длинных сур, пока header вне зоны видимости.
  bool _pastHeader = false;

  /// Кэш репозитория для использования в [dispose]. `ref` нельзя
  /// читать после unmount (Riverpod 2.x бросает StateError в
  /// `finalizeTree`), поэтому держим ссылку, полученную в [initState].
  late final QuranRepository _quranRepo;

  /// Режим чтения (`lineByLine` / `book`) берётся напрямую из
  /// [readerDisplaySettingsProvider] (поле `readingMode`) — единый
  /// источник истины вместо параллельного legacy-ключа
  /// `appPreferences.readingMode`. Топ-бар и строка в настройках
  /// чтения пишут в один провайдер, рассинхрон исключён.

  @override
  void initState() {
    super.initState();
    // Держим ссылку для [dispose] — там `ref` уже нельзя читать.
    _quranRepo = ref.read(quranRepositoryProvider);
    // Round 5 bugfix: ориентация управляется [OrientationGuard] —
    // не нужно вручную вызывать `SystemChrome.setPreferredOrientations`
    // здесь. Listener в `app_router.dart` отслеживает top-route и
    // автоматически переключает orientation когда top-route —
    // `/reader/:surahId`.
    //
    // Round 9.2B: lazy load аятов с Quran.com при первом mount.
    // Идемпотентно — если аяты уже в БД (cold install через seed),
    // ensureLoaded возвращает no-op. После записи в БД drift watch
    // в build() автоматически обновит UI.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: unawaited_futures
      ref.read(ayahsServiceProvider).ensureLoaded(widget.surahId);
    });
    // Дополнительный listener на `_pageCtrl` для **финальной**
    // проверки scroll position. Это **не throttle'd** — срабатывает
    // на каждом изменении offset'а (включая окончательное «замирание»
    // scroll'а в конце). В нём мы **только** проверяем, близок ли
    // scroll к концу (в пределах 1 viewport'а), и если да — записываем
    // `ayahs.last.id`. Это гарантирует финальную запись даже если
    // scroll-tick'и из `_onScroll` пропустили последний кадр (из-за
    // throttle или быстрого fling'а).
    _pageCtrl.addListener(_checkScrollEnd);
    _pageCtrl.addListener(_updatePastHeader);
    // «Не выключать экран»: применяем настройку после первого
    // кадра (platform channel); дальнейшие смены keepScreenOn
    // отслеживает `ref.listen` в build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyWakeLock(ref.read(readerDisplaySettingsProvider).keepScreenOn);
    });
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
          if (ref.read(readerDisplaySettingsProvider).readingMode == 'lineByLine') {
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
    _pageCtrl.removeListener(_updatePastHeader);
    _autoScrollTicker?.stop();
    _autoScrollTicker?.dispose();
    _autoScrollTicker = null;
    // Освобождаем wake-lock, если Reader его держал — иначе экран
    // останется незаблокированным после выхода из чтения.
    if (_wakeLockOn) {
      _wakeLockOn = false;
      unawaited(WakelockPlus.disable());
    }
    final repo = _quranRepo;
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
    // Round 5 bugfix: ориентация управляется [OrientationGuard] —
    // не нужно вручную вызывать `SystemChrome.setPreferredOrientations`
    // здесь. Listener в `app_router.dart` отслеживает top-route и
    // автоматически переключает orientation.
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

  // ── Автоскролл ────────────────────────────────────────────────

  /// Плавный автоскролл: Ticker даёт кадровую частоту, каждый тик
  /// прибавляет `autoScrollSpeed px/s × dt` через `jumpTo` — без
  /// рывков и без цепочек `animateTo`. Останавливается сам у конца
  /// суры или при ручном жесте пользователя (см.
  /// `NotificationListener` в build).
  void _toggleAutoScroll() {
    HapticFeedback.selectionClick();
    if (_autoScrollActive) {
      _stopAutoScroll();
    } else {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (!_pageCtrl.hasClients) return;
    setState(() {
      _autoScrollActive = true;
      // Панель остаётся видимой — нужна кнопка остановки.
      _controlsVisible = true;
    });
    _autoScrollLastElapsedMs = 0;
    _autoScrollTicker = createTicker(_onAutoScrollTick)..start();
  }

  void _stopAutoScroll() {
    _autoScrollTicker?.stop();
    _autoScrollTicker?.dispose();
    _autoScrollTicker = null;
    if (_autoScrollActive && mounted) {
      setState(() => _autoScrollActive = false);
    } else {
      _autoScrollActive = false;
    }
  }

  void _onAutoScrollTick(Duration elapsed) {
    if (!_pageCtrl.hasClients) {
      _stopAutoScroll();
      return;
    }
    final elapsedMs = elapsed.inMicroseconds / 1000;
    final dtMs = elapsedMs - _autoScrollLastElapsedMs;
    _autoScrollLastElapsedMs = elapsedMs;
    // Скорость читаем на каждый тик: слайдер в настройках меняет
    // её «на лету» без перезапуска.
    final speed = ref.read(readerDisplaySettingsProvider).autoScrollSpeed;
    final pos = _pageCtrl.position;
    final next = pos.pixels + speed * dtMs / 1000;
    if (next >= pos.maxScrollExtent) {
      _pageCtrl.jumpTo(pos.maxScrollExtent);
      _stopAutoScroll();
      return;
    }
    _pageCtrl.jumpTo(next);
  }

  /// «Не выключать экран»: дёргаем платформу только при реальном
  /// изменении флага (состояние кэшируем в [_wakeLockOn]).
  void _applyWakeLock(bool enabled) {
    if (enabled == _wakeLockOn) return;
    _wakeLockOn = enabled;
    unawaited(enabled ? WakelockPlus.enable() : WakelockPlus.disable());
  }

  /// Порог прокрутки, после которого [SurahHeader] считается вышедшим
  /// из зоны видимости. Приближение: высота ornament-рамки в portrait
  /// (~138dp при универсальной ширине 360dp) + её верхний padding (24dp).
  /// Точное измерение через `RenderBox` избыточно для показа/скрытия
  /// чипа-ориентира (см. план).
  static const _kHeaderScrollThreshold = 160.0;

  /// Обновляет [_pastHeader] по текущему scroll offset'у `_pageCtrl`.
  /// Вызывается listener'ом (добавлен в `initState`, снят в `dispose`).
  void _updatePastHeader() {
    if (!_pageCtrl.hasClients) return;
    final past = _pageCtrl.offset >= _kHeaderScrollThreshold;
    if (past != _pastHeader) {
      setState(() => _pastHeader = past);
    }
  }

  /// Содержимое Mushaf-зоны: GestureDetector (toggle панелей) →
  /// Padding → `_AnimatedControlsFrame` → dataAsync.when →
  /// ayahsAsync.when → `_SingleScrollMushaf`.
  ///
  /// Вынесено в helper, чтобы layout-builder мог переиспользовать
  /// один и тот же контент и в portrait (во весь экран), и в
  /// landscape (внутри `Expanded` рядом с `_LandscapeSidebar`).
  ///
  /// В landscape дополнительно **ограничиваем ширину текстовой полосы**
  /// (`textWidthPercent` кэп 80%) — на широком экране 100% даёт
  /// строки по 100+ символов, нечитаемые. Кэп 80% сохраняет
  /// пользовательский выбор, если он поставил <80%.
  Widget _buildMushafBody({
    required BuildContext context,
    required AppLocalizations t,
    required ReaderDisplaySettings display,
    required AsyncValue<ReaderData> dataAsync,
    required AsyncValue<List<Ayah>> ayahsAsync,
    required Set<int> bookmarkedIds,
    required bool isLandscape,
  }) {
    // Landscape cap на `paddingHorizontal` (≤ 16 dp): на широком экране
    // 32 dp внутреннего отступа оставляет на телефоне 736 dp текста
    // (норма), но съедает ~12% ширины. 16 dp совпадает с дефолтом
    // `AyahTile` (`paddingHorizontal ?? 16`) и стилем top-bar margin
    // (`EdgeInsets.fromLTRB(8, 4, 8, 0)`).
    //
    // `textWidthPercent` в landscape **не** cap'им — пользователь
    // управляет шириной полосы явно через слайдер, и принудительный
    // 80% cap лишает его контроля (см. user feedback 2026-08-02:
    // «большие отступы не соответствуют настройке горизонтального
    // отступа»). Cap был введён ранее из-за опасений за длину строк
    // на широких экранах, но `paddingHorizontal` уже ограничивает
    // отступы, а `fontSize * lineHeight` контролируется пользователем.
    final effectiveDisplay = isLandscape && display.paddingHorizontal > 16
        ? display.copyWith(paddingHorizontal: 16.0)
        : display;
    return GestureDetector(
      // `behavior: translucent` — тап доходит **и** к нам, **и** к
      // ребёнку (см. длинный комментарий в исходной build() ниже).
      behavior: HitTestBehavior.translucent,
      onTap: _toggleControls,
      // Только bottom-inset 4 dp для запаса снизу (последний аят
      // не «липнет» к границе viewport). Горизонтальный padding
      // применяется **внутри** `_SingleScrollMushaf` / `AyahTile`
      // — см. [ReaderDisplaySettings.paddingHorizontal].
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4),
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
              return Padding(
                // Только vertical: верхний отступ под ornament-header
                // / басмалу и нижний перед `_SingleScrollMushaf`.
                // Горизонтальный padding применяется внутри
                // `_SingleScrollMushaf` / `AyahTile` —
                // см. [ReaderDisplaySettings.paddingHorizontal].
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ayahsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
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
                        // `lineByLine` часть `Key` — при смене режима
                        // Flutter размонтирует старый `_SingleScrollMushaf`
                        // (см. длинный комментарий в исходной build()).
                        // `fontFamily` — форсирует пересоздание State при
                        // смене шрифта. `effectiveDisplay` гарантирует,
                        // что при смене ориентации (textWidthPercent
                        // кэп) AyahTile получает обновлённый display.
                        'mushaf-${display.readingMode}-${ayahs.length}-'
                        '${effectiveDisplay.fontFamily}-'
                        '${effectiveDisplay.textWidthPercent.toInt()}',
                      ),
                      mushafKey: _mushafKey,
                      ayahs: ayahs,
                      translations:
                          dataAsync.value?.translations ?? const {},
                      fontSize: effectiveDisplay.fontSize,
                      display: effectiveDisplay,
                      bookmarkedIds: bookmarkedIds,
                      scrollCtrl: _pageCtrl,
                      lineByLine: display.readingMode == 'lineByLine',
                      surahNumber: dataAsync.value?.surah?.id ?? 0,
                      onInitialLoad: (loaded) {
                        _lastAyahs = loaded;
                        _ayahsCount = loaded.length;
                        if (widget.initialAyah > 1) {
                          final idx = loaded.indexWhere(
                            (a) => a.ayahNumber == widget.initialAyah,
                          );
                          if (idx >= 0) {
          if (ref.read(readerDisplaySettingsProvider).readingMode == 'lineByLine') {
                              WidgetsBinding.instance.addPostFrameCallback((
                                _,
                              ) {
                                if (!mounted) return;
                                final state = _mushafKey.currentState;
                                if (state is _SingleScrollMushafState) {
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
                        _lastReportedAyahNumber = a.ayahNumber;
                        final repo = ref.read(quranRepositoryProvider);
                        if (_ayahsCount != null &&
                            _ayahsCount! - a.ayahNumber <= 50 &&
                            a.ayahNumber != _ayahsCount) {
                          if (_lastAyahs != null &&
                              _lastAyahs!.isNotEmpty) {
                            final lastAyah = _lastAyahs!.last;
                            if (lastAyah.ayahNumber == _ayahsCount) {
                              unawaited(
                                repo.recordLastRead(
                                  surahId: a.surahId,
                                  ayahId: lastAyah.id,
                                ),
                              );
                              _lastReportedAyahNumber =
                                  lastAyah.ayahNumber;
                            } else {
                              unawaited(
                                repo.recordLastRead(
                                  surahId: a.surahId,
                                  ayahId: a.id,
                                ),
                              );
                            }
                          } else {
                            unawaited(
                              repo.recordLastRead(
                                surahId: a.surahId,
                                ayahId: a.id,
                              ),
                            );
                          }
                        } else {
                          unawaited(
                            repo.recordLastRead(
                              surahId: a.surahId,
                              ayahId: a.id,
                            ),
                          );
                        }
                        unawaited(repo.recordAyahRead(surahId: a.surahId));
                      },
                      onFinalAyah: (int ayahId) {
                        final repo = ref.read(quranRepositoryProvider);
                        unawaited(
                          repo.recordLastRead(
                            surahId: widget.surahId,
                            ayahId: ayahId,
                          ),
                        );
                      },
                      onToggleBookmark: (Ayah a, bool isBookmarked) =>
                          toggleBookmark(
                        ref,
                        ayah: a,
                        isCurrentlyBookmarked: isBookmarked,
                      ),
                      onScrollDelta: (delta) {
                        // Скролл вниз (delta > 0) — панель
                        // сворачивается. Скролл вверх НЕ
                        // возвращает панель (см. подробный
                        // комментарий в исходной build()).
                        // Во время автоскролла `jumpTo` тоже даёт
                        // дельту — панелям сворачиваться нельзя
                        // (там кнопка остановки).
                        if (delta > 4 && !_autoScrollActive) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final prefs = ref.watch(appPreferencesProvider);
    final display = ref.watch(readerDisplaySettingsProvider);
    final readerKey = ReaderKey(
      surahId: widget.surahId,
      translationLang: prefs.translationLang,
      activeTranslatorId: prefs.activeTranslatorId,
    );
    final dataAsync = ref.watch(_readerDataProvider(readerKey));
    final ayahsAsync = ref.watch(_ayahsStreamProvider(widget.surahId));
    final bookmarkedIds =
        ref.watch(bookmarkedAyahIdsProvider).value ?? const <int>{};
    // «Не выключать экран»: реакция на смену настройки без rebuild'а
    // всего экрана — только платформенный вызов.
    ref.listen(readerDisplaySettingsProvider, (prev, next) {
      if (prev?.keepScreenOn != next.keepScreenOn) {
        _applyWakeLock(next.keepScreenOn);
      }
    });

    return Scaffold(
      // `themeVariant` влияет на фон зоны чтения, не на глобальную
      // тему (навигация остаётся тёмной). Через `ReaderPalette.of`.
      backgroundColor: ReaderPalette.of(display.themeVariant).background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Активируем landscape-раскладку при `width ≥ 600` И
          // `width > height`. Порог 600dp отсекает портретные
          // телефоны (даже если физически `800x400` — это всё ещё
          // portrait-ориентация из-за большей высоты), но покрывает
          // любой landscape phone, foldable в разложенном виде, и
          // планшеты в обеих ориентациях. Без этого sidebar съел бы
          // половину Mushaf на узких landscape-телефонах (<600dp).
          final isLandscape = constraints.maxWidth >= 600 &&
              constraints.maxWidth > constraints.maxHeight;
          return Stack(
            children: [
              // Задний план: Mushaf + (в landscape) sidebar слева.
              //
              // `SafeArea(top: false, bottom: false)` — убраны
              // left/right safe-area (Android system insets для
              // notch/cutout). Это позволяет тексту при
              // `paddingHorizontal: 0` быть в самом краю экрана.
              // top/bottom safe-area остаются на top/bottom bar'ах
              // (см. ниже), чтобы статус-бар и навигация не
              // перекрывались.
              Positioned.fill(
                child: NotificationListener<ScrollStartNotification>(
                  // Ручной жест (drag/fling) имеет приоритет над
                  // автоскроллом: пользователь перехватил управление —
                  // останавливаем авто-движение. Программный `jumpTo`
                  // приходит без dragDetails и автоскролл не трогает.
                  onNotification: (n) {
                    if (n.dragDetails != null && _autoScrollActive) {
                      _stopAutoScroll();
                    }
                    return false;
                  },
                  child: SafeArea(
                  // Включаем горизонтальные safe areas (`left: true`,
                  // `right: true`) — иначе в landscape Android navigation
                  // bar переезжает на боковую сторону и перекрывает
                  // текст Mushaf. `top/bottom: false` — вертикальные
                  // отступы (status-bar, gesture-bar) обрабатываются
                  // самим top/bottom-bar этого Reader-экрана.
                  top: false,
                  bottom: false,
                  child: Builder(
                    builder: (innerCtx) {
                      if (isLandscape) {
                        // Landscape: Row[sidebar, divider, Mushaf].
                        // Sidebar содержит prev/next суру,
                        // scroll-to-top/bottom и кнопку "открыть
                        // список сур". Divider — тонкая золотая
                        // линия в стиле Mushaf-рамки.
                        //
                        // Bug 2 round 3: `_LandscapeSidebar` БОЛЬШЕ
                        // не рендерится в landscape. Пользовательский
                        // feedback (2026-07-18): «sidebar перекрывает
                        // текст, должен быть скрыт в landscape». В
                        // landscape `_buildMushafBody(...)`
                        // рендерится на всю ширину экрана. Prev/Next
                        // сура и scroll-to-top/bottom доступны через:
                        //   - back в `_AnimatedTopBar` (открывает
                        //     SurahList, где выбираем другую суру);
                        //   - нативные жесты прокрутки;
                        //   - или открыть обычный portrait-режим и
                        //     воспользоваться sidebar.
                        // Round 2 сделал sidebar постоянным
                        // дополнением — round 3 убрал.
                        return _buildMushafBody(
                          context: context,
                          t: t,
                          display: display,
                          dataAsync: dataAsync,
                          ayahsAsync: ayahsAsync,
                          bookmarkedIds: bookmarkedIds,
                          isLandscape: true,
                        );
                      }
                      return _buildMushafBody(
                        context: context,
                        t: t,
                        display: display,
                        dataAsync: dataAsync,
                        ayahsAsync: ayahsAsync,
                        bookmarkedIds: bookmarkedIds,
                        isLandscape: false,
                      );
},
                  ),
                ),
                ),
              ),
          // Передний план: ghost-dock (бывш. верхняя панель) +
          // mini-player. Оба расположены ВНИЗУ над системными
          // кнопками навигации — `SafeArea` отдаёт bottom-inset
          // (кнопки / gesture-area). Ghost-dock сидит над
          // mini-player (в Column), поэтому они не перекрываются.
          // Анимированы синхронно через общий `_controlsVisible`.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AnimatedTopBar(
                    visible: _controlsVisible,
                    showTitle: _pastHeader,
                    surahNameLatin: dataAsync.value?.surah == null
                        ? '…'
                        : t.surahName(
                            dataAsync.value!.surah!.id,
                            fallback:
                                dataAsync.value!.surah!.nameTransliteration,
                          ),
                    ayahsCountLabel: dataAsync.value?.surah == null
                        ? ''
                        : t.ayahsCount(dataAsync.value!.surah!.ayahCount),
                    readingMode: display.readingMode,
                    readingModeTooltip: t.readingModeTooltip,
                    palette: ReaderPalette.of(display.themeVariant),
                    showTranslation: display.showTranslation,
                    translationTooltip: t.readerTranslationToggle,
                    onToggleTranslation: () {
                      HapticFeedback.selectionClick();
                      ref.read(displaySettingsProvider.notifier).set(
                        display.copyWith(
                          showTranslation: !display.showTranslation,
                        ),
                      );
                    },
                    autoScrollActive: _autoScrollActive,
                    autoScrollTooltip: t.readerAutoScroll,
                    onToggleAutoScroll: _toggleAutoScroll,
                    onThemeToggle: (anchor) {
                      // anchor — BuildContext самой кнопки палитры
                      // (из `_PillCluster`), а не экрана: popup
                      // якорится на кнопку, а не на весь Reader.
                      _showThemeSwitcher(anchor, display);
                    },
                    onBack: () => safePop(context),
                    onToggleReadingMode: () {
                      final next = display.readingMode == 'lineByLine'
                          ? 'book'
                          : 'lineByLine';
                      ref.read(displaySettingsProvider.notifier).set(
                        display.copyWith(readingMode: next),
                      );
                    },
                    onSettings: () {
                      context.push('/reader-settings/display');
                    },
                  ),
                  _AnimatedBottomBar(
                    visible: _controlsVisible,
                    palette: ReaderPalette.of(display.themeVariant),
                  ),
                ],
              ),
            ),
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
          );
        },
      ),
    );
  }

  void _showThemeSwitcher(BuildContext context, ReaderDisplaySettings display) {
    final t = AppLocalizations.of(context);
    final button = context.findRenderObject() as RenderBox?;
    if (button == null) return;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        button.localToGlobal(Offset.zero).dx,
        button.localToGlobal(Offset.zero).dy + button.size.height + 8,
        button.localToGlobal(Offset.zero).dx + button.size.width,
        button.localToGlobal(Offset.zero).dy,
      ),
      items: ReaderDisplaySettings.themeVariants.map((v) {
        final p = ReaderPalette.of(v);
        return PopupMenuItem<String>(
          value: v,
          child: Row(
            children: [
              ThemeVariantSwatch(palette: p, size: 28),
              const SizedBox(width: 12),
              Text(
                p.label(t),
                style: TextStyle(
                  color: ReaderPalette.of(display.themeVariant).text,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null && value != display.themeVariant) {
        ref.read(displaySettingsProvider.notifier).set(
          display.copyWith(themeVariant: value),
        );
      }
    });
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
      // RepaintBoundary: контент (сотни аятов) не должен
      // перерисовываться из-за 0.5%-scale-анимации рамки.
      child: RepaintBoundary(child: child),
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
    required this.showTitle,
    required this.surahNameLatin,
    required this.ayahsCountLabel,
    required this.readingMode,
    required this.readingModeTooltip,
    required this.palette,
    required this.showTranslation,
    required this.translationTooltip,
    required this.onToggleTranslation,
    required this.autoScrollActive,
    required this.autoScrollTooltip,
    required this.onToggleAutoScroll,
    required this.onThemeToggle,
    required this.onBack,
    required this.onToggleReadingMode,
    required this.onSettings,
  });

  final bool visible;
  final bool showTitle;
  final String surahNameLatin;
  final String ayahsCountLabel;
  final String readingMode;
  final String readingModeTooltip;
  final ReaderPalette palette;

  /// Переключатель перевода под текстом аятов.
  final bool showTranslation;
  final String translationTooltip;
  final VoidCallback onToggleTranslation;

  /// Автоскролл текста (плавное авто-движение вниз).
  final bool autoScrollActive;
  final String autoScrollTooltip;
  final VoidCallback onToggleAutoScroll;

  final void Function(BuildContext anchor)? onThemeToggle;
  final VoidCallback onBack;
  final VoidCallback onToggleReadingMode;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final isLineByLine = readingMode == 'lineByLine';
    // RepaintBoundary: slide/opacity-анимация панели не должна
    // перерисовывать слой контента, и наоборот.
    return RepaintBoundary(
      child: AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !visible,
          child: SizedBox(
            // Компактный ghost-dock: всего ~50dp (vs. ~100dp у
            // старой полноширинной карточки с названием). Расположен
            // внизу, над системной навигацией и над mini-player.
            height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Кнопка «назад» (слева) ────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _GhostCircle(
                        icon: Icons.arrow_back_ios_new,
                        iconSize: 18,
                        palette: palette,
                        onTap: onBack,
                      ),
                    ),
                  ),
                  // ── Чип-ориентир (по центру, при проскролле) ─
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(scale: anim, child: child),
                      ),
                      child: showTitle
                          ? _TitleChip(
                              key: const ValueKey('title'),
                              label: '$surahNameLatin • $ayahsCountLabel',
                              palette: palette,
                            )
                          : const SizedBox(key: ValueKey('empty')),
                    ),
                  ),
                  // ── Pill-кластер действий (справа) ─────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _PillCluster(
                        isLineByLine: isLineByLine,
                        modeTooltip: readingModeTooltip,
                        palette: palette,
                        showTranslation: showTranslation,
                        translationTooltip: translationTooltip,
                        onToggleTranslation: onToggleTranslation,
                        autoScrollActive: autoScrollActive,
                        autoScrollTooltip: autoScrollTooltip,
                        onToggleAutoScroll: onToggleAutoScroll,
                        onToggleReadingMode: onToggleReadingMode,
                        onThemeToggle: onThemeToggle,
                        onSettings: onSettings,
                      ),
                    ),
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

/// Полупрозрачная «подложка» + золотой hairline.
///
/// Раньше здесь был `BackdropFilter(blur 10)`: три живых фильтра над
/// прокручиваемым мушафом давали saveLayer+blur каждый кадр скролла
/// (непрерывно при автоскролле). Заменено на плотную заливку —
/// визуально читаемо на любом фоне, GPU-нейтрально.
Widget _glass({
  required ReaderPalette palette,
  required double radius,
  required Widget child,
}) {
  return Container(
    decoration: BoxDecoration(
      color: palette.surface.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: palette.gold.withValues(alpha: 0.22),
        width: 0.8,
      ),
    ),
    child: child,
  );
}

/// Круглая glass-кнопка (назад / одиночное действие).
class _GhostCircle extends StatelessWidget {
  const _GhostCircle({
    required this.icon,
    required this.iconSize,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final double iconSize;
  final ReaderPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _glass(
      palette: palette,
      radius: 20,
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          padding: EdgeInsets.zero,
          iconSize: iconSize,
          icon: Icon(icon, color: palette.gold),
          onPressed: onTap,
        ),
      ),
    );
  }
}

/// Компактный чип с названием суры и счётчиком аятов (показывается,
/// когда декоративный header проскроллен из зоны видимости).
class _TitleChip extends StatelessWidget {
  const _TitleChip({
    required this.label,
    required this.palette,
    super.key,
  });

  final String label;
  final ReaderPalette palette;

  @override
  Widget build(BuildContext context) {
    return _glass(
      palette: palette,
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.text.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

/// Единая кнопка ghost-дока: глиф 22 пп + слот точки-индикатора
/// (все кнопки одинаковой высоты, точка появляется у активных
/// тумблеров) + Tooltip + Semantics.
///
/// Состояния:
///  - [active] — золотая точка под иконкой («функция включена»);
///  - [dimmed] — приглушённый глиф (выключенный тумблер);
///  - [slash]  — диагональная черта поверх глифа (паттерн *_off);
///  - [toggled] — передаётся в `Semantics(toggled:)`: скринридер
///    объявляет состояние тумблера («включено/выключено»).
///
/// [builder] переопределяет тап-зону (тема: popup якорится на
/// контекст самой кнопки).
class _DockIcon extends StatelessWidget {
  const _DockIcon({
    required this.icon,
    required this.palette,
    this.onTap,
    this.tooltip,
    this.active = false,
    this.dimmed = false,
    this.slash = false,
    this.toggled,
    this.builder,
  });

  final IconData icon;
  final ReaderPalette palette;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool active;
  final bool dimmed;
  final bool slash;
  final bool? toggled;
  final Widget Function(BuildContext ctx, Widget child)? builder;

  @override
  Widget build(BuildContext context) {
    final color =
        dimmed ? palette.gold.withValues(alpha: 0.55) : palette.gold;
    final Widget glyph = slash
        ? _SlashedGlyph(icon: icon, color: color)
        : Icon(icon, color: color, size: 22);

    // Слот точки существует всегда — иконка не «прыгает» при
    // переключении состояния.
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 24, height: 24, child: Center(child: glyph)),
        const SizedBox(height: 2),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? palette.gold : Colors.transparent,
          ),
        ),
      ],
    );

    final Widget control;
    if (builder != null) {
      // Builder даёт тап-зоне собственный BuildContext (якорь popup).
      control = Builder(
        builder: (btnCtx) => Padding(
          padding: const EdgeInsets.all(8),
          child: builder!(btnCtx, child),
        ),
      );
    } else {
      control = IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        icon: child,
        onPressed: onTap,
      );
    }

    return Semantics(
      button: true,
      toggled: toggled,
      label: tooltip,
      child: tooltip == null || tooltip!.isEmpty
          ? control
          : Tooltip(message: tooltip!, child: control),
    );
  }
}

/// Глиф с диагональной чертой — универсальный маркер «выключено»
/// (паттерн Material *_off: wifi_off, mic_off). Используется для
/// перевода, у которого нет встроенного *_off-варианта.
class _SlashedGlyph extends StatelessWidget {
  const _SlashedGlyph({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        Transform.rotate(
          // Черта сверху-слева направо-вниз, как в *_off-иконках.
          angle: 0.7853981633974483, // pi/4
          child: Container(
            width: 24,
            height: 1.8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ],
    );
  }
}

/// Стадиум-кластер иконок справа: режим чтения, тема, автоскролл,
/// перевод, настройки — разделённые тонкими hairline-линиями.
class _PillCluster extends StatelessWidget {
  const _PillCluster({
    required this.isLineByLine,
    required this.modeTooltip,
    required this.palette,
    required this.showTranslation,
    required this.translationTooltip,
    required this.onToggleTranslation,
    required this.autoScrollActive,
    required this.autoScrollTooltip,
    required this.onToggleAutoScroll,
    required this.onToggleReadingMode,
    required this.onThemeToggle,
    required this.onSettings,
  });

  final bool isLineByLine;
  final String modeTooltip;
  final ReaderPalette palette;
  final bool showTranslation;
  final String translationTooltip;
  final VoidCallback onToggleTranslation;
  final bool autoScrollActive;
  final String autoScrollTooltip;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onToggleReadingMode;
  final void Function(BuildContext anchor)? onThemeToggle;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    // Единая система иконок дока:
    //  - залитые глифы одного оптического веса (22 пп);
    //  - состояние вкл/выкл — сменой СИЛУЭТА (а не только цвета):
    //    автоскролл «двойная стрелка → пауза в круге», перевод
    //    «глиф 文A → тот же глиф с диагональной чертой»;
    //  - золотая точка-индикатор под активной кнопкой: одним
    //    взглядом видно, какие функции включены;
    //  - `Semantics(toggled:)` сообщает скринридеру состояние.
    return _glass(
      palette: palette,
      radius: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Режим чтения: стопка отдельных строк (построчно) ↔
          // открытая книга (сплошной текст).
          _DockIcon(
            icon: isLineByLine ? Icons.view_stream : Icons.menu_book,
            tooltip: modeTooltip,
            palette: palette,
            onTap: onToggleReadingMode,
          ),
          _hairline(palette),
          if (onThemeToggle != null) ...[
            _DockIcon(
              icon: Icons.palette_outlined,
              palette: palette,
              // Тема открывает popup — якорится на саму кнопку,
              // поэтому тап-зона строится через `builder` (контекст
              // передаётся в `onThemeToggle`).
              builder: (btnCtx, child) => InkWell(
                onTap: () => onThemeToggle!(btnCtx),
                customBorder: const CircleBorder(),
                child: child,
              ),
            ),
            _hairline(palette),
          ],
          // Автоскролл: двойная стрелка вниз = «непрерывное движение»,
          // активное состояние — пауза в круге («идёт, тап остановит»).
          // Круг отличает её от паузы аудиоплеера.
          _DockIcon(
            icon: autoScrollActive
                ? Icons.pause_circle_outline
                : Icons.keyboard_double_arrow_down,
            tooltip: autoScrollTooltip,
            palette: palette,
            active: autoScrollActive,
            toggled: autoScrollActive,
            onTap: onToggleAutoScroll,
          ),
          _hairline(palette),
          // Перевод: универсальный глиф перевода «文A»; выключенное
          // состояние — тот же глиф с диагональной чертой (паттерн
          // Material *_off: wifi_off, mic_off).
          _DockIcon(
            icon: Icons.translate,
            slash: !showTranslation,
            dimmed: !showTranslation,
            tooltip: translationTooltip,
            palette: palette,
            active: showTranslation,
            toggled: showTranslation,
            onTap: onToggleTranslation,
          ),
          _hairline(palette),
          _DockIcon(
            icon: Icons.tune,
            palette: palette,
            onTap: onSettings,
          ),
        ],
      ),
    );
  }

  static Widget _hairline(ReaderPalette palette) => Container(
        width: 1,
        height: 22,
        color: palette.gold.withValues(alpha: 0.18),
      );
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
  const _AnimatedBottomBar({required this.visible, required this.palette});
  final bool visible;
  final ReaderPalette palette;

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
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              palette.surface,
                              palette.background,
                            ],
                          ),
                          border: Border.all(
                            color: hasError
                                ? AppColors.error
                                : palette.gold.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (hasError ? AppColors.error : palette.gold)
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
                                  : palette.gold,
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
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: palette.text,
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
                                          : palette.text.withValues(alpha: 0.6),
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
                                    : palette.gold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => ref
                                  .read(quranAudioHandlerProvider)
                                  .stop(),
                              icon: Icon(
                                Icons.close,
                                color: palette.text.withValues(alpha: 0.6),
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
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
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
      padding: const EdgeInsets.symmetric(horizontal: 0),
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

/// (round 3) `_LandscapeSidebar` удалён — user feedback «sidebar
/// перекрывает текст в landscape». Его функционал (prev/next сура,
/// scroll-to-top/bottom, open-surah-list) дублирован в
/// `_AnimatedTopBar` (back) и жестами прокрутки. Если понадобится
/// вернуть — лучше как overlay с toggle-кнопкой (FAB), не как
/// постоянное дополнение.

