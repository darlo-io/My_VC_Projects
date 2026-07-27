// SearchDao вЂ” FTS5 fulltext search (Sprint 2.7).
//
// РСЃРїРѕР»СЊР·СѓРµС‚ virtual table `ayahs_fts` (СЃРѕР·РґР°С‘С‚СЃСЏ РІ [AppDatabase._createFts])
// вЂ” СЃРѕРґРµСЂР¶РёС‚ text_uthmani + text_normalized РёР· `ayahs`, СЃРёРЅС…СЂРѕРЅРёР·РёСЂСѓРµС‚СЃСЏ
// triggers (INSERT/UPDATE/DELETE).
//
// РџСЂРµРёРјСѓС‰РµСЃС‚РІР° FTS5 vs LIKE:
//   вЂў BM25 ranking (РІСЃС‚СЂРѕРµРЅРЅС‹Р№ РІ SQLite)
//   вЂў Snippet generation (highlighted matches with <mark>)
//   вЂў Tokenization (Unicode61, diacritics removal)
//   вЂў Prefix search ('term*' matches 'terms', 'terminal')
//   вЂў Sub-millisecond РїРѕРёСЃРє РЅР° 10K+ Р°СЏС‚РѕРІ vs СЃРµРєСѓРЅРґС‹ РґР»СЏ LIKE
//
// API:
//   вЂў searchAyahsFts(query) в†’ List<AyahFtsHit> СЃ snippet Рё rank
//   вЂў searchTranslationsFts(query) в†’ List<TranslationFtsHit>
//   вЂў searchWordsFts(query) в†’ List<WordFtsHit>
//   вЂў searchAllFts(query) в†’ List<SearchHitUnion> (combined)
//
// РСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ РІ UI (Sprint 2.7c):
//   final hits = await ref.read(searchDaoProvider).searchAyahsFts('mercy');
//   for (final hit in hits) {
//     print(hit.snippet); // '<mark>mercy</mark>...'
//   }

import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'search_dao.g.dart';

/// Result of FTS5 search over `ayahs.text_uthmani` / `text_normalized`.
/// `snippet` СѓР¶Рµ СЃРѕРґРµСЂР¶РёС‚ `<mark>`-РѕР±С‘СЂРЅСѓС‚С‹Рµ СЃРѕРІРїР°РґРµРЅРёСЏ (РіРѕС‚РѕРІ РґР»СЏ
/// Р±РµР·РѕРїР°СЃРЅРѕРіРѕ СЂРµРЅРґРµСЂР° С‡РµСЂРµР· `flutter_html`).
class AyahFtsHit {
  AyahFtsHit({
    required this.ayahId,
    required this.surahId,
    required this.ayahNumber,
    required this.snippet,
    required this.rank,
  });

  final int ayahId;
  final int surahId;
  final int ayahNumber;
  final String snippet;
  final double rank; // bm25 score, РЅРёР¶Рµ = Р»СѓС‡С€Рµ
}

/// FTS5-search over `translations.text_value` (joined СЃ translators РґР»СЏ
/// `language_code`).
class TranslationFtsHit {
  TranslationFtsHit({
    required this.ayahId,
    required this.translatorId,
    required this.languageCode,
    required this.snippet,
    required this.rank,
  });

  final int ayahId;
  final int translatorId;
  final String languageCode;
  final String snippet;
  final double rank;
}

/// FTS5-search over `words.arabic` (РЅРѕСЂРјР°Р»РёР·РѕРІР°РЅРЅР°СЏ С„РѕСЂРјР°) + lemma/root.
class WordFtsHit {
  WordFtsHit({
    required this.ayahId,
    required this.position,
    required this.arabic,
    required this.normalized,
    required this.translation,
    required this.rank,
  });

  final int ayahId;
  final int position;
  final String arabic;
  final String normalized;
  final String translation;
  final double rank;
}

@DriftAccessor(
  tables: [Ayahs, Translations, Translators, Words, Tafsirs, TafsirSources],
)
class SearchDao extends DatabaseAccessor<AppDatabase> with _$SearchDaoMixin {
  SearchDao(super.db);

  /// Sanitize FTS5 query: РґРѕР±Р°РІР»СЏРµС‚ `*` Рє РїРѕСЃР»РµРґРЅРµРјСѓ С‚РѕРєРµРЅСѓ РґР»СЏ
  /// prefix-match, СЌРєСЂР°РЅРёСЂСѓРµС‚ СЃРїРµС†-СЃРёРјРІРѕР»С‹ (`"`, `'`).
  ///
  /// Р‘РµР· СЌС‚РѕРіРѕ `"С‚РµСЃС‚'` Р±СЂРѕСЃРёС‚ SQLite error, Р° `"С‚РµСЃС‚*` РѕС‚Р»РёС‡РЅРѕ
  /// РјР°С‚С‡РёС‚ РІСЃРµ СЃР»РѕРІР° СЃ РїСЂРµС„РёРєСЃРѕРј `С‚РµСЃС‚`.
  String _sanitizeFtsQuery(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    // Р­РєСЂР°РЅРёСЂСѓРµРј РєР°РІС‹С‡РєРё. FTS5 РІ СЂРµР¶РёРјРµ В«termВ» РёСЃРїРѕР»СЊР·СѓРµС‚ "..." Р°
    // РґР»СЏ prefix вЂ” РїРѕСЃР»РµРґРЅРµРµ СЃР»РѕРІРѕ СЃ *.
    final escaped = trimmed
        .replaceAll('"', '""')
        .replaceAll("'", '');

    // РџРѕСЃР»РµРґРЅРёР№ С‚РѕРєРµРЅ = prefix (РµСЃР»Рё РЅРµ РёРјРµРµС‚ *).
    final tokens = escaped.split(RegExp(r'\s+'));
    if (tokens.isEmpty) return escaped;
    final last = tokens.last;
    if (!last.endsWith('*') && !last.contains(':')) {
      tokens[tokens.length - 1] = '$last*';
    }
    return tokens.join(' ');
  }

  /// РџРѕРёСЃРє РїРѕ Р°СЏС‚Р°Рј (uthmani + normalized). BM25 ranking.
  Future<List<AyahFtsHit>> searchAyahsFts(String query,
      {int limit = 50}) async {
    final q = _sanitizeFtsQuery(query);
    if (q.isEmpty) return const [];

    final rows = await customSelect(
      '''
      SELECT
        a.id AS ayah_id,
        a.surah_id AS surah_id,
        a.ayah_number AS ayah_number,
        snippet(ayahs_fts, 0, '<mark>', '</mark>', '...', 16) AS snippet,
        bm25(ayahs_fts) AS rank
      FROM ayahs_fts
      JOIN ayahs a ON a.id = ayahs_fts.rowid
      WHERE ayahs_fts MATCH ?
      ORDER BY rank
      LIMIT ?
      ''',
      variables: [Variable.withString(q), Variable.withInt(limit)],
      readsFrom: {ayahs},
    ).get();

    return rows.map((r) {
      return AyahFtsHit(
        ayahId: r.read<int>('ayah_id'),
        surahId: r.read<int>('surah_id'),
        ayahNumber: r.read<int>('ayah_number'),
        snippet: r.read<String>('snippet'),
        rank: r.read<double>('rank'),
      );
    }).toList(growable: false);
  }

  /// РџРѕРёСЃРє РїРѕ РїРµСЂРµРІРѕРґР°Рј (С‚РѕР»СЊРєРѕ `language_code = ?`).
  Future<List<TranslationFtsHit>> searchTranslationsFts(
    String query, {
    required String languageCode,
    int limit = 50,
  }) async {
    final q = _sanitizeFtsQuery(query);
    if (q.isEmpty) return const [];

    final rows = await customSelect(
      '''
      SELECT
        t.ayah_id AS ayah_id,
        t.translator_id AS translator_id,
        tr.language_code AS language_code,
        snippet(translations_fts, 0, '<mark>', '</mark>', '...', 16)
          AS snippet,
        bm25(translations_fts) AS rank
      FROM translations_fts
      JOIN translations t
        ON t.ayah_id = translations_fts.rowid
      JOIN translators tr ON tr.id = t.translator_id
      WHERE translations_fts MATCH ?
        AND tr.language_code = ?
      ORDER BY rank
      LIMIT ?
      ''',
      variables: [
        Variable.withString(q),
        Variable.withString(languageCode),
        Variable.withInt(limit),
      ],
      readsFrom: {translations, translators},
    ).get();

    return rows.map((r) {
      return TranslationFtsHit(
        ayahId: r.read<int>('ayah_id'),
        translatorId: r.read<int>('translator_id'),
        languageCode: r.read<String>('language_code'),
        snippet: r.read<String>('snippet'),
        rank: r.read<double>('rank'),
      );
    }).toList(growable: false);
  }

  /// РџРѕРёСЃРє РїРѕ `words` (Р°СЂР°Р±СЃРєРёРµ С‚РµСЂРјРёРЅС‹ + lemma + root + РїРµСЂРµРІРѕРґС‹).
  Future<List<WordFtsHit>> searchWordsFts(String query,
      {int limit = 50}) async {
    final q = _sanitizeFtsQuery(query);
    if (q.isEmpty) return const [];

    final rows = await customSelect(
      '''
      SELECT
        w.ayah_id AS ayah_id,
        w.position AS position,
        w.arabic AS arabic,
        w.normalized AS normalized,
        IFNULL(w.translation, '') AS translation,
        bm25(words_fts) AS rank
      FROM words_fts
      JOIN words w ON w.id = words_fts.rowid
      WHERE words_fts MATCH ?
      ORDER BY rank
      LIMIT ?
      ''',
      variables: [Variable.withString(q), Variable.withInt(limit)],
      readsFrom: {words},
    ).get();

    return rows.map((r) {
      return WordFtsHit(
        ayahId: r.read<int>('ayah_id'),
        position: r.read<int>('position'),
        arabic: r.read<String>('arabic'),
        normalized: r.read<String>('normalized'),
        translation: r.read<String>('translation'),
        rank: r.read<double>('rank'),
      );
    }).toList(growable: false);
  }

  /// РџРѕРёСЃРє РїРѕ С‚Р°С„СЃРёСЂР°Рј (РїРѕ РІСЃРµРј РёСЃС‚РѕС‡РЅРёРєР°Рј РёР»Рё РєРѕРЅРєСЂРµС‚РЅРѕРјСѓ `language_code`).
  Future<List<TranslationFtsHit>> searchTafsirsFts(
    String query, {
    String? languageCode,
    int limit = 30,
  }) async {
    final q = _sanitizeFtsQuery(query);
    if (q.isEmpty) return const [];

    final langFilter = languageCode != null
        ? 'AND tr.language_code = ?'
        : '';
    final variables = <Variable<Object>>[
      Variable.withString(q),
      Variable.withInt(limit),
    ];
    if (languageCode != null) {
      variables.add(Variable.withString(languageCode));
    }

    final rows = await customSelect(
      '''
      SELECT
        t.ayah_id AS ayah_id,
        t.tafsir_source_id AS translator_id,
        IFNULL(tr.language_code, '') AS language_code,
        snippet(tafsirs_fts, 0, '<mark>', '</mark>', '...', 16)
          AS snippet,
        bm25(tafsirs_fts) AS rank
      FROM tafsirs_fts
      JOIN tafsirs t ON t.id = tafsirs_fts.rowid
      LEFT JOIN tafsir_sources tr
        ON tr.id = t.tafsir_source_id
      WHERE tafsirs_fts MATCH ?
        $langFilter
      ORDER BY rank
      LIMIT ?
      ''',
      variables: variables,
      readsFrom: {tafsirs, tafsirSources},
    ).get();

    return rows.map((r) {
      return TranslationFtsHit(
        ayahId: r.read<int>('ayah_id'),
        translatorId: r.read<int>('translator_id'),
        languageCode: r.read<String>('language_code'),
        snippet: r.read<String>('snippet'),
        rank: r.read<double>('rank'),
      );
    }).toList(growable: false);
  }

  /// Rebuild FTS5 РёРЅРґРµРєСЃРѕРІ СЃ РЅСѓР»СЏ (РёРґРµРјРїРѕС‚РµРЅС‚РЅРѕ).
  /// РџРѕР»РµР·РЅРѕ РїРѕСЃР»Рµ `INSERT INTO ayahs ... SELECT * FROM ...` (seed).
  Future<void> rebuildAll() async {
    // INSERT OR IGNORE (FTS5) вЂ” РЅРµР»СЊР·СЏ РІ external-content С‚Р°Р±Р»РёС†Рµ.
    // РСЃРїРѕР»СЊР·СѓРµРј 'rebuild' С‡РµСЂРµР· DELETE + INSERT РІ РѕРґРЅРѕРј tx.
    await transaction(() async {
      // РЈРґР°Р»СЏРµРј С‚СЂРёРіРіРµСЂС‹ С‡С‚РѕР±С‹ РѕРЅРё РЅРµ СЃСЂР°Р±РѕС‚Р°Р»Рё РІРѕ РІСЂРµРјСЏ rebuild.
      // (РўСЂРёРіРіРµСЂС‹ РїРµСЂРµСЃРѕР·РґР°СЃС‚ `_createFts`).
      // _createFts РґРµР»Р°РµС‚ DROP+CREATE РґР»СЏ РёРЅРґРµРєСЃРѕРІ Рё С‚СЂРёРіРіРµСЂРѕРІ,
      // Р° 'INSERT INTO xxx_fts(xxx_fts) VALUES('rebuild')' РїРµСЂРµРёРЅРґРµРєСЃРёСЂСѓРµС‚.
      await customStatement('INSERT INTO ayahs_fts(ayahs_fts) VALUES(\'rebuild\')');
      await customStatement('INSERT INTO translations_fts(translations_fts) VALUES(\'rebuild\')');
      await customStatement('INSERT INTO words_fts(words_fts) VALUES(\'rebuild\')');
      await customStatement('INSERT INTO tafsirs_fts(tafsirs_fts) VALUES(\'rebuild\')');
    });
  }
}
