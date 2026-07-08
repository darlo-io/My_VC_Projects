import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/router/safe_pop.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/daos/surah_dao.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/audio_player_controller.dart';
import '../data/reciters_repository.dart';

// === Theme constants for the redesigned listen screen ===
// Тёмная изумрудная палитра в духе референса `docs/images/listen.png`.
// Применяется только к этому экрану через Theme widget.
const _kEmerald = Color(0xFF0B3D2E); // base поверхность
const _kEmeraldDeep = Color(0xFF062A1F); // фон
const _kGold = Color(0xFFD4A951); // акцент (как на референсе)
const _kGoldSoft = Color(0xFFE0BC6C);
const _kGoldDeep = Color(0xFFB8902A);
const _kTextOnDark = Color(0xFFEFE6D0);
const _kTextOnDarkSoft = Color(0xFFB6A989);

ThemeData _buildListenTheme(BuildContext context) {
  final base = Theme.of(context);
  final darkBase = base.brightness == Brightness.dark
      ? base
      : ThemeData.dark().copyWith(
          scaffoldBackgroundColor: _kEmeraldDeep,
          canvasColor: _kEmeraldDeep,
        );
  return darkBase.copyWith(
    scaffoldBackgroundColor: _kEmeraldDeep,
    canvasColor: _kEmeraldDeep,
    colorScheme: const ColorScheme.dark(
      primary: _kGold,
      onPrimary: _kEmeraldDeep,
      secondary: _kGoldSoft,
      onSecondary: _kEmeraldDeep,
      surface: _kEmerald,
      onSurface: _kTextOnDark,
      surfaceContainerHighest: _kEmerald,
      error: Color(0xFFE57373),
    ),
    textTheme: base.textTheme.copyWith(
      bodyLarge: base.textTheme.bodyLarge?.copyWith(color: _kTextOnDark),
      bodyMedium:
          base.textTheme.bodyMedium?.copyWith(color: _kTextOnDarkSoft),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: _kTextOnDark,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class ListenScreen extends ConsumerStatefulWidget {
  const ListenScreen({super.key});

  @override
  ConsumerState<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends ConsumerState<ListenScreen> {
  String? _reciterId;
  int? _surahId;
  int? _ayahId;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final localeCode = locale.languageCode;
    final recitersAsync = ref.watch(recitersStreamProvider);
    final playerState = ref.watch(audioPlayerControllerProvider);
    final surahDao = ref.watch(surahDaoProvider);

    // Авто-выбор: при первой загрузке списка — первый ректор с
    // mp3quran-метаданными (у остальных нет аудио). Пользовательская
    // настройка reciterId в AppPreferences перекрывает дефолт.
    ref.listen<AsyncValue<List<Reciter>>>(recitersStreamProvider, (prev, next) {
      next.whenData((list) {
        if (_reciterId == null && list.isNotEmpty) {
          final saved = ref.read(appPreferencesProvider).reciterId;
          final candidate = list.firstWhere(
            (r) => r.id == saved,
            orElse: () => list.first,
          );
          _reciterId = candidate.id;
          // Сурah по умолчанию — первая в БД.
          _surahId ??= 1;
          _ayahId ??= 1;
        }
      });
    });

    ref.listen<AudioPlayerState>(audioPlayerControllerProvider, (prev, next) {
      if (next.reciter != null && prev?.reciter?.id != next.reciter!.id) {
        ref.read(appPreferencesProvider.notifier).setReciterId(next.reciter!.id);
      }
      if (next.error != null && prev?.error != next.error) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final messenger = ScaffoldMessenger.maybeOf(context);
          messenger?.showSnackBar(
            SnackBar(
              content: Text(t.playerError),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        });
      }
    });

    return Theme(
      data: _buildListenTheme(context),
      child: Scaffold(
        backgroundColor: _kEmerald,
        // Декоративный фоновый паттерн (мечеть + звёзды) — рендерится
        // простым CustomPainter, чтобы не зависеть от assets.
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _IslamicPatternPainter()),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _ListenTopBar(
                    title: t.navListen,
                    onBack: () => safePop(context),
                    onSettings: () => safePush(context, '/profile'),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: recitersAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: _kGold),
                      ),
                      error: (e, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            '$e',
                            style: const TextStyle(color: _kTextOnDark),
                          ),
                        ),
                      ),
                      data: (reciters) {
                        if (reciters.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.cloud_off_outlined,
                                      size: 48, color: _kTextOnDarkSoft),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Список чтецов пуст.\nНажмите «Обновить».',
                                    style: TextStyle(
                                      color: _kTextOnDark,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(recitersRepositoryProvider)
                                            .syncFromApi();
                                      } catch (e) {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('$e')),
                                        );
                                        return;
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kGold,
                                      foregroundColor: _kEmeraldDeep,
                                    ),
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Обновить список'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return _ListenBody(
                          reciters: reciters,
                          localeCode: localeCode,
                          playerState: playerState,
                          selectedReciterId: _reciterId,
                          selectedSurahId: _surahId,
                          selectedAyahId: _ayahId,
                          onReciterChanged: (id) =>
                              setState(() => _reciterId = id),
                          onSurahChanged: (id) =>
                              setState(() => _surahId = id),
                          onAyahChanged: (id) =>
                              setState(() => _ayahId = id),
                          onPlay: () {
                            final r = _reciterId ?? reciters.first.id;
                            final s = _surahId ?? 1;
                            ref
                                .read(audioPlayerControllerProvider.notifier)
                                .playSurah(
                                  reciterId: r,
                                  surahId: s,
                                  startAyah: _ayahId,
                                );
                          },
                          onTogglePause: () => ref
                              .read(audioPlayerControllerProvider.notifier)
                              .togglePlay(),
                          onSpeed: (s) => ref
                              .read(audioPlayerControllerProvider.notifier)
                              .setSpeed(s),
                          onSleepTimer: (m) => ref
                              .read(audioPlayerControllerProvider.notifier)
                              .setSleepTimer(m),
                          surahDao: surahDao,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === Top bar ===
class _ListenTopBar extends StatelessWidget {
  const _ListenTopBar({
    required this.title,
    required this.onBack,
    required this.onSettings,
  });
  final String title;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left, color: _kTextOnDark, size: 28),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _kTextOnDark,
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
          ),
          IconButton(
            onPressed: onSettings,
            icon: const Icon(Icons.bookmark_outline,
                color: _kTextOnDark, size: 26),
          ),
        ],
      ),
    );
  }
}

// === Body — single reciter card + surah/ayah selectors + player ===
class _ListenBody extends StatelessWidget {
  const _ListenBody({
    required this.reciters,
    required this.localeCode,
    required this.playerState,
    required this.selectedReciterId,
    required this.selectedSurahId,
    required this.selectedAyahId,
    required this.onReciterChanged,
    required this.onSurahChanged,
    required this.onAyahChanged,
    required this.onPlay,
    required this.onTogglePause,
    required this.surahDao,
    required this.onSpeed,
    required this.onSleepTimer,
  });

  final List<Reciter> reciters;
  final String localeCode;
  final AudioPlayerState playerState;
  final String? selectedReciterId;
  final int? selectedSurahId;
  final int? selectedAyahId;
  final ValueChanged<String> onReciterChanged;
  final ValueChanged<int> onSurahChanged;
  final ValueChanged<int> onAyahChanged;
  final VoidCallback onPlay;
  final VoidCallback onTogglePause;
  final SurahDao surahDao;
  final ValueChanged<double> onSpeed;
  final ValueChanged<int?> onSleepTimer;

  Reciter get _currentReciter {
    final id = selectedReciterId;
    if (id != null) {
      return reciters.firstWhere(
        (r) => r.id == id,
        orElse: () => reciters.first,
      );
    }
    return reciters.first;
  }

  @override
  Widget build(BuildContext context) {
    final reciter = _currentReciter;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _ReciterCard(
          reciter: reciter,
          localeCode: localeCode,
          onTap: () => _showReciterDropdown(context),
        ),
        const SizedBox(height: 16),
        _SurahAyahSelectors(
          surahId: selectedSurahId,
          ayahId: selectedAyahId,
          playerState: playerState,
          onSurahChanged: onSurahChanged,
          onAyahChanged: onAyahChanged,
          surahDao: surahDao,
          localeCode: localeCode,
        ),
        const SizedBox(height: 16),
        _AyahPanel(
          playerState: playerState,
        ),
        const SizedBox(height: 16),
        _Player(
          state: playerState,
          onPlay: onPlay,
          onTogglePause: onTogglePause,
        ),
        const SizedBox(height: 16),
        _PlaybackControls(
          state: playerState,
          onSpeed: onSpeed,
          onSleepTimer: onSleepTimer,
        ),
      ],
    );
  }

  void _showReciterDropdown(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kEmeraldDeep,
      builder: (sheetCtx) => _ReciterDropdownSheet(
        localeCode: localeCode,
        selectedId: selectedReciterId,
        onSelect: (r) {
          onReciterChanged(r.id);
          Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }
}

// === Single reciter card (тап → выезжающий список) ===
class _ReciterCard extends StatelessWidget {
  const _ReciterCard({
    required this.reciter,
    required this.localeCode,
    required this.onTap,
  });

  final Reciter reciter;
  final String localeCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = displayNameForLocale(reciter, localeCode);
    final subtitle = subtitleForReciter(reciter, localeCode);
    final rewaya = reciter.mp3quranRewaya ?? '';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kEmerald,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kGold.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            // «Фото»: пока — градиентный круг с первой буквой имени.
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_kGold, _kGoldDeep],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                display.isNotEmpty ? display[0] : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: _kEmeraldDeep,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    display,
                    style: const TextStyle(
                      color: _kTextOnDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _kTextOnDarkSoft,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (rewaya.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      rewaya,
                      style: const TextStyle(
                        color: _kGold,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.expand_more, color: _kTextOnDarkSoft),
          ],
        ),
      ),
    );
  }
}

// === Surah / Ayah row (два дропдауна в одну строку) ===
class _SurahAyahSelectors extends ConsumerWidget {
  const _SurahAyahSelectors({
    required this.surahId,
    required this.ayahId,
    required this.playerState,
    required this.onSurahChanged,
    required this.onAyahChanged,
    required this.surahDao,
    required this.localeCode,
  });

  final int? surahId;
  final int? ayahId;
  final AudioPlayerState playerState;
  final ValueChanged<int> onSurahChanged;
  final ValueChanged<int> onAyahChanged;
  final SurahDao surahDao;
  final String localeCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Раньше брали `playerState.surah?.ayahCount` — это значение
    // из последнего `playSurah()`. После выбора новой суры, но до
    // play, `state.surah` остаётся старой → пользователь видит
    // «Аят 1 из 7» даже для Al-Baqara (286). Теперь смотрим на
    // `surahId` напрямую через БД — это значение, которое юзер
    // только что выбрал в Surah picker.
    //
    // Используем `.value` вместо `maybeWhen` — он возвращает данные
    // когда есть, и `null` пока Future ещё в loading/error. До
    // завершения первого `getById`-запроса показываем «…» вместо
    // «Выбрать», чтобы UI не путал «не выбрано» с «loading».
    final selectedSurahAsync = surahId != null
        ? ref.watch(surahByIdProvider(SurahIdKey(surahId!)))
        : null;
    final selectedSurah = selectedSurahAsync?.value;
    final isLoading = selectedSurahAsync is AsyncLoading;
    final totalAyahs = selectedSurah?.ayahCount ?? 0;

    // Для primary-value чипа «Сура» показываем локализованное имя,
    // а не голый номер: «Аль-Бакара» вместо «2». Номер и
    // подзаголовок («Корова») идут в subtitle — дают контекст, не
    // перетягивая внимание с имени.
    //
    // Если БД ещё не ответила — НЕ показываем «Выбрать» (это путает
    // с «сура не выбрана»), а показываем loading-плейсхолдер.
    final String? surahName;
    final String surahSubtitle;
    if (selectedSurah != null) {
      surahName = displayNameForSurah(selectedSurah, localeCode);
      surahSubtitle =
          '№$surahId · ${subtitleForSurah(selectedSurah, localeCode)}'.trim();
    } else if (surahId != null && isLoading) {
      // Первый build пока Future.getById ещё в полёте. Лучше
      // показать «…» / «Загрузка…» чем «Выбрать» / [старое имя],
      // иначе пользователь видит «Аль-Бакара» мигающую на «The Cow».
      surahName = '…';
      surahSubtitle = 'Загрузка…';
    } else {
      surahName = null;
      surahSubtitle = '';
    }

    return Container(
      decoration: BoxDecoration(
        color: _kEmerald,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SelectorTile(
              icon: Icons.menu_book_outlined,
              label: 'Сура',
              value: surahName ?? 'Выбрать',
              subtitle: surahSubtitle,
              onTap: () => _showSurahPicker(context),
            ),
          ),
          const _Divider(),
          Expanded(
            child: _SelectorTile(
              icon: Icons.bookmark_outline,
              label: 'Аят',
              value: ayahId?.toString() ?? '—',
              subtitle: 'из $totalAyahs'.toString(),
              // Открываем picker только если выбрана сура — иначе
              // неизвестно, сколько аятов показывать. Не полагаемся на
              // захваченный totalAyahs: при смене суры он остаётся
              // старым (пока не придёт playSurah → state.surah.ayahCount
              // обновится). Это был баг — список аятов не обновлялся.
              onTap: surahId == null
                  ? null
                  : () => _showAyahPicker(context, surahId!),
            ),
          ),
        ],
      ),
    );
  }

  void _showSurahPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kEmerald,
      builder: (_) => _SurahListSheet(
        surahDao: surahDao,
        selectedId: surahId,
        localeCode: localeCode,
      ),
    );
    if (selected != null && selected != surahId) {
      onSurahChanged(selected);
    }
  }

  /// Всегда читаем [totalAyahs] по [surahId] внутри builder'а — иначе
  /// при смене суры picker показывает старые данные (bug user-report:
  /// «при выборе „Аль-Бакара“ список аятов от „Аль-Фатихи“»).
  void _showAyahPicker(BuildContext context, int surahIdValue) async {
    final surah = await surahDao.getById(surahIdValue);
    if (surah == null) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kEmerald,
      builder: (_) => _AyahListSheet(
        totalAyahs: surah.ayahCount,
        selectedAyah: ayahId,
      ),
    );
    if (selected != null) {
      onAyahChanged(selected);
    }
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32,
        color: _kGold.withValues(alpha: 0.3),
      );
}

class _SelectorTile extends StatelessWidget {
  const _SelectorTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: _kGold, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: _kTextOnDarkSoft,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: _kTextOnDark,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: _kTextOnDarkSoft,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SurahListSheet extends StatelessWidget {
  const _SurahListSheet({
    required this.surahDao,
    required this.selectedId,
    required this.localeCode,
  });
  final SurahDao surahDao;
  final int? selectedId;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, controller) => Container(
        decoration: const BoxDecoration(
          color: _kEmerald,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kTextOnDarkSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.menu_book_outlined,
                      color: _kGold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Выбор суры',
                    style: TextStyle(
                      color: _kTextOnDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Surah>>(
                future: surahDao.getAll(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _kGold),
                    );
                  }
                  final list = snap.data!;
                  return ListView.builder(
                    controller: controller,
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final s = list[i];
                      final selected = s.id == selectedId;
                      final name = displayNameForSurah(s, localeCode);
                      final sub = subtitleForSurah(s, localeCode);
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: _kEmeraldDeep,
                          child: Text(
                            '${s.id}',
                            style: TextStyle(
                              color: selected ? _kGold : _kTextOnDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          '${s.id}. $name',
                          style: TextStyle(
                            color: _kTextOnDark,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: sub.isEmpty
                            ? null
                            : Text(
                                sub,
                                style: const TextStyle(
                                    color: _kTextOnDarkSoft,
                                    fontSize: 12),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check,
                                color: _kGold, size: 20)
                            : null,
                        onTap: () => Navigator.pop(context, s.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet со списком аятов выбранной суры.
///
/// Аяты генерируются 1..N из `Surahs.ayahCount` (для текущей суры,
/// известен через playerState). Tap → возвращает выбранный номер через
/// [Navigator.pop] с аргументом.
class _AyahListSheet extends StatelessWidget {
  const _AyahListSheet({
    required this.totalAyahs,
    required this.selectedAyah,
  });

  final int totalAyahs;
  final int? selectedAyah;

  @override
  Widget build(BuildContext context) {
    if (totalAyahs <= 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Сначала выберите суру',
            style: TextStyle(color: _kTextOnDark, fontSize: 16),
          ),
        ),
      );
    }
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (ctx, controller) => Container(
        decoration: const BoxDecoration(
          color: _kEmeraldDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kTextOnDarkSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_outline,
                      color: _kGold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Аяты 1..$totalAyahs',
                    style: const TextStyle(
                      color: _kTextOnDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: totalAyahs,
                itemBuilder: (_, i) {
                  final n = i + 1;
                  final selected = n == selectedAyah;
                  return InkWell(
                    onTap: () => Navigator.pop(context, n),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? _kGold
                            : _kEmerald.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: selected
                            ? null
                            : Border.all(
                                color:
                                    _kGoldDeep.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$n',
                        style: TextStyle(
                          color: selected
                              ? _kEmeraldDeep
                              : _kTextOnDark,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// === Current ayah panel (плавная анимация при смене аята) ===
class _AyahPanel extends ConsumerWidget {
  const _AyahPanel({required this.playerState});

  final AudioPlayerState playerState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surah = playerState.surah;
    final surahDisplay = surah != null
        ? displayNameForSurah(surah, Localizations.localeOf(context).languageCode)
        : '—';
    final surahStr = surah?.nameAr ?? surahDisplay;
    final total = playerState.totalAyahs ?? surah?.ayahCount ?? 0;
    final curAyah = playerState.currentAyah ?? 1;
    final safeCurAyah = total > 0 ? curAyah.clamp(1, total) : 0;

    // Подтягиваем текст текущего аята из БД. Асинхронный запрос —
    // FutureBuilder показывает spinner на первом кадре и кэш на
    // последующих (Riverpod сам дедуплицирует идентичные Future).
    final ayahTextFuture = (surah != null && safeCurAyah > 0)
        ? ref.watch(ayahTextProvider(SurahAyahRef(
            surahId: surah.id, ayahNumber: safeCurAyah)))
        : null;

    return Container(
      decoration: BoxDecoration(
        color: _kEmerald,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kGold, width: 1.5),
                ),
              ),
              Text(
                '۝',
                style: TextStyle(
                  fontSize: 36,
                  color: _kGold.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Название суры (плавно меняется при переходе).
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, anim) {
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              );
            },
            child: Text(
              surahDisplay,
              key: ValueKey('ayah-${surah?.id ?? 0}'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kTextOnDark,
                fontSize: 20,
                height: 1.4,
              ),
            ),
          ),
          // Арабский текст текущего аята (обновляется при currentAyah).
          const SizedBox(height: 12),
          if (ayahTextFuture != null)
            ayahTextFuture.when(
              data: (ayah) {
                final text = ayah?.textUthmani ?? '';
                if (text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: child,
                  ),
                  child: Text(
                    text,
                    key: ValueKey('ayah-text-$safeCurAyah'),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      color: _kTextOnDark,
                      fontSize: 24,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
              loading: () => const SizedBox(height: 32),
              error: (_, _) => const SizedBox.shrink(),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: 4),
          // Арабское название суры (если отличается от display) мелким
          // шрифтом под основным.
          if (surahStr.isNotEmpty && surahStr != surahDisplay)
            Text(
              surahStr,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kTextOnDarkSoft,
                fontSize: 14,
              ),
            ),
          const SizedBox(height: 6),
          // Русский подзаголовок (например, «Открывающая»).
          if (surah != null)
            Builder(builder: (_) {
              final sub = subtitleForSurah(
                surah,
                Localizations.localeOf(context).languageCode,
              );
              if (sub.isEmpty || sub == surahDisplay) {
                return const SizedBox.shrink();
              }
              return Text(
                sub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kGold,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              );
            }),
          const SizedBox(height: 12),
          // Счётчик «Аят N из M».
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 4, horizontal: 12),
                decoration: BoxDecoration(
                  color: _kGoldDeep.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    total > 0
                        ? 'Аят $safeCurAyah из $total'
                        : '—',
                    key: ValueKey('count-$safeCurAyah-$total'),
                    style: const TextStyle(
                      color: _kGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// === Player (центральная кнопка play/pause + прогресс-бар) ===
class _Player extends ConsumerWidget {
  const _Player({
    required this.state,
    required this.onPlay,
    required this.onTogglePause,
  });

  final AudioPlayerState state;
  final VoidCallback onPlay;
  final VoidCallback onTogglePause;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTrack = state.surah != null;
    return Column(
      children: [
        // Полный прогресс-бар (seek).
        _SeekBar(state: state),
        const SizedBox(height: 16),
        // Центральный контрол: loop / prev / play / next / shuffle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              tooltip: 'Повтор',
              onPressed: () {},
              icon: const Icon(Icons.repeat, color: _kTextOnDarkSoft),
              iconSize: 24,
            ),
            IconButton(
              tooltip: 'Предыдущий аят',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Предыдущий аят')),
                );
              },
              icon: const Icon(Icons.skip_previous,
                  color: _kTextOnDark, size: 36),
            ),
            // Главная круглая кнопка — play/pause.
            _BigPlayButton(
              key: const Key('audio_play_button'),
              playing: state.playing,
              onPlay: onPlay,
              onPause: onTogglePause,
            ),
            IconButton(
              tooltip: 'Следующий аят',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Следующий аят')),
                );
              },
              icon: const Icon(Icons.skip_next, color: _kTextOnDark, size: 36),
            ),
            IconButton(
              tooltip: 'Перемешать',
              onPressed: () {},
              icon: const Icon(Icons.shuffle, color: _kTextOnDarkSoft),
              iconSize: 24,
            ),
          ],
        ),
      ],
    );
  }
}

class _BigPlayButton extends StatelessWidget {
  const _BigPlayButton({
    super.key,
    required this.playing,
    required this.onPlay,
    required this.onPause,
  });

  final bool playing;
  final VoidCallback onPlay;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    // ВАЖНО: play-кнопка всегда должна быть тапабельна. Раньше
    // `enabled: hasTrack` (state.surah != null) гасило onTap на
    // первом запуске — state.surah == null пока пользователь не
    // выберет суру. Получалось, что play не работал до тех пор, пока
    // пользователь не открывал бы picker. Убираем гейт — onPlay
    // сам вызовет `playSurah()` который поставит state.surah.
    return GestureDetector(
      onTap: playing ? onPause : onPlay,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              _kGold,
              _kGoldDeep,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: _kGold.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          playing ? Icons.pause : Icons.play_arrow,
          color: _kEmeraldDeep,
          size: 42,
        ),
      ),
    );
  }
}

class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.state});
  final AudioPlayerState state;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: _kGold,
        inactiveTrackColor: _kGold.withValues(alpha: 0.25),
        thumbColor: _kGold,
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
      ),
      child: Slider(
        min: 0,
        max: (state.durationMs ?? 1).toDouble(),
        value:
            (state.positionMs.clamp(0, state.durationMs ?? 1)).toDouble(),
        onChanged: (_) {},
      ),
    );
  }
}

// === Reciter dropdown (modal bottom sheet) ===
class _ReciterDropdownSheet extends ConsumerStatefulWidget {
  const _ReciterDropdownSheet({
    required this.localeCode,
    required this.selectedId,
    required this.onSelect,
  });

  final String localeCode;
  final String? selectedId;
  final ValueChanged<Reciter> onSelect;

  @override
  ConsumerState<_ReciterDropdownSheet> createState() =>
      _ReciterDropdownSheetState();
}

class _ReciterDropdownSheetState extends ConsumerState<_ReciterDropdownSheet> {
  // Локальный «оптимистичный» набор избранных: при тапе по звезде
  // сначала обновляем UI, потом пишем в БД. Закрытие шита и DB-стрим
  // через recitersStreamProvider потом подтвердят изменение.
  final Set<String> _favOverrides = <String>{};
  String _query = '';

  bool _isFav(Reciter r) {
    return _favOverrides.contains(r.id) ? !r.isFavorite : r.isFavorite;
  }

  void _toggleFavorite(Reciter r) {
    final next = !_isFav(r);
    setState(() {
      if (next) {
        _favOverrides.add(r.id);
      } else {
        _favOverrides.remove(r.id);
      }
    });
    // БД-апдейт — сразу. Стрим `recitersStreamProvider` потом подтянет
    // обновление и оверрайды сбросятся при следующем ребилде.
    ref.read(recitersRepositoryProvider).setFavorite(r.id, next);
  }

  @override
  Widget build(BuildContext context) {
    // Подписываемся на стрим ректоров напрямую — тогда любое
    // изменение в БД (например, sync из фона) обновит шит без
    // необходимости вручную прокидывать reciters из родителя.
    final recitersAsync = ref.watch(recitersStreamProvider);
    final all = recitersAsync.maybeWhen(
      data: (list) => list,
      orElse: () => const <Reciter>[],
    );
    final selectedId = widget.selectedId;

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? all
        : all.where((r) {
            return r.nameAr.toLowerCase().contains(q) ||
                (r.nameEn ?? '').toLowerCase().contains(q) ||
                (r.nameRu ?? '').toLowerCase().contains(q);
          }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, controller) => Container(
        decoration: const BoxDecoration(
          color: _kEmeraldDeep,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kTextOnDarkSoft.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.people_alt_outlined,
                      color: _kGold, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Выбор чтеца',
                    style: TextStyle(
                      color: _kTextOnDark,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Поиск — фильтр по nameAr / nameEn / nameRu.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: _kTextOnDark, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Поиск...',
                  hintStyle: const TextStyle(
                      color: _kTextOnDarkSoft, fontSize: 14),
                  prefixIcon: const Icon(Icons.search,
                      color: _kTextOnDarkSoft, size: 20),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: _kEmerald.withValues(alpha: 0.4),
                ),
              ),
            ),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    q.isEmpty
                        ? 'Нет чтецов. Нажмите «Обновить» в списке.'
                        : 'Ничего не найдено по «$q».',
                    style: const TextStyle(color: _kTextOnDarkSoft),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  itemCount: _groupByFavorite(filtered, selectedId).length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: 0),
                  itemBuilder: (_, i) {
                    final grouped = _groupByFavorite(filtered, selectedId);
                    if (i == 0) return const _SectionHeader('Все');
                    final r = grouped[i - 1];
                    return _ReciterDropdownTile(
                      reciter: r,
                      localeCode: widget.localeCode,
                      selected: r.id == selectedId,
                      favorite: _isFav(r),
                      onTap: () => widget.onSelect(r),
                      onToggleFavorite: () => _toggleFavorite(r),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Для простоты группируем так: сначала — избранные, потом все
  // (но де-дуплицируем «избранных» в общем списке).
  List<Reciter> _groupByFavorite(List<Reciter> all, String? selectedId) {
    final favs = all.where((r) => r.isFavorite).toList();
    final rest = all.where((r) => !r.isFavorite).toList();
    if (selectedId != null && favs.every((r) => r.id != selectedId)) {
      // Поднимаем выбранного чтеца наверх, даже если он не избранный.
      final sel = all.firstWhere(
        (r) => r.id == selectedId,
        orElse: () => rest.first,
      );
      return [sel, ...favs.where((r) => r.id != sel.id), ...rest];
    }
    return [...favs, ...rest];
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: _kGold,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      );
}

class _ReciterDropdownTile extends ConsumerWidget {
  const _ReciterDropdownTile({
    required this.reciter,
    required this.localeCode,
    required this.selected,
    required this.favorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final Reciter reciter;
  final String localeCode;
  final bool selected;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final display = displayNameForLocale(reciter, localeCode);
    // Один компактный subtitle — qira'a с rawn («Хафс от Асыма»), или
    // «Коран для обучения» / арабский fallback. Бейджи «128 kbps» /
    // «Murattal» раньше ехали за границу, поэтому теперь они —
    // мелким серым текстом в нижней строке, не мешая основному имени.
    final meta = subtitleForReciter(reciter, localeCode);
    final style = shortStyle(reciter.mp3quranRewaya);
    final metaParts = <String>[
      if (meta.isNotEmpty && meta != display) meta,
    ];
    final metaLine = metaParts.join(' · ');
    final tailsLine = [
      '128 kbps',
      if (style != null && style.isNotEmpty) style,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: _kEmerald,
              child: Text(
                display.isNotEmpty ? display[0] : '?',
                style: const TextStyle(
                  color: _kGold,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Полное имя чтеца — 1 строка + ellipsis (старое
                  // поведение maxLines: 2 отрезало имя на узкой панели,
                  // когда были большие бейджи; теперь их нет — одной
                  // строки хватает для 95% имён).
                  Text(
                    display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _kTextOnDark,
                      fontSize: 14,
                      height: 1.2,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  // «Версия Корана для обучения» / «Хафс от Асыма» /
                  // арабское имя — под именем, как просил user.
                  if (metaLine.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      metaLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _kTextOnDarkSoft,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                  // Технический «хвост» мелким серым — 128 kbps / Murattal.
                  // Не кликабельный, просто мета-info.
                  const SizedBox(height: 1),
                  Text(
                    tailsLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _kTextOnDarkSoft.withValues(alpha: 0.7),
                      fontSize: 10,
                      height: 1.2,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            // Trailing-блок: download/star/selected — без InkWell-ов,
            // чтобы row.onTap не срабатывал на тап по иконкам. Row
            // с mainAxisSize.min занимает ровно столько, сколько надо.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReciterDownloadIcon(reciter: reciter),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'В избранное',
                    icon: Icon(
                      favorite ? Icons.star : Icons.star_outline,
                      size: 18,
                      color: favorite ? _kGold : _kTextOnDarkSoft,
                    ),
                    onPressed: onToggleFavorite,
                  ),
                ),
                SizedBox(
                  width: 18,
                  child: selected
                      ? const Icon(Icons.check, color: _kGold, size: 18)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Иконка состояния кеша для одного ректора.
///
/// Состояния:
///   * idle, ничего не скачано        → `cloud_download_outlined`
///   * идёт загрузка                   → spinner с «57 / 114»
///   * все 114 скачаны                  → `download_done` / золотой чек
///   * last attempt failed              → `cloud_off` + snackbar-retry по тапу
class _ReciterDownloadIcon extends ConsumerWidget {
  const _ReciterDownloadIcon({required this.reciter});

  final Reciter reciter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Состояние фоновой загрузки (контроллер с одним слотом).
    final dlState = ref.watch(reciterDownloadControllerProvider);
    final isDownloadingThis = dlState.isDownloadingReciter(reciter.id);

    // Стрим ректоров с полным кешем — триггерит пересборку при insert/delete
    // записи в `audio_cache_metadata`.
    final fullyCached = ref.watch(fullyCachedRecitersProvider);
    final isDone = fullyCached.maybeWhen(
      data: (set) => set.contains(reciter.id),
      orElse: () => false,
    );

    if (isDownloadingThis) {
      final completed = dlState.completed;
      final total = dlState.total;
      return SizedBox(
        width: 34,
        height: 32,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: total > 0 ? completed / total : null,
                  color: _kGold,
                  backgroundColor: _kGoldDeep.withValues(alpha: 0.3),
                ),
              ),
              Text(
                '$completed',
                style: const TextStyle(
                  color: _kGold,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isDone) {
      return SizedBox(
        width: 34,
        height: 32,
        child: IconButton(
          padding: EdgeInsets.zero,
          tooltip: 'Все 114 сур скачаны',
          icon: const Icon(
            Icons.download_done_rounded,
            color: _kGold,
            size: 18,
          ),
          onPressed: null, // disabled — уже скачано
        ),
      );
    }

    return SizedBox(
      width: 34,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: 'Скачать все 114 сур для офлайн-прослушивания',
        icon: Icon(
          Icons.cloud_download_outlined,
          color: _kTextOnDarkSoft.withValues(alpha: 0.85),
          size: 18,
        ),
        onPressed: () {
          ref
              .read(reciterDownloadControllerProvider.notifier)
              .startDownload(reciter.id);
        },
      ),
    );
  }
}

// ============================================================================
// Ниже — служебные виджеты плеера и кнопок, перенесённые сюда из старой
// реализации без изменений логики, но с тёмной темой. Работают в паре с
// AudioPlayerController (positionStream.listen и т. д.).
// ============================================================================

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls({
    required this.state,
    required this.onSpeed,
    required this.onSleepTimer,
  });

  final AudioPlayerState state;
  final ValueChanged<double> onSpeed;
  final ValueChanged<int?> onSleepTimer;

  static const _kSpeedOptions = <double>[0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  static const _kSleepOptions = <int?>[null, 5, 10, 15, 30, 60];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kEmerald,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlTile(
            icon: Icons.speed,
            label: 'Скорость',
            value: '${state.speed.toStringAsFixed(2)}x',
            onTap: () => _showSpeedPicker(context),
          ),
          _ControlTile(
            icon: Icons.bedtime,
            label: 'Таймер сна',
            value: _sleepLabel(state),
            onTap: () => _showSleepPicker(context),
          ),
          _ControlTile(
            icon: Icons.nightlight_round,
            label: 'Ночной режим',
            value: 'Выкл',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ночной режим (TODO)')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSpeedPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<double>(
      context: context,
      builder: (_) => _ListSheet<double>(
        title: 'Скорость',
        options: _kSpeedOptions,
        label: (s) => '${s.toStringAsFixed(2)}x',
      ),
    );
    if (picked != null) onSpeed(picked);
  }

  void _showSleepPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<int?>(
      context: context,
      builder: (_) => _ListSheet<int?>(
        title: 'Таймер сна',
        options: _kSleepOptions,
        label: (m) => m == null ? 'Выкл' : '$m мин',
      ),
    );
    onSleepTimer(picked);
  }
}

/// Превращает [sleepTimerAtMs] (timestamp) в подпись «Выкл» / «N мин».
String _sleepLabel(AudioPlayerState s) {
  if (s.sleepTimerAtMs == null) return 'Выкл';
  final msLeft =
      s.sleepTimerAtMs!.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
  if (msLeft <= 0) return 'Выкл';
  final min = (msLeft / 60000).ceil();
  return '$min мин';
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Icon(icon, color: _kGold, size: 22),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _kTextOnDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: _kTextOnDarkSoft,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _ListSheet<T> extends StatelessWidget {
  const _ListSheet({
    required this.title,
    required this.options,
    required this.label,
  });

  final String title;
  final List<T> options;
  final String Function(T) label;

  @override
  Widget build(BuildContext context) => Container(
        color: _kEmeraldDeep,
        height: 320,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  color: _kTextOnDark,
                  fontSize: 18,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: options
                    .map((o) => ListTile(
                          title: Text(
                            label(o),
                            style: const TextStyle(color: _kTextOnDark),
                          ),
                          onTap: () => Navigator.pop(context, o),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      );
}

// === Background pattern painter (геометрическая арабеска) ===
class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A951).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const step = 80.0;
    for (double y = 0; y < size.height; y += step) {
      for (double x = 0; x < size.width; x += step) {
        _paintStar(canvas, Offset(x, y), step * 0.3, paint);
      }
    }
  }

  void _paintStar(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final angle = (i * 3.14159 * 2) / 8;
      final r1 = i.isEven ? r : r * 0.5;
      final pt = Offset(c.dx + r1 * _cos(angle), c.dy + r1 * _sin(angle));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  // Встроенные Taylor-разложения для cos/sin (без импорта dart:math).
  double _cos(double a) {
    final v = a % (2 * 3.14159265);
    final v2 = v * v;
    const fact = [1, 1, 2, 6, 24, 120];
    double result = 1, term = 1;
    for (var n = 1; n <= 5; n++) {
      term *= -v2 / (fact[n] * fact[n]);
      result += term;
    }
    return result;
  }

  double _sin(double a) {
    final v = a % (2 * 3.14159265);
    final v2 = v * v;
    // Taylor series for sin, degree 8. Need n+1 up to 7 → 8 fact'ов.
    const fact = [1, 1, 2, 6, 24, 120, 720, 5040];
    double result = v, term = v;
    for (var n = 1; n <= 5; n++) {
      term *= -v2 / (fact[n] * fact[n + 1]);
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _IslamicPatternPainter old) => false;
}

// === Removed legacy _PlayerErrorBanner class — ошибка теперь
// отображается через SnackBar в _ListenScreenState. ===

void _renderPlaceholderForDeleted() {} // ignore: unused_element
