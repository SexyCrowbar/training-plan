import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app_providers.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/util/one_rep_max.dart';
import 'e1rm_chart.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String? _activeLift;

  @override
  Widget build(BuildContext context) {
    final liftsAsync = ref.watch(_liftsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: liftsAsync.when(
        data: (lifts) {
          if (lifts.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Log sets to see your progress.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          _activeLift ??= lifts.first;
          final selected = lifts.contains(_activeLift)
              ? _activeLift!
              : lifts.first;
          final scheme = Theme.of(context).colorScheme;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Exercise',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selected,
                      isExpanded: true,
                      items: [
                        for (final lift in lifts)
                          DropdownMenuItem(
                            value: lift,
                            child: Text(
                              lift,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _activeLift = v);
                      },
                    ),
                  ),
                ),
              ),
              Expanded(child: _LiftDetail(liftName: selected)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

/// Union of distinct exercise names from history + all templates. Replaces
/// the hardcoded `LIFTS` list at `src/components/StatsScreen.jsx:3-9`.
final _liftsProvider = StreamProvider<List<String>>((ref) async* {
  final history = ref
      .watch(workoutRepositoryProvider)
      .watchDistinctExerciseNames();
  final templates = ref
      .watch(templateRepositoryProvider)
      .watchDistinctExerciseNames();

  var lastHistory = <String>[];
  var lastTemplates = <String>[];
  final controller = StreamController<List<String>>();

  List<String> merged() =>
      ({...lastHistory, ...lastTemplates}.toList()..sort());

  final historySub = history.listen((v) {
    lastHistory = v;
    controller.add(merged());
  });
  final templateSub = templates.listen((v) {
    lastTemplates = v;
    controller.add(merged());
  });

  ref.onDispose(() {
    historySub.cancel();
    templateSub.cancel();
    controller.close();
  });

  yield <String>[];
  yield* controller.stream;
});

class _LiftDetail extends ConsumerWidget {
  final String liftName;
  const _LiftDetail({required this.liftName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<ExerciseSetWithDate>>(
      future: ref
          .read(workoutRepositoryProvider)
          .getSetsForExerciseName(liftName),
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Build per-session best e1RM.
        final grouped =
            <int, ({DateTime date, double weight, int reps, double e1rm})>{};
        for (final row in data) {
          final e = estimatedOneRepMax(row.set.weightKg, row.set.reps);
          if (e == null) continue;
          final logId = row.set.logId;
          final existing = grouped[logId];
          if (existing == null || e > existing.e1rm) {
            grouped[logId] = (
              date: DateTime.fromMillisecondsSinceEpoch(row.log.date),
              weight: row.set.weightKg ?? 0,
              reps: row.set.reps ?? 0,
              e1rm: e,
            );
          }
        }
        final sessions = grouped.values.toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        if (sessions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No completed sets with weight + reps for this lift.',
              ),
            ),
          );
        }
        final current = sessions.last;
        final scheme = Theme.of(context).colorScheme;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                liftName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Estimated 1-Rep Max',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${current.e1rm} kg',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: scheme.primary,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Current 1RM',
                              style: TextStyle(
                                fontSize: 10,
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: sessions.length < 2
                          ? Center(
                              child: Text(
                                'Need at least 2 sessions for a chart',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            )
                          : E1rmChart(
                              values: sessions.map((s) => s.e1rm).toList(),
                            ),
                    ),
                    if (sessions.length >= 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('d MMM').format(sessions.first.date),
                              style: TextStyle(
                                fontSize: 10,
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 10,
                                color: scheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RECENT SESSIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final s in sessions.reversed.take(8)) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('d MMM').format(s.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  '${s.weight}kg × ${s.reps}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'est. ${s.e1rm}kg',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
