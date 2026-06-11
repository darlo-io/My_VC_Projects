// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'القرآن';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navRead => 'قراءة';

  @override
  String get navSearch => 'بحث';

  @override
  String get navBookmarks => 'إشارات';

  @override
  String get navProfile => 'الملف';

  @override
  String get navListen => 'استماع';

  @override
  String get navLearn => 'تعلّم';

  @override
  String get navTasbih => 'تسبيح';

  @override
  String get greetingAssalamu => 'السلام عليكم!';

  @override
  String hijriDateFallback(String date) {
    return '$date هـ';
  }

  @override
  String get homeFallbackSurahName => 'الفاتحة';

  @override
  String get homeFallbackDate => '';

  @override
  String get continueReading => 'متابعة القراءة';

  @override
  String get continueAction => 'متابعة';

  @override
  String surahAndAyah(String surah, int ayah) {
    return 'سورة $surah، آية $ayah';
  }

  @override
  String get cardRead => 'قراءة';

  @override
  String get cardListen => 'استماع';

  @override
  String get cardLearn => 'تعلّم';

  @override
  String get cardTest => 'اختبار';

  @override
  String get cardTasbih => 'تسبيح';

  @override
  String get cardStats => 'إحصائيات';

  @override
  String get chooseSurah => 'اختر سورة للقراءة';

  @override
  String get searchByNameOrNumber => 'ابحث بالاسم أو رقم السورة';

  @override
  String get tabSurahs => 'السور';

  @override
  String get tabJuz => 'الأجزاء';

  @override
  String ayahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count آية',
      many: '$count آية',
      few: '$count آيات',
      two: 'آيتان',
      one: 'آية واحدة',
      zero: 'لا آيات',
    );
    return '$_temp0';
  }

  @override
  String get revelationMeccan => 'مكية';

  @override
  String get revelationMedinan => 'مدنية';

  @override
  String juzNumber(int number) {
    return 'الجزء $number';
  }

  @override
  String get search => 'بحث';

  @override
  String get searchHint => 'ابحث في السور والآيات والترجمة…';

  @override
  String get searchResultsEmpty => 'لا توجد نتائج';

  @override
  String get searchResultsEmptyHint => 'جرّب كلمات مختلفة';

  @override
  String get searchSurahOnly => 'السور فقط';

  @override
  String get searchAll => 'الكل';

  @override
  String get bookmarksEmpty => 'لا توجد إشارات مرجعية';

  @override
  String get bookmarksEmptyHint => 'أضف إشارات من أي آية';

  @override
  String get addBookmark => 'إضافة إشارة';

  @override
  String get removeBookmark => 'حذف الإشارة';

  @override
  String get bookmarkLabel => 'تسمية (اختياري)';

  @override
  String get settings => 'الإعدادات';

  @override
  String get settingsLanguage => 'لغة الواجهة';

  @override
  String get settingsTheme => 'السمة';

  @override
  String get settingsFontSize => 'حجم الخط العربي';

  @override
  String get settingsTranslation => 'الترجمة';

  @override
  String get settingsAudioCache => 'ذاكرة الصوت';

  @override
  String settingsStorageUsed(String used, String limit) {
    return '$used م.ب / $limit م.ب مستخدمة';
  }

  @override
  String get settingsCacheLimit => 'حد حجم الذاكرة';

  @override
  String settingsCacheLimitValue(Object mb) {
    return '$mb م.ب';
  }

  @override
  String get settingsCacheClearConfirm => 'حذف كل الصوت المحمّل؟';

  @override
  String get settingsCacheCleared => 'تم مسح الذاكرة';

  @override
  String settingsCacheEvicted(Object count) {
    return 'حُذف $count ملف';
  }

  @override
  String get settingsClearCache => 'مسح ذاكرة الصوت';

  @override
  String get settingsAbout => 'حول التطبيق';

  @override
  String settingsVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get settingsReset => 'إعادة تعيين البيانات';

  @override
  String get settingsResetConfirm => 'هل أنت متأكد؟ سيتم حذف جميع البيانات.';

  @override
  String get settingsResetConfirmAction => 'حذف';

  @override
  String get settingsResetDone => 'تم حذف جميع البيانات';

  @override
  String settingsResetFailed(Object error) {
    return 'تعذّر إعادة التعيين: $error';
  }

  @override
  String get languageSystem => 'النظام';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageArabic => 'العربية';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get comingSoonDesc => 'ستتوفر هذه الميزة في تحديثات لاحقة.';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get error => 'خطأ';

  @override
  String get retry => 'إعادة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get ok => 'موافق';

  @override
  String get save => 'حفظ';

  @override
  String get delete => 'حذف';

  @override
  String get bootstrapChecking => 'جاري فحص المحتوى…';

  @override
  String get bootstrapDownloading => 'جاري تنزيل المحتوى…';

  @override
  String get bootstrapSeeding => 'تجهيز قاعدة البيانات…';

  @override
  String get bootstrapReady => 'جاهز';

  @override
  String get bootstrapFailed => 'تعذّر تحميل المحتوى. تحقق من الاتصال.';

  @override
  String get bootstrapLocalLoading => 'جاري تحميل القرآن (دون اتصال)…';

  @override
  String get bootstrapLocalReady => 'جاهز (دون اتصال)';

  @override
  String get bootstrapNetworkChecking => 'جاري التحقق من التحديثات…';

  @override
  String get bootstrapNetworkFailed => 'وضع عدم الاتصال (تم تخطي التحديثات)';

  @override
  String get bootstrapNetworkDone => 'محدّث';

  @override
  String get firstLaunchTitle => 'اختر لغتك';

  @override
  String get firstLaunchSubtitle => 'يمكنك التغيير لاحقاً من الإعدادات';

  @override
  String get firstLaunchAction => 'متابعة';

  @override
  String get statsTitle => 'الإحصاءات';

  @override
  String get statsSubtitle => 'تقدمك في قراءة القرآن';

  @override
  String get statsWeek => 'الأسبوع';

  @override
  String get statsMonth => 'الشهر';

  @override
  String get statsYear => 'السنة';

  @override
  String get statsAllTime => 'كل الوقت';

  @override
  String get statsAyahsRead => 'آيات مقروءة';

  @override
  String get statsSurahsRead => 'سور مقروءة';

  @override
  String get statsReadingTime => 'وقت القراءة';

  @override
  String get statsActivity => 'نشاط القراءة';

  @override
  String get statsPerDay => 'آيات في اليوم';

  @override
  String get statsProgressTitle => 'القرآن المقروء';

  @override
  String statsProgressPct(Object pct) {
    return '$pct٪';
  }

  @override
  String statsOfTotal(Object total) {
    return 'من $total';
  }

  @override
  String get statsTotalAll => 'المجموع';

  @override
  String get statsJuzTitle => 'التقدم بحسب الأجزاء';

  @override
  String get statsJuzAll => 'كل الأجزاء';

  @override
  String statsJuzProgressPct(Object pct) {
    return '$pct٪';
  }

  @override
  String get statsAchievementsTitle => 'الإنجازات الأخيرة';

  @override
  String get statsAchievementsAll => 'الكل';

  @override
  String get statsAchvLastRead => 'سورة مقروءة';

  @override
  String get statsAchvStreak => 'تحقيق الهدف';

  @override
  String get statsAchvRecord => 'رقم قياسي جديد';

  @override
  String get statsAchvStreakSubtitle => 'القراءة دون انقطاع';

  @override
  String get statsAchvRecordSubtitle => 'آيات في يوم واحد';

  @override
  String get statsAchvToday => 'اليوم';

  @override
  String get statsAchvYesterday => 'أمس';

  @override
  String statsAchvDaysAgo(Object days) {
    return 'قبل $days أيام';
  }

  @override
  String get weekdayMon => 'إثن';

  @override
  String get weekdayTue => 'ثلا';

  @override
  String get weekdayWed => 'أرب';

  @override
  String get weekdayThu => 'خمي';

  @override
  String get weekdayFri => 'جمع';

  @override
  String get weekdaySat => 'سبت';

  @override
  String get weekdaySun => 'أحد';

  @override
  String get monthShortJan => 'ينا';

  @override
  String get monthShortFeb => 'فبر';

  @override
  String get monthShortMar => 'مار';

  @override
  String get monthShortApr => 'أبر';

  @override
  String get monthShortMay => 'ماي';

  @override
  String get monthShortJun => 'يون';

  @override
  String get monthShortJul => 'يول';

  @override
  String get monthShortAug => 'أغس';

  @override
  String get monthShortSep => 'سبت';

  @override
  String get monthShortOct => 'أكت';

  @override
  String get monthShortNov => 'نوف';

  @override
  String get monthShortDec => 'ديس';

  @override
  String get audioChooseSurah => 'السورة';

  @override
  String get audioChooseAyah => 'الآية';

  @override
  String get audioSpeed => 'السرعة';

  @override
  String get audioSleepTimer => 'مؤقت النوم';

  @override
  String get audioNightMode => 'الوضع الليلي';

  @override
  String get audioSpeedOff => '1.0x';

  @override
  String get audioSleepOff => 'إيقاف';

  @override
  String audioSleepMinutes(Object minutes) {
    return '$minutes د';
  }

  @override
  String get audioSleepAfterCurrent => 'بعد السورة الحالية';

  @override
  String get audioPlaying => 'يعمل';

  @override
  String get audioPaused => 'متوقف';

  @override
  String get audioOff => 'إيقاف';

  @override
  String get hifzTitle => 'الحفظ';

  @override
  String get hifzRepeat => 'تكرار';

  @override
  String get hifzAbRepeat => 'تكرار A-B';

  @override
  String get hifzProgress => 'التقدّم';

  @override
  String get tasbihTotal => 'المجموع';

  @override
  String get tasbihTapHint => 'اضغط للعدّ';

  @override
  String get tasbihReset => 'تصفير العدّاد';

  @override
  String get tasbihSubhanAllah => 'سبحان الله';

  @override
  String get tasbihAlhamdulillah => 'الحمد لله';

  @override
  String get tasbihLaIla => 'لا إله إلا الله';

  @override
  String get tasbihAllahuAkbar => 'الله أكبر';

  @override
  String get surahName1 => '';

  @override
  String get surahName2 => '';

  @override
  String get surahName3 => '';

  @override
  String get surahName4 => '';

  @override
  String get surahName5 => '';

  @override
  String get surahName6 => '';

  @override
  String get surahName7 => '';

  @override
  String get surahName8 => '';

  @override
  String get surahName9 => '';

  @override
  String get surahName10 => '';

  @override
  String get surahName11 => '';

  @override
  String get surahName12 => '';

  @override
  String get surahName13 => '';

  @override
  String get surahName14 => '';

  @override
  String get surahName15 => '';

  @override
  String get surahName16 => '';

  @override
  String get surahName17 => '';

  @override
  String get surahName18 => '';

  @override
  String get surahName19 => '';

  @override
  String get surahName20 => '';

  @override
  String get surahName21 => '';

  @override
  String get surahName22 => '';

  @override
  String get surahName23 => '';

  @override
  String get surahName24 => '';

  @override
  String get surahName25 => '';

  @override
  String get surahName26 => '';

  @override
  String get surahName27 => '';

  @override
  String get surahName28 => '';

  @override
  String get surahName29 => '';

  @override
  String get surahName30 => '';

  @override
  String get surahName31 => '';

  @override
  String get surahName32 => '';

  @override
  String get surahName33 => '';

  @override
  String get surahName34 => '';

  @override
  String get surahName35 => '';

  @override
  String get surahName36 => '';

  @override
  String get surahName37 => '';

  @override
  String get surahName38 => '';

  @override
  String get surahName39 => '';

  @override
  String get surahName40 => '';

  @override
  String get surahName41 => '';

  @override
  String get surahName42 => '';

  @override
  String get surahName43 => '';

  @override
  String get surahName44 => '';

  @override
  String get surahName45 => '';

  @override
  String get surahName46 => '';

  @override
  String get surahName47 => '';

  @override
  String get surahName48 => '';

  @override
  String get surahName49 => '';

  @override
  String get surahName50 => '';

  @override
  String get surahName51 => '';

  @override
  String get surahName52 => '';

  @override
  String get surahName53 => '';

  @override
  String get surahName54 => '';

  @override
  String get surahName55 => '';

  @override
  String get surahName56 => '';

  @override
  String get surahName57 => '';

  @override
  String get surahName58 => '';

  @override
  String get surahName59 => '';

  @override
  String get surahName60 => '';

  @override
  String get surahName61 => '';

  @override
  String get surahName62 => '';

  @override
  String get surahName63 => '';

  @override
  String get surahName64 => '';

  @override
  String get surahName65 => '';

  @override
  String get surahName66 => '';

  @override
  String get surahName67 => '';

  @override
  String get surahName68 => '';

  @override
  String get surahName69 => '';

  @override
  String get surahName70 => '';

  @override
  String get surahName71 => '';

  @override
  String get surahName72 => '';

  @override
  String get surahName73 => '';

  @override
  String get surahName74 => '';

  @override
  String get surahName75 => '';

  @override
  String get surahName76 => '';

  @override
  String get surahName77 => '';

  @override
  String get surahName78 => '';

  @override
  String get surahName79 => '';

  @override
  String get surahName80 => '';

  @override
  String get surahName81 => '';

  @override
  String get surahName82 => '';

  @override
  String get surahName83 => '';

  @override
  String get surahName84 => '';

  @override
  String get surahName85 => '';

  @override
  String get surahName86 => '';

  @override
  String get surahName87 => '';

  @override
  String get surahName88 => '';

  @override
  String get surahName89 => '';

  @override
  String get surahName90 => '';

  @override
  String get surahName91 => '';

  @override
  String get surahName92 => '';

  @override
  String get surahName93 => '';

  @override
  String get surahName94 => '';

  @override
  String get surahName95 => '';

  @override
  String get surahName96 => '';

  @override
  String get surahName97 => '';

  @override
  String get surahName98 => '';

  @override
  String get surahName99 => '';

  @override
  String get surahName100 => '';

  @override
  String get surahName101 => '';

  @override
  String get surahName102 => '';

  @override
  String get surahName103 => '';

  @override
  String get surahName104 => '';

  @override
  String get surahName105 => '';

  @override
  String get surahName106 => '';

  @override
  String get surahName107 => '';

  @override
  String get surahName108 => '';

  @override
  String get surahName109 => '';

  @override
  String get surahName110 => '';

  @override
  String get surahName111 => '';

  @override
  String get surahName112 => '';

  @override
  String get surahName113 => '';

  @override
  String get surahName114 => '';

  @override
  String get reciterNameAlafasy => 'مشاري راشد العفاسي';

  @override
  String get reciterNameAbdulbasitmurattal => 'عبد الباسط عبد الصمد';

  @override
  String get reciterNameHusary => 'محمود خليل الحصري';

  @override
  String get reciterNameMinshawi => 'محمد صديق المنشاوي';

  @override
  String get reciterNameAbdurrahmaansudais => 'عبد الرحمن السديس';

  @override
  String get reciterNameSaaborimadina => 'سعود الشريم';

  @override
  String get reciterNameHudhaify => 'علي عبد الله جابر';

  @override
  String get reciterNameAhmedajamy => 'أحمد العجمي';

  @override
  String get nowPlaying => 'يُشغَّل الآن';

  @override
  String get selectSurahAndPlay => 'اختر سورة واضغط تشغيل';

  @override
  String get surahLabel => 'السورة';

  @override
  String get tabAyahs => 'آيات';

  @override
  String get searchAyahHint => 'اكتب للبحث في نص القرآن';

  @override
  String get learnTitle => 'كلمات للمراجعة';

  @override
  String get learnHubTitle => 'تعلّم';

  @override
  String get learnHubSubtitle =>
      'ادرس القرآن حسب المواضيع وقواعد التلاوة\nواحفظه عن ظهر قلب';

  @override
  String get learnHubMemorization => 'الحفظ';

  @override
  String get learnHubMemorizationHint => 'احفظ السور والآيات عن ظهر قلب';

  @override
  String get learnHubMemorizationProgress => 'تقدّم الحفظ';

  @override
  String get learnHubContinue => 'متابعة';

  @override
  String get learnHubStart => 'ابدأ';

  @override
  String get learnHubQuickAccess => 'وصول سريع';

  @override
  String get learnHubRecent => 'الجلسات الأخيرة';

  @override
  String get learnHubMyBookmarks => 'علاماتي';

  @override
  String get learnHubMyStats => 'إحصاءات الحفظ';

  @override
  String get learnHubMyPlan => 'خطتي الدراسية';

  @override
  String get learnHubBySection => 'تعلّم حسب القسم';

  @override
  String get learnHubByJuz => 'القرآن بالأجزاء';

  @override
  String get learnHubByJuzHint => 'أجزاء القرآن للدراسة المتدرجة';

  @override
  String get learnHubBySurah => 'السور';

  @override
  String get learnHubBySurahHint => 'اختر سورة للدراسة والحفظ';

  @override
  String get learnHubRecentAyahs => 'الآيات الأخيرة';

  @override
  String get learnHubRecentAyahsHint => 'اقرأ آخر 50 آية من القرآن';

  @override
  String get learnHubDuas => 'الأدعية والأذكار';

  @override
  String get learnHubDuasHint => 'أدعية وأذكار يومية أساسية';

  @override
  String get learnHubTajweed => 'قواعد التجويد';

  @override
  String get learnHubTajweedHint => 'تعلّم قواعد التلاوة الصحيحة';

  @override
  String get learnHubDailyGoal => 'هدف اليوم';

  @override
  String learnHubDailyGoalAyahs(Object current, Object target) {
    return '$current / $target آيات';
  }

  @override
  String get learnHubDailyGoalHint => 'استمر على نفس الروح!';

  @override
  String learnHubStreakDays(Object days) {
    return 'السلسلة: $days يوم';
  }

  @override
  String get learnSkip => 'تخطٍ';

  @override
  String learnRemaining(Object count) {
    return 'المتبقي: $count';
  }

  @override
  String learnSession(Object reviewed) {
    return 'الجلسة: $reviewed';
  }

  @override
  String get learnStatusMastered => 'متقن';

  @override
  String get learnStatusReviewing => 'قيد المراجعة';

  @override
  String get learnStatusLearning => 'قيد التعلم';

  @override
  String get learnStatusNew => 'جديد';

  @override
  String get learnQuality0 => 'لا أتذكر';

  @override
  String get learnQuality1 => 'بصعوبة';

  @override
  String get learnQuality2 => 'بتردد';

  @override
  String get learnQuality3 => 'تذكرت';

  @override
  String get learnQuality4 => 'جيد';

  @override
  String get learnQuality5 => 'ممتاز';

  @override
  String get learnEmptyTitle => 'تم إتقان كل الكلمات';

  @override
  String get learnEmptyHint => 'أضف كلمات جديدة من القراءة\nلمواصلة المراجعة.';

  @override
  String get wordTranslation => 'الترجمة';

  @override
  String get wordLemma => 'الجذر النحوي';

  @override
  String get wordRoot => 'الجذر';

  @override
  String get wordInVocab => 'في القاموس';

  @override
  String get wordAddToVocab => 'أضف إلى القاموس';

  @override
  String get wordEmptyHint => 'ستظهر الترجمة والقواعد عند اكتمال القاموس.';

  @override
  String notesForAyah(Object number) {
    return 'ملاحظات الآية $number';
  }

  @override
  String get notesEmpty => 'لا توجد ملاحظات بعد.\nأضف أول ملاحظة أدناه.';

  @override
  String get notesHint => 'نص الملاحظة…';

  @override
  String ayahLabel(Object number) {
    return 'الآية $number';
  }

  @override
  String get wordSameRoot => 'كلمات أخرى من الجذر نفسه';

  @override
  String get readerPrevSurah => 'السورة السابقة';

  @override
  String get readerNextSurah => 'السورة التالية';

  @override
  String get readerFirstSurah => 'السورة الأولى';

  @override
  String get readerLastSurah => 'السورة الأخيرة';

  @override
  String juzOpenError(Object number) {
    return 'تعذّر فتح الجزء $number';
  }

  @override
  String get statsToday => 'اليوم';

  @override
  String get statsThisWeek => 'هذا الأسبوع';

  @override
  String get statsStreak => 'أيام متتالية';

  @override
  String get statsLast7Days => 'آخر 7 أيام';

  @override
  String get statsNoData => 'لا يوجد سجل قراءة بعد. افتح أي سورة للبدء.';

  @override
  String get statsDaysUnit => 'يوم';

  @override
  String get statsStreakHint => 'افتح التطبيق يوميًا لزيادة سلسلتك.';

  @override
  String get quizTitle => 'اختبار';

  @override
  String get quizQuestion => 'أي ترجمة تطابق الآية؟';

  @override
  String quizProgress(Object current, Object total) {
    return 'السؤال $current من $total';
  }

  @override
  String get quizSkip => 'تخطٍ';

  @override
  String get quizNext => 'التالي';

  @override
  String get quizCorrect => 'صحيح!';

  @override
  String get quizWrong => 'غير صحيح';

  @override
  String get quizResultsTitle => 'النتائج';

  @override
  String quizScore(Object correct, Object total) {
    return '$correct من $total صحيحة';
  }

  @override
  String get quizPlayAgain => 'العب مرة أخرى';

  @override
  String get quizEmpty => 'لا توجد أسئلة بعد. اقرأ سورة أولاً، ثم عُد.';

  @override
  String get settingsReciter => 'القارئ';

  @override
  String get settingsReciterHint => 'اختر من يتلو القرآن';

  @override
  String get settingsReciterActive => 'المحدد حاليًا';

  @override
  String get settingsDownloads => 'التنزيلات';

  @override
  String get settingsDownloadsHint => 'إدارة الصوت المخزّن على الجهاز';

  @override
  String downloadsTotalCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سور مخزنة',
      two: 'سورتان مخزنتان',
      one: 'سورة واحدة مخزنة',
      zero: 'لا سور مخزنة',
    );
    return '$_temp0';
  }

  @override
  String get downloadsClear => 'حذف الكل';

  @override
  String get contentUpdateChecking => 'جارٍ التحقق من تحديثات المحتوى…';

  @override
  String get contentUpdateUpToDate => 'المحتوى محدّث';

  @override
  String contentUpdateAvailable(Object version) {
    return 'تحديث متاح: الإصدار $version';
  }

  @override
  String get contentUpdateFailed => 'فشل تحديث المحتوى';

  @override
  String get contentUpdateIntegrity => 'فشل فحص السلامة';

  @override
  String get mediaAlbum => 'القرآن';

  @override
  String get fontPreviewSurah => 'الفاتحة';

  @override
  String get playerError => 'تعذّر تشغيل الصوت';

  @override
  String get playerErrorHelp => 'تحقق من الاتصال وأعد المحاولة';

  @override
  String get copyError => 'نسخ الخطأ';

  @override
  String get retryCopied => 'تم نسخ الخطأ';

  @override
  String get readingModeLineByLine => 'سطر بسطر';

  @override
  String get readingModeBook => 'كتاب';

  @override
  String get readingModeTooltip => 'وضع القراءة';
}
