import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../../domain/util/week.dart';

class SetInput {
  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final bool completed;

  SetInput({
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.completed,
  });
}

class WorkoutRepository {
  final AppDatabase db;
  WorkoutRepository(this.db);

  /// Save a workout log and its sets in a transaction.
  /// Returns the new workoutLog id.
  Future<int> saveWorkout({
    required DateTime date,
    required int? templateId,
    required int dayId,
    required String blockId,
    required String blockName,
    required String blockIcon,
    required String theme,
    required List<SetInput> sets,
  }) async {
    return db.transaction(() async {
      final logId = await db.into(db.workoutLogs).insert(
            WorkoutLogsCompanion.insert(
              date: date.millisecondsSinceEpoch,
              templateId: Value(templateId),
              dayId: dayId,
              blockId: blockId,
              blockName: blockName,
              blockIcon: blockIcon,
              theme: theme,
            ),
          );
      for (final s in sets) {
        await db.into(db.exerciseSets).insert(
              ExerciseSetsCompanion.insert(
                logId: logId,
                exerciseId: Value(s.exerciseId),
                exerciseName: s.exerciseName,
                setNumber: s.setNumber,
                weightKg: Value(s.weightKg),
                reps: Value(s.reps),
                completed: Value(s.completed),
              ),
            );
      }
      return logId;
    });
  }

  Future<void> deleteLog(int logId) async {
    await (db.delete(db.workoutLogs)..where((l) => l.id.equals(logId))).go();
  }

  Stream<List<WorkoutLog>> watchAllLogs() {
    return (db.select(db.workoutLogs)..orderBy([(l) => OrderingTerm.desc(l.date)])).watch();
  }

  Future<List<WorkoutLog>> getAllLogs() {
    return (db.select(db.workoutLogs)..orderBy([(l) => OrderingTerm.desc(l.date)])).get();
  }

  Future<List<ExerciseSet>> getSetsForLog(int logId) {
    return (db.select(db.exerciseSets)
          ..where((s) => s.logId.equals(logId))
          ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
        .get();
  }

  /// All sets for a given exercise across history, joined with log dates.
  ///
  /// When [exerciseId] is non-null and non-empty, the WHERE clause matches rows
  /// by id OR by name. The OR ensures legacy/imported rows that only have
  /// exerciseId == '' but the same name are still included. When [exerciseId]
  /// is null or empty the query falls back to matching by name only.
  ///
  /// Only completed sets are returned, ordered by log date ascending.
  Future<List<ExerciseSetWithDate>> getSetsForExercise({
    String? exerciseId,
    required String exerciseName,
  }) async {
    final query = db.select(db.exerciseSets).join([
      innerJoin(db.workoutLogs, db.workoutLogs.id.equalsExp(db.exerciseSets.logId)),
    ])
      ..where(db.exerciseSets.completed.equals(true))
      ..orderBy([OrderingTerm.asc(db.workoutLogs.date)]);

    if (exerciseId != null && exerciseId.isNotEmpty) {
      // Match by stable id, OR by name only when the stored id is empty
      // (legacy/imported rows that have no id yet). Rows that have a different
      // non-empty id are excluded even if the name happens to match.
      query.where(
        db.exerciseSets.exerciseId.equals(exerciseId) |
            (db.exerciseSets.exerciseId.equals('') &
                db.exerciseSets.exerciseName.equals(exerciseName)),
      );
    } else {
      query.where(db.exerciseSets.exerciseName.equals(exerciseName));
    }

    final rows = await query.get();
    return rows.map((r) {
      final s = r.readTable(db.exerciseSets);
      final l = r.readTable(db.workoutLogs);
      return ExerciseSetWithDate(set: s, log: l);
    }).toList();
  }

  /// All sets for a given exercise name across history, joined with log dates.
  /// Used by StatsScreen (name-only picker path). Delegates to [getSetsForExercise].
  Future<List<ExerciseSetWithDate>> getSetsForExerciseName(String name) {
    return getSetsForExercise(exerciseName: name);
  }

  /// Top set (highest weight, tie-break highest reps) from the most recent
  /// completed session for the given exercise. When [exerciseId] is non-empty
  /// the lookup uses the stable id (with a name fallback for legacy rows) so
  /// the "Last: …" hint survives exercise renames. Falls back to name-only when
  /// no id is provided. Returns null if no prior completed set exists.
  Future<ExerciseSet?> getLastSessionTopSet(
    String exerciseName, {
    String? exerciseId,
  }) async {
    final resolvedId = (exerciseId != null && exerciseId.isNotEmpty) ? exerciseId : null;

    final joinQuery = db.select(db.exerciseSets).join([
      innerJoin(db.workoutLogs, db.workoutLogs.id.equalsExp(db.exerciseSets.logId)),
    ])
      ..where(db.exerciseSets.completed.equals(true))
      ..orderBy([OrderingTerm.desc(db.workoutLogs.date)])
      ..limit(1);

    if (resolvedId != null) {
      // Match by stable id, OR by name only for legacy/imported rows (id='').
      joinQuery.where(
        db.exerciseSets.exerciseId.equals(resolvedId) |
            (db.exerciseSets.exerciseId.equals('') &
                db.exerciseSets.exerciseName.equals(exerciseName)),
      );
    } else {
      joinQuery.where(db.exerciseSets.exerciseName.equals(exerciseName));
    }

    final newest = await joinQuery.getSingleOrNull();
    if (newest == null) return null;
    final logId = newest.readTable(db.exerciseSets).logId;

    final setsQuery = db.select(db.exerciseSets)
      ..where((s) => s.logId.equals(logId))
      ..where((s) => s.completed.equals(true));

    if (resolvedId != null) {
      setsQuery.where(
        (s) =>
            s.exerciseId.equals(resolvedId) |
            (s.exerciseId.equals('') & s.exerciseName.equals(exerciseName)),
      );
    } else {
      setsQuery.where((s) => s.exerciseName.equals(exerciseName));
    }

    final sets = await setsQuery.get();
    if (sets.isEmpty) return null;

    sets.sort((a, b) {
      final wA = a.weightKg ?? 0;
      final wB = b.weightKg ?? 0;
      final weightCmp = wB.compareTo(wA);
      if (weightCmp != 0) return weightCmp;
      return (b.reps ?? 0).compareTo(a.reps ?? 0);
    });
    return sets.first;
  }

  /// Block completion by day for the current week.
  /// weekStartDate in "YYYY-MM-DD" format (local time).
  Stream<Map<int, Set<String>>> watchDoneBlocks(String weekStartDate) {
    final cutoff = parseDateKey(weekStartDate).millisecondsSinceEpoch;
    return (db.select(db.workoutLogs)..where((l) => l.date.isBiggerOrEqualValue(cutoff)))
        .watch()
        .map((rows) {
      final out = <int, Set<String>>{1: {}, 2: {}, 3: {}, 4: {}, 5: {}};
      for (final r in rows) {
        out[r.dayId]?.add(r.blockId);
      }
      return out;
    });
  }

  /// Distinct exercise names across all history — used by StatsScreen's lift picker.
  Stream<List<String>> watchDistinctExerciseNames() {
    final q = db.selectOnly(db.exerciseSets, distinct: true)
      ..addColumns([db.exerciseSets.exerciseName])
      ..orderBy([OrderingTerm.asc(db.exerciseSets.exerciseName)]);
    return q.watch().map((rows) => rows.map((r) => r.read(db.exerciseSets.exerciseName)!).toList());
  }
}

class ExerciseSetWithDate {
  final ExerciseSet set;
  final WorkoutLog log;
  ExerciseSetWithDate({required this.set, required this.log});
}
