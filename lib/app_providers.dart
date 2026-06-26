import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/db/app_database.dart';
import 'data/repositories/gtg_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/template_repository.dart';
import 'data/repositories/template_seeder.dart';
import 'data/repositories/workout_repository.dart';
import 'domain/plan/models.dart';
import 'domain/plan/training_plan.dart';
import 'domain/util/week.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final templateSeederProvider = Provider<TemplateSeeder>(
  (ref) => TemplateSeeder(ref.watch(appDatabaseProvider)),
);

final templateRepositoryProvider = Provider<TemplateRepository>(
  (ref) => TemplateRepository(ref.watch(appDatabaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

final gtgRepositoryProvider = Provider<GtgRepository>(
  (ref) => GtgRepository(ref.watch(appDatabaseProvider)),
);

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.watch(appDatabaseProvider)),
);

/// Completes once first-launch seed has run.
final seedBootProvider = FutureProvider<void>((ref) async {
  await ref.watch(templateSeederProvider).seedIfEmpty();
});

final activeTemplateIdProvider = StreamProvider<int?>(
  (ref) => ref.watch(settingsRepositoryProvider).watchInt(SettingsKeys.activeTemplateId),
);

final activeTemplateProvider = StreamProvider<ResolvedTemplate?>((ref) async* {
  final id = ref.watch(activeTemplateIdProvider).valueOrNull;
  if (id == null) {
    yield null;
    return;
  }
  yield* ref.watch(templateRepositoryProvider).watchResolved(id);
});

final allTemplatesProvider = StreamProvider<List<Template>>(
  (ref) => ref.watch(templateRepositoryProvider).watchAll(),
);

/// Currently selected day (1..5). Seeded once from `derivedDayProvider`. After
/// that, the value only changes via:
///   * a manual day-tab tap (DayTabs),
///   * a midnight crossing (derivedDayProvider listener in TrainScreen),
///   * "Start new week" (TrainScreen sets it to 1).
/// Lifecycle changes (app minimize / resume / app switch) MUST NOT reset it —
/// hence `ref.read` instead of `ref.watch` so the StateProvider doesn't rebuild
/// when derivedDay re-emits.
final currentDayProvider = StateProvider<int>((ref) {
  return ref.read(derivedDayProvider);
});

/// Current lifecycle state of the app — written by a WidgetsBindingObserver
/// registered in ProtocolApp. Consumed by:
///   * RestTimerController — to decide whether to post a background notification.
///   * TrainScreen — to re-sync the active day when the app is resumed.
final appLifecycleProvider = StateProvider<AppLifecycleState>(
  (ref) => AppLifecycleState.resumed,
);

/// Day metadata from the static plan (name, theme, tag, gtg) — not user-editable.
final currentDayMetaProvider = Provider<Day>((ref) {
  final day = ref.watch(currentDayProvider);
  return TrainingPlan.days[day]!;
});

final weekStartProvider = StreamProvider<String>((ref) async* {
  final stream = ref.watch(settingsRepositoryProvider).watch(SettingsKeys.weekStartDate);
  await for (final stored in stream) {
    yield effectiveWeekStart(stored);
  }
});

/// Ticks on app start and at each local midnight. Downstream providers that
/// watch this will recompute, which is how `derivedDayProvider` advances.
final dateTickerProvider = StreamProvider<DateTime>((ref) {
  final controller = StreamController<DateTime>();
  Timer? timer;
  void scheduleNext() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    timer = Timer(nextMidnight.difference(now), () {
      if (controller.isClosed) return;
      controller.add(DateTime.now());
      scheduleNext();
    });
  }

  controller.add(DateTime.now());
  scheduleNext();

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Day of the 7-day cycle derived from today's date relative to weekStartDate.
/// Wraps continuously (day 8 == day 1) via the shared [dayOfCycle] helper, which
/// the GTG reminder callback also uses — so the UI and reminders always agree on
/// which day is which.
final derivedDayProvider = Provider<int>((ref) {
  ref.watch(dateTickerProvider);
  final weekStart = ref.watch(weekStartProvider).valueOrNull;
  if (weekStart == null) return 1;
  final now = DateTime.now();
  return dayOfCycle(now, parseDateKey(weekStart));
});

final doneBlocksProvider = StreamProvider<Map<int, Set<String>>>((ref) async* {
  final weekStart = ref.watch(weekStartProvider).valueOrNull;
  if (weekStart == null) {
    yield const {};
    return;
  }
  yield* ref.watch(workoutRepositoryProvider).watchDoneBlocks(weekStart);
});

final todayGtgProvider = StreamProvider<Map<int, int>>(
  (ref) => ref.watch(gtgRepositoryProvider).watchTodayCounts(),
);

/// Top set (highest weight, tie-break highest reps) from the most recent
/// completed session for an exercise name. Used by WorkoutScreen to show a
/// "Last: ${weight} kg × ${reps}" hint above the set inputs.
final lastTopSetProvider = FutureProvider.family<ExerciseSet?, String>(
  (ref, exerciseName) {
    return ref.watch(workoutRepositoryProvider).getLastSessionTopSet(exerciseName);
  },
);
