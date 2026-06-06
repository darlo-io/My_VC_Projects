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
  /// **'Your progress'**
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

  /// No description provided for @audioChooseReciter.
  ///
  /// In en, this message translates to:
  /// **'Choose reciter'**
  String get audioChooseReciter;

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
