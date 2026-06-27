import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app_providers.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/plan/models.dart';
import '../../domain/util/one_rep_max.dart';
import '../../theme/colors.dart';
import '../../widgets/confirm_modal.dart';
import '../../widgets/rest_timer_bar.dart';
import '../../widgets/set_row.dart';
import 'rest_timer_controller.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  final int dayId;
  final String blockId;
  const WorkoutScreen({super.key, required this.dayId, required this.blockId});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  /// exercise row id -> list of SetRowData indexed by set number - 1
  final Map<int, List<SetRowData>> _setsByExercise = {};
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    ref.read(restTimerProvider.notifier).stop();
    super.dispose();
  }

  void _hydrate(List<TemplateExercise> exs) {
    if (_initialized) return;
    for (final ex in exs) {
      _setsByExercise[ex.id] = List.generate(
        ex.sets,
        (_) => const SetRowData(done: false, weightText: '', repsText: ''),
      );
    }
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final template = ref.watch(activeTemplateProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    if (template == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final exercises = template.exercisesFor(widget.dayId, widget.blockId);
    _hydrate(exercises);

    final blockName = kBlockNames[widget.blockId] ?? widget.blockId;
    final blockIcon = kBlockIcons[widget.blockId] ?? '•';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(blockIcon),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                blockName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmBack(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final ex in exercises) _exerciseBlock(ex),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Finish block'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                  ),
                  onPressed: () => _finish(context, exercises),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          const RestTimerBar(),
        ],
      ),
    );
  }

  Widget _exerciseBlock(TemplateExercise ex) {
    final rows = _setsByExercise[ex.id] ?? const [];
    final scheme = Theme.of(context).colorScheme;
    return Consumer(builder: (context, ref, _) {
      final top = ref.watch(lastTopSetByIdProvider((ex.exerciseId, ex.name))).valueOrNull;
      final topWeight = (top != null && top.reps != null && top.weightKg != null && top.weightKg! > 0)
          ? top.weightKg
          : null;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ex.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ex.sets} × ${ex.target}  •  Rest ${ex.restSeconds}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.textMid,
                      ),
                    ),
                    if (top != null && top.reps != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Last: ${(top.weightKg == null || top.weightKg == 0) ? 'BW' : '${_formatKg(top.weightKg!)} kg'} × ${top.reps}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.primary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (ex.note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    ex.note,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.textMid,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 24),
                  Expanded(flex: 3, child: _headerLabel('Weight (kg)')),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: _headerLabel('Reps')),
                  const SizedBox(width: 8),
                  const SizedBox(width: 48, child: SizedBox()),
                ],
              ),
              for (var i = 0; i < rows.length; i++)
                SetRow(
                  key: ValueKey('${ex.id}_$i'),
                  setNumber: i + 1,
                  data: rows[i],
                  suggestedTarget: ex.target,
                  suggestedWeight: topWeight,
                  onChanged: (next, {required triggeredByCheckbox}) {
                    setState(() {
                      rows[i] = next;
                      _setsByExercise[ex.id] = rows;
                    });
                    if (triggeredByCheckbox && next.done && ex.restSeconds > 0) {
                      ref.read(restTimerProvider.notifier).start(ex.restSeconds);
                    }
                  },
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _headerLabel(String text) => Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.textMid,
        ),
      );

  Future<void> _confirmBack(BuildContext context) async {
    final hasProgress = _setsByExercise.values
        .expand((l) => l)
        .any((s) => s.done || s.weightText.isNotEmpty || s.repsText.isNotEmpty);
    if (!hasProgress) {
      context.pop();
      return;
    }
    final confirmed = await showConfirmModal(
      context: context,
      title: 'Discard this block?',
      message: 'Your sets will not be saved.',
      confirmLabel: 'Discard',
      danger: true,
    );
    if (confirmed && context.mounted) context.pop();
  }

  Future<void> _finish(
    BuildContext context,
    List<TemplateExercise> exercises,
  ) async {
    final meta = ref.read(currentDayMetaProvider);
    final templateId =
        await ref.read(settingsRepositoryProvider).getInt(SettingsKeys.activeTemplateId);

    final sets = <SetInput>[];
    double? bestPrWeight;
    int? bestPrReps;
    String? bestPrExercise;
    String? bestPrExerciseId;
    double bestPrE1rm = 0;
    int globalSetNumber = 0;

    for (final ex in exercises) {
      final rows = _setsByExercise[ex.id] ?? const [];
      for (var i = 0; i < rows.length; i++) {
        final r = rows[i];
        globalSetNumber++;
        sets.add(
          SetInput(
            exerciseId: ex.exerciseId,
            exerciseName: ex.name,
            setNumber: globalSetNumber,
            weightKg: r.weightKg,
            reps: r.reps,
            completed: r.done,
          ),
        );
        if (r.done) {
          final e1rm = estimatedOneRepMax(r.weightKg, r.reps);
          if (e1rm != null && e1rm > bestPrE1rm) {
            bestPrE1rm = e1rm;
            bestPrWeight = r.weightKg;
            bestPrReps = r.reps;
            bestPrExercise = ex.name;
            bestPrExerciseId = ex.exerciseId;
          }
        }
      }
    }

    final anyDone = sets.any((s) => s.completed);
    if (!anyDone) {
      if (!context.mounted) return;
      await showInfoModal(
        context: context,
        title: 'Nothing to save',
        message: 'Tick at least one set before finishing.',
      );
      return;
    }

    try {
      // PR check: compare to best prior e1rm for that exercise.
      // Uses the stable exerciseId so renames don't reset the PR baseline.
      PrResult? pr;
      if (bestPrExercise != null && bestPrE1rm > 0) {
        final prior = await ref.read(workoutRepositoryProvider).getSetsForExercise(
              exerciseId: bestPrExerciseId,
              exerciseName: bestPrExercise,
            );
        double priorBest = 0;
        for (final s in prior) {
          final e = estimatedOneRepMax(s.set.weightKg, s.set.reps);
          if (e != null && e > priorBest) priorBest = e;
        }
        if (bestPrE1rm > priorBest) {
          pr = PrResult(
            exercise: bestPrExercise,
            weight: bestPrWeight!,
            reps: bestPrReps!,
            e1rm: bestPrE1rm,
          );
        }
      }

      await ref.read(workoutRepositoryProvider).saveWorkout(
            date: DateTime.now(),
            templateId: templateId,
            dayId: widget.dayId,
            blockId: widget.blockId,
            blockName: kBlockNames[widget.blockId] ?? widget.blockId,
            blockIcon: kBlockIcons[widget.blockId] ?? '',
            theme: meta.theme.name,
            sets: sets,
          );

      if (!context.mounted) return;
      if (pr != null) {
        await showInfoModal(
          context: context,
          title: 'New PR!',
          message:
              '${pr.exercise}: ${pr.weight}kg × ${pr.reps} reps — est. ${pr.e1rm.toStringAsFixed(1)}kg 1RM',
          buttonLabel: "Let's go!",
        );
      }
      if (!context.mounted) return;
      final savedCount = sets.where((s) => s.completed).length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Block saved — $savedCount set${savedCount == 1 ? '' : 's'} logged'),
          duration: const Duration(seconds: 2),
        ),
      );
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      await showInfoModal(
        context: context,
        title: "Couldn't save",
        message: 'Something went wrong saving this block. Your sets are still here — try again.',
      );
      return;
    }
  }
}

class PrResult {
  final String exercise;
  final double weight;
  final int reps;
  final double e1rm;
  PrResult({
    required this.exercise,
    required this.weight,
    required this.reps,
    required this.e1rm,
  });
}

String _formatKg(double kg) {
  if (kg == kg.roundToDouble()) return kg.toInt().toString();
  return kg.toStringAsFixed(1);
}
