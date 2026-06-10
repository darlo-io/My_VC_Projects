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
  String get settingsResetDone => 'All data has been deleted';

  @override
  String settingsResetFailed(Object error) {
    return 'Could not reset: $error';
  }

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
  String get statsTitle => 'Statistics';

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

  @override
  String get surahName1 => 'The Opening';

  @override
  String get surahName2 => 'The Cow';

  @override
  String get surahName3 => 'The Family of Imraan';

  @override
  String get surahName4 => 'The Women';

  @override
  String get surahName5 => 'The Table';

  @override
  String get surahName6 => 'The Cattle';

  @override
  String get surahName7 => 'The Heights';

  @override
  String get surahName8 => 'The Spoils of War';

  @override
  String get surahName9 => 'The Repentance';

  @override
  String get surahName10 => 'Jonas';

  @override
  String get surahName11 => 'Hud';

  @override
  String get surahName12 => 'Joseph';

  @override
  String get surahName13 => 'The Thunder';

  @override
  String get surahName14 => 'Abraham';

  @override
  String get surahName15 => 'The Rock';

  @override
  String get surahName16 => 'The Bee';

  @override
  String get surahName17 => 'The Night Journey';

  @override
  String get surahName18 => 'The Cave';

  @override
  String get surahName19 => 'Mary';

  @override
  String get surahName20 => 'Taa-Haa';

  @override
  String get surahName21 => 'The Prophets';

  @override
  String get surahName22 => 'The Pilgrimage';

  @override
  String get surahName23 => 'The Believers';

  @override
  String get surahName24 => 'The Light';

  @override
  String get surahName25 => 'The Criterion';

  @override
  String get surahName26 => 'The Poets';

  @override
  String get surahName27 => 'The Ant';

  @override
  String get surahName28 => 'The Stories';

  @override
  String get surahName29 => 'The Spider';

  @override
  String get surahName30 => 'The Romans';

  @override
  String get surahName31 => 'Luqman';

  @override
  String get surahName32 => 'The Prostration';

  @override
  String get surahName33 => 'The Clans';

  @override
  String get surahName34 => 'Sheba';

  @override
  String get surahName35 => 'The Originator';

  @override
  String get surahName36 => 'Yaseen';

  @override
  String get surahName37 => 'Those drawn up in Ranks';

  @override
  String get surahName38 => 'The letter Saad';

  @override
  String get surahName39 => 'The Groups';

  @override
  String get surahName40 => 'The Forgiver';

  @override
  String get surahName41 => 'Explained in detail';

  @override
  String get surahName42 => 'Consultation';

  @override
  String get surahName43 => 'Ornaments of gold';

  @override
  String get surahName44 => 'The Smoke';

  @override
  String get surahName45 => 'Crouching';

  @override
  String get surahName46 => 'The Dunes';

  @override
  String get surahName47 => 'Muhammad';

  @override
  String get surahName48 => 'The Victory';

  @override
  String get surahName49 => 'The Inner Apartments';

  @override
  String get surahName50 => 'The letter Qaaf';

  @override
  String get surahName51 => 'The Winnowing Winds';

  @override
  String get surahName52 => 'The Mount';

  @override
  String get surahName53 => 'The Star';

  @override
  String get surahName54 => 'The Moon';

  @override
  String get surahName55 => 'The Beneficent';

  @override
  String get surahName56 => 'The Inevitable';

  @override
  String get surahName57 => 'The Iron';

  @override
  String get surahName58 => 'The Pleading Woman';

  @override
  String get surahName59 => 'The Exile';

  @override
  String get surahName60 => 'She that is to be examined';

  @override
  String get surahName61 => 'The Ranks';

  @override
  String get surahName62 => 'Friday';

  @override
  String get surahName63 => 'The Hypocrites';

  @override
  String get surahName64 => 'Mutual Disillusion';

  @override
  String get surahName65 => 'Divorce';

  @override
  String get surahName66 => 'The Prohibition';

  @override
  String get surahName67 => 'The Sovereignty';

  @override
  String get surahName68 => 'The Pen';

  @override
  String get surahName69 => 'The Reality';

  @override
  String get surahName70 => 'The Ascending Stairways';

  @override
  String get surahName71 => 'Noah';

  @override
  String get surahName72 => 'The Jinn';

  @override
  String get surahName73 => 'The Enshrouded One';

  @override
  String get surahName74 => 'The Cloaked One';

  @override
  String get surahName75 => 'The Resurrection';

  @override
  String get surahName76 => 'Man';

  @override
  String get surahName77 => 'The Emissaries';

  @override
  String get surahName78 => 'The Announcement';

  @override
  String get surahName79 => 'Those who drag forth';

  @override
  String get surahName80 => 'He frowned';

  @override
  String get surahName81 => 'The Overthrowing';

  @override
  String get surahName82 => 'The Cleaving';

  @override
  String get surahName83 => 'Defrauding';

  @override
  String get surahName84 => 'The Splitting Open';

  @override
  String get surahName85 => 'The Constellations';

  @override
  String get surahName86 => 'The Morning Star';

  @override
  String get surahName87 => 'The Most High';

  @override
  String get surahName88 => 'The Overwhelming';

  @override
  String get surahName89 => 'The Dawn';

  @override
  String get surahName90 => 'The City';

  @override
  String get surahName91 => 'The Sun';

  @override
  String get surahName92 => 'The Night';

  @override
  String get surahName93 => 'The Morning Hours';

  @override
  String get surahName94 => 'The Consolation';

  @override
  String get surahName95 => 'The Fig';

  @override
  String get surahName96 => 'The Clot';

  @override
  String get surahName97 => 'The Power, Fate';

  @override
  String get surahName98 => 'The Evidence';

  @override
  String get surahName99 => 'The Earthquake';

  @override
  String get surahName100 => 'The Chargers';

  @override
  String get surahName101 => 'The Calamity';

  @override
  String get surahName102 => 'Competition';

  @override
  String get surahName103 => 'The Declining Day, Epoch';

  @override
  String get surahName104 => 'The Traducer';

  @override
  String get surahName105 => 'The Elephant';

  @override
  String get surahName106 => 'Quraysh';

  @override
  String get surahName107 => 'Almsgiving';

  @override
  String get surahName108 => 'Abundance';

  @override
  String get surahName109 => 'The Disbelievers';

  @override
  String get surahName110 => 'Divine Support';

  @override
  String get surahName111 => 'The Palm Fibre';

  @override
  String get surahName112 => 'Sincerity';

  @override
  String get surahName113 => 'The Dawn';

  @override
  String get surahName114 => 'Mankind';

  @override
  String get reciterNameAlafasy => 'Mishary Rashid Alafasy';

  @override
  String get reciterNameAbdulbasitmurattal => 'Abdul Basit Abdul Samad';

  @override
  String get reciterNameHusary => 'Mahmud Khalil Al-Husary';

  @override
  String get reciterNameMinshawi => 'Mohamed Siddiq Al-Minshawi';

  @override
  String get reciterNameAbdurrahmaansudais => 'Abdul Rahman Al-Sudais';

  @override
  String get reciterNameSaaborimadina => 'Saud Al-Shuraim';

  @override
  String get reciterNameHudhaify => 'Ali Al-Hudhaify';

  @override
  String get reciterNameAhmedajamy => 'Ahmed Al-Ajamy';

  @override
  String get nowPlaying => 'Now playing';

  @override
  String get selectSurahAndPlay => 'Pick a surah and press play';

  @override
  String get surahLabel => 'Surah';

  @override
  String get tabAyahs => 'Ayahs';

  @override
  String get searchAyahHint => 'Type to search the Quran text';

  @override
  String get learnTitle => 'Words to review';

  @override
  String get learnSkip => 'Skip';

  @override
  String learnRemaining(Object count) {
    return 'Remaining: $count';
  }

  @override
  String learnSession(Object reviewed) {
    return 'Session: $reviewed';
  }

  @override
  String get learnStatusMastered => 'Mastered';

  @override
  String get learnStatusReviewing => 'Reviewing';

  @override
  String get learnStatusLearning => 'Learning';

  @override
  String get learnStatusNew => 'New';

  @override
  String get learnQuality0 => 'Don\'t remember';

  @override
  String get learnQuality1 => 'With effort';

  @override
  String get learnQuality2 => 'Hesitated';

  @override
  String get learnQuality3 => 'Recalled';

  @override
  String get learnQuality4 => 'Good';

  @override
  String get learnQuality5 => 'Easy';

  @override
  String get learnEmptyTitle => 'All words mastered';

  @override
  String get learnEmptyHint =>
      'Add new words from reading\nto continue reviewing.';

  @override
  String get wordTranslation => 'Translation';

  @override
  String get wordLemma => 'Lemma';

  @override
  String get wordRoot => 'Root';

  @override
  String get wordInVocab => 'In vocabulary';

  @override
  String get wordAddToVocab => 'Add to vocabulary';

  @override
  String get wordEmptyHint =>
      'Translation and grammar will appear once the dictionary is filled in.';

  @override
  String notesForAyah(Object number) {
    return 'Notes for ayah $number';
  }

  @override
  String get notesEmpty => 'No notes yet.\nAdd the first one below.';

  @override
  String get notesHint => 'Note text…';

  @override
  String ayahLabel(Object number) {
    return 'Ayah $number';
  }

  @override
  String get wordSameRoot => 'Other words with the same root';

  @override
  String get readerPrevSurah => 'Previous surah';

  @override
  String get readerNextSurah => 'Next surah';

  @override
  String get readerFirstSurah => 'First surah';

  @override
  String get readerLastSurah => 'Last surah';

  @override
  String juzOpenError(Object number) {
    return 'Could not open Juz $number';
  }

  @override
  String get statsToday => 'Today';

  @override
  String get statsThisWeek => 'This week';

  @override
  String get statsStreak => 'Day streak';

  @override
  String get statsLast7Days => 'Last 7 days';

  @override
  String get statsNoData =>
      'No reading history yet. Open any surah to start tracking.';

  @override
  String get statsDaysUnit => 'days';

  @override
  String get statsStreakHint => 'Open the app daily to grow your streak.';

  @override
  String get quizTitle => 'Quiz';

  @override
  String get quizQuestion => 'Which translation matches the ayah?';

  @override
  String quizProgress(Object current, Object total) {
    return 'Question $current of $total';
  }

  @override
  String get quizSkip => 'Skip';

  @override
  String get quizNext => 'Next';

  @override
  String get quizCorrect => 'Correct!';

  @override
  String get quizWrong => 'Not quite';

  @override
  String get quizResultsTitle => 'Results';

  @override
  String quizScore(Object correct, Object total) {
    return '$correct of $total correct';
  }

  @override
  String get quizPlayAgain => 'Play again';

  @override
  String get quizEmpty =>
      'No questions available yet. Read a surah first, then come back.';

  @override
  String get settingsReciter => 'Reciter';

  @override
  String get settingsReciterHint => 'Choose who reads the Quran aloud';

  @override
  String get settingsReciterActive => 'Currently selected';

  @override
  String get mediaAlbum => 'Quran';

  @override
  String get fontPreviewSurah => 'Al-Fatiha';

  @override
  String get playerError => 'Could not play audio';

  @override
  String get playerErrorHelp => 'Check your connection and try again';

  @override
  String get copyError => 'Copy error';

  @override
  String get retryCopied => 'Error copied to clipboard';

  @override
  String get readingModeLineByLine => 'Line by line';

  @override
  String get readingModeBook => 'Book';

  @override
  String get readingModeTooltip => 'Reading mode';
}
