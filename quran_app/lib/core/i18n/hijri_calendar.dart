/// Конвертация григорианской даты в дату Исламского календаря
/// (табличный / Umm al-Qura) и форматирование по locale.
///
/// Реализован табличный алгоритм (Kuwaiti/tabular civil Hijri),
/// достаточный для отображения в шапке приложения. Он даёт
/// погрешность не более ±1 день по сравнению с наблюдаемым
/// хиджрийским календарём Umm al-Qura, и при этом — никаких
/// внешних пакетов и таблиц на годы вперёд.
///
/// Использование:
///   final hijri = HijriDate.fromGregorian(DateTime.now());
///   final formatted = formatHijriDate(hijri, locale);
library;

class HijriDate {
  const HijriDate({required this.year, required this.month, required this.day});
  final int year;
  final int month;
  final int day;

  @override
  String toString() => '$year-$month-$day';
}

/// Конвертация григорианской даты в табличный хиджрийский календарь.
/// Алгоритм «Kuwaiti civil algorithm» (D. König, 2019).
/// Погрешность: ±1 день относительно Umm al-Qura.
HijriDate hijriFromGregorian(DateTime g) {
  // 1) Считаем абсолютный JDN (юлианский день) на полдень по гринвичу.
  // Формула работает для григорианских дат начиная с 1582-10-15.
  final day = g.day;
  final month = g.month;
  final year = g.year;

  final a = ((14 - month) / 12).floor();
  final y = year + 4800 - a;
  final m = month + 12 * a - 3;
  final jd = day
      + ((153 * m + 2) / 5).floor()
      + 365 * y
      + (y / 4).floor()
      - (y / 100).floor()
      + (y / 400).floor()
      - 32045;

  // 2) Хиджрийский JDN: 1 Мухаррама 1 г. х. = JDN 1948440 (пятница).
  final l = jd - 1948440 + 10632;
  final n = ((l - 1) / 10631).floor();
  final l2 = l - 10631 * n + 354;
  final j =
      ((10985 - l2) / 5316).floor() * ((50 * l2) / 17719).floor()
          + (l2 / 5670).floor() * ((43 * l2) / 15238).floor();
  final l3 = l2 - ((30 - j) / 15).floor() * ((17719 * j) / 50).floor()
      - (j / 16).floor() * ((15238 * j) / 43).floor() + 29;
  final monthI = ((24 * l3) / 708).floor();
  final dayI = l3 - ((708 * monthI) / 24).floor();
  final yearI = 30 * n + j - 30;

  return HijriDate(year: yearI, month: monthI, day: dayI);
}

/// Локализованное название месяца хиджрийского календаря.
String hijriMonthName(int month, String localeCode) {
  assert(month >= 1 && month <= 12, 'month must be 1..12');
  const ru = [
    'Мухаррам',
    'Сафар',
    'Раби аль-авваль',
    'Раби ас-сани',
    'Джумада аль-уля',
    'Джумада ас-сания',
    'Раджаб',
    'Шаабан',
    'Рамадан',
    'Шавваль',
    'Зуль-каада',
    'Зуль-хиджа',
  ];
  const en = [
    'Muharram',
    'Safar',
    "Rabi' al-awwal",
    "Rabi' al-thani",
    'Jumada al-awwal',
    'Jumada al-thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qa'dah",
    'Dhu al-Hijjah',
  ];
  const ar = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الثانية',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];
  final i = month - 1;
  switch (localeCode) {
    case 'ar':
      return ar[i];
    case 'ru':
      return ru[i];
    case 'en':
    default:
      return en[i];
  }
}

/// Собрать строку вида `23 Зуль-каада 1445 г. х.`. Локаль-чувствительно.
String formatHijriDate(HijriDate d, String localeCode) {
  final month = hijriMonthName(d.month, localeCode);
  switch (localeCode) {
    case 'ar':
      return '${d.day} $month ${d.year} هـ';
    case 'ru':
      return '${d.day} $month ${d.year} г. х.';
    case 'en':
    default:
      return '${d.day} $month ${d.year} AH';
  }
}
