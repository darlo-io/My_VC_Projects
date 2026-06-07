// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Коран';

  @override
  String get navHome => 'Главная';

  @override
  String get navRead => 'Читать';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navBookmarks => 'Закладки';

  @override
  String get navProfile => 'Профиль';

  @override
  String get navListen => 'Слушать';

  @override
  String get navLearn => 'Учить';

  @override
  String get navTasbih => 'Тасбих';

  @override
  String get greetingAssalamu => 'Ассаляму алейкум!';

  @override
  String hijriDateFallback(String date) {
    return '$date г. х.';
  }

  @override
  String get homeFallbackSurahName => 'Аль-Фатиха';

  @override
  String get homeFallbackDate => '';

  @override
  String get continueReading => 'Продолжить чтение';

  @override
  String get continueAction => 'Продолжить';

  @override
  String surahAndAyah(String surah, int ayah) {
    return 'Сура $surah, аят $ayah';
  }

  @override
  String get cardRead => 'Читать';

  @override
  String get cardListen => 'Слушать';

  @override
  String get cardLearn => 'Учить';

  @override
  String get cardTest => 'Тест';

  @override
  String get cardTasbih => 'Тасбих';

  @override
  String get cardStats => 'Статистика';

  @override
  String get chooseSurah => 'Выберите суру для чтения';

  @override
  String get searchByNameOrNumber => 'Поиск по названию или номеру суры';

  @override
  String get tabSurahs => 'Суры';

  @override
  String get tabJuz => 'Джузы';

  @override
  String ayahsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count аятов',
      many: '$count аятов',
      few: '$count аята',
      one: '$count аят',
    );
    return '$_temp0';
  }

  @override
  String get revelationMeccan => 'Мекканская';

  @override
  String get revelationMedinan => 'Мединская';

  @override
  String juzNumber(int number) {
    return 'Джуз $number';
  }

  @override
  String get search => 'Поиск';

  @override
  String get searchHint => 'Поиск по суре, аяту, переводу…';

  @override
  String get searchResultsEmpty => 'Ничего не найдено';

  @override
  String get searchResultsEmptyHint => 'Попробуйте другие ключевые слова';

  @override
  String get searchSurahOnly => 'Только суры';

  @override
  String get searchAll => 'Все';

  @override
  String get bookmarksEmpty => 'Закладок пока нет';

  @override
  String get bookmarksEmptyHint => 'Добавляйте закладки из любого аята';

  @override
  String get addBookmark => 'Добавить закладку';

  @override
  String get removeBookmark => 'Удалить закладку';

  @override
  String get bookmarkLabel => 'Ярлык (необязательно)';

  @override
  String get settings => 'Настройки';

  @override
  String get settingsLanguage => 'Язык интерфейса';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsFontSize => 'Размер арабского шрифта';

  @override
  String get settingsTranslation => 'Перевод';

  @override
  String get settingsAudioCache => 'Аудио-кеш';

  @override
  String settingsStorageUsed(String used, String limit) {
    return '$used МБ / $limit МБ использовано';
  }

  @override
  String get settingsCacheLimit => 'Лимит размера кеша';

  @override
  String get settingsClearCache => 'Очистить аудио-кеш';

  @override
  String get settingsAbout => 'О приложении';

  @override
  String settingsVersion(String version) {
    return 'Версия $version';
  }

  @override
  String get settingsReset => 'Сбросить все данные';

  @override
  String get settingsResetConfirm => 'Вы уверены? Все данные будут удалены.';

  @override
  String get settingsResetConfirmAction => 'Удалить';

  @override
  String get languageSystem => 'Системный';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageArabic => 'العربية';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get comingSoonDesc =>
      'Эта функция будет доступна в следующих обновлениях.';

  @override
  String get loading => 'Загрузка…';

  @override
  String get error => 'Ошибка';

  @override
  String get retry => 'Повторить';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'ОК';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get bootstrapChecking => 'Проверка контента…';

  @override
  String get bootstrapDownloading => 'Загрузка контента…';

  @override
  String get bootstrapSeeding => 'Подготовка базы данных…';

  @override
  String get bootstrapReady => 'Готово';

  @override
  String get bootstrapFailed =>
      'Не удалось загрузить контент. Проверьте подключение.';

  @override
  String get firstLaunchTitle => 'Выберите язык';

  @override
  String get firstLaunchSubtitle => 'Изменить можно в настройках';

  @override
  String get firstLaunchAction => 'Продолжить';

  @override
  String get statsTitle => 'Ваш прогресс';

  @override
  String get statsWeek => 'Неделя';

  @override
  String get statsMonth => 'Месяц';

  @override
  String get statsYear => 'Год';

  @override
  String get statsAllTime => 'Всё время';

  @override
  String get statsAyahsRead => 'Прочитано аятов';

  @override
  String get statsSurahsRead => 'Прочитано сур';

  @override
  String get statsReadingTime => 'Время чтения';

  @override
  String get statsActivity => 'Активность чтения';

  @override
  String get statsPerDay => 'Аятов в день';

  @override
  String get audioChooseReciter => 'Выберите чтеца';

  @override
  String get audioChooseSurah => 'Сура';

  @override
  String get audioChooseAyah => 'Аят';

  @override
  String get audioSpeed => 'Скорость';

  @override
  String get audioSleepTimer => 'Таймер сна';

  @override
  String get audioNightMode => 'Ночной режим';

  @override
  String get audioOff => 'Выключен';

  @override
  String get hifzTitle => 'Заучивание';

  @override
  String get hifzRepeat => 'Повтор';

  @override
  String get hifzAbRepeat => 'Повтор A-B';

  @override
  String get hifzProgress => 'Прогресс';

  @override
  String get tasbihTotal => 'Всего';

  @override
  String get tasbihTapHint => 'нажмите для счёта';

  @override
  String get tasbihReset => 'Сбросить счётчик';

  @override
  String get tasbihSubhanAllah => 'СубханАллах';

  @override
  String get tasbihAlhamdulillah => 'Альхамдулиллях';

  @override
  String get tasbihLaIla => 'Ля иляха илляЛлах';

  @override
  String get tasbihAllahuAkbar => 'Аллаху Акбар';
}
