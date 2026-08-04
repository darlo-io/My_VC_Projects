import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/daos/tafsir_dao.dart';
import '../../../core/i18n/tafsir_ru_names.dart';
import 'quran_com_tafsir_api.dart';

/// Состояние фоновой синхронизации списка тафсиров.
enum TafsirsSyncStage {
  idle,
  checkingCache,
  running,
  completed,
  failed,
}

class TafsirsSyncState {
  const TafsirsSyncState({
    required this.stage,
    this.lastSyncedAt,
    this.error,
    this.insertedCount,
  });

  final TafsirsSyncStage stage;
  final DateTime? lastSyncedAt;
  final Object? error;
  final int? insertedCount;

  bool get isRunning =>
      stage == TafsirsSyncStage.checkingCache ||
      stage == TafsirsSyncStage.running;

  static const idle = TafsirsSyncState(stage: TafsirsSyncStage.idle);

  // Round 9.6 (code review #M14): добавлены параметры
  // `clearError` и `clearInsertedCount` для явного сброса
  // nullable полей. Без них вызов `copyWith(stage: X)` пассивно
  // сбрасывал `error` и `insertedCount` в null — что в этом
  // API намеренно (если перешли в новую стадию, прошлая
  // ошибка уже неактуальна), но это было сложно отлаживать.
  //
  // Чтобы дать вызывающему коду выбор, добавлены явные
  // `clearError: true` / `clearInsertedCount: true`. По
  // умолчанию `copyWith` сохраняет предыдущие значения (как
  // для `stage` и `lastSyncedAt`).
  TafsirsSyncState copyWith({
    TafsirsSyncStage? stage,
    DateTime? lastSyncedAt,
    Object? error,
    int? insertedCount,
    bool clearError = false,
    bool clearInsertedCount = false,
  }) {
    return TafsirsSyncState(
      stage: stage ?? this.stage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: clearError ? null : (error ?? this.error),
      insertedCount: clearInsertedCount
          ? null
          : (insertedCount ?? this.insertedCount),
    );
  }
}

/// Фоновый воркер для синхронизации списка тафсиров с Quran.com API.
///
/// Триггеры:
///   1. **Cold start** — `unawaited(tafsirsSyncService.maybeSync())`
///      из `ContentBootstrapper.bootstrap()`.
///   2. **Manual** — кнопка «Обновить список» в tafsir picker'е
///      вызывает [forceSync] (TTL игнорируется).
///
/// Семантика кеша:
///   - [maybeSync] скипает sync если `MAX(syncedAt) - now < cacheTtl` **И**
///     в БД уже есть хотя бы один source для запрошенного языка
///     (`countSourcesByLanguage(lang) > 0`).
///   - TTL — 30 дней, т.к. список тафсиров у Quran.com меняется
///     крайне редко (добавление нового tafsir — раз в несколько лет).
class TafsirsSyncService {
  TafsirsSyncService(
    this._dao,
    this._api, {
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  final TafsirDao _dao;
  final QuranComTafsirApi _api;

  /// SharedPreferences для кеша `_lastSyncedAt` (TTL между
  /// сессиями). Round 9.6: обязательный параметр в production
  /// коде. Unit-тесты могут передавать `setMockInitialValues({})`-
  /// инициализированный instance.
  final SharedPreferences _prefs;

  final ValueNotifier<TafsirsSyncState> state =
      ValueNotifier(TafsirsSyncState.idle);

  static const _kDefaultCacheTtl = Duration(days: 30);

  /// Round 9.6 (code review #M6): cache-TTL timestamp теперь
  /// персистится в `SharedPreferences` (ключ
  /// `tafsirs.lastSyncedAt`), а не только in-memory. Раньше после
  /// cold start `_lastSyncedAt == null` → `forceSync` всегда
  /// срабатывал на каждом запуске, даже если sync был час назад.
  /// Теперь TTL работает корректно между сессиями.
  static const _kLastSyncedAtKey = 'tafsirs.lastSyncedAt';

  DateTime? _lastSyncedAt;

  /// Читает `_lastSyncedAt` из кеша. Идемпотентно — повторный
  /// вызов возвращает то же значение. На cold start возвращает
  /// последнее сохранённое время вместо `null` (раньше — `null`).
  Future<DateTime?> _loadLastSyncedAt() async {
    final ms = _prefs.getInt(_kLastSyncedAtKey);
    if (ms == null) return _lastSyncedAt;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> _saveLastSyncedAt(DateTime dt) async {
    _lastSyncedAt = dt;
    await _prefs.setInt(_kLastSyncedAtKey, dt.millisecondsSinceEpoch);
  }

  Future<void> maybeSync({
    String languageCode = 'ru',
    Duration cacheTtl = _kDefaultCacheTtl,
  }) async {
    if (state.value.isRunning) return;

    state.value = state.value.copyWith(
      stage: TafsirsSyncStage.checkingCache,
      clearError: true,
    );
    try {
      final count = await _dao.countSourcesByLanguage(languageCode);
      // Round 9.6 (code review #M6): загружаем TTL-таймстамп из
      // SharedPreferences для корректной работы между сессиями.
      final last = await _loadLastSyncedAt();
      final freshEnough =
          last != null && DateTime.now().difference(last) < cacheTtl;
      if (freshEnough && count > 0) {
        state.value = TafsirsSyncState(
          stage: TafsirsSyncStage.idle,
          lastSyncedAt: last,
        );
        developer.log(
          'tafsirs sync: cache fresh (age ${DateTime.now().difference(last)}'
          ', count=$count), skipping',
          name: 'tafsirs_sync',
        );
        return;
      }
      developer.log(
        'tafsirs sync: cache stale (last=$last, count=$count), starting sync',
        name: 'tafsirs_sync',
      );
    } catch (e) {
      developer.log(
        'tafsirs sync: cache check failed ($e), proceeding to sync',
        name: 'tafsirs_sync',
      );
    }
    await forceSync(languageCode: languageCode);
  }

  /// Принудительная синхронизация (обходит все проверки кеша).
  /// Используется из кнопки «Обновить список» в picker'е и из
  /// per-ayah [fetchTafsirForAyah] для гарантии наличия source в БД.
  Future<int> forceSync({String languageCode = 'ru'}) async {
    state.value = state.value.copyWith(
      stage: TafsirsSyncStage.running,
      clearError: true,
      clearInsertedCount: true,
    );
    try {
      final dtos = await _api.fetchSources(language: languageCode);
      var n = 0;
      for (final d in dtos) {
        // API возвращает language_name вроде "arabic", "english", "russian".
        // Нормализуем в короткий код для UI-фильтрации.
        final lang = _normalizeLang(d.languageName, fallback: languageCode);
        await _dao.upsertSource(
          id: d.id,
          slug: d.slug,
          // API не отдаёт арабское имя отдельным полем для всех tafsirs —
          // используем `name` как fallback (часто на арабском).
          nameAr: d.name,
          nameEn: d.translatedName.isNotEmpty ? d.translatedName : d.name,
          // Русский перевод (только для ru-локали). Приоритет:
          //   1. kTafsirRuNames[id] — hard-coded для Arabic-original
          //      tafsirs которых Quran.com не переводит на русский;
          //   2. d.translatedName — русский перевод от API
          //      (если бы был; на практике почти не встречается);
          //   3. null — UI fallback на nameEn (английская транслитерация).
          //
          // Sprint 2.5.2 (round 3 bugfix): до этого фикса
          // `nameRu` падал на null и UI всегда показывал английские
          // имена «Tafsir Ibn Kathir», «Al-Sa'di» etc. С этим
          // фиксом + hard-coded `kTafsirRuNames` UI показывает
          // «Ибн Касир (Исмаил ибн Умар)», «Ас-Саади (Абдур-Рахман
          // ибн Насир)» и т.д. (см. `lib/core/i18n/tafsir_ru_names.dart`).
          nameRu: languageCode == 'ru'
              ? (kTafsirRuNames[d.id] ??
                  (d.translatedName.isNotEmpty ? d.translatedName : null))
              : null,
          languageCode: lang,
          quranComId: d.id,
        );
        n += 1;
      }
      final now = DateTime.now();
      // Round 9.6 (code review #M6): persist + in-memory update.
      await _saveLastSyncedAt(now);
      state.value = TafsirsSyncState(
        stage: TafsirsSyncStage.completed,
        lastSyncedAt: now,
        insertedCount: n,
      );
      developer.log(
        'tafsirs sync: completed, inserted/updated=$n (lang=$languageCode)',
        name: 'tafsirs_sync',
      );
      return n;
    } catch (e, st) {
      developer.log(
        'tafsirs sync: failed: $e',
        name: 'tafsirs_sync',
        error: e,
        stackTrace: st,
      );
      state.value = TafsirsSyncState(
        stage: TafsirsSyncStage.failed,
        error: e,
      );
      rethrow;
    }
  }

  /// Дёргает Quran.com для конкретного (ayah, source) и сохраняет
  /// в БД.
  ///
  /// Аргументы:
  ///   - [tafsirSourceId] — **LOCAL** `tafsir_sources.id` (PK),
  ///     не Quran.com id. DB FK constraint `tafsirs.tafsir_source_id`
  ///     требует именно local id. Quran.com id (`quran_com_id`)
  ///     вычисляется внутри функции через lookup по этому
  ///     local id — без этого round 2 фикс использовал Quran.com
  ///     id для DB INSERT, что нарушало FK constraint и watch-stream
  ///     в UI не получал событие (бесконечный loading).
  ///
  /// `verseKey` формируется как "N:V" (surah:ayah).
  ///
  /// Если source ещё не синхронизирован — сначала вызывает
  /// [forceSync], потом повторяет lookup. Если API возвращает null
  /// (404) — кидает [TafsirNotFoundException], UI показывает
  /// empty-state.
  Future<void> fetchTafsirForAyah({
    required int ayahId,
    required int surahId,
    required int ayahNumber,
    required int tafsirSourceId,
    String languageCode = 'ru',
  }) async {
    var src = await _dao.getById(tafsirSourceId);
    if (src == null) {
      // Источник не в БД — синхронизируем список с Quran.com
      // (например, после `forceSync` пользователь нажал на tafsir
      // не из picker'а, а из deep-link).
      await forceSync(languageCode: languageCode);
      src = await _dao.getById(tafsirSourceId);
    }
    if (src == null) {
      throw TafsirNotFoundException(
        'tafsir source id=$tafsirSourceId not in DB after sync',
      );
    }
    final quranComId = src.quranComId ?? src.id;
    final verseKey = '$surahId:$ayahNumber';
    // **Round 4 bugfix**: explicit `.timeout(90s)` — Dio `receiveTimeout`
    // 60s срабатывает, но иногда на медленных сетях запрос висит
    // после timeout (connection pool не закрылся). 90s = receiveTimeout
    // +30s buffer, после чего падает `TimeoutException`, который
    // `_fetch` ловит и показывает retry-кнопку в UI. Без этого
    // пользователь видел бы бесконечный loading state.
    //
    // Curl-проверка на c1316607 (16-17 июля) показывала 0.5-1s
    // response для этого endpoint — значит 90s более чем достаточно
    // для нормального сценария. Превышение 90s = проблема с сетью.
    //
    // Round 9.6 (code review #C10): теперь API возвращает
    // [TafsirFetchResult] — sealed класс с тремя вариантами:
    // success, notFound, timeout. Это позволяет UI показать
    // разные сообщения: «нет тафсира» vs «не удалось загрузить,
    // повторить?». Раньше оба случая мапились на один
    // [TafsirNotFoundException].
    final result = await _api.fetchByAyah(
      tafsirId: quranComId,
      verseKey: verseKey,
    ).timeout(
      const Duration(seconds: 90),
      onTimeout: () {
        developer.log(
          'tafsir fetch TIMEOUT after 90s for tafsirId=$quranComId, '
          'ayah=$verseKey',
          name: 'tafsir_sync',
        );
        return const TafsirTimeout(Duration(seconds: 90));
      },
    );
    switch (result) {
      case TafsirSuccess(:final verse):
        await _dao.upsertTafsir(
          ayahId: ayahId,
          tafsirSourceId: tafsirSourceId, // LOCAL id — FK constraint
          text: verse.text,
        );
      case TafsirNotFound():
        throw TafsirNotFoundException(
          'No tafsir for quranComId=$quranComId, ayah=$verseKey (404)',
        );
      case TafsirTimeout():
        throw TafsirNotFoundException(
          'No tafsir for quranComId=$quranComId, ayah=$verseKey '
          '(timeout ${result.timeoutDuration.inSeconds}s)',
        );
    }
  }

  /// Маппинг `language_name` от API → короткий код.
  /// Quran.com отдаёт "arabic", "english", "russian", "urdu" и т.д.
  String _normalizeLang(String name, {required String fallback}) {
    final lower = name.toLowerCase();
    if (lower.contains('arab')) return 'ar';
    if (lower.contains('russ')) return 'ru';
    if (lower.contains('engl')) return 'en';
    if (lower.contains('urd')) return 'ur';
    if (lower.contains('turk')) return 'tr';
    if (lower.contains('fr')) return 'fr';
    return fallback;
  }
}

/// 404 от Quran.com (ayah не покрыт тафсиром). UI ловит в retry-handler
/// и показывает empty-state «Нет тафсира для этого аята».
class TafsirNotFoundException implements Exception {
  TafsirNotFoundException(this.message);
  final String message;
  @override
  String toString() => 'TafsirNotFoundException: $message';
}
