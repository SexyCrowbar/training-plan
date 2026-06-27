import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../data/repositories/template_repository.dart';
import '../../domain/plan/models.dart';
import '../../domain/plan/training_plan.dart';
import '../../widgets/confirm_modal.dart';
import 'widgets/block_exercise_list.dart';

class TemplateEditorScreen extends ConsumerStatefulWidget {
  final int templateId;
  const TemplateEditorScreen({super.key, required this.templateId});

  @override
  ConsumerState<TemplateEditorScreen> createState() =>
      _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends ConsumerState<TemplateEditorScreen> {
  int _selectedDay = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAsync = ref.watch(_resolvedProvider(widget.templateId));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(resolvedAsync.valueOrNull?.template.name ?? 'Template'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Plan saved'),
                  duration: Duration(seconds: 1),
                ),
              );
              Navigator.of(context).pop();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'reset') {
                final ok = await showConfirmModal(
                  context: context,
                  title: 'Reset to default?',
                  message:
                      'This template will be replaced with the built-in Iron/Body plan. Your workout history is kept.',
                  confirmLabel: 'Reset',
                  danger: true,
                );
                if (!ok) return;
                await ref
                    .read(templateSeederProvider)
                    .resetTemplateToDefault(widget.templateId);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'reset',
                child: Text('Reset to default'),
              ),
            ],
          ),
        ],
      ),
      body: resolvedAsync.when(
        data: (resolved) {
          if (resolved == null) {
            return const Center(child: Text('Template not found'));
          }
          final repo = ref.read(templateRepositoryProvider);
          final dayMeta = TrainingPlan.days[_selectedDay]!;
          return Column(
            children: [
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: 7,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final dayId = i + 1;
                    final selected = dayId == _selectedDay;
                    final label = dayId == 7 ? 'Rest' : 'Day $dayId';
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = dayId),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? scheme.primary : scheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected
                                ? scheme.primary
                                : scheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: selected
                                ? scheme.onPrimary
                                : scheme.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (dayMeta.isRestDay)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Rest day — no exercises to edit.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      for (final blockId in kBlockIds) ...[
                        BlockExerciseList(
                          blockId: blockId,
                          exercises: resolved.exercisesFor(
                            _selectedDay,
                            blockId,
                          ),
                          onAdd: () =>
                              _addExercise(repo, _selectedDay, blockId),
                          onRemove: (rowId) => repo.removeExercise(rowId),
                          onUpdate:
                              (
                                rowId, {
                                name,
                                sets,
                                target,
                                restSeconds,
                                note,
                              }) => repo.updateExercise(
                                rowId,
                                name: name,
                                sets: sets,
                                target: target,
                                restSeconds: restSeconds,
                                note: note,
                              ),
                          onReorder: (ids) async {
                            final blockRefId = await repo.getBlockRefId(
                              widget.templateId,
                              _selectedDay,
                              blockId,
                            );
                            await repo.reorderExercises(blockRefId, ids);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  Future<void> _addExercise(
    TemplateRepository repo,
    int dayId,
    String blockId,
  ) async {
    final blockRefId = await repo.getBlockRefId(
      widget.templateId,
      dayId,
      blockId,
    );
    await repo.addExercise(
      blockRefId,
      name: 'New exercise',
      sets: 3,
      target: '8-10 reps',
      restSeconds: 90,
    );
    // Scroll to the bottom so the new exercise row is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

final _resolvedProvider = StreamProvider.family<ResolvedTemplate?, int>((
  ref,
  templateId,
) {
  return ref.watch(templateRepositoryProvider).watchResolved(templateId);
});
