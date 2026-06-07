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
  String get firstLaunchTitle => 'اختر لغتك';

  @override
  String get firstLaunchSubtitle => 'يمكنك التغيير لاحقاً من الإعدادات';

  @override
  String get firstLaunchAction => 'متابعة';

  @override
  String get statsTitle => 'تقدّمك';

  @override
  String get statsWeek => 'الأسبوع';

  @override
  String get statsMonth => 'الشهر';

  @override
  String get statsYear => 'السنة';

  @override
  String get statsAllTime => 'كل الوقت';

  @override
  String get statsAyahsRead => 'الآيات المقروءة';

  @override
  String get statsSurahsRead => 'السور المقروءة';

  @override
  String get statsReadingTime => 'وقت القراءة';

  @override
  String get statsActivity => 'نشاط القراءة';

  @override
  String get statsPerDay => 'آيات في اليوم';

  @override
  String get audioChooseReciter => 'اختر القارئ';

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
}
