import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/app_providers.dart';
import 'package:protocol/data/db/app_database.dart';
import 'package:protocol/data/repositories/settings_repository.dart';
import 'package:protocol/data/repositories/workout_repository.dart';
import 'package:protocol/domain/plan/training_plan.dart';
import 'package:protocol/features/settings/import_export_controller.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late ImportExportController ctrl;
  late WorkoutRepository workouts;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    ctrl = container.read(importExportControllerProvider);
    workouts = container.read(workoutRepositoryProvider);
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // dayName bug (red → green)
  // ---------------------------------------------------------------------------
  group('dayName', () {
    test('exports canonical day name, not blockName', () async {
      // Seed a workout log for dayId 1, blockId 'hypertrophy'.
      // blockName is "Afternoon Hypertrophy" — the bug uses this instead of
      // the day name "Day 1: Chest Power".
      await workouts.saveWorkout(
        date: DateTime.fromMillisecondsSinceEpoch(1_000_000),
        templateId: null,
        dayId: 1,
        blockId: 'hypertrophy',
        blockName: 'Afternoon Hypertrophy',
        blockIcon: '💪',
        theme: 'iron',
        sets: [
          SetInput(
            exerciseId: '',
            exerciseName: 'Bench Press',
            setNumber: 1,
            weightKg: 80.0,
            reps: 5,
            completed: true,
          ),
        ],
      );

      final json = await ctrl.buildHistoryJson();
      final entries = List<Map<String, dynamic>>.from(jsonDecode(json) as List);
      expect(entries, hasLength(1));
      final entry = entries.first;

      final expectedDayName = TrainingPlan.days[1]!.name;
      expect(
        entry['dayName'],
        equals(expectedDayName),
        reason:
            'dayName should be the canonical plan day name, not the blockName',
      );
      expect(
        entry['dayName'],
        isNot(equals('Afternoon Hypertrophy')),
        reason: 'dayName must NOT be the blockName',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Full round-trip
  // ---------------------------------------------------------------------------
  group('history round-trip', () {
    test('buildHistoryJson → importHistory preserves all fields', () async {
      final date1 = DateTime.utc(2026, 1, 15, 10, 0, 0);
      final date2 = DateTime.utc(2026, 1, 20, 14, 30, 0);

      // Log 1: dayId 1, two exercises with mixed sets
      await workouts.saveWorkout(
        date: date1,
        templateId: null,
        dayId: 1,
        blockId: 'power',
        blockName: 'Morning Power',
        blockIcon: '⚡',
        theme: 'iron',
        sets: [
          SetInput(
            exerciseId: '',
            exerciseName: 'Barbell Bench Press',
            setNumber: 1,
            weightKg: 100.0,
            reps: 3,
            completed: true,
          ),
          SetInput(
            exerciseId: '',
            exerciseName: 'Barbell Bench Press',
            setNumber: 2,
            weightKg: null, // bodyweight-style null weight
            reps: 5,
            completed: false,
          ),
          SetInput(
            exerciseId: '',
            exerciseName: 'Pull-Ups',
            setNumber: 3,
            weightKg: null,
            reps: null, // null reps
            completed: true,
          ),
        ],
      );

      // Log 2: dayId 2, single set
      await workouts.saveWorkout(
        date: date2,
        templateId: null,
        dayId: 2,
        blockId: 'hypertrophy',
        blockName: 'Afternoon Hypertrophy',
        blockIcon: '💪',
        theme: 'body',
        sets: [
          SetInput(
            exerciseId: '',
            exerciseName: 'EZ-Bar Curls',
            setNumber: 1,
            weightKg: 27.5,
            reps: 12,
            completed: true,
          ),
        ],
      );

      final json = await ctrl.buildHistoryJson();

      // Import into a fresh second db
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db2.close);
      final container2 = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db2)],
      );
      addTearDown(container2.dispose);
      final ctrl2 = container2.read(importExportControllerProvider);
      final workouts2 = container2.read(workoutRepositoryProvider);

      final stats = await ctrl2.importHistory(json);
      expect(stats.logs, equals(2));
      expect(stats.sets, equals(4)); // 3 + 1

      // Verify logs in the new db (ordered ascending by date)
      final logs = await (db2.select(
        db2.workoutLogs,
      )..orderBy([(l) => OrderingTerm.asc(l.date)])).get();
      expect(logs, hasLength(2));

      // Log 1 fields
      final log1 = logs[0];
      expect(
        DateTime.fromMillisecondsSinceEpoch(log1.date).toUtc(),
        equals(date1),
      );
      expect(log1.dayId, equals(1));
      expect(log1.blockId, equals('power'));
      expect(log1.blockName, equals('Morning Power'));
      expect(log1.blockIcon, equals('⚡'));
      expect(log1.theme, equals('iron'));

      // Log 1 sets
      final sets1 = await workouts2.getSetsForLog(log1.id);
      expect(sets1, hasLength(3));

      final benchSets = sets1
          .where((s) => s.exerciseName == 'Barbell Bench Press')
          .toList();
      final pullSets = sets1
          .where((s) => s.exerciseName == 'Pull-Ups')
          .toList();
      expect(benchSets, hasLength(2));
      expect(pullSets, hasLength(1));

      // First bench set: weight 100, reps 3, completed
      expect(benchSets[0].weightKg, equals(100.0));
      expect(benchSets[0].reps, equals(3));
      expect(benchSets[0].completed, isTrue);

      // Second bench set: null weight (bodyweight), reps 5, incomplete
      expect(benchSets[1].weightKg, isNull);
      expect(benchSets[1].reps, equals(5));
      expect(benchSets[1].completed, isFalse);

      // Pull-Up set: null weight, null reps, completed
      expect(pullSets[0].weightKg, isNull);
      expect(pullSets[0].reps, isNull);
      expect(pullSets[0].completed, isTrue);

      // Log 2
      final log2 = logs[1];
      expect(
        DateTime.fromMillisecondsSinceEpoch(log2.date).toUtc(),
        equals(date2),
      );
      expect(log2.dayId, equals(2));
      expect(log2.blockId, equals('hypertrophy'));
      expect(log2.blockName, equals('Afternoon Hypertrophy'));
      expect(log2.blockIcon, equals('💪'));
      expect(log2.theme, equals('body'));

      final sets2 = await workouts2.getSetsForLog(log2.id);
      expect(sets2, hasLength(1));
      expect(sets2[0].exerciseName, equals('EZ-Bar Curls'));
      expect(sets2[0].weightKg, equals(27.5));
      expect(sets2[0].reps, equals(12));
      expect(sets2[0].completed, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Null coercion
  // ---------------------------------------------------------------------------
  group('null coercion', () {
    test('null weightKg exports as "—" and re-imports as null', () async {
      await workouts.saveWorkout(
        date: DateTime.utc(2026, 2, 1),
        templateId: null,
        dayId: 1,
        blockId: 'power',
        blockName: 'Morning Power',
        blockIcon: '⚡',
        theme: 'iron',
        sets: [
          SetInput(
            exerciseId: '',
            exerciseName: 'Pull-Ups',
            setNumber: 1,
            weightKg: null,
            reps: 10,
            completed: true,
          ),
        ],
      );

      final json = await ctrl.buildHistoryJson();

      // Verify the raw JSON token
      expect(json, contains('"weight": "—"'));

      // Round-trip and check null is preserved
      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db2.close);
      final container2 = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db2)],
      );
      addTearDown(container2.dispose);
      final ctrl2 = container2.read(importExportControllerProvider);
      final workouts2 = container2.read(workoutRepositoryProvider);

      await ctrl2.importHistory(json);
      final logs = await db2.select(db2.workoutLogs).get();
      expect(logs, hasLength(1));
      final sets = await workouts2.getSetsForLog(logs[0].id);
      expect(sets, hasLength(1));
      expect(sets[0].weightKg, isNull);
      expect(sets[0].reps, equals(10));
    });

    test('null reps exports as "—" and re-imports as null', () async {
      await workouts.saveWorkout(
        date: DateTime.utc(2026, 2, 2),
        templateId: null,
        dayId: 1,
        blockId: 'power',
        blockName: 'Morning Power',
        blockIcon: '⚡',
        theme: 'iron',
        sets: [
          SetInput(
            exerciseId: '',
            exerciseName: 'Holds',
            setNumber: 1,
            weightKg: 20.0,
            reps: null,
            completed: true,
          ),
        ],
      );

      final json = await ctrl.buildHistoryJson();

      expect(json, contains('"reps": "—"'));

      final db2 = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db2.close);
      final container2 = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db2)],
      );
      addTearDown(container2.dispose);
      final ctrl2 = container2.read(importExportControllerProvider);
      final workouts2 = container2.read(workoutRepositoryProvider);

      await ctrl2.importHistory(json);
      final logs = await db2.select(db2.workoutLogs).get();
      final sets = await workouts2.getSetsForLog(logs[0].id);
      expect(sets, hasLength(1));
      expect(sets[0].weightKg, equals(20.0));
      expect(sets[0].reps, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // State round-trip
  // ---------------------------------------------------------------------------
  group('state round-trip', () {
    test(
      'buildStateJson → importState preserves GTG counts and weekStartDate',
      () async {
        // Seed GTG rows directly
        await db
            .into(db.gtgLogs)
            .insert(
              GtgLogsCompanion.insert(date: '2026-01-15', dayId: 1, count: 3),
            );
        await db
            .into(db.gtgLogs)
            .insert(
              GtgLogsCompanion.insert(date: '2026-01-15', dayId: 2, count: 5),
            );
        await db
            .into(db.gtgLogs)
            .insert(
              GtgLogsCompanion.insert(date: '2026-01-20', dayId: 3, count: 2),
            );

        // Seed weekStartDate setting
        await db
            .into(db.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                key: 'weekStartDate',
                value: '2026-01-13',
              ),
            );

        final json = await ctrl.buildStateJson();

        // Import into a fresh second db
        final db2 = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db2.close);
        final container2 = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db2)],
        );
        addTearDown(container2.dispose);
        final ctrl2 = container2.read(importExportControllerProvider);

        final stats = await ctrl2.importState(json);
        expect(stats.rows, equals(3));
        expect(stats.weekStartApplied, isTrue);

        // Verify GTG rows
        final rows = await db2.select(db2.gtgLogs).get();
        expect(rows, hasLength(3));

        final row1 = rows.firstWhere(
          (r) => r.date == '2026-01-15' && r.dayId == 1,
        );
        expect(row1.count, equals(3));

        final row2 = rows.firstWhere(
          (r) => r.date == '2026-01-15' && r.dayId == 2,
        );
        expect(row2.count, equals(5));

        final row3 = rows.firstWhere(
          (r) => r.date == '2026-01-20' && r.dayId == 3,
        );
        expect(row3.count, equals(2));

        // Verify weekStartDate was persisted
        final settings2 = container2.read(settingsRepositoryProvider);
        final weekStart = await settings2.get(SettingsKeys.weekStartDate);
        expect(weekStart, equals('2026-01-13'));
      },
    );

    test(
      'importState without weekStartDate leaves setting untouched',
      () async {
        final db2 = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db2.close);
        final container2 = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db2)],
        );
        addTearDown(container2.dispose);
        final ctrl2 = container2.read(importExportControllerProvider);

        // Preset a weekStartDate in db2
        await db2
            .into(db2.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                key: 'weekStartDate',
                value: '2026-01-01',
              ),
            );

        // Import state with no weekStartDate field
        const jsonNoWeek = '{"gtg": {"2026-02-01": {"4": 7}}}';
        final stats = await ctrl2.importState(jsonNoWeek);
        expect(stats.weekStartApplied, isFalse);

        // Original value should be unchanged
        final settings2 = container2.read(settingsRepositoryProvider);
        final weekStart = await settings2.get(SettingsKeys.weekStartDate);
        expect(weekStart, equals('2026-01-01'));
      },
    );
  });
}
