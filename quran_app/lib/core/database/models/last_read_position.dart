/// Snapshot of the user's most recent reading position, enriched
/// with the surrounding surah metadata so the home screen can
/// render "Continue reading" without a second round-trip to the
/// database.
///
/// Produced by [PositionDao.watchLastWithSurah]. The view is
/// intentionally read-only: the DAO is the single source of truth
/// for how the position is computed and persisted.
class LastReadPosition {
  const LastReadPosition({
    required this.surahId,
    required this.surahName,
    required this.ayahNumber,
    required this.progress,
    this.ayahCount = 0,
  });

  /// Empty snapshot (no recorded position yet). The home screen
  /// substitutes the localized fallback via
  /// `t.homeFallbackSurahName` when this is emitted. The
  /// `progress` is 0.0 by construction; `surahName` is the empty
  /// string so the UI doesn't render a stale label.
  const LastReadPosition.empty()
      : surahId = 0,
        surahName = '',
        ayahNumber = 0,
        progress = 0.0,
        ayahCount = 0;

  /// 1-based surah number, or 0 for the empty snapshot.
  final int surahId;

  /// Latin transliteration (e.g. "Al-Baqara") for the surah this
  /// position belongs to. Empty for the empty snapshot.
  final String surahName;

  /// 1-based ayah number within the surah, or 0 for the empty
  /// snapshot.
  final int ayahNumber;

  /// Reading progress in `[0.0, 1.0]`, computed as
  /// `ayahNumber / surah.ayahCount`. 0.0 for the empty snapshot or
  /// when the surah's `ayahCount` is missing.
  final double progress;

  /// Total number of ayahs in the surah. 0 for the empty snapshot
  /// or when the surah's `ayahCount` is missing.
  ///
  /// **Зачем**: `progress` — это double, и при `ayahNumber / ayahCount`
  /// даже для **полностью** прочитанной суры результат может быть
  /// `0.9999999999999999` (из-за floating-point неточностей
  /// integer-division → double), а не ровно `1.0`. Это приводит
  /// к тому, что условие `last.progress < 1.0` на главной
  /// срабатывает как `true`, и панель «Продолжить чтение»
  /// показывается **даже после прочтения всей суры**.
  ///
  /// Используйте [isCompleted] вместо сравнения `progress < 1.0`
  /// для надёжной проверки.
  final int ayahCount;

  /// True, если пользователь дочитал суру до конца
  /// (`ayahNumber >= ayahCount`).
  ///
  /// Используется на главной вместо `progress < 1.0` для
  /// корректного скрытия «Продолжить чтение» после прочтения.
  bool get isCompleted => ayahCount > 0 && ayahNumber >= ayahCount;
}
