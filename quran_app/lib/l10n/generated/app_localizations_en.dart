// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Quran';

  @override
  String get navHome => 'Home';

  @override
  String get navRead => 'Read';

  @override
  String get navSearch => 'Search';

  @override
  String get navBookmarks => 'Bookmarks';

  @override
  String get navProfile => 'Profile';

  @override
  String get navListen => 'Listen';

  @override
  String get navLearn => 'Learn';

  @override
  String get navTasbih => 'Tasbih';

  @override
  String get greetingAssalamu => 'Assalamu Alaikum!';

  @override
  String hijriDateFallback(String date) {
    return '$date AH';
  }

  @override
  String get homeFallbackSurahName => 'Al-Fatiha';

  @override
  String get homeFallbackDate => '';

  @override
  String get continueReading => 'Continue reading';

  @override
  String get continueAction => 'Continue';

  @override
  String surahAndAyah(String surah, int ayah) {
    return 'Surah $surah, ayah $ayah';
  }

  @override
  String get cardRead => 'Read';

  @override
  String get cardListen => 'Listen';

  @override
  String get cardLearn => 'Learn';

  @override
  String get cardTest => 'Test';

  @override
  String get cardTasbih => 'Tasbih';

  @override
  String get cardStats => 'Statistics';

  @override
  String get chooseSurah => 'Choose a surah';

  @override
  String get searchByNameOrNumber => 'Search by name or number';

  @override
  String get tabSurahs => 'Surahs';

  @override
  String get tabJuz => 'Juz';

  @override
  String ayahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ayahs',
      one: '1 ayah',
    );
    return '$_temp0';
  }

  @override
  String get revelationMeccan => 'Meccan';

  @override
  String get revelationMedinan => 'Medinan';

  @override
  String juzNumber(int number) {
    return 'Juz $number';
  }

  @override
  String get search => 'Search';

  @override
  String get searchHint => 'Search surah, ayah, translation…';

  @override
  String get searchResultsEmpty => 'No results';

  @override
  String get searchResultsEmptyHint => 'Try different keywords';

  @override
  String get searchSurahOnly => 'Surah only';

  @override
  String get searchAll => 'All';

  @override
  String get bookmarksEmpty => 'No bookmarks yet';

  @override
  String get bookmarksEmptyHint => 'Add bookmarks from any ayah';

  @override
  String get addBookmark => 'Add bookmark';

  @override
  String get removeBookmark => 'Remove bookmark';

  @override
  String get bookmarkLabel => 'Label (optional)';

  @override
  String get settings => 'Settings';

  @override
  String get settingsLanguage => 'Interface language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsFontSize => 'Arabic font size';

  @override
  String get settingsTranslation => 'Translation';

  @override
  String get settingsAudioCache => 'Audio cache';

  @override
  String settingsStorageUsed(String used, String limit) {
    return '$used MB / $limit MB used';
  }

  @override
  String get settingsCacheLimit => 'Cache size limit';

  @override
  String settingsCacheLimitValue(Object mb) {
    return '$mb MB';
  }

  @override
  String get settingsCacheClearConfirm => 'Delete all downloaded audio?';

  @override
  String get settingsCacheCleared => 'Cache cleared';

  @override
  String settingsCacheEvicted(Object count) {
    return 'Removed $count files';
  }

  @override
  String get settingsClearCache => 'Clear audio cache';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsReset => 'Reset all data';

  @override
  String get settingsResetConfirm => 'Are you sure? All data will be deleted.';

  @override
  String get settingsResetConfirmAction => 'Delete';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageArabic => 'العربية';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get comingSoonDesc =>
      'This feature will be available in a future update.';

  @override
  String get loading => 'Loading…';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get bootstrapChecking => 'Checking content…';

  @override
  String get bootstrapDownloading => 'Downloading content…';

  @override
  String get bootstrapSeeding => 'Preparing database…';

  @override
  String get bootstrapReady => 'Ready';

  @override
  String get bootstrapFailed =>
      'Could not load content. Check your connection.';

  @override
  String get bootstrapLocalLoading => 'Loading Quran (offline)…';

  @override
  String get bootstrapLocalReady => 'Ready (offline)';

  @override
  String get bootstrapNetworkChecking => 'Checking for updates…';

  @override
  String get bootstrapNetworkFailed => 'Offline mode (updates skipped)';

  @override
  String get bootstrapNetworkDone => 'Up to date';

  @override
  String get firstLaunchTitle => 'Choose your language';

  @override
  String get firstLaunchSubtitle => 'You can change this later in Settings';

  @override
  String get firstLaunchAction => 'Continue';

  @override
  String get statsTitle => 'Your progress';

  @override
  String get statsWeek => 'Week';

  @override
  String get statsMonth => 'Month';

  @override
  String get statsYear => 'Year';

  @override
  String get statsAllTime => 'All time';

  @override
  String get statsAyahsRead => 'Ayahs read';

  @override
  String get statsSurahsRead => 'Surahs read';

  @override
  String get statsReadingTime => 'Reading time';

  @override
  String get statsActivity => 'Reading activity';

  @override
  String get statsPerDay => 'Ayahs per day';

  @override
  String get audioChooseSurah => 'Surah';

  @override
  String get audioChooseAyah => 'Ayah';

  @override
  String get audioSpeed => 'Speed';

  @override
  String get audioSleepTimer => 'Sleep timer';

  @override
  String get audioNightMode => 'Night mode';

  @override
  String get audioOff => 'Off';

  @override
  String get hifzTitle => 'Memorization';

  @override
  String get hifzRepeat => 'Repeat';

  @override
  String get hifzAbRepeat => 'A-B repeat';

  @override
  String get hifzProgress => 'Progress';

  @override
  String get tasbihTotal => 'Total';

  @override
  String get tasbihTapHint => 'Tap to count';

  @override
  String get tasbihReset => 'Reset counter';

  @override
  String get tasbihSubhanAllah => 'SubhanAllah';

  @override
  String get tasbihAlhamdulillah => 'Alhamdulillah';

  @override
  String get tasbihLaIla => 'La ilaha illallah';

  @override
  String get tasbihAllahuAkbar => 'Allahu Akbar';
}
