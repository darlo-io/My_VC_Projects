import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../tafsir/data/tafsirs_sync_service.dart';

/// Показать панель тафсира для конкретного аята.
///
/// Поведение:
/// - Сначала показываем **список** доступных source'ов (с фильтром
///   по UI-языку, дефолт — русский), иконкой `menu_book_outlined`.
/// - При тапе на source загружаем и показываем текст тафсира.
/// - Текст реактивный — Drift `Stream` показывает обновления сразу
///   после `upsertTafsir` (например, после retry).
/// - Empty state «Нет тафсира для этого аята» + кнопка retry, которая
///   зовёт [TafsirsSyncService.fetchTafsirForAyah].
///
/// Последний выбранный source-id хранится в in-memory Map (per-key),
/// чтобы при повторном открытии не показывать заново список.
Future<void> showTafsirPanel({
  required BuildContext context,
  required WidgetRef ref,
  required Ayah ayah,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: AppColors.border, width: 1),
    ),
    builder: (_) => _TafsirPanel(ayah: ayah),
  );
}

/// Round 9.6 (code review #C4): persist в SharedPreferences
/// (ключ `tafsir.lastSourceIdMap`) JSON-encoded map
/// `ayahId → sourceId`. На cold restart — гидратируется через
/// [_loadLastSourceMap]. Раньше — in-memory, терялось на restart.
Map<int, int>? _persistedLastSourceMap;

/// Hydrates [_persistedLastSourceMap] из SharedPreferences при
/// первом обращении. Lazy init — на cold start мы обычно
/// открываем tafsir-panel редко, не нужно парсить JSON в main().
Future<Map<int, int>> _loadLastSourceMap(
  SharedPreferences prefs,
) async {
  if (_persistedLastSourceMap != null) return _persistedLastSourceMap!;
  final raw = prefs.getString('tafsir.lastSourceIdMap');
  if (raw == null || raw.isEmpty) {
    _persistedLastSourceMap = {};
    return _persistedLastSourceMap!;
  }
  try {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _persistedLastSourceMap = {
      for (final e in json.entries) int.parse(e.key): e.value as int,
    };
    return _persistedLastSourceMap!;
  } catch (_) {
    _persistedLastSourceMap = {};
    return _persistedLastSourceMap!;
  }
}

Future<void> _saveLastSourceMap(SharedPreferences prefs) async {
  if (_persistedLastSourceMap == null) return;
  await prefs.setString(
    'tafsir.lastSourceIdMap',
    jsonEncode({
      for (final e in _persistedLastSourceMap!.entries)
        '${e.key}': e.value,
    }),
  );
}

/// Backwards-compat shim: in-memory reference на
/// [_persistedLastSourceMap]. Используется в местах где раньше
/// обращались напрямую к map.
// ignore: unused_element
int? _lookupPersistedLastSourceId(int ayahId) {
  final map = _persistedLastSourceMap;
  if (map == null) return null;
  return map[ayahId];
}

class _TafsirPanel extends ConsumerStatefulWidget {
  const _TafsirPanel({required this.ayah});
  final Ayah ayah;

  @override
  ConsumerState<_TafsirPanel> createState() => _TafsirPanelState();
}

class _TafsirPanelState extends ConsumerState<_TafsirPanel> {
  TafsirSource? _selectedSource;
  bool _loading = false;
  String? _error;

  /// **Round 6 bugfix (2026-07-22)**: результат fetch'а теперь
  /// хранится в локальном state, а не через `StreamBuilder` +
  /// `watchByAyahAndSource` stream. Проблема с stream — при
  /// `upsertTafsir` drift emit'ит только ПОСЛЕ завершения
  /// транзакции, а `_fetch` возвращается раньше → rebuild
  /// `StreamBuilder.builder` происходит с задержкой (или не
  /// происходит, если stream буферизуется). Прямое чтение из
  /// DB после `fetchTafsirForAyah` гарантирует что
  /// текст сразу доступен в `_fetchedTafsir`.
  Tafsir? _fetchedTafsir;

  @override
  void initState() {
    super.initState();
    // Если для этого аята уже выбирали source — открываем сразу
    // текст (subsequent tap UX, см. AGENTS.md «Tafsir»).
    // Round 9.6 (code review #C4): теперь читаем из
    // SharedPreferences. Идемпотентно hydrate через
    // [_loadLastSourceMap].
    unawaited(_hydrateThenResolve(widget.ayah.id));
  }

  Future<void> _hydrateThenResolve(int ayahId) async {
    final prefs = await SharedPreferences.getInstance();
    await _loadLastSourceMap(prefs);
    if (!mounted) return;
    final cachedId = _persistedLastSourceMap?[ayahId];
    if (cachedId != null) {
      unawaited(_resolveInitial(cachedId));
    }
  }

  Future<void> _resolveInitial(int sourceId) async {
    final source = await ref.read(tafsirDaoProvider).getById(sourceId);
    if (!mounted || source == null) return;
    setState(() => _selectedSource = source);
    // **Round 6 bugfix**: после загрузки source'а из БД — запускаем
    // _fetch чтобы подгрузить текст. Без этого при initial source
    // (когда пользователь уже выбирал tafsir для этого аята ранее)
    // UI остался бы в loading forever.
    unawaited(_fetch(source));
  }

  @override
  void dispose() {
    super.dispose();
  }

  // (placeholder to ensure trailing newlines don't break)

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lang = ref.watch(appPreferencesProvider).languageCode ?? 'ru';

    developer.log('[tafsir_panel] build() called, lang=$lang, _selectedSource=${_selectedSource?.id}', name: 'tafsir_panel');

    // Список source'ов на нужном языке — reactive.
    final sourcesAsync = ref.watch(_sourcesForLangProvider(lang));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.menu_book_outlined,
                      color: AppColors.gold, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.tafsirButton,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (_selectedSource != null)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.list_alt,
                          color: AppColors.gold, size: 22),
                      tooltip: t.tafsirButton,
                      onPressed: () =>
                          setState(() => _selectedSource = null),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: 8),
              Flexible(
                child: _selectedSource == null
                    ? _buildSourceList(sourcesAsync, t, lang)
                    : _buildTafsirView(t, lang),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceList(
    AsyncValue<List<TafsirSource>> sourcesAsync,
    AppLocalizations t,
    String lang,
  ) {
    return sourcesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('$e', textAlign: TextAlign.center),
        ),
      ),
      data: (sources) {
        if (sources.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off,
                      size: 36, color: AppColors.textTertiary),
                  const SizedBox(height: 8),
                  Text(
                    t.tafsirEmpty,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          itemCount: sources.length,
          separatorBuilder: (_, _) => const SizedBox(height: 4),
          itemBuilder: (context, i) {
            final s = sources[i];
            // Локализация названия источника:
            //   ru → s.nameRu ?? s.nameEn (fallback на en, если
            //        перевод на русский не вернулся из API);
            //   en → s.nameEn;
            //   ar → s.nameEn (Quran.com API не возвращает
            //        localized name для арабских tafsirs, они и так
            //        на арабском — но мы отдаём en как fallback).
            final displayName = _localizedSourceName(s, lang);
            // **Round 7 (2026-07-22)**: показываем бейдж с кодом
            // языка текста (AR/RU/UR/BN/KU) — Quran.com имеет
            // только 1 русский тафсир (id=170), остальные на
            // арабском/урду/бенгали/курдском. Бейдж сразу информирует
            // пользователя о том, на каком языке будет текст.
            final showLangBadge = s.languageCode != lang;
            return ListTile(
              leading: const Icon(Icons.menu_book_outlined,
                  color: AppColors.gold, size: 20),
              title: Text(
                displayName,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textPrimary),
              ),
              subtitle: showLangBadge
                  ? Text(
                      _languageDisplayName(s.languageCode),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    )
                  : null,
              trailing: showLangBadge
                  ? _LangBadge(code: s.languageCode)
                  : null,
              onTap: () => _selectSource(s),
            );
          },
        );
      },
    );
  }

  Widget _buildTafsirView(AppLocalizations t, String lang) {
    final source = _selectedSource!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            // Локализация заголовка tafsir view (после выбора
            // конкретного source'а). Используем ту же функцию, что
            // и в source list — единая логика.
            _localizedSourceName(source, lang),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.gold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: _buildTafsirContent(t, source),
        ),
      ],
    );
  }

  /// **Round 6 bugfix**: заменил `StreamBuilder` на прямую логику
  /// по `_fetchedTafsir` / `_loading` / `_error`. Причины:
  /// - StreamBuilder ждал первого emit от `watchByAyahAndSource`
  ///   (которое зависит от Drift's stream pipeline) — на этом
  ///   устройстве emit задерживался, builder не вызывался.
  /// - `initialData: const []` не помогло — builder всё равно
  ///   не вызывался (verified 2026-07-22 через stderr.writeln).
  /// - Прямое чтение `_fetchedTafsir` после `await _fetch(...)`
  ///   гарантирует мгновенное обновление UI.
  Widget _buildTafsirContent(AppLocalizations t, TafsirSource source) {
    // Priority: success → error → loading → loading (initial).
    if (_fetchedTafsir != null) {
      final text = _stripHtml(_fetchedTafsir!.textValue);
      // **Round 7 (2026-07-22)**: для RTL-языков (арабский, урду,
      // курдский/Sorani) оборачиваем текст в Directionality(rtl) —
      // Flutter автоматически выравнивает текст справа налево
      // (RTL-параграф), расставляет punctuation правильно и
      // подбирает направление при копировании. Также подключаем
      // шрифт с поддержкой Arabic glyphs (Amiri / Scheherazade).
      // Если язык LTR (en, ru, bn) — стандартный LTR.
      final isRtl = _isRtlLanguage(source.languageCode);
      final textWidget = Text(
        text,
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
        style: TextStyle(
          fontSize: isRtl ? 18 : 14,
          color: AppColors.textPrimary,
          height: 1.8,
          fontFamily: isRtl ? 'Amiri' : null,
          fontFamilyFallback: isRtl ? const ['Scheherazade'] : null,
        ),
      );
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // **Round 7**: маленький бейдж с языком текста,
            // показываем только если язык НЕ совпадает с UI-локалью
            // пользователя (т.е. это «иностранный» тафсир).
            if (_isForeignLanguage(source.languageCode))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    _LangBadge(code: source.languageCode),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _languageWarning(source.languageCode),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            textWidget,
          ],
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off,
                  size: 36, color: AppColors.textTertiary),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loading ? null : () => _fetch(source),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(t.tafsirRetry),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.textOnGold,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Loading (initial state or active fetch).
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Future<void> _selectSource(TafsirSource s) async {
    developer.log('[tafsir_panel] _selectSource called with id=${s.id}', name: 'tafsir_panel');
    setState(() {
      _selectedSource = s;
      _fetchedTafsir = null;
      _error = null;
    });
    // Round 9.6 (code review #C4): persist lastSourceId per ayah в
    // SharedPreferences (вместо in-memory). На cold restart —
    // последний выбор восстанавливается, не нужно снова открывать
    // picker.
    final prefs = await SharedPreferences.getInstance();
    await _loadLastSourceMap(prefs);
    _persistedLastSourceMap?[widget.ayah.id] = s.id;
    await _saveLastSourceMap(prefs);
    // **Round 6 bugfix**: запускаем _fetch напрямую (без ожидания
    // StreamBuilder'а). Раньше fetch запускался внутри builder'а
    // StreamBuilder'а, который не вызывался на этом устройстве —
    // отсюда infinite loading.
    unawaited(_fetch(s));
  }

  Future<void> _fetch(TafsirSource source) async {
    setState(() {
      _loading = true;
      _error = null;
      _fetchedTafsir = null;
    });

    try {
      // **Round 4 bugfix**: explicit `.timeout(60s)` — гарантирует
      // обратную связь пользователю через 60s, даже если
      // внутренний 90s timeout `fetchTafsirForAyah` не сработал
      // (например, на зависшем Dio connection pool).
      await ref.read(tafsirsSyncServiceProvider).fetchTafsirForAyah(
            ayahId: widget.ayah.id,
            surahId: widget.ayah.surahId,
            ayahNumber: widget.ayah.ayahNumber,
            tafsirSourceId: source.id,
          ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException(
            'tafsir load timed out after 60s for source.id=${source.id}',
          );
        },
      );
      // **Round 6 bugfix**: читаем прямо из DB после успешного
      // `fetchTafsirForAyah` — без ожидания Drift watch stream.
      // Раньше UI зависел от `StreamBuilder` builder'а, который
      // не вызывался на этом устройстве (см. round 5 plan).
      final dao = ref.read(tafsirDaoProvider);
      final rows = await dao.getForAyah(widget.ayah.id, sourceId: source.id);
      if (!mounted) return;
      if (rows.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Нет тафсира для этого аята';
        });
        return;
      }
      setState(() {
        _loading = false;
        _fetchedTafsir = rows.first;
      });
    } catch (e, st) {
      if (!mounted) return;
      developer.log(
        'tafsir fetch failed: $e',
        name: 'tafsir_panel',
        error: e,
        stackTrace: st,
      );
      String errorMessage;
      if (e is TimeoutException) {
        errorMessage =
            'Превышено время ожидания (60s). Проверьте сеть и нажмите «Повторить».';
      } else if (e is TafsirNotFoundException) {
        errorMessage = 'Нет тафсира для этого аята';
      } else {
        errorMessage = 'Ошибка загрузки: $e';
      }
      setState(() {
        _loading = false;
        _error = errorMessage;
      });
    }
  }
}

/// Provider, отдающий список source'ов для UI-языка. Внутри дёргает
/// sync, если кеш пуст (например, на cold start).
///
/// **`autoDispose`**: provider утилизируется когда нет ни одного
/// listener'а (т.е. когда tafsir panel закрыт). При повторном
/// открытии панели — re-evaluate. Без `autoDispose` результат
/// первого вызова кешируется навечно, и миграция `v16→v17` (или
/// forceSync) не подхватывается UI до перезапуска приложения.
final _sourcesForLangProvider = FutureProvider.autoDispose
    .family<List<TafsirSource>, String>((ref, lang) async {
  final dao = ref.watch(tafsirDaoProvider);
  final initial = await dao.getAllSources(languageCode: lang);
  if (initial.isNotEmpty) return initial;
  // Кеш пуст — пробуем sync.
  try {
    await ref.read(tafsirsSyncServiceProvider).forceSync(languageCode: lang);
  } catch (_) {
    // Если sync упал, покажем пустой список — UI нарисует cloud-off
    // + «Нет тафсира для этого аята». Пользователь может retry
    // через forceSync, вызванный из fetchTafsirForAyah.
  }
  return dao.getAllSources(languageCode: lang);
});

/// Локализованное имя источника тафсира.
///
/// Логика (Sprint 2.5.1):
///   - ru → [TafsirSource.nameRu] ?? [TafsirSource.nameAr] ??
///     [TafsirSource.nameEn];
///   - en → [TafsirSource.nameEn];
///   - ar → [TafsirSource.nameAr] ?? [TafsirSource.nameEn].
///
/// Сценарий, найденный в device verification 2026-07-17:
/// Arabic-original tafsirs (Tafsir Ibn Kathir, Al-Sa'di и т.д.) на
/// Quran.com API не имеют русского перевода (`?language=ru` всё
/// равно возвращает `translated_name.name` на английском, потому
/// что русская локализация для Arabic-тафсиров отсутствует в их
/// data). До фикса русские пользователи видели «Tafsir Ibn Kathir»
/// (английская транслитерация). Теперь fallback: арабский оригинал
/// «تفسير ابن كثير» — это исходное имя, и оно информативнее
/// английской транслитерации.
///
/// До Sprint 2.5.1 здесь было просто `s.nameEn`.
String _localizedSourceName(TafsirSource s, String lang) {
  switch (lang) {
    case 'ru':
      if (s.nameRu != null && s.nameRu!.isNotEmpty) return s.nameRu!;
      // Fallback: для Arabic-оригинальных tafsirs перевода на
      // русский нет — отдаём оригинальное арабское имя (лучше
      // английской транслитерации для русскоязычного пользователя).
      if (s.nameAr.isNotEmpty) return s.nameAr;
      return s.nameEn;
    case 'ar':
      return s.nameAr.isNotEmpty ? s.nameAr : s.nameEn;
    case 'en':
    default:
      return s.nameEn;
  }
}

/// Минимальный HTML-strip для tafsir.text. Quran.com оборачивает
/// арабские фразы в `<span class="...">`, цитаты в `<i>`, абзацы в
/// `<p>`. Нам нужно plain text. Полноценный рендеринг HTML будет в
/// Sprint 2.5 (через `flutter_html`); пока — strip + пробелы.
String _stripHtml(String input) {
  final noTags = input
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll(RegExp(r'</p\s*>'), '\n\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  return noTags
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .trim();
}

/// **Round 7 (2026-07-22)**: определение RTL-языка для арабских
/// текстов. Арабский, урду и курдский (Sorani) — RTL.
bool _isRtlLanguage(String? code) {
  switch (code) {
    case 'ar':
    case 'ur':
    case 'ku':
    case 'fa': // фарси (на будущее)
    case 'he': // иврит (на будущее)
      return true;
    default:
      return false;
  }
}

/// **Round 7 (2026-07-22)**: определение «иностранного» языка —
/// когда язык источника НЕ русский (в текущей сборке только
/// 'ru' имеет русский перевод; остальные 'ar', 'ur', 'bn', 'ku').
/// Используется чтобы показывать бейдж с предупреждением в tafsir view.
bool _isForeignLanguage(String? sourceLang) {
  return sourceLang != null && sourceLang != 'ru';
}

/// Полное название языка на UI-языке пользователя. Используется
/// в subtitle source picker'а для иностранных тафсиров.
String _languageDisplayName(String? code) {
  switch (code) {
    case 'ar':
      return 'Арабский оригинал';
    case 'ur':
      return 'Урду';
    case 'bn':
      return 'Бенгальский';
    case 'ku':
      return 'Курдский (сорани)';
    case 'en':
      return 'English';
    case 'ru':
      return 'Русский';
    default:
      return code ?? '';
  }
}

/// Предупреждение под текстом иностранного тафсира.
String _languageWarning(String? code) {
  switch (code) {
    case 'ar':
      return 'Quran.com предоставляет только оригинал на арабском. '
          'Перевода на русский для этого тафсира нет.';
    case 'ur':
      return 'Текст на урду. Перевода на русский нет.';
    case 'bn':
      return 'Текст на бенгальском. Перевода на русский нет.';
    case 'ku':
      return 'Текст на курдском. Перевода на русский нет.';
    case 'en':
      return 'Текст на английском. Выберите Ас-Саади для перевода на русский.';
    default:
      return 'Текст на иностранном языке.';
  }
}

/// **Round 7**: маленький бейдж с кодом языка (AR/RU/UR/BN/KU/EN).
/// Показывается в source picker'е (trailing) и в tafsir view (header).
class _LangBadge extends StatelessWidget {
  const _LangBadge({required this.code});
  final String code;

  Color get _bgColor {
    switch (code) {
      case 'ru':
        return AppColors.gold;
      case 'ar':
        return const Color(0xFF2E7D32); // emerald green
      case 'ur':
        return const Color(0xFF1565C0); // blue
      case 'bn':
        return const Color(0xFFC62828); // red
      case 'ku':
        return const Color(0xFF6A1B9A); // purple
      case 'en':
        return AppColors.textTertiary;
      default:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = code.toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
