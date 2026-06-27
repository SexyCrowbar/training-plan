import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/data/db/app_database.dart';
import 'package:protocol/data/repositories/settings_repository.dart';
import 'package:protocol/data/repositories/template_seeder.dart';
import 'package:protocol/domain/util/week.dart';

void main() {
  late AppDatabase db;
  late TemplateSeeder seeder;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    seeder = TemplateSeeder(db);
  });

  tearDown(() async => db.close());

  Future<int> templateCount() async =>
      (await db.select(db.templates).get()).length;
  Future<String?> setting(String key) async => (await (db.select(
    db.appSettings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  test('fresh install seeds a 7-day Default and stamps planVersion', () async {
    await seeder.seedOrMigrate();
    expect(await templateCount(), 1);
    final blocks = await db.select(db.templateBlocks).get();
    expect(blocks.length, 7 * 4); // 7 days x 4 block slots
    expect((blocks.map((b) => b.dayId).toSet().toList()..sort()), [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
    ]);
    expect(await setting(SettingsKeys.activeTemplateId), isNotNull);
    expect(
      await setting(SettingsKeys.planVersion),
      TemplateSeeder.currentPlanVersion.toString(),
    );
    expect(await setting(SettingsKeys.weekStartDate), todayKey());
  });

  test(
    'upgrade wipes old templates, reseeds, and KEEPS workout history',
    () async {
      await db
          .into(db.templates)
          .insert(
            TemplatesCompanion.insert(name: 'Old', createdAt: 1, updatedAt: 1),
          );
      await db
          .into(db.workoutLogs)
          .insert(
            WorkoutLogsCompanion.insert(
              date: 1000,
              dayId: 4,
              blockId: 'power',
              blockName: 'X',
              blockIcon: '',
              theme: 'body',
            ),
          );

      await seeder.seedOrMigrate();

      expect(
        await templateCount(),
        1,
      ); // old one wiped, single Default reseeded
      expect((await db.select(db.templates).get()).single.name, 'Default');
      expect(
        (await db.select(db.workoutLogs).get()).length,
        1,
      ); // history preserved
    },
  );

  test('second run is a no-op once migrated', () async {
    await seeder.seedOrMigrate();
    final firstActive = await setting(SettingsKeys.activeTemplateId);
    await seeder.seedOrMigrate();
    expect(await templateCount(), 1);
    expect(await setting(SettingsKeys.activeTemplateId), firstActive);
  });
}
