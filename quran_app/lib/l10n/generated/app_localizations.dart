import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get navRead;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get navBookmarks;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get navListen;

  /// No description provided for @navLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// No description provided for @navTasbih.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get navTasbih;

  /// No description provided for @greetingAssalamu.
  ///
  /// In en, this message translates to:
  /// **'Assalamu Alaikum!'**
  String get greetingAssalamu;

  /// No description provided for @hijriDateFallback.
  ///
  /// In en, this message translates to:
  /// **'{date} AH'**
  String hijriDateFallback(String date);

  /// No description provided for @homeFallbackSurahName.
  ///
  /// In en, this message translates to:
  /// **'Al-Fatiha'**
  String get homeFallbackSurahName;

  /// No description provided for @homeFallbackDate.
  ///
  /// In en, this message translates to:
  /// **''**
  String get homeFallbackDate;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @surahAndAyah.
  ///
  /// In en, this message translates to:
  /// **'Surah {surah}, ayah {ayah}'**
  String surahAndAyah(String surah, int ayah);

  /// No description provided for @cardRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get cardRead;

  /// No description provided for @cardListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get cardListen;

  /// No description provided for @cardLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get cardLearn;

  /// No description provided for @cardTest.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get cardTest;

  /// No description provided for @cardTasbih.
  ///
  /// In en, this message translates to:
  /// **'Tasbih'**
  String get cardTasbih;

  /// No description provided for @cardStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get cardStats;

  /// No description provided for @chooseSurah.
  ///
  /// In en, this message translates to:
  /// **'Choose a surah'**
  String get chooseSurah;

  /// No description provided for @searchByNameOrNumber.
  ///
  /// In en, this message translates to:
  /// **'Search by name or number'**
  String get searchByNameOrNumber;

  /// No description provided for @tabSurahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get tabSurahs;

  /// No description provided for @tabJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get tabJuz;

  /// No description provided for @ayahsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 ayah} other{{count} ayahs}}'**
  String ayahsCount(int count);

  /// No description provided for @revelationMeccan.
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get revelationMeccan;

  /// No description provided for @revelationMedinan.
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get revelationMedinan;

  /// No description provided for @juzNumber.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}'**
  String juzNumber(int number);

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search surah, ayah, translation…'**
  String get searchHint;

  /// No description provided for @searchResultsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get searchResultsEmpty;

  /// No description provided for @searchResultsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords'**
  String get searchResultsEmptyHint;

  /// No description provided for @searchSurahOnly.
  ///
  /// In en, this message translates to:
  /// **'Surah only'**
  String get searchSurahOnly;

  /// No description provided for @searchAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get searchAll;

  /// No description provided for @bookmarksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get bookmarksEmpty;

  /// No description provided for @bookmarksEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add bookmarks from any ayah'**
  String get bookmarksEmptyHint;

  /// No description provided for @addBookmark.
  ///
  /// In en, this message translates to:
  /// **'Add bookmark'**
  String get addBookmark;

  /// No description provided for @removeBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get removeBookmark;

  /// No description provided for @bookmarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get bookmarkLabel;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsFontSize.
  ///
  /// In en, this message translates to:
  /// **'Arabic font size'**
  String get settingsFontSize;

  /// No description provided for @settingsTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get settingsTranslation;

  /// No description provided for @settingsAudioCache.
  ///
  /// In en, this message translates to:
  /// **'Audio cache'**
  String get settingsAudioCache;

  /// No description provided for @settingsStorageUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} MB / {limit} MB used'**
  String settingsStorageUsed(String used, String limit);

  /// No description provided for @settingsCacheLimit.
  ///
  /// In en, this message translates to:
  /// **'Cache size limit'**
  String get settingsCacheLimit;

  /// No description provided for @settingsCacheLimitValue.
  ///
  /// In en, this message translates to:
  /// **'{mb} MB'**
  String settingsCacheLimitValue(Object mb);

  /// No description provided for @settingsCacheClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all downloaded audio?'**
  String get settingsCacheClearConfirm;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get settingsCacheCleared;

  /// No description provided for @settingsCacheEvicted.
  ///
  /// In en, this message translates to:
  /// **'Removed {count} files'**
  String settingsCacheEvicted(Object count);

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear audio cache'**
  String get settingsClearCache;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersion(String version);

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset all data'**
  String get settingsReset;

  /// No description provided for @settingsResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? All data will be deleted.'**
  String get settingsResetConfirm;

  /// No description provided for @settingsResetConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsResetConfirmAction;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageRussian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @comingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'This feature will be available in a future update.'**
  String get comingSoonDesc;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @bootstrapChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking content…'**
  String get bootstrapChecking;

  /// No description provided for @bootstrapDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading content…'**
  String get bootstrapDownloading;

  /// No description provided for @bootstrapSeeding.
  ///
  /// In en, this message translates to:
  /// **'Preparing database…'**
  String get bootstrapSeeding;

  /// No description provided for @bootstrapReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get bootstrapReady;

  /// No description provided for @bootstrapFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load content. Check your connection.'**
  String get bootstrapFailed;

  /// No description provided for @bootstrapLocalLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading Quran (offline)…'**
  String get bootstrapLocalLoading;

  /// No description provided for @bootstrapLocalReady.
  ///
  /// In en, this message translates to:
  /// **'Ready (offline)'**
  String get bootstrapLocalReady;

  /// No description provided for @bootstrapNetworkChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get bootstrapNetworkChecking;

  /// No description provided for @bootstrapNetworkFailed.
  ///
  /// In en, this message translates to:
  /// **'Offline mode (updates skipped)'**
  String get bootstrapNetworkFailed;

  /// No description provided for @bootstrapNetworkDone.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get bootstrapNetworkDone;

  /// No description provided for @firstLaunchTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get firstLaunchTitle;

  /// No description provided for @firstLaunchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in Settings'**
  String get firstLaunchSubtitle;

  /// No description provided for @firstLaunchAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get firstLaunchAction;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get statsWeek;

  /// No description provided for @statsMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get statsMonth;

  /// No description provided for @statsYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get statsYear;

  /// No description provided for @statsAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get statsAllTime;

  /// No description provided for @statsAyahsRead.
  ///
  /// In en, this message translates to:
  /// **'Ayahs read'**
  String get statsAyahsRead;

  /// No description provided for @statsSurahsRead.
  ///
  /// In en, this message translates to:
  /// **'Surahs read'**
  String get statsSurahsRead;

  /// No description provided for @statsReadingTime.
  ///
  /// In en, this message translates to:
  /// **'Reading time'**
  String get statsReadingTime;

  /// No description provided for @statsActivity.
  ///
  /// In en, this message translates to:
  /// **'Reading activity'**
  String get statsActivity;

  /// No description provided for @statsPerDay.
  ///
  /// In en, this message translates to:
  /// **'Ayahs per day'**
  String get statsPerDay;

  /// No description provided for @audioChooseSurah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get audioChooseSurah;

  /// No description provided for @audioChooseAyah.
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get audioChooseAyah;

  /// No description provided for @audioSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get audioSpeed;

  /// No description provided for @audioSleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get audioSleepTimer;

  /// No description provided for @audioNightMode.
  ///
  /// In en, this message translates to:
  /// **'Night mode'**
  String get audioNightMode;

  /// No description provided for @audioOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get audioOff;

  /// No description provided for @hifzTitle.
  ///
  /// In en, this message translates to:
  /// **'Memorization'**
  String get hifzTitle;

  /// No description provided for @hifzRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get hifzRepeat;

  /// No description provided for @hifzAbRepeat.
  ///
  /// In en, this message translates to:
  /// **'A-B repeat'**
  String get hifzAbRepeat;

  /// No description provided for @hifzProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get hifzProgress;

  /// No description provided for @tasbihTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get tasbihTotal;

  /// No description provided for @tasbihTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to count'**
  String get tasbihTapHint;

  /// No description provided for @tasbihReset.
  ///
  /// In en, this message translates to:
  /// **'Reset counter'**
  String get tasbihReset;

  /// No description provided for @tasbihSubhanAllah.
  ///
  /// In en, this message translates to:
  /// **'SubhanAllah'**
  String get tasbihSubhanAllah;

  /// No description provided for @tasbihAlhamdulillah.
  ///
  /// In en, this message translates to:
  /// **'Alhamdulillah'**
  String get tasbihAlhamdulillah;

  /// No description provided for @tasbihLaIla.
  ///
  /// In en, this message translates to:
  /// **'La ilaha illallah'**
  String get tasbihLaIla;

  /// No description provided for @tasbihAllahuAkbar.
  ///
  /// In en, this message translates to:
  /// **'Allahu Akbar'**
  String get tasbihAllahuAkbar;

  /// No description provided for @surahName1.
  ///
  /// In en, this message translates to:
  /// **'The Opening'**
  String get surahName1;

  /// No description provided for @surahName2.
  ///
  /// In en, this message translates to:
  /// **'The Cow'**
  String get surahName2;

  /// No description provided for @surahName3.
  ///
  /// In en, this message translates to:
  /// **'The Family of Imraan'**
  String get surahName3;

  /// No description provided for @surahName4.
  ///
  /// In en, this message translates to:
  /// **'The Women'**
  String get surahName4;

  /// No description provided for @surahName5.
  ///
  /// In en, this message translates to:
  /// **'The Table'**
  String get surahName5;

  /// No description provided for @surahName6.
  ///
  /// In en, this message translates to:
  /// **'The Cattle'**
  String get surahName6;

  /// No description provided for @surahName7.
  ///
  /// In en, this message translates to:
  /// **'The Heights'**
  String get surahName7;

  /// No description provided for @surahName8.
  ///
  /// In en, this message translates to:
  /// **'The Spoils of War'**
  String get surahName8;

  /// No description provided for @surahName9.
  ///
  /// In en, this message translates to:
  /// **'The Repentance'**
  String get surahName9;

  /// No description provided for @surahName10.
  ///
  /// In en, this message translates to:
  /// **'Jonas'**
  String get surahName10;

  /// No description provided for @surahName11.
  ///
  /// In en, this message translates to:
  /// **'Hud'**
  String get surahName11;

  /// No description provided for @surahName12.
  ///
  /// In en, this message translates to:
  /// **'Joseph'**
  String get surahName12;

  /// No description provided for @surahName13.
  ///
  /// In en, this message translates to:
  /// **'The Thunder'**
  String get surahName13;

  /// No description provided for @surahName14.
  ///
  /// In en, this message translates to:
  /// **'Abraham'**
  String get surahName14;

  /// No description provided for @surahName15.
  ///
  /// In en, this message translates to:
  /// **'The Rock'**
  String get surahName15;

  /// No description provided for @surahName16.
  ///
  /// In en, this message translates to:
  /// **'The Bee'**
  String get surahName16;

  /// No description provided for @surahName17.
  ///
  /// In en, this message translates to:
  /// **'The Night Journey'**
  String get surahName17;

  /// No description provided for @surahName18.
  ///
  /// In en, this message translates to:
  /// **'The Cave'**
  String get surahName18;

  /// No description provided for @surahName19.
  ///
  /// In en, this message translates to:
  /// **'Mary'**
  String get surahName19;

  /// No description provided for @surahName20.
  ///
  /// In en, this message translates to:
  /// **'Taa-Haa'**
  String get surahName20;

  /// No description provided for @surahName21.
  ///
  /// In en, this message translates to:
  /// **'The Prophets'**
  String get surahName21;

  /// No description provided for @surahName22.
  ///
  /// In en, this message translates to:
  /// **'The Pilgrimage'**
  String get surahName22;

  /// No description provided for @surahName23.
  ///
  /// In en, this message translates to:
  /// **'The Believers'**
  String get surahName23;

  /// No description provided for @surahName24.
  ///
  /// In en, this message translates to:
  /// **'The Light'**
  String get surahName24;

  /// No description provided for @surahName25.
  ///
  /// In en, this message translates to:
  /// **'The Criterion'**
  String get surahName25;

  /// No description provided for @surahName26.
  ///
  /// In en, this message translates to:
  /// **'The Poets'**
  String get surahName26;

  /// No description provided for @surahName27.
  ///
  /// In en, this message translates to:
  /// **'The Ant'**
  String get surahName27;

  /// No description provided for @surahName28.
  ///
  /// In en, this message translates to:
  /// **'The Stories'**
  String get surahName28;

  /// No description provided for @surahName29.
  ///
  /// In en, this message translates to:
  /// **'The Spider'**
  String get surahName29;

  /// No description provided for @surahName30.
  ///
  /// In en, this message translates to:
  /// **'The Romans'**
  String get surahName30;

  /// No description provided for @surahName31.
  ///
  /// In en, this message translates to:
  /// **'Luqman'**
  String get surahName31;

  /// No description provided for @surahName32.
  ///
  /// In en, this message translates to:
  /// **'The Prostration'**
  String get surahName32;

  /// No description provided for @surahName33.
  ///
  /// In en, this message translates to:
  /// **'The Clans'**
  String get surahName33;

  /// No description provided for @surahName34.
  ///
  /// In en, this message translates to:
  /// **'Sheba'**
  String get surahName34;

  /// No description provided for @surahName35.
  ///
  /// In en, this message translates to:
  /// **'The Originator'**
  String get surahName35;

  /// No description provided for @surahName36.
  ///
  /// In en, this message translates to:
  /// **'Yaseen'**
  String get surahName36;

  /// No description provided for @surahName37.
  ///
  /// In en, this message translates to:
  /// **'Those drawn up in Ranks'**
  String get surahName37;

  /// No description provided for @surahName38.
  ///
  /// In en, this message translates to:
  /// **'The letter Saad'**
  String get surahName38;

  /// No description provided for @surahName39.
  ///
  /// In en, this message translates to:
  /// **'The Groups'**
  String get surahName39;

  /// No description provided for @surahName40.
  ///
  /// In en, this message translates to:
  /// **'The Forgiver'**
  String get surahName40;

  /// No description provided for @surahName41.
  ///
  /// In en, this message translates to:
  /// **'Explained in detail'**
  String get surahName41;

  /// No description provided for @surahName42.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get surahName42;

  /// No description provided for @surahName43.
  ///
  /// In en, this message translates to:
  /// **'Ornaments of gold'**
  String get surahName43;

  /// No description provided for @surahName44.
  ///
  /// In en, this message translates to:
  /// **'The Smoke'**
  String get surahName44;

  /// No description provided for @surahName45.
  ///
  /// In en, this message translates to:
  /// **'Crouching'**
  String get surahName45;

  /// No description provided for @surahName46.
  ///
  /// In en, this message translates to:
  /// **'The Dunes'**
  String get surahName46;

  /// No description provided for @surahName47.
  ///
  /// In en, this message translates to:
  /// **'Muhammad'**
  String get surahName47;

  /// No description provided for @surahName48.
  ///
  /// In en, this message translates to:
  /// **'The Victory'**
  String get surahName48;

  /// No description provided for @surahName49.
  ///
  /// In en, this message translates to:
  /// **'The Inner Apartments'**
  String get surahName49;

  /// No description provided for @surahName50.
  ///
  /// In en, this message translates to:
  /// **'The letter Qaaf'**
  String get surahName50;

  /// No description provided for @surahName51.
  ///
  /// In en, this message translates to:
  /// **'The Winnowing Winds'**
  String get surahName51;

  /// No description provided for @surahName52.
  ///
  /// In en, this message translates to:
  /// **'The Mount'**
  String get surahName52;

  /// No description provided for @surahName53.
  ///
  /// In en, this message translates to:
  /// **'The Star'**
  String get surahName53;

  /// No description provided for @surahName54.
  ///
  /// In en, this message translates to:
  /// **'The Moon'**
  String get surahName54;

  /// No description provided for @surahName55.
  ///
  /// In en, this message translates to:
  /// **'The Beneficent'**
  String get surahName55;

  /// No description provided for @surahName56.
  ///
  /// In en, this message translates to:
  /// **'The Inevitable'**
  String get surahName56;

  /// No description provided for @surahName57.
  ///
  /// In en, this message translates to:
  /// **'The Iron'**
  String get surahName57;

  /// No description provided for @surahName58.
  ///
  /// In en, this message translates to:
  /// **'The Pleading Woman'**
  String get surahName58;

  /// No description provided for @surahName59.
  ///
  /// In en, this message translates to:
  /// **'The Exile'**
  String get surahName59;

  /// No description provided for @surahName60.
  ///
  /// In en, this message translates to:
  /// **'She that is to be examined'**
  String get surahName60;

  /// No description provided for @surahName61.
  ///
  /// In en, this message translates to:
  /// **'The Ranks'**
  String get surahName61;

  /// No description provided for @surahName62.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get surahName62;

  /// No description provided for @surahName63.
  ///
  /// In en, this message translates to:
  /// **'The Hypocrites'**
  String get surahName63;

  /// No description provided for @surahName64.
  ///
  /// In en, this message translates to:
  /// **'Mutual Disillusion'**
  String get surahName64;

  /// No description provided for @surahName65.
  ///
  /// In en, this message translates to:
  /// **'Divorce'**
  String get surahName65;

  /// No description provided for @surahName66.
  ///
  /// In en, this message translates to:
  /// **'The Prohibition'**
  String get surahName66;

  /// No description provided for @surahName67.
  ///
  /// In en, this message translates to:
  /// **'The Sovereignty'**
  String get surahName67;

  /// No description provided for @surahName68.
  ///
  /// In en, this message translates to:
  /// **'The Pen'**
  String get surahName68;

  /// No description provided for @surahName69.
  ///
  /// In en, this message translates to:
  /// **'The Reality'**
  String get surahName69;

  /// No description provided for @surahName70.
  ///
  /// In en, this message translates to:
  /// **'The Ascending Stairways'**
  String get surahName70;

  /// No description provided for @surahName71.
  ///
  /// In en, this message translates to:
  /// **'Noah'**
  String get surahName71;

  /// No description provided for @surahName72.
  ///
  /// In en, this message translates to:
  /// **'The Jinn'**
  String get surahName72;

  /// No description provided for @surahName73.
  ///
  /// In en, this message translates to:
  /// **'The Enshrouded One'**
  String get surahName73;

  /// No description provided for @surahName74.
  ///
  /// In en, this message translates to:
  /// **'The Cloaked One'**
  String get surahName74;

  /// No description provided for @surahName75.
  ///
  /// In en, this message translates to:
  /// **'The Resurrection'**
  String get surahName75;

  /// No description provided for @surahName76.
  ///
  /// In en, this message translates to:
  /// **'Man'**
  String get surahName76;

  /// No description provided for @surahName77.
  ///
  /// In en, this message translates to:
  /// **'The Emissaries'**
  String get surahName77;

  /// No description provided for @surahName78.
  ///
  /// In en, this message translates to:
  /// **'The Announcement'**
  String get surahName78;

  /// No description provided for @surahName79.
  ///
  /// In en, this message translates to:
  /// **'Those who drag forth'**
  String get surahName79;

  /// No description provided for @surahName80.
  ///
  /// In en, this message translates to:
  /// **'He frowned'**
  String get surahName80;

  /// No description provided for @surahName81.
  ///
  /// In en, this message translates to:
  /// **'The Overthrowing'**
  String get surahName81;

  /// No description provided for @surahName82.
  ///
  /// In en, this message translates to:
  /// **'The Cleaving'**
  String get surahName82;

  /// No description provided for @surahName83.
  ///
  /// In en, this message translates to:
  /// **'Defrauding'**
  String get surahName83;

  /// No description provided for @surahName84.
  ///
  /// In en, this message translates to:
  /// **'The Splitting Open'**
  String get surahName84;

  /// No description provided for @surahName85.
  ///
  /// In en, this message translates to:
  /// **'The Constellations'**
  String get surahName85;

  /// No description provided for @surahName86.
  ///
  /// In en, this message translates to:
  /// **'The Morning Star'**
  String get surahName86;

  /// No description provided for @surahName87.
  ///
  /// In en, this message translates to:
  /// **'The Most High'**
  String get surahName87;

  /// No description provided for @surahName88.
  ///
  /// In en, this message translates to:
  /// **'The Overwhelming'**
  String get surahName88;

  /// No description provided for @surahName89.
  ///
  /// In en, this message translates to:
  /// **'The Dawn'**
  String get surahName89;

  /// No description provided for @surahName90.
  ///
  /// In en, this message translates to:
  /// **'The City'**
  String get surahName90;

  /// No description provided for @surahName91.
  ///
  /// In en, this message translates to:
  /// **'The Sun'**
  String get surahName91;

  /// No description provided for @surahName92.
  ///
  /// In en, this message translates to:
  /// **'The Night'**
  String get surahName92;

  /// No description provided for @surahName93.
  ///
  /// In en, this message translates to:
  /// **'The Morning Hours'**
  String get surahName93;

  /// No description provided for @surahName94.
  ///
  /// In en, this message translates to:
  /// **'The Consolation'**
  String get surahName94;

  /// No description provided for @surahName95.
  ///
  /// In en, this message translates to:
  /// **'The Fig'**
  String get surahName95;

  /// No description provided for @surahName96.
  ///
  /// In en, this message translates to:
  /// **'The Clot'**
  String get surahName96;

  /// No description provided for @surahName97.
  ///
  /// In en, this message translates to:
  /// **'The Power, Fate'**
  String get surahName97;

  /// No description provided for @surahName98.
  ///
  /// In en, this message translates to:
  /// **'The Evidence'**
  String get surahName98;

  /// No description provided for @surahName99.
  ///
  /// In en, this message translates to:
  /// **'The Earthquake'**
  String get surahName99;

  /// No description provided for @surahName100.
  ///
  /// In en, this message translates to:
  /// **'The Chargers'**
  String get surahName100;

  /// No description provided for @surahName101.
  ///
  /// In en, this message translates to:
  /// **'The Calamity'**
  String get surahName101;

  /// No description provided for @surahName102.
  ///
  /// In en, this message translates to:
  /// **'Competition'**
  String get surahName102;

  /// No description provided for @surahName103.
  ///
  /// In en, this message translates to:
  /// **'The Declining Day, Epoch'**
  String get surahName103;

  /// No description provided for @surahName104.
  ///
  /// In en, this message translates to:
  /// **'The Traducer'**
  String get surahName104;

  /// No description provided for @surahName105.
  ///
  /// In en, this message translates to:
  /// **'The Elephant'**
  String get surahName105;

  /// No description provided for @surahName106.
  ///
  /// In en, this message translates to:
  /// **'Quraysh'**
  String get surahName106;

  /// No description provided for @surahName107.
  ///
  /// In en, this message translates to:
  /// **'Almsgiving'**
  String get surahName107;

  /// No description provided for @surahName108.
  ///
  /// In en, this message translates to:
  /// **'Abundance'**
  String get surahName108;

  /// No description provided for @surahName109.
  ///
  /// In en, this message translates to:
  /// **'The Disbelievers'**
  String get surahName109;

  /// No description provided for @surahName110.
  ///
  /// In en, this message translates to:
  /// **'Divine Support'**
  String get surahName110;

  /// No description provided for @surahName111.
  ///
  /// In en, this message translates to:
  /// **'The Palm Fibre'**
  String get surahName111;

  /// No description provided for @surahName112.
  ///
  /// In en, this message translates to:
  /// **'Sincerity'**
  String get surahName112;

  /// No description provided for @surahName113.
  ///
  /// In en, this message translates to:
  /// **'The Dawn'**
  String get surahName113;

  /// No description provided for @surahName114.
  ///
  /// In en, this message translates to:
  /// **'Mankind'**
  String get surahName114;

  /// No description provided for @reciterNameAlafasy.
  ///
  /// In en, this message translates to:
  /// **'Mishary Rashid Alafasy'**
  String get reciterNameAlafasy;

  /// No description provided for @reciterNameAbdulbasitmurattal.
  ///
  /// In en, this message translates to:
  /// **'Abdul Basit Abdul Samad'**
  String get reciterNameAbdulbasitmurattal;

  /// No description provided for @reciterNameHusary.
  ///
  /// In en, this message translates to:
  /// **'Mahmud Khalil Al-Husary'**
  String get reciterNameHusary;

  /// No description provided for @reciterNameMinshawi.
  ///
  /// In en, this message translates to:
  /// **'Mohamed Siddiq Al-Minshawi'**
  String get reciterNameMinshawi;

  /// No description provided for @reciterNameAbdurrahmaansudais.
  ///
  /// In en, this message translates to:
  /// **'Abdul Rahman Al-Sudais'**
  String get reciterNameAbdurrahmaansudais;

  /// No description provided for @reciterNameSaaborimadina.
  ///
  /// In en, this message translates to:
  /// **'Saud Al-Shuraim'**
  String get reciterNameSaaborimadina;

  /// No description provided for @reciterNameHudhaify.
  ///
  /// In en, this message translates to:
  /// **'Ali Al-Hudhaify'**
  String get reciterNameHudhaify;

  /// No description provided for @reciterNameAhmedajamy.
  ///
  /// In en, this message translates to:
  /// **'Ahmed Al-Ajamy'**
  String get reciterNameAhmedajamy;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @selectSurahAndPlay.
  ///
  /// In en, this message translates to:
  /// **'Pick a surah and press play'**
  String get selectSurahAndPlay;

  /// No description provided for @surahLabel.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get surahLabel;

  /// No description provided for @tabAyahs.
  ///
  /// In en, this message translates to:
  /// **'Ayahs'**
  String get tabAyahs;

  /// No description provided for @searchAyahHint.
  ///
  /// In en, this message translates to:
  /// **'Type to search the Quran text'**
  String get searchAyahHint;

  /// No description provided for @learnTitle.
  ///
  /// In en, this message translates to:
  /// **'Words to review'**
  String get learnTitle;

  /// No description provided for @learnSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get learnSkip;

  /// No description provided for @learnRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining: {count}'**
  String learnRemaining(Object count);

  /// No description provided for @learnSession.
  ///
  /// In en, this message translates to:
  /// **'Session: {reviewed}'**
  String learnSession(Object reviewed);

  /// No description provided for @learnStatusMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get learnStatusMastered;

  /// No description provided for @learnStatusReviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing'**
  String get learnStatusReviewing;

  /// No description provided for @learnStatusLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learnStatusLearning;

  /// No description provided for @learnStatusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get learnStatusNew;

  /// No description provided for @learnQuality0.
  ///
  /// In en, this message translates to:
  /// **'Don\'t remember'**
  String get learnQuality0;

  /// No description provided for @learnQuality1.
  ///
  /// In en, this message translates to:
  /// **'With effort'**
  String get learnQuality1;

  /// No description provided for @learnQuality2.
  ///
  /// In en, this message translates to:
  /// **'Hesitated'**
  String get learnQuality2;

  /// No description provided for @learnQuality3.
  ///
  /// In en, this message translates to:
  /// **'Recalled'**
  String get learnQuality3;

  /// No description provided for @learnQuality4.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get learnQuality4;

  /// No description provided for @learnQuality5.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get learnQuality5;

  /// No description provided for @learnEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'All words mastered'**
  String get learnEmptyTitle;

  /// No description provided for @learnEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add new words from reading\nto continue reviewing.'**
  String get learnEmptyHint;

  /// No description provided for @wordTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get wordTranslation;

  /// No description provided for @wordLemma.
  ///
  /// In en, this message translates to:
  /// **'Lemma'**
  String get wordLemma;

  /// No description provided for @wordRoot.
  ///
  /// In en, this message translates to:
  /// **'Root'**
  String get wordRoot;

  /// No description provided for @wordInVocab.
  ///
  /// In en, this message translates to:
  /// **'In vocabulary'**
  String get wordInVocab;

  /// No description provided for @wordAddToVocab.
  ///
  /// In en, this message translates to:
  /// **'Add to vocabulary'**
  String get wordAddToVocab;

  /// No description provided for @wordEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Translation and grammar will appear once the dictionary is filled in.'**
  String get wordEmptyHint;

  /// No description provided for @notesForAyah.
  ///
  /// In en, this message translates to:
  /// **'Notes for ayah {number}'**
  String notesForAyah(Object number);

  /// No description provided for @notesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notes yet.\nAdd the first one below.'**
  String get notesEmpty;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Note text…'**
  String get notesHint;

  /// No description provided for @ayahLabel.
  ///
  /// In en, this message translates to:
  /// **'Ayah {number}'**
  String ayahLabel(Object number);

  /// No description provided for @wordSameRoot.
  ///
  /// In en, this message translates to:
  /// **'Other words with the same root'**
  String get wordSameRoot;

  /// No description provided for @readerPrevSurah.
  ///
  /// In en, this message translates to:
  /// **'Previous surah'**
  String get readerPrevSurah;

  /// No description provided for @readerNextSurah.
  ///
  /// In en, this message translates to:
  /// **'Next surah'**
  String get readerNextSurah;

  /// No description provided for @readerFirstSurah.
  ///
  /// In en, this message translates to:
  /// **'First surah'**
  String get readerFirstSurah;

  /// No description provided for @readerLastSurah.
  ///
  /// In en, this message translates to:
  /// **'Last surah'**
  String get readerLastSurah;

  /// No description provided for @juzOpenError.
  ///
  /// In en, this message translates to:
  /// **'Could not open Juz {number}'**
  String juzOpenError(Object number);

  /// No description provided for @statsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statsToday;

  /// No description provided for @statsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get statsThisWeek;

  /// No description provided for @statsStreak.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get statsStreak;

  /// No description provided for @statsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get statsLast7Days;

  /// No description provided for @statsNoData.
  ///
  /// In en, this message translates to:
  /// **'No reading history yet. Open any surah to start tracking.'**
  String get statsNoData;

  /// No description provided for @statsDaysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get statsDaysUnit;

  /// No description provided for @statsStreakHint.
  ///
  /// In en, this message translates to:
  /// **'Open the app daily to grow your streak.'**
  String get statsStreakHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
