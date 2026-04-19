import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app_providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/util/one_rep_max.dart';
import '../../widgets/confirm_modal.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(_logsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No workouts logged yet.\nFinish a block to see it here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _HistoryCard(log: logs[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

final _logsProvider = StreamProvider<List<WorkoutLog>>(
  (ref) => ref.watch(workoutRepositoryProvider).watchAllLogs(),
);

class _HistoryCard extends ConsumerWidget {
  final WorkoutLog log;
  const _HistoryCard({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final date = DateTime.fromMillisecondsSinceEpoch(log.date);
    final dateStr = DateFormat('d MMM yyyy, HH:mm').format(date);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(log.blockIcon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.blockName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${dateStr}  •  Day ${log.dayId}',
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: scheme.error),
                  onPressed: () async {
                    final ok = await showConfirmModal(
                      context: context,
                      title: 'Delete entry?',
                      message: 'This workout log will be permanently removed.',
                      confirmLabel: 'Delete',
                      danger: true,
                    );
                    if (ok) {
                      await ref.read(workoutRepositoryProvider).deleteLog(log.id);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            FutureBuilder(
              future: ref.read(workoutRepositoryProvider).getSetsForLog(log.id),
              builder: (context, snap) {
                final sets = snap.data ?? const <ExerciseSet>[];
                if (sets.isEmpty) return const SizedBox.shrink();
                final grouped = <String, List<ExerciseSet>>{};
                for (final s in sets) {
                  grouped.putIfAbsent(s.exerciseName, () => []).add(s);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final entry in grouped.entries) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.key,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      for (final s in entry.value)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text(
                            _formatSet(s),
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurface.withValues(alpha: 0.7),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatSet(ExerciseSet s) {
    final mark = s.completed ? '✓' : '–';
    final w = s.weightKg?.toString() ?? '—';
    final r = s.reps?.toString() ?? '—';
    final e1rm = estimatedOneRepMax(s.weightKg, s.reps);
    final tail = e1rm == null ? '' : '  (est. ${e1rm}kg)';
    return '$mark  set ${s.setNumber}: ${w}kg × $r$tail';
  }
}
