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

  Future<int> insertLog({
    required int epochMs,
    int dayId = 1,
    String blockId = 'power',
  }) {
    return db
        .into(db.workoutLogs)
        .insert(
          WorkoutLogsCompanion.insert(
            date: epochMs,
            dayId: dayId,
            blockId: blockId,
            blockName: 'Test',
            blockIcon: '',
            theme: 'iron',
          ),
        );
  }

  Future<void> insertSet({
    required int logId,
    required String name,
    required int setNumber,
    String exerciseId = '',
    double? weight,
    int? reps,
    bool completed = true,
  }) async {
    await db
        .into(db.exerciseSets)
        .insert(
          ExerciseSetsCompanion.insert(
            logId: logId,
            exerciseId: Value(exerciseId),
            exerciseName: name,
            setNumber: setNumber,
            weightKg: Value(weight),
            reps: Value(reps),
            completed: Value(completed),
          ),
        );
  }

  group('getLastSessionTopSet', () {
    test('returns null when no history exists', () async {
      expect(await repo.getLastSessionTopSet('Bench'), isNull);
    });

    test('returns top set from the most recent session', () async {
      final older = await insertLog(epochMs: 1000);
      await insertSet(
        logId: older,
        name: 'Bench',
        setNumber: 1,
        weight: 100,
        reps: 5,
      );

      final newer = await insertLog(epochMs: 2000);
      await insertSet(
        logId: newer,
        name: 'Bench',
        setNumber: 1,
        weight: 80,
        reps: 3,
      );
      await insertSet(
        logId: newer,
        name: 'Bench',
        setNumber: 2,
        weight: 85,
        reps: 2,
      );
      await insertSet(
        logId: newer,
        name: 'Bench',
        setNumber: 3,
        weight: 80,
        reps: 5,
      );

      final result = await repo.getLastSessionTopSet('Bench');
      expect(result, isNotNull);
      expect(result!.weightKg, 85);
      expect(result.reps, 2);
    });

    test('bodyweight (null weight): returns set with most reps', () async {
      final log = await insertLog(epochMs: 1000);
      await insertSet(
        logId: log,
        name: 'Pull-Ups',
        setNumber: 1,
        weight: null,
        reps: 10,
      );
      await insertSet(
        logId: log,
        name: 'Pull-Ups',
        setNumber: 2,
        weight: null,
        reps: 8,
      );

      final result = await repo.getLastSessionTopSet('Pull-Ups');
      expect(result, isNotNull);
      expect(result!.weightKg, isNull);
      expect(result.reps, 10);
    });

    test('ignores incomplete sets', () async {
      final log = await insertLog(epochMs: 1000);
      await insertSet(
        logId: log,
        name: 'Bench',
        setNumber: 1,
        weight: 100,
        reps: 5,
        completed: true,
      );
      await insertSet(
        logId: log,
        name: 'Bench',
        setNumber: 2,
        weight: 120,
        reps: 3,
        completed: false,
      );

      final result = await repo.getLastSessionTopSet('Bench');
      expect(result!.weightKg, 100);
    });

    test('tie on weight breaks by reps descending', () async {
      final log = await insertLog(epochMs: 1000);
      await insertSet(
        logId: log,
        name: 'Bench',
        setNumber: 1,
        weight: 80,
        reps: 5,
      );
      await insertSet(
        logId: log,
        name: 'Bench',
        setNumber: 2,
        weight: 80,
        reps: 8,
      );
      await insertSet(
        logId: log,
        name: 'Bench',
        setNumber: 3,
        weight: 80,
        reps: 3,
      );

      final result = await repo.getLastSessionTopSet('Bench');
      expect(result!.reps, 8);
    });

    test(
      'skips newer sessions that have no completed sets of this exercise',
      () async {
        final old = await insertLog(epochMs: 1000);
        await insertSet(
          logId: old,
          name: 'Bench',
          setNumber: 1,
          weight: 100,
          reps: 5,
          completed: true,
        );

        final newer = await insertLog(epochMs: 2000);
        await insertSet(
          logId: newer,
          name: 'Bench',
          setNumber: 1,
          weight: 120,
          reps: 3,
          completed: false,
        );
        await insertSet(
          logId: newer,
          name: 'Squats',
          setNumber: 1,
          weight: 140,
          reps: 5,
          completed: true,
        );

        final result = await repo.getLastSessionTopSet('Bench');
        expect(result!.weightKg, 100);
      },
    );
  });

  group('getSetsForExercise', () {
    test('unifies history across a rename when exerciseId matches', () async {
      // First log: exercise called 'Bench Press' with exerciseId 'uuid-1'
      final log1 = await insertLog(epochMs: 1000);
      await insertSet(
        logId: log1,
        name: 'Bench Press',
        exerciseId: 'uuid-1',
        setNumber: 1,
        weight: 100,
        reps: 5,
      );

      // Second log: same exerciseId but renamed to 'Barbell Bench'
      final log2 = await insertLog(epochMs: 2000);
      await insertSet(
        logId: log2,
        name: 'Barbell Bench',
        exerciseId: 'uuid-1',
        setNumber: 1,
        weight: 105,
        reps: 4,
      );

      final results = await repo.getSetsForExercise(
        exerciseId: 'uuid-1',
        exerciseName: 'Barbell Bench',
      );

      // Both sets from both logs should be returned (history unified across rename)
      expect(results.length, 2);
      final weights = results.map((r) => r.set.weightKg).toSet();
      expect(weights, containsAll([100.0, 105.0]));
    });

    test('falls back to name when exerciseId is empty (legacy rows)', () async {
      final log = await insertLog(epochMs: 1000);
      // Legacy/imported row: exerciseId is empty string
      await insertSet(
        logId: log,
        name: 'Squat',
        exerciseId: '',
        setNumber: 1,
        weight: 120,
        reps: 5,
      );

      final results = await repo.getSetsForExercise(
        exerciseId: '',
        exerciseName: 'Squat',
      );

      expect(results.length, 1);
      expect(results.first.set.weightKg, 120.0);
    });

    test(
      'does not return unrelated rows when exerciseId is non-empty',
      () async {
        // Insert a set for 'uuid-1'
        final log1 = await insertLog(epochMs: 1000);
        await insertSet(
          logId: log1,
          name: 'Bench Press',
          exerciseId: 'uuid-1',
          setNumber: 1,
          weight: 100,
          reps: 5,
        );

        // Insert a set for a completely different exercise
        final log2 = await insertLog(epochMs: 2000);
        await insertSet(
          logId: log2,
          name: 'Nope',
          exerciseId: 'uuid-other',
          setNumber: 1,
          weight: 80,
          reps: 8,
        );

        // Query with uuid-1 but exerciseName 'Nope' — should NOT return the
        // 'Nope'/'uuid-other' row, only the uuid-1 row.
        final results = await repo.getSetsForExercise(
          exerciseId: 'uuid-1',
          exerciseName: 'Nope',
        );

        // Only the uuid-1 set should be returned (matched by id), not the
        // 'Nope'/'uuid-other' one.
        expect(results.length, 1);
        expect(results.first.set.weightKg, 100.0);
      },
    );
  });
}
