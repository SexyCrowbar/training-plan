import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../data/db/app_database.dart';
import '../../data/models/history_entry.dart';
import '../../data/models/state_snapshot.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/workout_repository.dart';

/// Coordinates JSON import/export of history + state between the app and the
/// file picker. Mirrors the React `data/history.json` / `data/state.json`
/// shapes so users can migrate from the web app.
class ImportExportController {
  final Ref ref;
  ImportExportController(this.ref);

  AppDatabase get _db => ref.read(appDatabaseProvider);
  WorkoutRepository get _workouts => ref.read(workoutRepositoryProvider);
  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  // --- EXPORT ---

  /// Serialize all workout logs + sets to the `history.json` shape.
  Future<String> buildHistoryJson() async {
    final logs = await (_db.select(_db.workoutLogs)
          ..orderBy([(l) => OrderingTerm.desc(l.date)]))
        .get();
    final entries = <HistoryEntry>[];
    for (final log in logs) {
      final sets = await _workouts.getSetsForLog(log.id);
      final byName = <String, List<ExerciseSet>>{};
      for (final s in sets) {
        byName.putIfAbsent(s.exerciseName, () => []).add(s);
      }
      entries.add(
        HistoryEntry(
          date: DateTime.fromMillisecondsSinceEpoch(log.date),
          day: log.dayId,
          dayName: log.blockName, // best-effort — dayName is not persisted
          blockId: log.blockId,
          blockName: log.blockName,
          blockIcon: log.blockIcon,
          theme: log.theme,
          exercises: [
            for (final entry in byName.entries)
              HistoryExercise(
                name: entry.key,
                sets: [
                  for (final s in entry.value)
                    HistorySet(
                      done: s.completed,
                      weight: s.weightKg?.toString() ?? '—',
                      reps: s.reps?.toString() ?? '—',
                    ),
                ],
              ),
          ],
        ),
      );
    }
    return const JsonEncoder.withIndent('  ')
        .convert([for (final e in entries) e.toJson()]);
  }

  /// Serialize GTG counts + week-start to the `state.json` shape.
  Future<String> buildStateJson() async {
    final rows = await _db.select(_db.gtgLogs).get();
    final gtg = <String, Map<int, int>>{};
    for (final r in rows) {
      gtg.putIfAbsent(r.date, () => {})[r.dayId] = r.count;
    }
    final weekStart = await _settings.get(SettingsKeys.weekStartDate);
    final snap = StateSnapshot(gtg: gtg, weekStartDate: weekStart);
    return const JsonEncoder.withIndent('  ').convert(snap.toJson());
  }

  /// Prompt the user to choose a location, then write the given string there.
  /// Returns the saved file path or null if the user cancelled.
  Future<String?> saveToFile({
    required String suggestedName,
    required String content,
  }) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export $suggestedName',
      fileName: suggestedName,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: utf8.encode(content),
    );
    if (path == null) return null;
    // On some platforms file_picker writes the bytes itself; on others it just
    // returns the chosen path. Write defensively if the file isn't there yet.
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) {
      await file.writeAsString(content);
    }
    return path;
  }

  // --- IMPORT ---

  /// Let the user pick a file, read its text. Returns null on cancel.
  Future<String?> pickJsonText() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;
    if (f.bytes != null) return utf8.decode(f.bytes!);
    if (f.path != null) return await File(f.path!).readAsString();
    return null;
  }

  /// Import workout history from the `history.json` shape. Each entry becomes
  /// a new workout log with `template_id = null` (imported history predates
  /// the Flutter templates feature).
  Future<ImportStats> importHistory(String jsonText) async {
    final raw = jsonDecode(jsonText);
    if (raw is! List) {
      throw const FormatException('Expected a JSON array of history entries.');
    }
    final entries = [
      for (final e in raw) HistoryEntry.fromJson(e as Map<String, dynamic>),
    ];

    int logs = 0;
    int sets = 0;
    await _db.transaction(() async {
      for (final entry in entries) {
        final setInputs = <SetInput>[];
        var setNumber = 0;
        for (final ex in entry.exercises) {
          for (final s in ex.sets) {
            setNumber++;
            setInputs.add(
              SetInput(
                exerciseId: '',
                exerciseName: ex.name,
                setNumber: setNumber,
                weightKg: s.weightKg,
                reps: s.repsInt,
                completed: s.done,
              ),
            );
          }
        }
        await _workouts.saveWorkout(
          date: entry.date,
          templateId: null,
          dayId: entry.day,
          blockId: entry.blockId,
          blockName: entry.blockName,
          blockIcon: entry.blockIcon,
          theme: entry.theme,
          sets: setInputs,
        );
        logs++;
        sets += setInputs.length;
      }
    });
    return ImportStats(logs: logs, sets: sets);
  }

  /// Import GTG counts + optional weekStartDate from the `state.json` shape.
  Future<ImportStateStats> importState(String jsonText) async {
    final raw = jsonDecode(jsonText);
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object matching state.json.');
    }
    final snap = StateSnapshot.fromJson(raw);
    int rows = 0;
    await _db.transaction(() async {
      for (final dateEntry in snap.gtg.entries) {
        for (final dayEntry in dateEntry.value.entries) {
          await _db.into(_db.gtgLogs).insertOnConflictUpdate(
                GtgLogsCompanion.insert(
                  date: dateEntry.key,
                  dayId: dayEntry.key,
                  count: dayEntry.value,
                ),
              );
          rows++;
        }
      }
      if (snap.weekStartDate != null) {
        await _settings.set(SettingsKeys.weekStartDate, snap.weekStartDate!);
      }
    });
    return ImportStateStats(
      rows: rows,
      weekStartApplied: snap.weekStartDate != null,
    );
  }

  /// First-launch seeding of workout history from the bundled asset. No-op if
  /// the workout_logs table already has rows.
  Future<ImportStats?> autoSeedFromBundledHistory() async {
    final existing = await _db.select(_db.workoutLogs).get();
    if (existing.isNotEmpty) return null;
    try {
      final text = await rootBundle.loadString('assets/seed/history.json');
      return await importHistory(text);
    } catch (_) {
      return null;
    }
  }
}

class ImportStats {
  final int logs;
  final int sets;
  ImportStats({required this.logs, required this.sets});
}

class ImportStateStats {
  final int rows;
  final bool weekStartApplied;
  ImportStateStats({required this.rows, required this.weekStartApplied});
}

final importExportControllerProvider = Provider<ImportExportController>(
  (ref) => ImportExportController(ref),
);

/// Completes once first-launch history auto-seed has run.
final historyAutoSeedProvider = FutureProvider<ImportStats?>((ref) async {
  // Wait for template seeder to finish first so the two provider chains don't
  // race on the same db connection.
  await ref.watch(seedBootProvider.future);
  return ref.watch(importExportControllerProvider).autoSeedFromBundledHistory();
});
