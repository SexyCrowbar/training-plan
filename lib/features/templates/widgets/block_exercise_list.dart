import 'package:flutter/material.dart';

import '../../../data/db/app_database.dart';
import '../../../domain/plan/models.dart';
import 'exercise_row_editor.dart';

/// Renders one block (warmup / power / hypertrophy / endurance) inside the
/// template editor: header, reorderable exercise rows, `+ Add Exercise`.
class BlockExerciseList extends StatelessWidget {
  final String blockId;
  final List<TemplateExercise> exercises;

  final Future<void> Function() onAdd;
  final Future<void> Function(int exerciseRowId) onRemove;
  final Future<void> Function(
    int exerciseRowId, {
    String? name,
    int? sets,
    String? target,
    int? restSeconds,
    String? note,
  })
  onUpdate;
  final Future<void> Function(List<int> orderedRowIds) onReorder;

  const BlockExerciseList({
    super.key,
    required this.blockId,
    required this.exercises,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = kBlockIcons[blockId] ?? '•';
    final name = kBlockNames[blockId] ?? blockId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${exercises.length} exercise${exercises.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'No exercises yet.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: exercises.length,
                onReorder: (oldIdx, newIdx) {
                  final idx = newIdx > oldIdx ? newIdx - 1 : newIdx;
                  final ids = [for (final e in exercises) e.id];
                  final moved = ids.removeAt(oldIdx);
                  ids.insert(idx, moved);
                  onReorder(ids);
                },
                itemBuilder: (context, i) {
                  final ex = exercises[i];
                  return Padding(
                    key: ValueKey('ex_${ex.id}'),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ExerciseRowEditor(
                      exercise: ex,
                      dragHandle: ReorderableDragStartListener(
                        index: i,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.drag_handle,
                            color: scheme.onSurface.withValues(alpha: 0.4),
                            size: 20,
                          ),
                        ),
                      ),
                      onCommit: ({name, sets, target, restSeconds, note}) {
                        onUpdate(
                          ex.id,
                          name: name,
                          sets: sets,
                          target: target,
                          restSeconds: restSeconds,
                          note: note,
                        );
                      },
                      onDelete: () => onRemove(ex.id),
                    ),
                  );
                },
              ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add exercise'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
