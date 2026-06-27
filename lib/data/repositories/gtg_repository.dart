import 'package:drift/drift.dart';

import '../../domain/util/week.dart';
import '../db/app_database.dart';

class GtgRepository {
  final AppDatabase db;
  GtgRepository(this.db);

  Stream<Map<int, int>> watchCountsFor(String dateKey) {
    return (db.select(db.gtgLogs)..where((g) => g.date.equals(dateKey)))
        .watch()
        .map((rows) => {for (final r in rows) r.dayId: r.count});
  }

  Stream<Map<int, int>> watchTodayCounts() => watchCountsFor(todayKey());

  Future<int> countFor(int dayId, [String? dateStr]) async {
    final key = dateStr ?? todayKey();
    final row = await (db.select(db.gtgLogs)
          ..where((g) => g.date.equals(key) & g.dayId.equals(dayId)))
        .getSingleOrNull();
    return row?.count ?? 0;
  }

  Future<void> setCount(int dayId, int count) async {
    final clamped = count < 0 ? 0 : count;
    final key = todayKey();
    await db.into(db.gtgLogs).insertOnConflictUpdate(
          GtgLogsCompanion.insert(date: key, dayId: dayId, count: clamped),
        );
  }

  Future<void> adjust(int dayId, int delta) async {
    final current = await countFor(dayId);
    await setCount(dayId, current + delta);
  }

  /// Clears all GTG rows. Used by "Start new week".
  Future<void> clearAll() async {
    await db.delete(db.gtgLogs).go();
  }
}
