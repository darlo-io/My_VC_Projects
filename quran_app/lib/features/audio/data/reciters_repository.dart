import '../../../core/database/app_database.dart';
import '../../../core/database/daos/reciter_dao.dart';

/// Описание ректора для засева в БД. CDN-шаблон содержит `{surah}`,
/// который подставляется в URL при запросе файла.
class ReciterSeed {
  const ReciterSeed({
    required this.id,
    required this.slug,
    required this.nameAr,
    required this.nameEn,
    required this.style,
    required this.cdnTemplate,
  });

  final String id;
  final String slug;
  final String nameAr;
  final String nameEn;
  final String style; // 'murattal' | 'mujawwad'
  final String cdnTemplate; // например:
  // "https://cdn.islamic.network/quran/audio-surah/128/{id}/{surah}.mp3"
}

/// Дефолтный список ректоров (популярные, открытые CDN).
/// Расширяется по мере добавления ректоров в UI выбора.
const kDefaultReciters = <ReciterSeed>[
  ReciterSeed(
    id: 'ar.alafasy',
    slug: 'mishari',
    nameAr: 'مشاري بن راشد العفاسي',
    nameEn: 'Mishary Rashid Alafasy',
    style: 'murattal',
    cdnTemplate:
        'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy/{surah}.mp3',
  ),
  ReciterSeed(
    id: 'ar.abdulbasitmurattal',
    slug: 'abdul_basit',
    nameAr: 'عبد الباسط عبد الصمد',
    nameEn: 'Abdul Basit Abdul Samad',
    style: 'murattal',
    cdnTemplate:
        'https://cdn.islamic.network/quran/audio-surah/128/ar.abdulbasitmurattal/{surah}.mp3',
  ),
  ReciterSeed(
    id: 'ar.husary',
    slug: 'husary',
    nameAr: 'محمود خليل الحصري',
    nameEn: 'Mahmoud Khalil Al-Husary',
    style: 'murattal',
    cdnTemplate:
        'https://cdn.islamic.network/quran/audio-surah/128/ar.husary/{surah}.mp3',
  ),
  ReciterSeed(
    id: 'ar.minshawi',
    slug: 'minshawi',
    nameAr: 'محمد صديق المنشاوي',
    nameEn: 'Mohamed Siddiq Al-Minshawi',
    style: 'murattal',
    cdnTemplate:
        'https://cdn.islamic.network/quran/audio-surah/128/ar.minshawi/{surah}.mp3',
  ),
  ReciterSeed(
    id: 'ar.abdurrahmaansudais',
    slug: 'sudais',
    nameAr: 'عبد الرحمن السديس',
    nameEn: 'Abdul Rahman Al-Sudais',
    style: 'murattal',
    cdnTemplate:
        'https://cdn.islamic.network/quran/audio-surah/128/ar.abdurrahmaansudais/{surah}.mp3',
  ),
  ReciterSeed(
    id: 'ar.saaborimadina',
    slug: 'saabori',
    nameAr: 'سعود الشريم',
    nameEn: 'Saud Al-Shuraim',
    style: 'murattal',
    cdnTemplate:
        'https://cdn.islamic.network/quran/audio-surah/128/ar.saaborimadina/{surah}.mp3',
  ),
  ReciterSeed(
    id: 'ar.hudhaify',
    slug: 'hudhaify',
    nameAr: 'علي عبد الله جابر',
    nameEn: 'Ali Al-Hudhaify',
    style: 'murattal',
    cdnTemplate:
        'https://cdn.islamic.network/quran/audio-surah/128/ar.hudhaify/{surah}.mp3',
  ),
  ReciterSeed(
    id: 'ar.ahmedajamy',
    slug: 'ahmed_ajamy',
    nameAr: 'أحمد بن علي العجمي',
    nameEn: 'Ahmed Al-Ajamy',
    style: 'mujawwad',
    cdnTemplate:
        'https://cdn.islamic.network/quran/audio-surah/128/ar.ahmedajamy/{surah}.mp3',
  ),
];

/// Разрешает URL конкретной суры у данного ректора.
String resolveAudioUrl(Reciter reciter, int surahNumber) {
  return reciter.id // используем cdnTemplate, зашитый в id
      // (см. kDefaultReciters) — для MVP шаблон хранится не в БД,
      // а вшит в [ReciterSeed]. Здесь мы восстанавливаем URL по id.
      .let((_) => _resolveFromId(reciter.id, surahNumber));
}

String _resolveFromId(String reciterId, int surah) {
  final surahStr = surah.toString().padLeft(3, '0');
  return 'https://cdn.islamic.network/quran/audio-surah/128/'
      '$reciterId/$surahStr.mp3';
}

extension _Let<T> on T {
  R let<R>(R Function(T) f) => f(this);
}

/// Репозиторий ректоров. На первом запуске сеет таблицу дефолтным списком.
class RecitersRepository {
  RecitersRepository(this._dao);

  final ReciterDao _dao;

  /// Идемпотентный seed: если в таблице уже есть записи — no-op.
  Future<void> ensureSeeded() async {
    final existing = await _dao.count();
    if (existing > 0) return;
    await _dao.insertAll(
      kDefaultReciters
          .map(
            (r) => RecitersCompanion.insert(
              id: r.id,
              slug: r.slug,
              nameAr: r.nameAr,
              nameEn: r.nameEn,
              style: r.style,
            ),
          )
          .toList(),
    );
  }

  Stream<List<Reciter>> watchAll() => _dao.watchAll();
  Future<Reciter?> getById(String id) => _dao.getById(id);
  Future<List<Reciter>> getAll() => _dao.getAll();
}
