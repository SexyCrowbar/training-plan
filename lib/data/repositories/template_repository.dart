import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/plan/models.dart';
import '../db/app_database.dart';

/// Resolved template row + blocks + exercises, for UI rendering.
class ResolvedTemplate {
  final Template template;
  final Map<int, Map<String, List<TemplateExercise>>> byDayBlock;

  ResolvedTemplate({required this.template, required this.byDayBlock});

  List<TemplateExercise> exercisesFor(int dayId, String blockId) {
    return byDayBlock[dayId]?[blockId] ?? const [];
  }
}

class TemplateRepository {
  final AppDatabase db;
  final Uuid _uuid = const Uuid();

  TemplateRepository(this.db);

  Stream<List<Template>> watchAll() =>
      (db.select(db.templates)..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();

  /// Distinct exercise names across ALL templates, sorted alphabetically.
  /// Combined with [WorkoutRepository.watchDistinctExerciseNames] to get the
  /// full lift list for the Stats screen.
  Stream<List<String>> watchDistinctExerciseNames() {
    final q = db.selectOnly(db.templateExercises, distinct: true)
      ..addColumns([db.templateExercises.name])
      ..orderBy([OrderingTerm.asc(db.templateExercises.name)]);
    return q.watch().map(
          (rows) => rows.map((r) => r.read(db.templateExercises.name)!).toList(),
        );
  }

  Future<Template?> findById(int id) =>
      (db.select(db.templates)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Stream a fully resolved template (all blocks + exercises).
  Stream<ResolvedTemplate?> watchResolved(int templateId) async* {
    final templateStream = (db.select(db.templates)..where((t) => t.id.equals(templateId)))
        .watchSingleOrNull();
    await for (final template in templateStream) {
      if (template == null) {
        yield null;
        continue;
      }
      final blocks = await (db.select(db.templateBlocks)
            ..where((b) => b.templateId.equals(templateId)))
          .get();
      final blockIds = blocks.map((b) => b.id).toList();
      final exercises = blockIds.isEmpty
          ? <TemplateExercise>[]
          : await (db.select(db.templateExercises)
                ..where((e) => e.blockRefId.isIn(blockIds))
                ..orderBy([(e) => OrderingTerm.asc(e.position)]))
              .get();

      final byDayBlock = <int, Map<String, List<TemplateExercise>>>{};
      final byBlockRefId = <int, (int, String)>{
        for (final b in blocks) b.id: (b.dayId, b.blockId),
      };
      for (final b in blocks) {
        byDayBlock.putIfAbsent(b.dayId, () => {})[b.blockId] = [];
      }
      for (final ex in exercises) {
        final pair = byBlockRefId[ex.blockRefId];
        if (pair == null) continue;
        byDayBlock[pair.$1]![pair.$2]!.add(ex);
      }
      yield ResolvedTemplate(template: template, byDayBlock: byDayBlock);
    }
  }

  Future<int> createEmpty(String name) async {
    return db.transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final id = await db.into(db.templates).insert(
            TemplatesCompanion.insert(name: name, createdAt: now, updatedAt: now),
          );
      for (var dayId = 1; dayId <= 7; dayId++) {
        for (final blockId in kBlockIds) {
          await db.into(db.templateBlocks).insert(
                TemplateBlocksCompanion.insert(
                  templateId: id,
                  dayId: dayId,
                  blockId: blockId,
                ),
              );
        }
      }
      return id;
    });
  }

  Future<int> duplicate(int sourceId, String newName) async {
    return db.transaction(() async {
      final source = await findById(sourceId);
      if (source == null) throw StateError('Template $sourceId not found');
      final now = DateTime.now().millisecondsSinceEpoch;
      final newId = await db.into(db.templates).insert(
            TemplatesCompanion.insert(name: newName, createdAt: now, updatedAt: now),
          );
      final sourceBlocks = await (db.select(db.templateBlocks)
            ..where((b) => b.templateId.equals(sourceId)))
          .get();
      for (final sb in sourceBlocks) {
        final newBlockId = await db.into(db.templateBlocks).insert(
              TemplateBlocksCompanion.insert(
                templateId: newId,
                dayId: sb.dayId,
                blockId: sb.blockId,
              ),
            );
        final sourceExs = await (db.select(db.templateExercises)
              ..where((e) => e.blockRefId.equals(sb.id))
              ..orderBy([(e) => OrderingTerm.asc(e.position)]))
            .get();
        for (final ex in sourceExs) {
          await db.into(db.templateExercises).insert(
                TemplateExercisesCompanion.insert(
                  blockRefId: newBlockId,
                  position: ex.position,
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
      return newId;
    });
  }

  Future<void> rename(int templateId, String newName) async {
    await (db.update(db.templates)..where((t) => t.id.equals(templateId))).write(
      TemplatesCompanion(
        name: Value(newName),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> delete(int templateId) async {
    await (db.delete(db.templates)..where((t) => t.id.equals(templateId))).go();
  }

  // --- Exercise-level edits ---

  Future<int> getBlockRefId(int templateId, int dayId, String blockId) async {
    final row = await (db.select(db.templateBlocks)
          ..where((b) =>
              b.templateId.equals(templateId) &
              b.dayId.equals(dayId) &
              b.blockId.equals(blockId)))
        .getSingle();
    return row.id;
  }

  Future<void> addExercise(
    int blockRefId, {
    required String name,
    required int sets,
    required String target,
    required int restSeconds,
    String note = '',
  }) async {
    await db.transaction(() async {
      final existing = await (db.select(db.templateExercises)
            ..where((e) => e.blockRefId.equals(blockRefId)))
          .get();
      await db.into(db.templateExercises).insert(
            TemplateExercisesCompanion.insert(
              blockRefId: blockRefId,
              position: existing.length,
              exerciseId: _uuid.v4(),
              name: name,
              sets: sets,
              target: target,
              restSeconds: restSeconds,
              note: Value(note),
            ),
          );
    });
    await _touch(blockRefId);
  }

  Future<void> updateExercise(
    int exerciseRowId, {
    String? name,
    int? sets,
    String? target,
    int? restSeconds,
    String? note,
  }) async {
    await (db.update(db.templateExercises)..where((e) => e.id.equals(exerciseRowId))).write(
      TemplateExercisesCompanion(
        name: name == null ? const Value.absent() : Value(name),
        sets: sets == null ? const Value.absent() : Value(sets),
        target: target == null ? const Value.absent() : Value(target),
        restSeconds: restSeconds == null ? const Value.absent() : Value(restSeconds),
        note: note == null ? const Value.absent() : Value(note),
      ),
    );
    await _touchByExerciseRow(exerciseRowId);
  }

  Future<void> removeExercise(int exerciseRowId) async {
    final row = await (db.select(db.templateExercises)..where((e) => e.id.equals(exerciseRowId)))
        .getSingleOrNull();
    if (row == null) return;
    await db.transaction(() async {
      await (db.delete(db.templateExercises)..where((e) => e.id.equals(exerciseRowId))).go();
      final siblings = await (db.select(db.templateExercises)
            ..where((e) => e.blockRefId.equals(row.blockRefId))
            ..orderBy([(e) => OrderingTerm.asc(e.position)]))
          .get();
      for (var i = 0; i < siblings.length; i++) {
        if (siblings[i].position != i) {
          await (db.update(db.templateExercises)..where((e) => e.id.equals(siblings[i].id)))
              .write(TemplateExercisesCompanion(position: Value(i)));
        }
      }
    });
    await _touch(row.blockRefId);
  }

  Future<void> reorderExercises(int blockRefId, List<int> orderedRowIds) async {
    await db.transaction(() async {
      for (var i = 0; i < orderedRowIds.length; i++) {
        await (db.update(db.templateExercises)..where((e) => e.id.equals(orderedRowIds[i])))
            .write(TemplateExercisesCompanion(position: Value(i)));
      }
    });
    await _touch(blockRefId);
  }

  Future<void> _touch(int blockRefId) async {
    final block = await (db.select(db.templateBlocks)..where((b) => b.id.equals(blockRefId)))
        .getSingleOrNull();
    if (block == null) return;
    await (db.update(db.templates)..where((t) => t.id.equals(block.templateId))).write(
      TemplatesCompanion(updatedAt: Value(DateTime.now().millisecondsSinceEpoch)),
    );
  }

  Future<void> _touchByExerciseRow(int exerciseRowId) async {
    final row = await (db.select(db.templateExercises)..where((e) => e.id.equals(exerciseRowId)))
        .getSingleOrNull();
    if (row != null) await _touch(row.blockRefId);
  }
}
