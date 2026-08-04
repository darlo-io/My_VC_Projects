import 'package:meta/meta.dart';

/// Forward-compat tag для `just_audio` `setFilePath(tag: ...)` /
/// `currentTag`, доступный начиная с `just_audio` 0.10.x.
///
/// **На 2026-07-31 не используется**: проект пинит
/// `just_audio: ^0.9.42` (см. `pubspec.yaml`). В 0.9.42 нет ни
/// параметра `tag:` в `setFilePath`, ни геттера `_player.currentTag`
/// — добавлять их в вызов при сборке на 0.9.42 нельзя
/// (compile error, не runtime-mismatch).
///
/// Этот класс оставлен как маркер миграции для Phase 3
/// (word-timing highlight, см. AGENTS.md):
///   1. Когда апгрейдимся на `just_audio: ^0.10.x` — раскомментируем
///      `tag:` в `_playSurahMp3Quran` (см. закомментированный код
///      ниже) и добавляем геттер `currentTag` в `AudioPlayerController`.
///   2. Сейчас обёртки `(reciterId, surahId)` нет ни в одном
///      consumer-коде — добавится одновременно с word-timing loader.
///
/// Шаблон использования (для справки, не активен сейчас):
///
/// ```dart
/// await _player.setFilePath(
///   file.path,
///   tag: MediaItemTag(reciterId: reciter.id, surahId: surah.id),
/// );
/// // … позже из любого места:
/// final t = _player.currentTag;
/// if (t is MediaItemTag) { … }
/// ```
@immutable
class MediaItemTag {
  const MediaItemTag({
    required this.reciterId,
    required this.surahId,
    this.ayahStart,
  });

  /// Recursive id ректора (`ar.alafasy`, `ar.abdulbasitmurattal`, или
  /// `mp3quran:<id>` для синонимов из `RecitersSyncService`).
  final String reciterId;

  /// Глобальный номер суры 1..114.
  final int surahId;

  /// Номер аята, с которого начать (Phase 3 — стартовая точка
  /// word-timing lookup). `null` = с начала суры.
  final int? ayahStart;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItemTag &&
          other.reciterId == reciterId &&
          other.surahId == surahId &&
          other.ayahStart == ayahStart);

  @override
  int get hashCode => Object.hash(reciterId, surahId, ayahStart);

  @override
  String toString() =>
      'MediaItemTag(reciter=$reciterId, surah=$surahId, ayahStart=$ayahStart)';
}
