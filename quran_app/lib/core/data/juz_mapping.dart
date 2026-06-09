/// Maps a 1-based Juz number to the (surah, ayah) where that Juz
/// starts in the Madinah Mushaf (the standard Hafs reading used by
/// the quran.com API we seed from).
///
/// The Mushaf does not split at surah boundaries: a Juz typically
/// starts somewhere mid-surah (e.g. Juz 3 begins at Al-Baqara 253).
/// We use these coordinates as the deep-link target when the user
/// taps a Juz tile on the reader's home screen, so they land at
/// the first ayah of their chosen Juz.
///
/// Coordinates verified against the standard Madinah Mushaf layout
/// (KFUPM / quran.com). When the seed grows `Ayahs.juz` data, this
/// table can be retired in favour of a `WHERE juz = ?` query.
///
/// Lives in `lib/core/data/` rather than under `lib/features/`
/// because the data is shared between the DAO layer (used to
/// backfill the `Ayahs.juz` column at create / migration time)
/// and the reader / Juz-picker UI.
class JuzStart {
  const JuzStart({required this.surahId, required this.ayahNumber});
  final int surahId;
  final int ayahNumber;
}

/// 1-based index: entry at position `n` is the start of Juz `n+1`.
const kJuzStarts = <JuzStart>[
  JuzStart(surahId: 1, ayahNumber: 1),    // Juz 1 — Al-Fatiha 1
  JuzStart(surahId: 2, ayahNumber: 142),  // Juz 2 — Al-Baqara 142
  JuzStart(surahId: 2, ayahNumber: 253),  // Juz 3 — Al-Baqara 253
  JuzStart(surahId: 3, ayahNumber: 92),   // Juz 4 — Aal-Imran 92
  JuzStart(surahId: 4, ayahNumber: 24),   // Juz 5 — An-Nisa 24
  JuzStart(surahId: 4, ayahNumber: 148),  // Juz 6 — An-Nisa 148
  JuzStart(surahId: 5, ayahNumber: 83),   // Juz 7 — Al-Ma'idah 83
  JuzStart(surahId: 6, ayahNumber: 111),  // Juz 8 — Al-An'am 111
  JuzStart(surahId: 7, ayahNumber: 88),   // Juz 9 — Al-A'raf 88
  JuzStart(surahId: 8, ayahNumber: 41),   // Juz 10 — Al-Anfal 41
  JuzStart(surahId: 9, ayahNumber: 93),   // Juz 11 — At-Tawbah 93
  JuzStart(surahId: 11, ayahNumber: 6),   // Juz 12 — Hud 6
  JuzStart(surahId: 12, ayahNumber: 53),  // Juz 13 — Yusuf 53
  JuzStart(surahId: 15, ayahNumber: 1),   // Juz 14 — Al-Hijr 1
  JuzStart(surahId: 17, ayahNumber: 1),   // Juz 15 — Al-Isra 1
  JuzStart(surahId: 18, ayahNumber: 75),  // Juz 16 — Al-Kahf 75
  JuzStart(surahId: 21, ayahNumber: 1),   // Juz 17 — Al-Anbiya 1
  JuzStart(surahId: 23, ayahNumber: 1),   // Juz 18 — Al-Mu'minun 1
  JuzStart(surahId: 25, ayahNumber: 21),  // Juz 19 — Al-Furqan 21
  JuzStart(surahId: 27, ayahNumber: 56),  // Juz 20 — An-Naml 56
  JuzStart(surahId: 29, ayahNumber: 46),  // Juz 21 — Al-Ankabut 46
  JuzStart(surahId: 33, ayahNumber: 31),  // Juz 22 — Al-Ahzab 31
  JuzStart(surahId: 36, ayahNumber: 28),  // Juz 23 — Ya-Sin 28
  JuzStart(surahId: 39, ayahNumber: 32),  // Juz 24 — Az-Zumar 32
  JuzStart(surahId: 41, ayahNumber: 47),  // Juz 25 — Fussilat 47
  JuzStart(surahId: 46, ayahNumber: 1),   // Juz 26 — Al-Ahqaf 1
  JuzStart(surahId: 51, ayahNumber: 31),  // Juz 27 — Adh-Dhariyat 31
  JuzStart(surahId: 58, ayahNumber: 1),   // Juz 28 — Al-Mujadilah 1
  JuzStart(surahId: 67, ayahNumber: 1),   // Juz 29 — Al-Mulk 1
  JuzStart(surahId: 78, ayahNumber: 1),   // Juz 30 — An-Naba 1
];

/// Look up where the [juzNumber]-th Juz starts. Returns Juz 1
/// (Al-Fatiha 1) if `juzNumber` is out of range, so callers can
/// use the result without a null check.
JuzStart juzStart(int juzNumber) {
  if (juzNumber < 1 || juzNumber > kJuzStarts.length) {
    return kJuzStarts.first;
  }
  return kJuzStarts[juzNumber - 1];
}
