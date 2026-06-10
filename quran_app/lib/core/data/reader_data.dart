import '../database/app_database.dart';

/// DTO, который объединяет (Surah + translations-by-ayahId).
/// Виджет [ReaderScreen] целиком зависит только от этого объекта —
/// никакой прямой работы с [SurahDao] / [TranslationDao] в build().
class ReaderData {
  const ReaderData({required this.surah, required this.translations});
  const ReaderData.empty()
      : surah = null,
        translations = const {};

  final Surah? surah;

  /// `ayahId -> translation text` для **всех** аятов суры. Если у
  /// аята нет перевода на текущем языке — запись отсутствует (UI
  /// показывает fallback).
  final Map<int, String> translations;
}
