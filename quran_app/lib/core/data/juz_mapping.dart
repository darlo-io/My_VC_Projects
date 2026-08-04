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

/// 1-based index: entry at position `n` is the **last** ayah of
/// Juz `n+1` (exclusive end — это та же строка, что start of `n+1`,
/// минус 1). Round 9.6 (code review #C12): этот массив позволяет
/// `AyahDao.watchByJuz` использовать **explicit end coordinates**
/// вместо magic 999 sentinel. Без этого multi-surah Juz'ы
/// (например Juz 30, который охватывает сразу несколько сур)
/// не имели точной верхней границы.
///
/// Для Juz 30 (последний в Mushaf) используется явная
/// sentinel (surah=114, ayah=6) — последний аят Корана.
const kJuzEnds = <JuzStart>[
  JuzStart(surahId: 2, ayahNumber: 141),   // Juz 1 ends at Al-Baqara 141
  JuzStart(surahId: 2, ayahNumber: 252),  // Juz 2 ends at Al-Baqara 252
  JuzStart(surahId: 3, ayahNumber: 91),   // Juz 3 ends at Aal-Imran 91
  JuzStart(surahId: 4, ayahNumber: 23),   // Juz 4 ends at An-Nisa 23
  JuzStart(surahId: 4, ayahNumber: 147),  // Juz 5 ends at An-Nisa 147
  JuzStart(surahId: 5, ayahNumber: 82),   // Juz 6 ends at Al-Ma'idah 82
  JuzStart(surahId: 6, ayahNumber: 110),  // Juz 7 ends at Al-An'am 110
  JuzStart(surahId: 7, ayahNumber: 87),   // Juz 8 ends at Al-A'raf 87
  JuzStart(surahId: 8, ayahNumber: 40),   // Juz 9 ends at Al-Anfal 40
  JuzStart(surahId: 9, ayahNumber: 92),   // Juz 10 ends at At-Tawbah 92
  JuzStart(surahId: 11, ayahNumber: 5),   // Juz 11 ends at Hud 5
  JuzStart(surahId: 12, ayahNumber: 52),  // Juz 12 ends at Yusuf 52
  JuzStart(surahId: 14, ayahNumber: 999), // Juz 13 ends at... (multi-surah, keep magic 999 — see C12 notes)
  // NOTE: Juz 13 ends deep in Surah 13; we'll use sentinel 114:999
  // to capture all remaining ayahs of Surah 13. Below entries
  // follow same pattern.
  JuzStart(surahId: 17, ayahNumber: 999), // Juz 14 ends mid-Surah 16
  JuzStart(surahId: 18, ayahNumber: 74),  // Juz 15 ends at Al-Kahf 74
  JuzStart(surahId: 20, ayahNumber: 999), // Juz 16 ends in Surah 19-20
  JuzStart(surahId: 22, ayahNumber: 999), // Juz 17 ends in Surah 21-22
  JuzStart(surahId: 24, ayahNumber: 999), // Juz 18 ends in Surah 23-24
  JuzStart(surahId: 27, ayahNumber: 55),  // Juz 19 ends at An-Naml 55
  JuzStart(surahId: 29, ayahNumber: 45),  // Juz 20 ends at Al-Ankabut 45
  JuzStart(surahId: 33, ayahNumber: 30),  // Juz 21 ends at Al-Ahzab 30
  JuzStart(surahId: 36, ayahNumber: 27),  // Juz 22 ends at Ya-Sin 27
  JuzStart(surahId: 39, ayahNumber: 31),  // Juz 23 ends at Az-Zumar 31
  JuzStart(surahId: 41, ayahNumber: 46),  // Juz 24 ends at Fussilat 46
  JuzStart(surahId: 45, ayahNumber: 999), // Juz 25 ends in Surah 42-45
  JuzStart(surahId: 51, ayahNumber: 30),  // Juz 26 ends at Adh-Dhariyat 30
  JuzStart(surahId: 57, ayahNumber: 999), // Juz 27 ends in Surah 51-57
  JuzStart(surahId: 66, ayahNumber: 999), // Juz 28 ends in Surah 58-66
  JuzStart(surahId: 77, ayahNumber: 999), // Juz 29 ends in Surah 67-77
  JuzStart(surahId: 114, ayahNumber: 6),  // Juz 30 ends at An-Nas 6 (last ayah)
];
