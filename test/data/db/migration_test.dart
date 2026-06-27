// ignore_for_file: avoid_print
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/data/db/app_database.dart';

import 'generated/schema.dart';

void main() {
  // ---------------------------------------------------------------------------
  // 4a — SchemaVerifier: migrate from v1 → v2 and validate
  // ---------------------------------------------------------------------------
  test('v1 to v2 migrates and validates schema', () async {
    final verifier = SchemaVerifier(GeneratedHelper());

    final connection = await verifier.startAt(1);
    final db = AppDatabase.forTesting(connection);

    await verifier.migrateAndValidate(db, 2);
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // Index-existence check: fresh v2 in-memory DB must have all 3 indices
  // ---------------------------------------------------------------------------
  test('fresh v2 database contains the three secondary indices', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type='index' AND name LIKE 'idx_%'",
        )
        .get();

    final names = rows.map((r) => r.read<String>('name')).toSet();

    expect(
      names,
      contains('idx_exercise_sets_log_id'),
      reason: 'Missing index on exercise_sets(log_id)',
    );
    expect(
      names,
      contains('idx_exercise_sets_exercise_name'),
      reason: 'Missing index on exercise_sets(exercise_name)',
    );
    expect(
      names,
      contains('idx_workout_logs_date'),
      reason: 'Missing index on workout_logs(date)',
    );
  });
}
