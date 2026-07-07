import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'playback_sessions_dao.g.dart';

/// DAO для телеметрии аудио-прослушивания (master plan §4.4).
/// Одна запись = одна сессия плеера. Открывается при `play(...)`,
/// закрывается на `stop`/смене суры / длинной паузе.
///
/// Retention — за рамками этого DAO (workmanager позже).
@DriftAccessor(tables: [PlaybackSessions])
class PlaybackSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$PlaybackSessionsDaoMixin {
  PlaybackSessionsDao(super.db);

  /// Открыть новую сессию. Возвращает `id` строки.
  ///
  /// `ayahEnd`, `endedAt`, `durationPlayedMs` заполняются
  /// значениями по умолчанию (см. таблицу `PlaybackSessions`);
  /// [close] обновляет их позже. На свежевставленной строке
  /// `closeReason = 'pending'` — фильтр для «открытых» сессий.
  Future<int> open({
    required String reciterId,
    required int surahId,
    required int ayahStart,
    required DateTime startedAt,
  }) {
    return into(playbackSessions).insert(
      PlaybackSessionsCompanion.insert(
        reciterId: reciterId,
        surahId: surahId,
        ayahStart: ayahStart,
        startedAt: startedAt,
      ),
    );
  }

  /// Закрыть сессию [id] с финальными метриками.
  ///
  /// Названо `finish` (а не `close`) потому, что `close` уже
  /// определён в [DatabaseConnectionUser] — Drift-DAO mixin,
  /// который вызывается для освобождения ресурсов. `close()`
  /// здесь был бы конфликтом сигнатур (см. round-3 hotfix).
  Future<void> finish({
    required int id,
    required int ayahEnd,
    required DateTime endedAt,
    required int durationPlayedMs,
    required String closeReason,
  }) async {
    await (update(playbackSessions)..where((r) => r.id.equals(id))).write(
      PlaybackSessionsCompanion(
        ayahEnd: Value(ayahEnd),
        endedAt: Value(endedAt),
        durationPlayedMs: Value(durationPlayedMs),
        closeReason: Value(closeReason),
      ),
    );
  }

  /// Удалить сессии старше [olderThan]. Возвращает кол-во удалённых.
  /// Используется follow-up `workmanager`-таском для retention в 90 дней.
  Future<int> deleteOlderThan(DateTime olderThan) =>
      (delete(playbackSessions)..where((r) => r.startedAt.isSmallerThanValue(olderThan)))
          .go();

  /// Суммарное время прослушивания (ms) для ректора — нужно для
  /// Phase 2 / Statistics. Идемпотентно читается на UI.
  Future<int> totalPlayedMsFor(String reciterId) async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(duration_played_ms), 0) AS s '
      'FROM playback_sessions WHERE reciter_id = ?',
      variables: [Variable.withString(reciterId)],
      readsFrom: {playbackSessions},
    ).getSingle();
    return row.read<int>('s');
  }
}
