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
  String settingsCacheLimitValue(Object mb) {
    return '$mb МБ';
  }

  @override
  String get settingsCacheClearConfirm => 'Удалить все скачанные аудио?';

  @override
  String get settingsCacheCleared => 'Кеш очищен';

  @override
  String settingsCacheEvicted(Object count) {
    return 'Удалено файлов: $count';
  }

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
  String get bootstrapLocalLoading => 'Загрузка Корана (оффлайн)…';

  @override
  String get bootstrapLocalReady => 'Готово (оффлайн)';

  @override
  String get bootstrapNetworkChecking => 'Проверка обновлений…';

  @override
  String get bootstrapNetworkFailed => 'Оффлайн-режим (обновления пропущены)';

  @override
  String get bootstrapNetworkDone => 'Обновлено';

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

  @override
  String get surahName1 => 'Аль-Фатиха';

  @override
  String get surahName2 => 'Аль-Бакара';

  @override
  String get surahName3 => 'Аль Имран';

  @override
  String get surahName4 => 'Ан-Ниса';

  @override
  String get surahName5 => 'Аль-Маида';

  @override
  String get surahName6 => 'Аль-Ан\'ам';

  @override
  String get surahName7 => 'Аль-А\'раф';

  @override
  String get surahName8 => 'Аль-Анфаль';

  @override
  String get surahName9 => 'Ат-Тавба';

  @override
  String get surahName10 => 'Юнус';

  @override
  String get surahName11 => 'Худ';

  @override
  String get surahName12 => 'Юсуф';

  @override
  String get surahName13 => 'Ар-Ра\'д';

  @override
  String get surahName14 => 'Ибрахим';

  @override
  String get surahName15 => 'Аль-Хиджр';

  @override
  String get surahName16 => 'Ан-Нахль';

  @override
  String get surahName17 => 'Аль-Исра';

  @override
  String get surahName18 => 'Аль-Кехф';

  @override
  String get surahName19 => 'Марьям';

  @override
  String get surahName20 => 'Та Ха';

  @override
  String get surahName21 => 'Аль-Анбия';

  @override
  String get surahName22 => 'Аль-Хаджж';

  @override
  String get surahName23 => 'Аль-Му\'минун';

  @override
  String get surahName24 => 'Ан-Нур';

  @override
  String get surahName25 => 'Аль-Фуркан';

  @override
  String get surahName26 => 'Аш-Шу\'ара';

  @override
  String get surahName27 => 'Ан-Намль';

  @override
  String get surahName28 => 'Аль-Касас';

  @override
  String get surahName29 => 'Аль-\'Анкабут';

  @override
  String get surahName30 => 'Ар-Рум';

  @override
  String get surahName31 => 'Лукман';

  @override
  String get surahName32 => 'Ас-Саджда';

  @override
  String get surahName33 => 'Аль-Ахзаб';

  @override
  String get surahName34 => 'Саба';

  @override
  String get surahName35 => 'Фатыр';

  @override
  String get surahName36 => 'Ясин';

  @override
  String get surahName37 => 'Ас-Саффат';

  @override
  String get surahName38 => 'Сад';

  @override
  String get surahName39 => 'Аз-Зумар';

  @override
  String get surahName40 => 'Гафир';

  @override
  String get surahName41 => 'Фуссылат';

  @override
  String get surahName42 => 'Аш-Шура';

  @override
  String get surahName43 => 'Аз-Зухруф';

  @override
  String get surahName44 => 'Ад-Духан';

  @override
  String get surahName45 => 'Аль-Джасия';

  @override
  String get surahName46 => 'Аль-Ахкаф';

  @override
  String get surahName47 => 'Мухаммад';

  @override
  String get surahName48 => 'Аль-Фатх';

  @override
  String get surahName49 => 'Аль-Худжурат';

  @override
  String get surahName50 => 'Каф';

  @override
  String get surahName51 => 'Аз-Зарият';

  @override
  String get surahName52 => 'Ат-Тур';

  @override
  String get surahName53 => 'Ан-Наджм';

  @override
  String get surahName54 => 'Аль-Камар';

  @override
  String get surahName55 => 'Ар-Рахман';

  @override
  String get surahName56 => 'Аль-Ваки\'а';

  @override
  String get surahName57 => 'Аль-Хадид';

  @override
  String get surahName58 => 'Аль-Муджадила';

  @override
  String get surahName59 => 'Аль-Хашр';

  @override
  String get surahName60 => 'Аль-Мумтахана';

  @override
  String get surahName61 => 'Ас-Сафф';

  @override
  String get surahName62 => 'Аль-Джуму\'а';

  @override
  String get surahName63 => 'Аль-Мунафикун';

  @override
  String get surahName64 => 'Ат-Тагабун';

  @override
  String get surahName65 => 'Ат-Талак';

  @override
  String get surahName66 => 'Ат-Тахрим';

  @override
  String get surahName67 => 'Аль-Мульк';

  @override
  String get surahName68 => 'Аль-Калам';

  @override
  String get surahName69 => 'Аль-Хакка';

  @override
  String get surahName70 => 'Аль-Ма\'аридж';

  @override
  String get surahName71 => 'Нух';

  @override
  String get surahName72 => 'Аль-Джинн';

  @override
  String get surahName73 => 'Аль-Муззаммиль';

  @override
  String get surahName74 => 'Аль-Муддассир';

  @override
  String get surahName75 => 'Аль-Кыяма';

  @override
  String get surahName76 => 'Аль-Инсан';

  @override
  String get surahName77 => 'Аль-Мурсалят';

  @override
  String get surahName78 => 'Ан-Наба';

  @override
  String get surahName79 => 'Ан-Нази\'ат';

  @override
  String get surahName80 => 'Абаса';

  @override
  String get surahName81 => 'Ат-Таквир';

  @override
  String get surahName82 => 'Аль-Инфитар';

  @override
  String get surahName83 => 'Аль-Мутаффифин';

  @override
  String get surahName84 => 'Аль-Иншикак';

  @override
  String get surahName85 => 'Аль-Бурудж';

  @override
  String get surahName86 => 'Ат-Тарик';

  @override
  String get surahName87 => 'Аль-А\'ля';

  @override
  String get surahName88 => 'Аль-Гашия';

  @override
  String get surahName89 => 'Аль-Фаджр';

  @override
  String get surahName90 => 'Аль-Баляд';

  @override
  String get surahName91 => 'Аш-Шамс';

  @override
  String get surahName92 => 'Аль-Ляйль';

  @override
  String get surahName93 => 'Ад-Духа';

  @override
  String get surahName94 => 'Аш-Шарх';

  @override
  String get surahName95 => 'Ат-Тин';

  @override
  String get surahName96 => 'Аль-Алак';

  @override
  String get surahName97 => 'Аль-Кадр';

  @override
  String get surahName98 => 'Аль-Баййина';

  @override
  String get surahName99 => 'Аз-Залзаля';

  @override
  String get surahName100 => 'Аль-Адийат';

  @override
  String get surahName101 => 'Аль-Кари\'а';

  @override
  String get surahName102 => 'Ат-Такасур';

  @override
  String get surahName103 => 'Аль-Аср';

  @override
  String get surahName104 => 'Аль-Хумаза';

  @override
  String get surahName105 => 'Аль-Филь';

  @override
  String get surahName106 => 'Курайш';

  @override
  String get surahName107 => 'Аль-Ма\'ун';

  @override
  String get surahName108 => 'Аль-Кавсар';

  @override
  String get surahName109 => 'Аль-Кафирун';

  @override
  String get surahName110 => 'Ан-Наср';

  @override
  String get surahName111 => 'Аль-Масад';

  @override
  String get surahName112 => 'Аль-Ихлас';

  @override
  String get surahName113 => 'Аль-Фаляк';

  @override
  String get surahName114 => 'Ан-Нас';

  @override
  String get reciterNameAlafasy => 'Мишари Рашид аль-Афаси';

  @override
  String get reciterNameAbdulbasitmurattal => 'Абдул-Басит Абд ус-Самад';

  @override
  String get reciterNameHusary => 'Махмуд Халиль аль-Хусари';

  @override
  String get reciterNameMinshawi => 'Мухаммад Сиддик аль-Миншави';

  @override
  String get reciterNameAbdurrahmaansudais => 'Абдур-Рахман ас-Судайс';

  @override
  String get reciterNameSaaborimadina => 'Сауд аш-Шурайм';

  @override
  String get reciterNameHudhaify => 'Али аль-Худайфи';

  @override
  String get reciterNameAhmedajamy => 'Ахмад аль-Аджми';

  @override
  String get nowPlaying => 'Идёт';

  @override
  String get selectSurahAndPlay => 'Выберите суру и нажмите play';

  @override
  String get surahLabel => 'Сура';

  @override
  String get tabAyahs => 'Аяты';

  @override
  String get searchAyahHint => 'Введите запрос для поиска по тексту Корана';

  @override
  String get learnTitle => 'Слова для повторения';

  @override
  String get learnSkip => 'Пропустить';

  @override
  String learnRemaining(Object count) {
    return 'Осталось: $count';
  }

  @override
  String learnSession(Object reviewed) {
    return 'Сессия: $reviewed';
  }

  @override
  String get learnStatusMastered => 'Освоено';

  @override
  String get learnStatusReviewing => 'Повторение';

  @override
  String get learnStatusLearning => 'Изучение';

  @override
  String get learnStatusNew => 'Новое';

  @override
  String get learnQuality0 => 'Не помню';

  @override
  String get learnQuality1 => 'С трудом';

  @override
  String get learnQuality2 => 'С усилием';

  @override
  String get learnQuality3 => 'Помню';

  @override
  String get learnQuality4 => 'Хорошо';

  @override
  String get learnQuality5 => 'Отлично';

  @override
  String get learnEmptyTitle => 'Все слова выучены';

  @override
  String get learnEmptyHint =>
      'Добавьте новые слова из чтения,\nчтобы продолжить повторение.';

  @override
  String get wordTranslation => 'Перевод';

  @override
  String get wordLemma => 'Лемма';

  @override
  String get wordRoot => 'Корень';

  @override
  String get wordInVocab => 'В словаре';

  @override
  String get wordAddToVocab => 'Добавить в словарь';

  @override
  String get wordEmptyHint =>
      'Перевод и грамматика появятся, когда словарь будет пополнен.';

  @override
  String notesForAyah(Object number) {
    return 'Заметки к аяту $number';
  }

  @override
  String get notesEmpty => 'Заметок пока нет.\nДобавьте первую ниже.';

  @override
  String get notesHint => 'Текст заметки…';

  @override
  String ayahLabel(Object number) {
    return 'Аят $number';
  }

  @override
  String get wordSameRoot => 'Другие слова с тем же корнем';

  @override
  String get readerPrevSurah => 'Предыдущая сура';

  @override
  String get readerNextSurah => 'Следующая сура';

  @override
  String get readerFirstSurah => 'Первая сура';

  @override
  String get readerLastSurah => 'Последняя сура';

  @override
  String juzOpenError(Object number) {
    return 'Не удалось открыть Джуз $number';
  }
}
