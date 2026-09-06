/// Маппинг mp3quran.id → relative path на QuranAudio CDN
/// (quranicaudio.com) для **per-surah** файлов.
///
/// Зачем не Quran.com: verses.quran.com отдаёт только per-AYAH файлы
/// (`{path}/mp3/{sssnnn}.mp3` — проверено 2026-08-25, 200); per-surah
/// (`{path}/mp3/{NNN}.mp3`) не существует — 404 на всех путях. А
/// плеер приложения играет целые суры (один MP3 + seek по offset).
///
/// Quranicaudio.com: один MP3 на суру (`{path}/{NNN}.mp3`), 177
/// ректоров через `GET https://quranicaudio.com/api/qaris`
/// (`relative_path`). Проверка 2026-08-25: все пути ниже → 200.
///
/// Источник истины имён/серверов — БД устройства (таблица reciters,
/// sync из mp3quran API); id стабильны. Отсутствие записи = нет
/// уверенного соответствия риваи/имени (напр. mp3quran:118 — Husary
/// Qalon, у quranicaudio только Hafs) → кандидат пропускается,
/// играет mp3quran.net.
const String kQuranAudioCdnBase = 'https://download.quranicaudio.com/quran';

/// mp3quranId → quranicaudio relative_path (без слэшей по краям).
const Map<int, String> kMp3quranToQuranAudio = {
  4: 'abu_bakr_ash-shaatree', // Абу Бакр Аш-Шатри
  5: 'rifai', // Хани Ар-Рифайи
  6: 'mahmood_khaleel_al-husaree', // Хусари (Hafs)
  9: 'yasser_ad-dussary', // Ясир Ад-Даусари
  31: 'sa3ood_al-shuraym', // Сауд Аш-Шурайм
  51: 'abdul_basit_murattal', // Абдуль-Басит [Murattal]
  54: 'abdurrahmaan_as-sudays', // Судайс
  74: 'huthayfi', // Аль-Худайфи
  112: 'muhammad_siddeeq_al-minshaawee', // Миншави
  123: 'mishaari_raashid_al_3afaasee', // Аль-Афаси
};

/// Per-surah URL на QuranAudio CDN: `{base}/{path}/{NNN}.mp3`.
String? resolveQuranAudioSurahUrl(int? mp3quranId, int surahNumber) {
  if (mp3quranId == null) return null;
  final path = kMp3quranToQuranAudio[mp3quranId];
  if (path == null) return null;
  final surahStr = surahNumber.toString().padLeft(3, '0');
  return '$kQuranAudioCdnBase/$path/$surahStr.mp3';
}
