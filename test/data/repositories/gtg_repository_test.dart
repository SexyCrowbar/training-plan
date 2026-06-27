import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/data/db/app_database.dart';
import 'package:protocol/data/repositories/gtg_repository.dart';

void main() {
  late AppDatabase db;
  late GtgRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = GtgRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertGtgLog(String dateKey, int dayId, int count) async {
    await db
        .into(db.gtgLogs)
        .insert(
          GtgLogsCompanion.insert(date: dateKey, dayId: dayId, count: count),
        );
  }

  group('watchCountsFor', () {
    test('returns only rows matching the given dateKey', () async {
      await insertGtgLog('2026-06-26', 1, 3);
      await insertGtgLog('2026-06-27', 1, 5);

      final result = await repo.watchCountsFor('2026-06-26').first;
      expect(result, equals({1: 3}));
    });

    test('returns only the matching date, not others', () async {
      await insertGtgLog('2026-06-26', 1, 3);
      await insertGtgLog('2026-06-27', 1, 5);

      final result = await repo.watchCountsFor('2026-06-27').first;
      expect(result, equals({1: 5}));
    });

    test('returns empty map for a date with no rows', () async {
      await insertGtgLog('2026-06-26', 1, 3);

      final result = await repo.watchCountsFor('2099-01-01').first;
      expect(result, isEmpty);
    });
  });
}
