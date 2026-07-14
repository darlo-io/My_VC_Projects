import 'dart:async';
import 'dart:developer' as developer;

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/quran_com_reciter_dao.dart';
import '../../../core/database/daos/reciter_dao.dart';
import 'mp3quran_api.dart';
import 'quran_com_api.dart';
import 'quran_com_reciter_mapping.dart';
import 'reciter_ru_names.dart';

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

/// Резолв URL суры через Quran.com CDN (Sprint 1.5).
///
/// Источник истины — [kMp3quranToQuranCom]. `null` если для mp3quran.id
/// нет маппинга (fallback на [resolveSurahUrl]).
String? resolveQuranComSurahUrl(int? mp3quranId, int surahNumber) {
  if (mp3quranId == null) return null;
  final m = kMp3quranToQuranCom[mp3quranId];
  if (m == null) return null;
  final surahStr = surahNumber.toString().padLeft(3, '0');
  // Per-surah URL — Quran.com тоже отдаёт per-surah (Alafasy/mp3/001.mp3
  // содержит все 7 аятов Surah 1). Для per-ayah см. resolveQuranComAyahUrl.
  return 'https://verses.quran.com/${m.path}/mp3/$surahStr.mp3';
}

/// Резолв URL конкретного аята (Sprint 1.5, Phase 2).
///
/// Per-ayah URL формат: `{reciter_path}/mp3/{SSSAYY}.mp3` где
/// SSS = 3-значный номер суры, AYY = 3-значный номер аята.
String? resolveQuranComAyahUrl(int? mp3quranId, int surahNumber, int ayahNumber) {
  if (mp3quranId == null) return null;
  final m = kMp3quranToQuranCom[mp3quranId];
  if (m == null) return null;
  final surahStr = surahNumber.toString().padLeft(3, '0');
  final ayahStr = ayahNumber.toString().padLeft(3, '0');
  return 'https://verses.quran.com/${m.path}/mp3/$surahStr$ayahStr.mp3';
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
  // Приоритет: ru (если он не «сломанный» — иначе fallback на en) → en → ar.
  if (isRu && (r.nameRu ?? '').isNotEmpty && !looksLikeBrokenRussian(r.nameRu!)) {
    return r.nameRu!;
  }
  if ((r.nameEn ?? '').isNotEmpty) return r.nameEn!;
  return r.nameAr;
}

/// Subtitle для UI: rewaya (если есть) — это и disambiguator для
/// ректоров с одинаковыми именами (например, разные
/// «Абдур-Рахман Ас-Судайс» с разными qira'at), и полезная
/// информация для знатоков. Fallback — арабское/английское имя.
/// В крайнем случае — slug.
String subtitleForReciter(Reciter r, String localeCode) {
  final display = displayNameForLocale(r, localeCode);
  // 1) Rewaya предпочитаем — это и disambiguator, и информация.
  final rewaya = shortRewaya(r.mp3quranRewaya);
  if (rewaya != null && rewaya.isNotEmpty) return rewaya;
  // 2) Арабское имя (на русской локали) — fallback для тех, кто
  //    распознаёт по письменности.
  if (localeCode.toLowerCase() == 'ru' &&
      r.nameAr.isNotEmpty &&
      r.nameAr != display) {
    return r.nameAr;
  }
  // 3) Английское имя.
  if (r.nameEn != null &&
      r.nameEn!.isNotEmpty &&
      r.nameEn != display &&
      localeCode.toLowerCase() != 'eng') {
    return r.nameEn!;
  }
  return r.slug;
}

/// Извлекает метку из `mp3quranRewaya` для подзаголовка picker'а.
///
/// Полная строка выглядит как
/// «Версия: Хафс от Асыма - Murattal» / «Rewayat Warsh A'n Nafi'
/// - Murattal» / «Версия: Варш от Нафиъ по цепочке Абу Бакра
/// аль-Асбахани - Murattal». Для picker'а хочется видеть
/// qira'a+rawn (Хафс от Асыма / Варш от Нафи'), но не длинные
/// цепочки передачи.
///
/// Возвращает:
///   * "Хафс от Асыма"        (qira'a + rawn)
///   * "Варш от Нафиъ"        (без «по цепочке...», обрезаем)
///   * "Warsh A'n Nafi'"      (англ. префикс)
///   * null                   (если rewaya не распарсили или null)
String? shortRewaya(String? rewaya) {
  if (rewaya == null || rewaya.isEmpty) return null;
  var s = rewaya;
  // 1) Снимаем префикс «Версия: » / «Rewayat ».
  const prefixRu = 'Версия: ';
  const prefixEn = 'Rewayat ';
  if (s.startsWith(prefixRu)) {
    s = s.substring(prefixRu.length);
  } else if (s.startsWith(prefixEn)) {
    s = s.substring(prefixEn.length);
  }
  // 2) Отрезаем хвост « - Murattal» / « - <style>» — это
  //    не disambiguator, а стиль чтения.
  final sep = s.lastIndexOf(' - ');
  if (sep > 0) {
    s = s.substring(0, sep);
  }
  // 3) Обрезаем длинные «хвосты» вида «по цепочке …» / «Men
  //    Tariq …» — для picker'а важнее qira'a+rawn, чем цепочка
  //    передачи. Можно открыть полную информацию через «rewaya»
  //    реп/страницу позже (Phase 2).
  final cutMarkers = [' по цепочке ', " Men Tariq ", ' - Men '];
  for (final m in cutMarkers) {
    final i = s.indexOf(m);
    if (i > 0) s = s.substring(0, i);
  }
  return s.trim();
}

/// Извлекает короткую метку **стиля** чтения из
/// `mp3quranRewaya` («Murattal», «Mujawwad», «Mu'allim» и т.п.)
/// для бейджа в UI. Полная строка выглядит как
/// «Версия: Хафс от Асыма - Murattal», стиль идёт **после
/// последнего** ` - `.
String? shortStyle(String? rewaya) {
  if (rewaya == null || rewaya.isEmpty) return null;
  final sep = rewaya.lastIndexOf(' - ');
  if (sep < 0) return null;
  final style = rewaya.substring(sep + 3).trim();
  if (style.isEmpty) return null;
  // Снимаем типовые суффиксы, оставляем только qira'a+rawn часть
  // в UI. Например «Версия Корана нараспев - Версия Корана нараспев» —
  // оба куска одинаковые, оставляем только один.
  return style;
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
  RecitersRepository(
    this._dao, {
    Mp3QuranApi? api,
    QuranComApi? quranComApi,
    QuranComReciterDao? quranComDao,
  })  : _api = api ?? Mp3QuranApi(),
        _quranComApi = quranComApi ?? QuranComApi(),
        _quranComDao = quranComDao;

  final ReciterDao _dao;
  final Mp3QuranApi _api;
  final QuranComApi _quranComApi;
  final QuranComReciterDao? _quranComDao;

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
      var ruName = d.nameByLocale['ru'];
      // 1. Проверяем ручной override (Russian Wikipedia + hand-curated)
      if (kReciterRuNames.containsKey(d.id)) {
        ruName = kReciterRuNames[d.id];
      }
      // 2. Проверяем, что русское имя не "сломанное" (например, "Мшари"
      //    без "и", или "Коран,Аудио,Библиотека,..." — мусор от id=256)
      if (ruName != null && looksLikeBrokenRussian(ruName)) {
        // Fallback на English transliteration (всегда корректна)
        ruName = enName;
      }
      await _dao.upsertWithMp3quranMultiLocale(
        reciterId: id,
        slug: 'mp3quran-${d.id}',
        nameAr: arName,
        nameRu: ruName ?? enName,
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

  /// Sync Quran.com recitations — Sprint 1.5.
  ///
  /// Дёргает `/api/v4/resources/recitations?language=ru` (multi-locale
  /// fallback ar+en+ru), для каждого результата ищет соответствующий
  /// mp3quran-id через [kMp3quranToQuranCom] и записывает в
  /// [QuranComReciters]. Reciters без mp3quran-аналога (Quran.com-only)
  /// сохраняются с `reciterId = "quran_com:N"`.
  ///
  /// Идемпотентно — повторный вызов перезаписывает `syncedAt` и
  /// обновляет `nameLocalized`.
  ///
  /// Возвращает количество синхронизированных записей. `0` если
  /// [QuranComReciterDao] не инициализирован (опциональная зависимость).
  Future<int> syncQuranComFromApi({
    List<String> languages = const ['ru', 'en', 'ar'],
  }) async {
    if (_quranComDao == null) return 0;
    final merged = await _quranComApi.fetchRecitationsMultiLocale(
      languages: languages,
    );
    final now = DateTime.now();
    var inserted = 0;
    // Map Quran.com id → (mp3quranId, path) для обратной ссылки.
    final quranComToMp3quran = <int, int>{};
    kMp3quranToQuranCom.forEach((mp3quranId, m) {
      quranComToMp3quran[m.quranComId] = mp3quranId;
    });

    final upserts = <QuranComReciterDaoUpsert>[];
    for (final entry in merged.entries) {
      final qcId = entry.key;
      final d = entry.value;
      // Лучший ID для cross-reference с Reciters: mp3quranId
      // (если есть), иначе quran_com:N.
      final mp3quranId = quranComToMp3quran[qcId];
      final reciterId = mp3quranId != null
          ? 'mp3quran:$mp3quranId'
          : 'quran_com:$qcId';
      final ruName = d.nameByLocale['ru'] ?? d.translatedName;
      upserts.add(
        QuranComReciterDaoUpsert(
          reciterId: reciterId,
          quranComId: qcId,
          path: d.path ?? '',
          style: d.style,
          nameLocalized: ruName,
        ),
      );
      inserted += 1;
    }
    await _quranComDao!.upsertAll(upserts);
    developer.log(
      'quran_com sync: $inserted reciters',
      name: 'reciters_repo',
    );
    return inserted;
  }

  /// Hybrid resolve: предпочитает Quran.com если запись есть, иначе
  /// fallback на mp3quran CDN.
  String? resolveSurahUrlHybrid(Reciter reciter, int surahNumber) {
    // Не делаем асинхронный lookup здесь — UI поток не должен ждать.
    // Static mapping — primary, table — secondary (через кэш).
    // TODO(Sprint 2): переписать через AsyncValue/FutureProvider.
    return resolveQuranComSurahUrl(reciter.mp3quranId, surahNumber) ??
        resolveSurahUrl(reciter, surahNumber);
  }

  /// Стрим избранных.
  Stream<List<Reciter>> watchFavorites() => _dao.watchFavorites();

  Future<Reciter?> getById(String id) => _dao.getById(id);

  /// Установить/снять отметку избранного.
  Future<void> setFavorite(String reciterId, bool isFavorite) =>
      _dao.setFavorite(reciterId, isFavorite);

  Future<DateTime?> latestMp3quranSync() => _dao.latestMp3quranSync();
  Future<int> countRecitersWithoutMp3quranInfo() =>
      _dao.countRecitersWithoutMp3quranInfo();

  /// Применяет ручной override + fallback на nameEn для «сломанных»
  /// русских имён. Используется после [syncFromApi] и в качестве
  /// самостоятельной операции fix-up при старте.
  ///
  /// Возвращает количество исправленных строк.
  Future<int> applyNameOverrides() async {
    final all = await _dao.getAll();
    var fixed = 0;
    for (final r in all) {
      final id = r.mp3quranId;
      if (id == null) continue;
      // 1. Приоритет — ручной override из kReciterRuNames.
      final override = kReciterRuNames[id];
      String? newName;
      if (override != null) {
        newName = override;
      } else if (looksLikeBrokenRussian(r.nameRu ?? '')) {
        // 2. Fallback на nameEn, если русский «сломанный» (мусор от
        //    mp3quran: «Мшари» без «и», или «Коран,Аудио,Библиотека,...»).
        newName = r.nameEn;
      }
      if (newName != null && newName != r.nameRu) {
        await _dao.updateNameRu(r.id, newName);
        fixed += 1;
      }
    }
    return fixed;
  }
}