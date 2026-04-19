import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/plan/models.dart';
import '../../domain/plan/training_plan.dart';
import '../db/app_database.dart';

class TemplateSeeder {
  final AppDatabase db;
  final Uuid _uuid = const Uuid();

  TemplateSeeder(this.db);

  /// Idempotent. If any template exists, does nothing.
  /// Otherwise creates "Default" from TrainingPlan and sets it active.
  Future<void> seedIfEmpty() async {
    final existing = await db.select(db.templates).get();
    if (existing.isNotEmpty) return;
    final templateId = await createTemplateFromPlan('Default');
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(
            key: 'active_template_id',
            value: templateId.toString(),
          ),
        );
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
