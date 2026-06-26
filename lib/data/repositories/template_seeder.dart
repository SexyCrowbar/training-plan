import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/plan/models.dart';
import '../../domain/plan/training_plan.dart';
import '../../domain/util/week.dart';
import '../db/app_database.dart';

class TemplateSeeder {
  final AppDatabase db;
  final Uuid _uuid = const Uuid();

  TemplateSeeder(this.db);

  /// Current plan-data version. Bump when the canonical 7-day plan or day
  /// numbering changes in a way that must overwrite users' seeded templates.
  static const currentPlanVersion = 1;

  Future<int?> _settingInt(String key) async {
    final row = await (db.select(db.appSettings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return int.tryParse(row?.value ?? '');
  }

  Future<void> _setSetting(String key, String value) async {
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value),
        );
  }

  /// Run once per plan version. On a fresh install this seeds the 7-day Default.
  /// On upgrade from an older plan version it WIPES all templates and reseeds
  /// Default (Option C), then re-anchors the cycle to today. Workout history and
  /// GTG logs are never touched. Idempotent: a no-op once stamped current.
  Future<void> seedOrMigrate() async {
    final stored = await _settingInt('plan_version') ?? 0;
    if (stored >= currentPlanVersion) return;

    // Wipe templates (and their blocks/exercises) explicitly — does not depend
    // on FK cascade being enabled.
    await db.delete(db.templateExercises).go();
    await db.delete(db.templateBlocks).go();
    await db.delete(db.templates).go();

    final templateId = await createTemplateFromPlan('Default');
    await _setSetting('active_template_id', templateId.toString());
    await _setSetting('weekStartDate', todayKey());
    await _setSetting('plan_version', currentPlanVersion.toString());
  }

  /// Creates a new template populated from TrainingPlan.days.
  Future<int> createTemplateFromPlan(String name) async {
    return db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final templateId = await db.into(db.templates).insert(
            TemplatesCompanion.insert(name: name, createdAt: now, updatedAt: now),
          );

      for (final day in TrainingPlan.days.values) {
        for (final blockId in kBlockIds) {
          final planBlock = day.blocks.firstWhere(
            (b) => b.id == blockId,
            orElse: () => Block(id: blockId, icon: '', name: '', exercises: const []),
          );
          final blockRefId = await db.into(db.templateBlocks).insert(
                TemplateBlocksCompanion.insert(
                  templateId: templateId,
                  dayId: day.id,
                  blockId: blockId,
                ),
              );
          for (var i = 0; i < planBlock.exercises.length; i++) {
            final ex = planBlock.exercises[i];
            await db.into(db.templateExercises).insert(
                  TemplateExercisesCompanion.insert(
                    blockRefId: blockRefId,
                    position: i,
                    exerciseId: _uuid.v4(),
                    name: ex.name,
                    sets: ex.sets,
                    target: ex.target,
                    restSeconds: ex.restSeconds,
                    note: Value(ex.note),
                  ),
                );
          }
        }
      }
      return templateId;
    });
  }

  /// Wipe and re-seed a specific template to the plan defaults.
  Future<void> resetTemplateToDefault(int templateId) async {
    await db.transaction(() async {
      final blocks = await (db.select(db.templateBlocks)
            ..where((b) => b.templateId.equals(templateId)))
          .get();
      for (final b in blocks) {
        await (db.delete(db.templateExercises)
              ..where((e) => e.blockRefId.equals(b.id)))
            .go();
      }
      await (db.delete(db.templateBlocks)
            ..where((b) => b.templateId.equals(templateId)))
          .go();

      for (final day in TrainingPlan.days.values) {
        for (final blockId in kBlockIds) {
          final planBlock = day.blocks.firstWhere(
            (b) => b.id == blockId,
            orElse: () => Block(id: blockId, icon: '', name: '', exercises: const []),
          );
          final blockRefId = await db.into(db.templateBlocks).insert(
                TemplateBlocksCompanion.insert(
                  templateId: templateId,
                  dayId: day.id,
                  blockId: blockId,
                ),
              );
          for (var i = 0; i < planBlock.exercises.length; i++) {
            final ex = planBlock.exercises[i];
            await db.into(db.templateExercises).insert(
                  TemplateExercisesCompanion.insert(
                    blockRefId: blockRefId,
                    position: i,
                    exerciseId: _uuid.v4(),
                    name: ex.name,
                    sets: ex.sets,
                    target: ex.target,
                    restSeconds: ex.restSeconds,
                    note: Value(ex.note),
                  ),
                );
          }
        }
      }
      await (db.update(db.templates)..where((t) => t.id.equals(templateId))).write(
        TemplatesCompanion(updatedAt: Value(DateTime.now().millisecondsSinceEpoch)),
      );
    });
  }
}
