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

  Future<List<ExerciseSet>> getSetsForLog(int logId) {
    return (db.select(db.exerciseSets)
          ..where((s) => s.logId.equals(logId))
          ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
        .get();
  }

  /// All sets for a given exercise name across history, joined with log dates.
  /// Used by StatsScreen.
  Future<List<ExerciseSetWithDate>> getSetsForExerciseName(String name) async {
    final query = db.select(db.exerciseSets).join([
      innerJoin(db.workoutLogs, db.workoutLogs.id.equalsExp(db.exerciseSets.logId)),
    ])
      ..where(db.exerciseSets.exerciseName.equals(name))
      ..where(db.exerciseSets.completed.equals(true))
      ..orderBy([OrderingTerm.asc(db.workoutLogs.date)]);
    final rows = await query.get();
    return rows.map((r) {
      final s = r.readTable(db.exerciseSets);
      final l = r.readTable(db.workoutLogs);
      return ExerciseSetWithDate(set: s, log: l);
    }).toList();
  }

  /// Top set (highest weight, tie-break highest reps) from the most recent
  /// completed session for [exerciseName]. Returns null if no prior completed
  /// set exists. Null weight is treated as 0 for sort ordering so weighted sets
  /// always rank above bodyweight, and within all-bodyweight sessions the set
  /// with the most reps wins.
  Future<ExerciseSet?> getLastSessionTopSet(String exerciseName) async {
    final newest = await (db.select(db.exerciseSets).join([
      innerJoin(db.workoutLogs, db.workoutLogs.id.equalsExp(db.exerciseSets.logId)),
    ])
          ..where(db.exerciseSets.exerciseName.equals(exerciseName))
          ..where(db.exerciseSets.completed.equals(true))
          ..orderBy([OrderingTerm.desc(db.workoutLogs.date)])
          ..limit(1))
        .getSingleOrNull();
    if (newest == null) return null;
    final logId = newest.readTable(db.exerciseSets).logId;

    final sets = await (db.select(db.exerciseSets)
          ..where((s) => s.logId.equals(logId))
          ..where((s) => s.exerciseName.equals(exerciseName))
          ..where((s) => s.completed.equals(true)))
        .get();
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
