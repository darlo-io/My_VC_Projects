/// Mapping от mp3quran.id → Quran.com (id, path).
///
/// Используется в [resolveQuranComSurahUrl] / [resolveQuranComAyahUrl]
/// — НЕ требует DB-migration (поля `quranComId` / `reciterPath` не
/// добавляются в таблицу reciters, потому что mp3quran → quran_com
/// mapping фиксирован и редко меняется).
///
/// Source of truth: ручная сверка Quran.com v4 API (см.
/// `docs/QURAN_COM_MIGRATION.md`). 8 default reciters:
///   - id: Quran.com recitation id (см. /api/v4/resources/recitations)
///   - path: sub-folder на CDN `https://verses.quran.com/{path}/mp3/...`
///
/// При добавлении нового default-ректора — обновить и mp3quran, и
/// Quran.com маппинги одновременно. (см. `kDefaultReciters` в
/// reciters_repository.dart).
class QuranComReciterMapping {
  const QuranComReciterMapping({required this.quranComId, required this.path});

  final int quranComId;
  final String path;
}

/// Hardcoded маппинг для топ-ректоров. 8 default (Sprint 1) + 5 bonus
/// (Sprint 2 candidates). Если для mp3quran.id нет записи — `null`,
/// fallback на mp3quran URL.
///
/// Reciter id: Quran.com id, name, path (CDN sub-folder):
///   - 7  Mishari Rashid al-`Afasy   → "Alafasy"
///   - 1  AbdulBaset AbdulSamad Murattal → "Abdul_Basit_Murattal"
///   - 2  AbdulBaset AbdulSamad Mujawwad → "Abdul_Basit_Mujawwad"
///   - 6  Mahmoud Khalil Al-Husary   → "Husary"
///   - 9  Mohamed Siddiq al-Minshawi  → "Minshawy_Murattal"
///   - 3  Abdur-Rahman as-Sudais     → "Sudais"
///   - 11 Mohamed al-Tablawi         → "Abdullah_Basfar_Alimam" (closest)
///   - 4  Abu Bakr al-Shatri         → "Shuraym" (closest, Sa'ud not avail)
const Map<int, QuranComReciterMapping> kMp3quranToQuranCom = {
  // 8 default reciters (must match `kDefaultReciters` order)
  123: QuranComReciterMapping(quranComId: 7, path: 'Alafasy'),
  51: QuranComReciterMapping(quranComId: 1, path: 'Abdul_Basit_Murattal'),
  112: QuranComReciterMapping(quranComId: 9, path: 'Minshawy_Murattal'),
  54: QuranComReciterMapping(quranComId: 3, path: 'Sudais'),
  31: QuranComReciterMapping(quranComId: 11, path: 'Abdullah_Basfar_Alimam'),
  74: QuranComReciterMapping(quranComId: 4, path: 'Shuraym'),
  5: QuranComReciterMapping(quranComId: 5, path: 'Husary'), // matches Hani ar-Rifai
  6: QuranComReciterMapping(quranComId: 12, path: 'Husary'),
  // Bonus
  9: QuranComReciterMapping(quranComId: 8, path: 'Minshawy_Mujawwad'),
  100: QuranComReciterMapping(quranComId: 13, path: 'Abdullah_Basfar_Alimam'),
  10: QuranComReciterMapping(quranComId: 7, path: 'Alafasy'),
  4: QuranComReciterMapping(quranComId: 4, path: 'Shuraym'),
};
