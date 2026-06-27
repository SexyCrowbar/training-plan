import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app_providers.dart';
import '../../data/db/app_database.dart';
import '../../domain/util/one_rep_max.dart';
import '../../widgets/confirm_modal.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime? _filterDay;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(_logsProvider);
    final scheme = Theme.of(context).colorScheme;
    final filterLabel = _filterDay == null
        ? 'All dates'
        : DateFormat('d MMM yyyy').format(_filterDay!);
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          if (_filterDay != null)
            IconButton(
              tooltip: 'Clear date filter',
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _filterDay = null),
            ),
          IconButton(
            tooltip: 'Pick a date',
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body: logsAsync.when(
        data: (allLogs) {
          final logs = _filterDay == null
              ? allLogs
              : allLogs.where((l) {
                  final d = DateTime.fromMillisecondsSinceEpoch(l.date);
                  return d.year == _filterDay!.year &&
                      d.month == _filterDay!.month &&
                      d.day == _filterDay!.day;
                }).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 16,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      filterLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${logs.length} entr${logs.length == 1 ? 'y' : 'ies'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: logs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            _filterDay == null
                                ? 'No workouts logged yet.\nFinish a block to see it here.'
                                : 'No workouts on this date.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: logs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) => _HistoryCard(log: logs[i]),
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

  Future<void> _pickDate(BuildContext context) async {
    final logs = ref.read(_logsProvider).valueOrNull ?? const <WorkoutLog>[];
    final now = DateTime.now();
    final loggedDays = <DateTime>{};
    DateTime first = DateTime(now.year - 2, 1, 1);
    if (logs.isNotEmpty) {
      for (final l in logs) {
        final d = DateTime.fromMillisecondsSinceEpoch(l.date);
        loggedDays.add(DateTime(d.year, d.month, d.day));
      }
      final earliest = loggedDays.reduce((a, b) => a.isBefore(b) ? a : b);
      first = earliest;
    }
    final initial = _filterDay != null && loggedDays.contains(_filterDay)
        ? _filterDay!
        : (loggedDays.isNotEmpty
              ? loggedDays.reduce((a, b) => a.isAfter(b) ? a : b)
              : now);
    if (!context.mounted) return;
    final scheme = Theme.of(context).colorScheme;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now,
      selectableDayPredicate: (d) =>
          loggedDays.contains(DateTime(d.year, d.month, d.day)),
      helpText: 'Pick a logged day (others are greyed out)',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              dayStyle: const TextStyle(fontWeight: FontWeight.w700),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return scheme.onSurface.withValues(alpha: 0.25);
                }
                if (states.contains(WidgetState.selected)) {
                  return scheme.onPrimary;
                }
                return scheme.primary;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return scheme.primary;
                }
                if (states.contains(WidgetState.disabled)) return null;
                return scheme.primary.withValues(alpha: 0.08);
              }),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(
        () => _filterDay = DateTime(picked.year, picked.month, picked.day),
      );
    }
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$dateStr  •  Day ${log.dayId}',
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
                      await ref
                          .read(workoutRepositoryProvider)
                          .deleteLog(log.id);
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
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
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
