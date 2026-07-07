import 'dart:async';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/reciter_dao.dart';
import 'mp3quran_api.dart';

/// Режим загрузки для ректора. Все mp3quran-ректоры имеют per-surah
/// файлы, так что режим всегда `surah`. Оставлено для обратной
/// совместимости с тестами и старым кодом.
enum ReciterMode { surah, ayah, both }

/// Резолв URL конкретной суры для ректора.
///
/// Использует mp3quran-метаданные из БД:
///   `${mp3quranServer}${NNN}.mp3`
/// (например, `https://server8.mp3quran.net/afs/001.mp3`).
///
/// `null` если ректор не имеет mp3quran-метаданных (например, ещё
/// не синхронизирован с API).
String? resolveSurahUrl(Reciter reciter, int surahNumber) {
  final server = reciter.mp3quranServer;
  final moshafId = reciter.mp3quranMoshafId;
  if (server == null || moshafId == null) return null;
  final surahStr = surahNumber.toString().padLeft(3, '0');
  final base = server.endsWith('/') ? server : '$server/';
  return '$base$surahStr.mp3';
}

/// Префикс кэш-файла. Использует [Reciter.id] (формат `mp3quran:N`)
/// и 3-значный падинг номера суры.
String audioCacheRelativePath(String reciterId, int surahNumber) {
  final surahStr = surahNumber.toString().padLeft(3, '0');
  return '$reciterId/$surahStr.mp3';
}

ReciterMode modeForReciter(String reciterId) =>
    ReciterMode.surah;

/// True, если у ректора есть mp3quran-метаданные (для UI-индикации).
bool reciterHasAudio(Reciter reciter) =>
    reciter.mp3quranServer != null && reciter.mp3quranMoshafId != null;

/// Локализованное display-имя ректора для UI.
///
/// Приоритет: ru → en → ar (по коду локали устройства). Если конкретная
/// локаль не загружена в БД (NULL), проваливаемся на следующую. В
/// худшем случае вернётся арабское `nameAr` (всегда заполнено).
String displayNameForLocale(Reciter r, String localeCode) {
  final isRu = localeCode.toLowerCase() == 'ru';
  if (isRu && (r.nameRu ?? '').isNotEmpty) return r.nameRu!;
  if ((r.nameEn ?? '').isNotEmpty) return r.nameEn!;
  return r.nameAr;
}

/// Subtitle для UI: арабское имя (если отличается от display), иначе
/// rewaya из mp3quran, иначе slug.
String subtitleForReciter(Reciter r, String localeCode) {
  final display = displayNameForLocale(r, localeCode);
  if (localeCode.toLowerCase() == 'ru' && r.nameAr.isNotEmpty && r.nameAr != display) {
    return r.nameAr;
  }
  if (r.nameEn != null &&
      r.nameEn!.isNotEmpty &&
      r.nameEn != display &&
      localeCode.toLowerCase() != 'eng') {
    return r.nameEn!;
  }
  return r.mp3quranRewaya ?? r.slug;
}

/// Локализованное display-имя суры для UI.
///
/// Приоритет: ru → en → ar. `nameRu` заполняется миграцией v11→v12
/// через [kSurahRuNames] (см. `surah_ru_names.dart`). Если русского
/// перевода нет (NULL), проваливаемся на `nameTransliteration` (например,
/// "The Opening"). В крайнем случае — `nameAr` (всегда заполнено).
String displayNameForSurah(Surah s, String localeCode) {
  final isRu = localeCode.toLowerCase() == 'ru';
  if (isRu && (s.nameRu ?? '').isNotEmpty) return s.nameRu!;
  if (s.nameTransliteration.isNotEmpty) return s.nameTransliteration;
  return s.nameAr;
}

/// Subtitle суры: русский перевод (если есть), иначе арабский (если
/// отличается от display), иначе пустая строка.
String subtitleForSurah(Surah s, String localeCode) {
  final display = displayNameForSurah(s, localeCode);
  final isRu = localeCode.toLowerCase() == 'ru';
  if (isRu && (s.subtitleRu ?? '').isNotEmpty) return s.subtitleRu!;
  if (s.nameAr.isNotEmpty && s.nameAr != display) return s.nameAr;
  return '';
}

/// Репозиторий ректоров.
///
/// Данные полностью приходят из MP3Quran.net API через [syncFromApi].
/// Хардкоженных seed-ов больше нет — UI работает только с тем, что
/// подтянет sync.
///
/// [ensureSeeded] — стаб, оставлен для обратной совместимости с
/// вызывающим кодом (bootstrapper). Сейчас делает no-op: если в
/// БД нет ректоров — UI показывает «Нажмите Обновить». Полный
/// список появится после первого `syncFromApi()`.
class RecitersRepository {
  RecitersRepository(this._dao, {Mp3QuranApi? api}) : _api = api ?? Mp3QuranApi();

  final ReciterDao _dao;
  final Mp3QuranApi _api;

  /// Legacy stub — раньше тут засеивались 8 дефолтных ректоров.
  /// Теперь UI показывает «Список пуст, нажмите Обновить» пока
  /// [syncFromApi] не подтянет данные.
  Future<void> ensureSeeded() async {
    // No-op: all data comes from MP3Quran.net API.
  }

  /// Подтягивает полный список ректоров (~240) с mp3quran.net и
  /// записывает в БД. Три параллельных реквеста (ar + en + ru) за
  /// ~2-3 секунды суммарно. Идемпотентно — повторные вызовы
  /// обновляют кеш свежими данными.
  Future<int> syncFromApi({
    List<String> languages = const ['ar', 'eng', 'ru'],
  }) async {
    final merged = await _api.fetchRecitersMultiLocale(languages: languages);
    final now = DateTime.now().millisecondsSinceEpoch;
    var inserted = 0;
    for (final entry in merged.entries) {
      final d = entry.value;
      final moshaf = _pickHafsMoshaf(d);
      if (moshaf == null) continue;
      final id = 'mp3quran:${d.id}';
      final arName = d.nameByLocale['ar'] ?? d.name;
      final enName = d.nameByLocale['eng'];
      final ruName = d.nameByLocale['ru'];

      await _dao.upsertWithMp3quranMultiLocale(
        reciterId: id,
        slug: 'mp3quran-${d.id}',
        nameAr: arName,
        nameRu: ruName,
        nameEn: enName,
        style: 'murattal',
        mp3quranId: d.id,
        moshafId: moshaf.id,
        server: moshaf.server,
        rewaya: moshaf.name,
        moshafType: moshaf.moshafType,
        surahTotal: moshaf.surahTotal,
        cachedAt: now,
      );
      inserted += 1;
    }
    return inserted;
  }

  Mp3QuranMoshafDto? _pickHafsMoshaf(Mp3QuranReciterDto reciter) {
    // Приоритет 1: Hafs + 114 сур + murattal.
    final hafsMurattal = reciter.firstMoshafWhere(
      (m) =>
          m.surahTotal >= 114 &&
          m.name.toLowerCase().contains('hafs') &&
          m.name.toLowerCase().contains('murattal'),
    );
    if (hafsMurattal != null) return hafsMurattal;
    // Приоритет 2: Hafs + 114 сур (любой стиль).
    final hafsAny = reciter.firstMoshafWhere(
      (m) => m.surahTotal >= 114 && m.name.toLowerCase().contains('hafs'),
    );
    if (hafsAny != null) return hafsAny;
    // Приоритет 3: первый мусхаф со 114 сурами.
    return reciter.firstMoshafWhere((m) => m.surahTotal >= 114);
  }

  /// Стрим всех ректоров из БД.
  Stream<List<Reciter>> watchAll() => _dao.watchAll();

  /// Стрим избранных.
  Stream<List<Reciter>> watchFavorites() => _dao.watchFavorites();

  Future<Reciter?> getById(String id) => _dao.getById(id);

  /// Установить/снять отметку избранного.
  Future<void> setFavorite(String reciterId, bool isFavorite) =>
      _dao.setFavorite(reciterId, isFavorite);

  Future<DateTime?> latestMp3quranSync() => _dao.latestMp3quranSync();
  Future<int> countRecitersWithoutMp3quranInfo() =>
      _dao.countRecitersWithoutMp3quranInfo();
}