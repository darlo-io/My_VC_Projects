import 'package:quran_app/l10n/generated/app_localizations.dart';

/// Короткие (3-буквенные) имена дней недели с учётом locale.
///
/// Используется в bar-chart'е Statistics (X-axis labels).
/// Соответствует референсу `docs/images/statistic.png`:
/// `Mo/Tu/We/Th/Fr/Sa/Su` (en) или `Пн/Вт/Ср/Чт/Пт/Сб/Вс` (ru) или
/// `إثن/ثلا/أرب/خمي/جمع/سبت/أحد` (ar).
String localizedWeekdayShort(AppLocalizations t, int weekday) {
  // `DateTime.weekday` — 1=Monday, 7=Sunday.
  switch (weekday) {
    case DateTime.monday:
      return t.weekdayMon;
    case DateTime.tuesday:
      return t.weekdayTue;
    case DateTime.wednesday:
      return t.weekdayWed;
    case DateTime.thursday:
      return t.weekdayThu;
    case DateTime.friday:
      return t.weekdayFri;
    case DateTime.saturday:
      return t.weekdaySat;
    case DateTime.sunday:
      return t.weekdaySun;
    default:
      return '';
  }
}

/// Короткие (3-буквенные) имена месяцев с учётом locale.
String localizedMonthShort(AppLocalizations t, int month) {
  // `DateTime.month` — 1..12.
  switch (month) {
    case 1:
      return t.monthShortJan;
    case 2:
      return t.monthShortFeb;
    case 3:
      return t.monthShortMar;
    case 4:
      return t.monthShortApr;
    case 5:
      return t.monthShortMay;
    case 6:
      return t.monthShortJun;
    case 7:
      return t.monthShortJul;
    case 8:
      return t.monthShortAug;
    case 9:
      return t.monthShortSep;
    case 10:
      return t.monthShortOct;
    case 11:
      return t.monthShortNov;
    case 12:
      return t.monthShortDec;
    default:
      return '';
  }
}
