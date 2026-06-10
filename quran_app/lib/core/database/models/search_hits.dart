/// Облегчённые projections, которые DAO отдают наружу. Живут здесь
/// (а не рядом с DAO), чтобы UI/repos могли импортировать типы
/// результата без захода в `daos/...` (которые импортируют
/// `app_database.dart` → cycle).
library;

class SurahSearchHit {
  const SurahSearchHit({
    required this.surahId,
    required this.nameAr,
    required this.nameEn,
    required this.nameTransliteration,
  });

  final int surahId;
  final String nameAr;
  final String nameEn;
  final String nameTransliteration;
}

class AyahSearchHit {
  const AyahSearchHit({
    required this.ayahId,
    required this.surahId,
    required this.ayahNumber,
    required this.surahNameAr,
    required this.textUthmani,
    required this.textNormalized,
  });

  final int ayahId;
  final int surahId;
  final int ayahNumber;
  final String surahNameAr;
  final String textUthmani;
  final String textNormalized;
}

class TranslationSearchHit {
  const TranslationSearchHit({
    required this.ayahId,
    required this.surahId,
    required this.ayahNumber,
    required this.surahNameAr,
    required this.text,
    required this.translatorName,
  });

  final int ayahId;
  final int surahId;
  final int ayahNumber;
  final String surahNameAr;
  final String text;
  final String translatorName;
}

class WordSearchHit {
  const WordSearchHit({
    required this.wordId,
    required this.surahId,
    required this.ayahNumber,
    required this.position,
    required this.arabic,
    required this.normalized,
    this.translation,
    this.lemma,
    this.root,
  });

  final int wordId;
  final int surahId;
  final int ayahNumber;
  final int position;
  final String arabic;
  final String normalized;
  final String? translation;
  final String? lemma;
  final String? root;
}
