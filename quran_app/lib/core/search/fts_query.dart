/// FTS5 query helpers shared by every DAO and screen that issues a
/// `MATCH` against one of the FTS5 shadow tables in [AppDatabase]
/// (`ayahs_fts`, `translations_fts`, `words_fts`).
///
/// Centralising this logic in one place avoids the bug class where
/// each caller writes its own sanitization — historically we had
/// three different normalizers across `AyahDao`, `WordsDao`, and
/// `search_screen.dart`, and at least one of them dropped FTS5
/// reserved characters without bounds-checking, so user input
/// containing `"`, `*`, `(`, etc. could either crash the query or
/// silently change its meaning.
library;

import 'arabic_normalizer.dart';

/// Normalize a free-form user query into a safe FTS5 prefix-MATCH
/// expression:
///   1. apply the same Arabic normalization used at index time
///      (collapse alef/ya/ta-marbuta variants, strip diacritics,
///      tatweel). Without this step a user typing `الرحمن` could
///      miss rows whose `text_normalized` was collapsed from
///      `ٱلرَّحْمَٰنِ`;
///   2. split on whitespace;
///   3. drop FTS5 reserved characters from each token
///      (`" ' ( ) * : ^ - + . , ;`);
///   4. drop empty tokens;
///   5. emit each remaining token as a prefix (`token*`).
///
/// Prefix-MATCH means partial words still match: typing `الرح`
/// finds `الرحمن`.
///
/// Returns the empty string if the query has no searchable tokens
/// — callers should treat this as "no results" rather than passing
/// an empty MATCH to SQLite (which would error).
String buildFtsPrefixQuery(String raw) {
  const banned = {'"', '\'', '(', ')', '*', ':', '^', '-', '+', '.', ',', ';'};
  // Arabic normalization is cheap and idempotent on Latin-only input,
  // so we apply it unconditionally — Latin tokens are passed through
  // unchanged. The normalizer lives in [arabic_normalizer.dart] and
  // is the same function used by [ContentBootstrapper] when seeding
  // `ayahs.text_normalized`, so the index and the query stay in lockstep.
  final normalized = ArabicNormalizer.normalize(raw);
  final tokens = normalized
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .map((t) => t.split('').where((c) => !banned.contains(c)).join())
      .where((t) => t.isNotEmpty)
      .toList();
  if (tokens.isEmpty) return '';
  return tokens.map((t) => '$t*').join(' ');
}
