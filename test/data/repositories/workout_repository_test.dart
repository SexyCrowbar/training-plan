import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/data/db/app_database.dart';
import 'package:protocol/data/repositories/workout_repository.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertLog({required int epochMs, int dayId = 1, String blockId = 'power'}) {
    return db.into(db.workoutLogs).insert(WorkoutLogsCompanion.insert(
          date: epochMs,
          dayId: dayId,
          blockId: blockId,
          blockName: 'Test',
          blockIcon: '',
          theme: 'iron',
        ));
  }

  Future<void> insertSet({
    required int logId,
    required String name,
    required int setNumber,
    double? weight,
    int? reps,
    bool completed = true,
  }) async {
    await db.into(db.exerciseSets).insert(ExerciseSetsCompanion.insert(
          logId: logId,
          exerciseName: name,
          setNumber: setNumber,
          weightKg: Value(weight),
          reps: Value(reps),
          completed: Value(completed),
        ));
  }

  group('getLastSessionTopSet', () {
    test('returns null when no history exists', () async {
      expect(await repo.getLastSessionTopSet('Bench'), isNull);
    });

    test('returns top set from the most recent session', () async {
      final older = await insertLog(epochMs: 1000);
      await insertSet(logId: older, name: 'Bench', setNumber: 1, weight: 100, reps: 5);

      final newer = await insertLog(epochMs: 2000);
      await insertSet(logId: newer, name: 'Bench', setNumber: 1, weight: 80, reps: 3);
      await insertSet(logId: newer, name: 'Bench', setNumber: 2, weight: 85, reps: 2);
      await insertSet(logId: newer, name: 'Bench', setNumber: 3, weight: 80, reps: 5);

      final result = await repo.getLastSessionTopSet('Bench');
      expect(result, isNotNull);
      expect(result!.weightKg, 85);
      expect(result.reps, 2);
    });

    test('bodyweight (null weight): returns set with most reps', () async {
      final log = await insertLog(epochMs: 1000);
      await insertSet(logId: log, name: 'Pull-Ups', setNumber: 1, weight: null, reps: 10);
      await insertSet(logId: log, name: 'Pull-Ups', setNumber: 2, weight: null, reps: 8);

      final result = await repo.getLastSessionTopSet('Pull-Ups');
      expect(result, isNotNull);
      expect(result!.weightKg, isNull);
      expect(result.reps, 10);
    });

    test('ignores incomplete sets', () async {
      final log = await insertLog(epochMs: 1000);
      await insertSet(logId: log, name: 'Bench', setNumber: 1, weight: 100, reps: 5, completed: true);
      await insertSet(logId: log, name: 'Bench', setNumber: 2, weight: 120, reps: 3, completed: false);

      final result = await repo.getLastSessionTopSet('Bench');
      expect(result!.weightKg, 100);
    });

    test('tie on weight breaks by reps descending', () async {
      final log = await insertLog(epochMs: 1000);
      await insertSet(logId: log, name: 'Bench', setNumber: 1, weight: 80, reps: 5);
      await insertSet(logId: log, name: 'Bench', setNumber: 2, weight: 80, reps: 8);
      await insertSet(logId: log, name: 'Bench', setNumber: 3, weight: 80, reps: 3);

      final result = await repo.getLastSessionTopSet('Bench');
      expect(result!.reps, 8);
    });

    test('skips newer sessions that have no completed sets of this exercise', () async {
      final old = await insertLog(epochMs: 1000);
      await insertSet(logId: old, name: 'Bench', setNumber: 1, weight: 100, reps: 5, completed: true);

      final newer = await insertLog(epochMs: 2000);
      await insertSet(logId: newer, name: 'Bench', setNumber: 1, weight: 120, reps: 3, completed: false);
      await insertSet(logId: newer, name: 'Squats', setNumber: 1, weight: 140, reps: 5, completed: true);

      final result = await repo.getLastSessionTopSet('Bench');
      expect(result!.weightKg, 100);
    });
  });
}
