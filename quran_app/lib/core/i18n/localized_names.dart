import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// Helper extension that wraps the 114+8 raw ARB lookups
/// (`surahName1`, `surahName2`, ..., `reciterNameAlafasy`, ...) into
/// ergonomic accessors. Adds runtime safety (falls back to the
/// transliteration from the DB if a key is missing) and per-reciter
/// id resolution.
///
/// Keep this file hand-maintained; if you add more localized
/// resource categories (e.g. word-by-word translations), add the
/// corresponding helper here.
extension SurahAndReciterNames on AppLocalizations {
  /// Localized name of the surah with id [id] (1..114). If no
  /// localized key is present (extremely rare — only possible during
  /// a partial localization), falls back to [fallback] (e.g. the
  /// transliteration stored in the database).
  String surahName(int id, {String fallback = '?'}) {
    switch (id) {
      case 1: return surahName1;
      case 2: return surahName2;
      case 3: return surahName3;
      case 4: return surahName4;
      case 5: return surahName5;
      case 6: return surahName6;
      case 7: return surahName7;
      case 8: return surahName8;
      case 9: return surahName9;
      case 10: return surahName10;
      case 11: return surahName11;
      case 12: return surahName12;
      case 13: return surahName13;
      case 14: return surahName14;
      case 15: return surahName15;
      case 16: return surahName16;
      case 17: return surahName17;
      case 18: return surahName18;
      case 19: return surahName19;
      case 20: return surahName20;
      case 21: return surahName21;
      case 22: return surahName22;
      case 23: return surahName23;
      case 24: return surahName24;
      case 25: return surahName25;
      case 26: return surahName26;
      case 27: return surahName27;
      case 28: return surahName28;
      case 29: return surahName29;
      case 30: return surahName30;
      case 31: return surahName31;
      case 32: return surahName32;
      case 33: return surahName33;
      case 34: return surahName34;
      case 35: return surahName35;
      case 36: return surahName36;
      case 37: return surahName37;
      case 38: return surahName38;
      case 39: return surahName39;
      case 40: return surahName40;
      case 41: return surahName41;
      case 42: return surahName42;
      case 43: return surahName43;
      case 44: return surahName44;
      case 45: return surahName45;
      case 46: return surahName46;
      case 47: return surahName47;
      case 48: return surahName48;
      case 49: return surahName49;
      case 50: return surahName50;
      case 51: return surahName51;
      case 52: return surahName52;
      case 53: return surahName53;
      case 54: return surahName54;
      case 55: return surahName55;
      case 56: return surahName56;
      case 57: return surahName57;
      case 58: return surahName58;
      case 59: return surahName59;
      case 60: return surahName60;
      case 61: return surahName61;
      case 62: return surahName62;
      case 63: return surahName63;
      case 64: return surahName64;
      case 65: return surahName65;
      case 66: return surahName66;
      case 67: return surahName67;
      case 68: return surahName68;
      case 69: return surahName69;
      case 70: return surahName70;
      case 71: return surahName71;
      case 72: return surahName72;
      case 73: return surahName73;
      case 74: return surahName74;
      case 75: return surahName75;
      case 76: return surahName76;
      case 77: return surahName77;
      case 78: return surahName78;
      case 79: return surahName79;
      case 80: return surahName80;
      case 81: return surahName81;
      case 82: return surahName82;
      case 83: return surahName83;
      case 84: return surahName84;
      case 85: return surahName85;
      case 86: return surahName86;
      case 87: return surahName87;
      case 88: return surahName88;
      case 89: return surahName89;
      case 90: return surahName90;
      case 91: return surahName91;
      case 92: return surahName92;
      case 93: return surahName93;
      case 94: return surahName94;
      case 95: return surahName95;
      case 96: return surahName96;
      case 97: return surahName97;
      case 98: return surahName98;
      case 99: return surahName99;
      case 100: return surahName100;
      case 101: return surahName101;
      case 102: return surahName102;
      case 103: return surahName103;
      case 104: return surahName104;
      case 105: return surahName105;
      case 106: return surahName106;
      case 107: return surahName107;
      case 108: return surahName108;
      case 109: return surahName109;
      case 110: return surahName110;
      case 111: return surahName111;
      case 112: return surahName112;
      case 113: return surahName113;
      case 114: return surahName114;
      default: return fallback;
    }
  }

  /// Localized name of the reciter with id [id] (e.g. `ar.alafasy`).
  /// The id is the full id from the database (`ar.<slug>`); we strip
  /// the `ar.` prefix and look up the corresponding key.
  String reciterName(String id, {String fallback = '?'}) {
    switch (id) {
      case 'ar.alafasy': return reciterNameAlafasy;
      case 'ar.abdulbasitmurattal': return reciterNameAbdulbasitmurattal;
      case 'ar.husary': return reciterNameHusary;
      case 'ar.minshawi': return reciterNameMinshawi;
      case 'ar.abdurrahmaansudais': return reciterNameAbdurrahmaansudais;
      case 'ar.saaborimadina': return reciterNameSaaborimadina;
      case 'ar.hudhaify': return reciterNameHudhaify;
      case 'ar.ahmedajamy': return reciterNameAhmedajamy;
      default: return fallback;
    }
  }
}

/// Static lookup that doesn't require a [BuildContext]. Falls back to
/// the (transliterated) English names in `kFallbackSurahNames` when
/// ARB lookups are unavailable (e.g. inside `addPostFrameCallback`
/// before the first frame, or in unit tests without `WidgetsApp`).
class LocalizedNames {
  LocalizedNames._();

  /// Last-resort English transliteration for surah 1..114 when ARB is
  /// not available. The same values are bundled into the ARB files
  /// (en) as `surahNameN`, so this is purely a defensive fallback.
  static const surahEn = <int, String>{
    1: 'The Opening', 2: 'The Cow', 3: 'The Family of Imraan',
    4: 'The Women', 5: 'The Table', 6: 'The Cattle', 7: 'The Heights',
    8: 'The Spoils of War', 9: 'The Repentance', 10: 'Jonas',
    11: 'Hud', 12: 'Joseph', 13: 'The Thunder', 14: 'Abraham',
    15: 'The Rock', 16: 'The Bee', 17: 'The Night Journey',
    18: 'The Cave', 19: 'Mary', 20: 'Taa-Haa', 21: 'The Prophets',
    22: 'The Pilgrimage', 23: 'The Believers', 24: 'The Light',
    25: 'The Criterion', 26: 'The Poets', 27: 'The Ant',
    28: 'The Stories', 29: 'The Spider', 30: 'The Romans', 31: 'Luqman',
    32: 'The Prostration', 33: 'The Clans', 34: 'Sheba',
    35: 'The Originator', 36: 'Yaseen',
    37: 'Those drawn up in Ranks', 38: 'The letter Saad',
    39: 'The Groups', 40: 'The Forgiver',
    41: 'Explained in detail', 42: 'Consultation',
    43: 'Ornaments of gold', 44: 'The Smoke', 45: 'Crouching',
    46: 'The Dunes', 47: 'Muhammad', 48: 'The Victory',
    49: 'The Inner Apartments', 50: 'The letter Qaaf',
    51: 'The Winnowing Winds', 52: 'The Mount', 53: 'The Star',
    54: 'The Moon', 55: 'The Beneficent', 56: 'The Inevitable',
    57: 'The Iron', 58: 'The Pleading Woman', 59: 'The Exile',
    60: 'She that is to be examined', 61: 'The Ranks', 62: 'Friday',
    63: 'The Hypocrites', 64: 'Mutual Disillusion', 65: 'Divorce',
    66: 'The Prohibition', 67: 'The Sovereignty', 68: 'The Pen',
    69: 'The Reality', 70: 'The Ascending Stairways', 71: 'Noah',
    72: 'The Jinn', 73: 'The Enshrouded One',
    74: 'The Cloaked One', 75: 'The Resurrection', 76: 'Man',
    77: 'The Emissaries', 78: 'The Announcement',
    79: 'Those who drag forth', 80: 'He frowned',
    81: 'The Overthrowing', 82: 'The Cleaving', 83: 'Defrauding',
    84: 'The Splitting Open', 85: 'The Constellations',
    86: 'The Morning Star', 87: 'The Most High',
    88: 'The Overwhelming', 89: 'The Dawn', 90: 'The City',
    91: 'The Sun', 92: 'The Night', 93: 'The Morning Hours',
    94: 'The Consolation', 95: 'The Fig', 96: 'The Clot',
    97: 'The Power, Fate', 98: 'The Evidence',
    99: 'The Earthquake', 100: 'The Chargers', 101: 'The Calamity',
    102: 'Competition', 103: 'The Declining Day, Epoch',
    104: 'The Traducer', 105: 'The Elephant', 106: 'Quraysh',
    107: 'Almsgiving', 108: 'Abundance',
    109: 'The Disbelievers', 110: 'Divine Support',
    111: 'The Palm Fibre', 112: 'Sincerity', 113: 'The Dawn',
    114: 'Mankind',
  };

  /// Last-resort English name for a reciter id.
  static const reciterEn = <String, String>{
    'ar.alafasy': 'Mishary Rashid Alafasy',
    'ar.abdulbasitmurattal': 'Abdul Basit Abdul Samad',
    'ar.husary': 'Mahmud Khalil Al-Husary',
    'ar.minshawi': 'Mohamed Siddiq Al-Minshawi',
    'ar.abdurrahmaansudais': 'Abdul Rahman Al-Sudais',
    'ar.saaborimadina': 'Ali Al-Hudhaify (Saboor)',
    'ar.hudhaify': 'Ali Al-Hudhaify',
    'ar.ahmedajamy': 'Ahmed Al-Ajamy',
  };
}

/// Lookup helper for the BuildContext-free case. Use this from places
/// where [AppLocalizations.of(context)] isn't available (e.g. Drift
/// converters, service workers).
String localizedSurahName(int id, AppLocalizations? l10n) {
  final fallback = LocalizedNames.surahEn[id] ?? '?';
  if (l10n != null) {
    return l10n.surahName(id, fallback: fallback);
  }
  return fallback;
}

String localizedReciterName(String id, AppLocalizations? l10n) {
  final fallback = LocalizedNames.reciterEn[id] ?? '?';
  if (l10n != null) {
    return l10n.reciterName(id, fallback: fallback);
  }
  return fallback;
}
