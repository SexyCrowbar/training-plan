# Training Plan Feature Additions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three independent features to the Protocol Flutter app: (1) date-driven active day that auto-advances at local midnight, (2) previous top set shown under each exercise on the workout screen, and (3) rest-timer sound + background notification with a settings toggle.

**Architecture:** Three feature slices built in order 2 → 3 → 1 (smallest to largest surface area). A shared `appLifecycleProvider` introduced during Feature 3 is consumed by Feature 1 for lifecycle-aware re-syncs. All features follow existing patterns: Riverpod providers live in `lib/app_providers.dart`, DB queries in repositories, `flutter_local_notifications` for alerts.

**Tech Stack:** Flutter 3.24 / Dart 3.5+, Riverpod 2, Drift (SQLite), flutter_local_notifications, permission_handler.

**Working directory:** `training-plan/` (the Flutter project — has its own git repo).

**Source spec:** `docs/superpowers/specs/2026-04-24-training-plan-features-design.md`

---

## Feature 2 — Last session's top set on workout screen

### Task 2.1: Add `getLastSessionTopSet` to WorkoutRepository

**Files:**
- Modify: `lib/data/repositories/workout_repository.dart`
- Create: `test/data/repositories/workout_repository_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/data/repositories/workout_repository_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/data/db/app_database.dart';
import 'package:protocol/data/repositories/workout_repository.dart';

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertLog({required int epochMs, int dayId = 1, String blockId = 'power'}) {
    return db.into(db.workoutLogs).insert(WorkoutLogsCompanion.insert(
          date: epochMs,
          dayId: dayId,
          blockId: blockId,
          blockName: 'Test',
          blockIcon: '',
          theme: 'iron',
        ));
  }

  Future<void> insertSet({
    required int logId,
    required String name,
    required int setNumber,
    double? weight,
    int? reps,
    bool completed = true,
  }) async {
    await db.into(db.exerciseSets).insert(ExerciseSetsCompanion.insert(
          logId: logId,
          exerciseName: name,
          setNumber: setNumber,
          weightKg: Value(weight),
          reps: Value(reps),
          completed: Value(completed),
        ));
  }

  group('getLastSessionTopSet', () {
    test('returns null when no history exists', () async {
      expect(await repo.getLastSessionTopSet('Bench'), isNull);
    });

    test('returns top set from the most recent session', () async {
      final older = await insertLog(epochMs: 1000);
      await insertSet(logId: older, name: 'Bench', setNumber: 1, weight: 100, reps: 5);

      final newer = await insertLog(epochMs: 2000);
      await insertSet(logId: newer, name: 'Bench', setNumber: 1, weight: 80, reps: 3);
      await insertSet(logId: newer, name: 'Bench', setNumber: 2, weight: 85, reps: 2);
      await insertSet(logId: newer, name: 'Bench', setNumber: 3, weight: 80, reps: 5);

      final result = await repo.getLastSessionTopSet('Bench');
      expect(result, isNotNull);
      expect(result!.weightKg, 85);
      expect(result.reps, 2);
    });

    test('bodyweight (null weight): returns set with most reps', () async {
      final log = await insertLog(epochMs: 1000);
      await insertSet(logId: log, name: 'Pull-Ups', setNumber: 1, weight: null, reps: 10);
      await insertSet(logId: log, name: 'Pull-Ups', setNumber: 2, weight: null, reps: 8);

      final result = await repo.getLastSessionTopSet('Pull-Ups');
      expect(result, isNotNull);
      expect(result!.weightKg, isNull);
      expect(result.reps, 10);
    });

    test('ignores incomplete sets', () async {
      final log = await insertLog(epochMs: 1000);
      await insertSet(logId: log, name: 'Bench', setNumber: 1, weight: 100, reps: 5, completed: true);
      await insertSet(logId: log, name: 'Bench', setNumber: 2, weight: 120, reps: 3, completed: false);

      final result = await repo.getLastSessionTopSet('Bench');
      expect(result!.weightKg, 100);
    });

    test('tie on weight breaks by reps descending', () async {
      final log = await insertLog(epochMs: 1000);
      await insertSet(logId: log, name: 'Bench', setNumber: 1, weight: 80, reps: 5);
      await insertSet(logId: log, name: 'Bench', setNumber: 2, weight: 80, reps: 8);
      await insertSet(logId: log, name: 'Bench', setNumber: 3, weight: 80, reps: 3);

      final result = await repo.getLastSessionTopSet('Bench');
      expect(result!.reps, 8);
    });

    test('skips newer sessions that have no completed sets of this exercise', () async {
      final old = await insertLog(epochMs: 1000);
      await insertSet(logId: old, name: 'Bench', setNumber: 1, weight: 100, reps: 5, completed: true);

      final newer = await insertLog(epochMs: 2000);
      await insertSet(logId: newer, name: 'Bench', setNumber: 1, weight: 120, reps: 3, completed: false);
      await insertSet(logId: newer, name: 'Squats', setNumber: 1, weight: 140, reps: 5, completed: true);

      final result = await repo.getLastSessionTopSet('Bench');
      expect(result!.weightKg, 100);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/data/repositories/workout_repository_test.dart
```

Expected: compile error — `The method 'getLastSessionTopSet' isn't defined for the class 'WorkoutRepository'.`

- [ ] **Step 3: Implement `getLastSessionTopSet`**

In `lib/data/repositories/workout_repository.dart`, add the method inside the `WorkoutRepository` class (insert above `watchDoneBlocks`):

```dart
  /// Top set (highest weight, tie-break highest reps) from the most recent
  /// completed session for [exerciseName]. Returns null if no prior completed
  /// set exists. Null weight is treated as 0 for sort ordering so weighted sets
  /// always rank above bodyweight, and within all-bodyweight sessions the set
  /// with the most reps wins.
  Future<ExerciseSet?> getLastSessionTopSet(String exerciseName) async {
    final newest = await (db.select(db.exerciseSets).join([
      innerJoin(db.workoutLogs, db.workoutLogs.id.equalsExp(db.exerciseSets.logId)),
    ])
          ..where(db.exerciseSets.exerciseName.equals(exerciseName))
          ..where(db.exerciseSets.completed.equals(true))
          ..orderBy([OrderingTerm.desc(db.workoutLogs.date)])
          ..limit(1))
        .getSingleOrNull();
    if (newest == null) return null;
    final logId = newest.readTable(db.exerciseSets).logId;

    final sets = await (db.select(db.exerciseSets)
          ..where((s) => s.logId.equals(logId))
          ..where((s) => s.exerciseName.equals(exerciseName))
          ..where((s) => s.completed.equals(true)))
        .get();
    if (sets.isEmpty) return null;

    sets.sort((a, b) {
      final wA = a.weightKg ?? 0;
      final wB = b.weightKg ?? 0;
      final weightCmp = wB.compareTo(wA);
      if (weightCmp != 0) return weightCmp;
      return (b.reps ?? 0).compareTo(a.reps ?? 0);
    });
    return sets.first;
  }
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
flutter test test/data/repositories/workout_repository_test.dart
```

Expected: `All tests passed!` (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/data/repositories/workout_repository.dart test/data/repositories/workout_repository_test.dart
git commit -m "feat(workout): add getLastSessionTopSet repo query"
```

---

### Task 2.2: Add `lastTopSetProvider`

**Files:**
- Modify: `lib/app_providers.dart`

- [ ] **Step 1: Add the provider**

Append to the end of `lib/app_providers.dart` (after `todayGtgProvider`):

```dart
/// Top set (highest weight, tie-break highest reps) from the most recent
/// completed session for an exercise name. Used by WorkoutScreen to show a
/// "Last: ${weight} kg × ${reps}" hint above the set inputs.
final lastTopSetProvider = FutureProvider.family<ExerciseSet?, String>(
  (ref, exerciseName) {
    return ref.watch(workoutRepositoryProvider).getLastSessionTopSet(exerciseName);
  },
);
```

`ExerciseSet` is already available via the existing `import 'data/db/app_database.dart';` at the top of the file (line 3 — Drift's generated types are exported from that import). No new imports required.

- [ ] **Step 2: Run analyze to verify no type errors**

```bash
flutter analyze lib/app_providers.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/app_providers.dart
git commit -m "feat(providers): add lastTopSetProvider family"
```

---

### Task 2.3: Render "Last:" line in WorkoutScreen

**Files:**
- Modify: `lib/features/workout/workout_screen.dart`

- [ ] **Step 1: Update `_exerciseBlock`**

In `lib/features/workout/workout_screen.dart`, find the block inside `_exerciseBlock` that renders the `'${ex.sets} × ${ex.target}  •  Rest ${ex.restSeconds}s'` Text (approx line 132–140). Replace the single `Padding` with a `Padding` that wraps a `Column` containing both the target line and a `Consumer` for the last-top-set line.

Replace this:

```dart
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${ex.sets} × ${ex.target}  •  Rest ${ex.restSeconds}s',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
```

With this:

```dart
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ex.sets} × ${ex.target}  •  Rest ${ex.restSeconds}s',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Consumer(builder: (context, ref, _) {
                    final top = ref.watch(lastTopSetProvider(ex.name)).valueOrNull;
                    if (top == null || top.reps == null) return const SizedBox.shrink();
                    final w = top.weightKg;
                    final weightLabel = (w == null || w == 0) ? 'BW' : '${_formatKg(w)} kg';
                    return Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Last: $weightLabel × ${top.reps}',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.primary.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
```

Add a private top-level helper at the bottom of the file (below the `PrResult` class):

```dart
String _formatKg(double kg) {
  if (kg == kg.roundToDouble()) return kg.toInt().toString();
  return kg.toStringAsFixed(1);
}
```

The required imports (`../../app_providers.dart` for `lastTopSetProvider`, `package:flutter_riverpod/flutter_riverpod.dart` for `Consumer`) are already present in this file — no new imports required.

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/features/workout/workout_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Smoke test the app**

```bash
flutter test
```

Expected: existing smoke test `App boots and shows a MaterialApp` still passes, and the new repo test still passes.

- [ ] **Step 4: Commit**

```bash
git add lib/features/workout/workout_screen.dart
git commit -m "feat(workout): show last session's top set under each exercise"
```

---

## Feature 3 — Rest timer sound + background notification + toggle

### Task 3.1: Add rest-timer channel and post method to NotificationHelper

**Files:**
- Modify: `lib/notifications/notification_helper.dart`

- [ ] **Step 1: Extend NotificationHelper**

Replace the entire contents of `lib/notifications/notification_helper.dart` with:

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHelper {
  // GTG channel (existing)
  static const _gtgChannelId = 'gtg_reminders';
  static const _gtgChannelName = 'GTG Reminders';
  static const _gtgChannelDesc = 'Hourly reminders to do a Grease-the-Groove set.';
  static const _gtgNotificationId = 1001;

  // Rest timer channel (new)
  static const _restChannelId = 'rest_timer_alerts';
  static const _restChannelName = 'Rest timer alerts';
  static const _restChannelDesc = 'Notifies when your rest timer is up.';
  static const _restNotificationId = 1002;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: androidInit);
    await _plugin.initialize(init);
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _gtgChannelId,
      _gtgChannelName,
      description: _gtgChannelDesc,
      importance: Importance.defaultImportance,
    ));
    await androidImpl?.createNotificationChannel(const AndroidNotificationChannel(
      _restChannelId,
      _restChannelName,
      description: _restChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    ));
  }

  static Future<bool> requestPermissions() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission() ?? true;
    return granted;
  }

  static Future<void> postGtgReminder() async {
    const androidDetails = AndroidNotificationDetails(
      _gtgChannelId,
      _gtgChannelName,
      channelDescription: _gtgChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      autoCancel: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      _gtgNotificationId,
      'Grease the Groove',
      'Time for a set. Keep it easy — no sweat.',
      details,
    );
  }

  static Future<void> postRestTimerAlert() async {
    const androidDetails = AndroidNotificationDetails(
      _restChannelId,
      _restChannelName,
      channelDescription: _restChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      playSound: true,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      _restNotificationId,
      'Rest over',
      'Time for your next set.',
      details,
    );
  }
}
```

Note: the existing `_channelId`/`_channelName`/`_channelDesc` are renamed to `_gtgChannelId` etc. for symmetry with the new rest constants. These are file-private (underscore-prefixed), so no other file in the codebase can reference them.

- [ ] **Step 2: Verify the app still analyzes cleanly**

```bash
flutter analyze lib/
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/notifications/notification_helper.dart
git commit -m "feat(notifications): add rest-timer channel + postRestTimerAlert"
```

---

### Task 3.2: Add `restTimerAlertEnabled` to SettingsKeys

**Files:**
- Modify: `lib/data/repositories/settings_repository.dart`

- [ ] **Step 1: Add the key**

In `lib/data/repositories/settings_repository.dart`, add the new key to the `SettingsKeys` class:

```dart
class SettingsKeys {
  static const activeTemplateId = 'active_template_id';
  static const weekStartDate = 'weekStartDate';
  static const remindersEnabled = 'reminders_enabled';
  static const startHour = 'start_hour';
  static const endHour = 'end_hour';
  static const restTimerAlertEnabled = 'rest_timer_alert_enabled';
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/data/repositories/settings_repository.dart
git commit -m "feat(settings): add restTimerAlertEnabled key"
```

---

### Task 3.3: Add `appLifecycleProvider` and wire up observer in ProtocolApp

**Files:**
- Modify: `lib/app_providers.dart`
- Modify: `lib/app.dart`

- [ ] **Step 1: Add the provider**

In `lib/app_providers.dart`, add at the top (after the existing `import` lines, in the imports section):

```dart
import 'package:flutter/widgets.dart';
```

Then add near the other UI state providers (after `currentDayProvider`):

```dart
/// Current lifecycle state of the app — written by a WidgetsBindingObserver
/// registered in ProtocolApp. Consumed by:
///   * RestTimerController — to decide whether to post a background notification.
///   * TrainScreen — to re-sync the active day when the app is resumed.
final appLifecycleProvider = StateProvider<AppLifecycleState>(
  (ref) => AppLifecycleState.resumed,
);
```

- [ ] **Step 2: Convert ProtocolApp to a ConsumerStatefulWidget with a lifecycle observer**

Replace the entire contents of `lib/app.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import 'router.dart';
import 'theme/theme_builder.dart';

class ProtocolApp extends ConsumerStatefulWidget {
  const ProtocolApp({super.key});

  @override
  ConsumerState<ProtocolApp> createState() => _ProtocolAppState();
}

class _ProtocolAppState extends ConsumerState<ProtocolApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(appLifecycleProvider.notifier).state = state;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Protocol',
      theme: theme,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 3: Run the smoke test**

```bash
flutter test test/widget_test.dart
```

Expected: `App boots and shows a MaterialApp` still passes.

- [ ] **Step 4: Run analyze across the app**

```bash
flutter analyze lib/
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/app_providers.dart lib/app.dart
git commit -m "feat(app): add appLifecycleProvider + WidgetsBindingObserver"
```

---

### Task 3.4: Refactor RestTimerController to accept `onExpired`

**Files:**
- Modify: `lib/features/workout/rest_timer_controller.dart`
- Create: `test/features/workout/rest_timer_controller_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/features/workout/rest_timer_controller_test.dart`:

```dart
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/features/workout/rest_timer_controller.dart';

void main() {
  group('RestTimerController', () {
    test('onExpired fires exactly once when the timer reaches zero', () {
      fakeAsync((async) {
        var calls = 0;
        final ctrl = RestTimerController(onExpired: () async {
          calls++;
        });

        ctrl.start(3);
        // Advance past the full duration.
        async.elapse(const Duration(seconds: 4));

        expect(calls, 1);
        expect(ctrl.state.running, isFalse);
        expect(ctrl.state.remainingSeconds, 0);
      });
    });

    test('skip() does not trigger onExpired', () {
      fakeAsync((async) {
        var calls = 0;
        final ctrl = RestTimerController(onExpired: () async {
          calls++;
        });

        ctrl.start(10);
        async.elapse(const Duration(seconds: 2));
        ctrl.skip();
        async.elapse(const Duration(seconds: 20));

        expect(calls, 0);
      });
    });

    test('onExpired null (legacy construction) does not throw', () {
      fakeAsync((async) {
        final ctrl = RestTimerController();
        ctrl.start(1);
        async.elapse(const Duration(seconds: 2));
        expect(ctrl.state.running, isFalse);
      });
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

```bash
flutter test test/features/workout/rest_timer_controller_test.dart
```

Expected: compile error — the `onExpired` named parameter is not defined on `RestTimerController`.

- [ ] **Step 3: Refactor the controller**

Replace the contents of `lib/features/workout/rest_timer_controller.dart` with:

```dart
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../notifications/notification_helper.dart';

class RestTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool running;

  const RestTimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.running,
  });

  double get progress => totalSeconds == 0 ? 0 : remainingSeconds / totalSeconds;
  bool get isActive => running && remainingSeconds > 0;

  const RestTimerState.idle() : remainingSeconds = 0, totalSeconds = 0, running = false;

  RestTimerState copyWith({int? remainingSeconds, int? totalSeconds, bool? running}) =>
      RestTimerState(
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        running: running ?? this.running,
      );
}

class RestTimerController extends StateNotifier<RestTimerState> {
  RestTimerController({this.onExpired}) : super(const RestTimerState.idle());

  final Future<void> Function()? onExpired;
  Timer? _timer;

  void start(int seconds) {
    if (seconds <= 0) {
      stop();
      return;
    }
    _timer?.cancel();
    state = RestTimerState(
      remainingSeconds: seconds,
      totalSeconds: seconds,
      running: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = state.remainingSeconds - 1;
      if (next <= 0) {
        _timer?.cancel();
        HapticFeedback.mediumImpact();
        state = state.copyWith(remainingSeconds: 0, running: false);
        onExpired?.call();
      } else {
        state = state.copyWith(remainingSeconds: next);
      }
    });
  }

  void stop() {
    _timer?.cancel();
    state = const RestTimerState.idle();
  }

  void skip() {
    _timer?.cancel();
    state = state.copyWith(remainingSeconds: 0, running: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerController, RestTimerState>((ref) {
  return RestTimerController(onExpired: () async {
    final lifecycle = ref.read(appLifecycleProvider);
    if (lifecycle == AppLifecycleState.resumed) return;
    final enabled = await ref
        .read(settingsRepositoryProvider)
        .getBool(SettingsKeys.restTimerAlertEnabled, defaultValue: true);
    if (!enabled) return;
    await NotificationHelper.postRestTimerAlert();
  });
});
```

- [ ] **Step 4: Run the tests to verify they pass**

```bash
flutter test test/features/workout/rest_timer_controller_test.dart
```

Expected: all 3 tests pass.

- [ ] **Step 5: Run analyze**

```bash
flutter analyze lib/
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/features/workout/rest_timer_controller.dart test/features/workout/rest_timer_controller_test.dart
git commit -m "feat(workout): rest timer fires alert on expiry when backgrounded"
```

---

### Task 3.5: Add Settings toggle for the rest timer alert

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Add the `_restAlertEnabledProvider` and UI card**

In `lib/features/settings/settings_screen.dart`, add a new private provider near the existing `_remindersEnabledProvider`:

```dart
final _restAlertEnabledProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchBool(SettingsKeys.restTimerAlertEnabled, defaultValue: true);
});
```

Inside the `build` method, read the new value near the existing watches:

```dart
    final restAlertEnabled = ref.watch(_restAlertEnabledProvider).valueOrNull ?? true;
```

Then insert a new card in the `ListView` between the "Test reminder now" card and the "Data" card (approximately line 127–128, right after the closing `),` of the `Test reminder now` Card). The card:

```dart
          const SizedBox(height: 10),
          Card(
            child: SwitchListTile(
              title: const Text('Rest timer alert'),
              subtitle: const Text(
                'Sound + notification when rest ends (while app is backgrounded).',
              ),
              value: restAlertEnabled,
              onChanged: (v) async {
                if (v) {
                  final granted = await NotificationHelper.requestPermissions();
                  if (!granted) return;
                }
                await settings.setBool(SettingsKeys.restTimerAlertEnabled, v);
              },
            ),
          ),
```

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/settings/settings_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Run all tests**

```bash
flutter test
```

Expected: smoke test + repo tests + controller tests all pass.

- [ ] **Step 4: Commit**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "feat(settings): add rest timer alert toggle"
```

---

## Feature 1 — Date-driven active day

### Task 1.1: Change `effectiveWeekStart` fallback to `todayKey()`

**Files:**
- Modify: `lib/domain/util/week.dart`
- Create: `test/domain/util/week_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/domain/util/week_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/domain/util/week.dart';

void main() {
  group('effectiveWeekStart', () {
    test('returns the stored value when provided', () {
      expect(effectiveWeekStart('2026-04-20'), '2026-04-20');
    });

    test('returns todayKey when stored is null', () {
      expect(effectiveWeekStart(null), todayKey());
    });

    test('returns todayKey when stored is empty string', () {
      expect(effectiveWeekStart(''), todayKey());
    });
  });

  group('dateKey / parseDateKey', () {
    test('round-trips a date', () {
      final d = DateTime(2026, 4, 24);
      expect(parseDateKey(dateKey(d)), d);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify some pass and some fail**

```bash
flutter test test/domain/util/week_test.dart
```

Expected: The `returns todayKey when stored is null` and `returns todayKey when stored is empty string` tests fail (current fallback is `today − 6 days`). The other two pass.

- [ ] **Step 3: Update `effectiveWeekStart`**

In `lib/domain/util/week.dart`, replace:

```dart
/// Effective week-start: the stored value, or 6 days ago as a safe default.
String effectiveWeekStart(String? stored) {
  if (stored != null && stored.isNotEmpty) return stored;
  return dateKey(DateTime.now().subtract(const Duration(days: 6)));
}
```

With:

```dart
/// Effective week-start: the stored value, or today as the default.
/// A fresh install lands on day 1 of the plan because (today - today).inDays == 0,
/// which the derivedDayProvider clamps to day 1.
String effectiveWeekStart(String? stored) {
  if (stored != null && stored.isNotEmpty) return stored;
  return todayKey();
}
```

- [ ] **Step 4: Run the test to verify it passes**

```bash
flutter test test/domain/util/week_test.dart
```

Expected: all 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/util/week.dart test/domain/util/week_test.dart
git commit -m "feat(week): default week start to today so fresh installs land on day 1"
```

---

### Task 1.2: Add `derivedDayProvider` and `dateTickerProvider`

**Files:**
- Modify: `lib/app_providers.dart`

`lib/app_providers.dart` already imports `domain/util/week.dart` (line 11) for `effectiveWeekStart`, which also exposes `parseDateKey`. No new imports required for this task.

- [ ] **Step 1: Add the providers**

Insert immediately after `weekStartProvider` in `lib/app_providers.dart`:

```dart
/// Ticks on app start and at each local midnight. Downstream providers that
/// watch this will recompute, which is how `derivedDayProvider` advances.
final dateTickerProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  while (true) {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now);
    await Future<void>.delayed(delay);
    yield DateTime.now();
  }
});

/// Day of the 5-day cycle derived from today's date relative to weekStartDate.
/// Clamps at 5 (rest day); after day 5 the user must tap "Start new week".
final derivedDayProvider = Provider<int>((ref) {
  ref.watch(dateTickerProvider);
  final weekStart = ref.watch(weekStartProvider).valueOrNull;
  if (weekStart == null) return 1;
  final start = parseDateKey(weekStart);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(start).inDays;
  return (diff + 1).clamp(1, 5);
});
```

- [ ] **Step 2: Update `currentDayProvider` to seed from derived**

Replace:

```dart
/// Currently selected day (1..5) — UI state.
final currentDayProvider = StateProvider<int>((ref) => 1);
```

With:

```dart
/// Currently selected day (1..5). Seeded from `derivedDayProvider`; re-synced by
/// TrainScreen on midnight ticks and on app resume. Manual day-tab taps write to
/// `.state` directly and remain in effect until the next sync point.
final currentDayProvider = StateProvider<int>((ref) {
  return ref.watch(derivedDayProvider);
});
```

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/app_providers.dart
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/app_providers.dart
git commit -m "feat(providers): add derivedDayProvider + dateTickerProvider"
```

---

### Task 1.3: Sync `currentDayProvider` from derived in TrainScreen; remove trainAutoAdvanceProvider usage

**Files:**
- Modify: `lib/features/train/train_screen.dart`

- [ ] **Step 1: Update TrainScreen**

In `lib/features/train/train_screen.dart`:

1. Remove the `train_controller.dart` import (line 15) and the `ref.watch(trainAutoAdvanceProvider);` call (line 22).
2. Add two `ref.listen` calls at the top of `build` to sync `currentDayProvider` from derived on midnight ticks and lifecycle resumes.

Replace the `build` body's opening section. Find:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(trainAutoAdvanceProvider);

    // historyAutoSeedProvider transitively awaits seedBootProvider, so
    // watching it covers both first-launch seeds in one boot gate.
    final boot = ref.watch(historyAutoSeedProvider);
```

Replace with:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-sync the displayed day to today's derived day whenever the ticker
    // fires (midnight crossing) or when the app is resumed. Manual day-tab
    // taps between these events remain in effect.
    ref.listen<int>(derivedDayProvider, (prev, next) {
      ref.read(currentDayProvider.notifier).state = next;
    }, fireImmediately: true);
    ref.listen<AppLifecycleState>(appLifecycleProvider, (prev, next) {
      if (prev != null && next == AppLifecycleState.resumed) {
        ref.invalidate(dateTickerProvider);
        ref.read(currentDayProvider.notifier).state = ref.read(derivedDayProvider);
      }
    });

    // historyAutoSeedProvider transitively awaits seedBootProvider, so
    // watching it covers both first-launch seeds in one boot gate.
    final boot = ref.watch(historyAutoSeedProvider);
```

`AppLifecycleState` is already available via the existing `package:flutter/material.dart` import (Material re-exports `widgets.dart`). No new imports required.

Remove the now-unused `import 'train_controller.dart';` line (line 15).

- [ ] **Step 2: Analyze**

```bash
flutter analyze lib/features/train/train_screen.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Run the smoke test**

```bash
flutter test test/widget_test.dart
```

Expected: passes.

- [ ] **Step 4: Commit**

```bash
git add lib/features/train/train_screen.dart
git commit -m "feat(train): sync active day from derived on tick and resume"
```

---

### Task 1.4: Remove `trainAutoAdvanceProvider`

**Files:**
- Delete: `lib/features/train/train_controller.dart`

- [ ] **Step 1: Verify nothing else references `trainAutoAdvanceProvider`**

```bash
grep -r "trainAutoAdvanceProvider" lib/ test/
```

Expected: no results (we removed the last reference in Task 1.3).

- [ ] **Step 2: Delete the file**

```bash
rm lib/features/train/train_controller.dart
```

- [ ] **Step 3: Analyze and test**

```bash
flutter analyze lib/
flutter test
```

Expected: `No issues found!` and all tests pass.

- [ ] **Step 4: Commit**

```bash
git add -A lib/features/train/
git commit -m "refactor(train): remove trainAutoAdvanceProvider (superseded by derivedDayProvider)"
```

---

### Task 1.5: Add a unit test for `derivedDayProvider`

**Files:**
- Create: `test/app_providers_test.dart`

- [ ] **Step 1: Write the test**

Create `test/app_providers_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/app_providers.dart';
import 'package:protocol/data/db/app_database.dart';
import 'package:protocol/data/repositories/settings_repository.dart';
import 'package:protocol/domain/util/week.dart';

void main() {
  group('derivedDayProvider', () {
    test('returns 1 when weekStart is today', () async {
      final container = ProviderContainer(overrides: [
        weekStartProvider.overrideWith((ref) async* {
          yield todayKey();
        }),
      ]);
      addTearDown(container.dispose);

      // Wait for the stream to emit.
      await container.read(weekStartProvider.future);
      expect(container.read(derivedDayProvider), 1);
    });

    test('returns (diff + 1) when weekStart is N days ago, clamped to 5', () async {
      final now = DateTime.now();
      final threeDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3));
      final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));

      final c3 = ProviderContainer(overrides: [
        weekStartProvider.overrideWith((ref) async* {
          yield dateKey(threeDaysAgo);
        }),
      ]);
      addTearDown(c3.dispose);
      await c3.read(weekStartProvider.future);
      expect(c3.read(derivedDayProvider), 4);

      final c7 = ProviderContainer(overrides: [
        weekStartProvider.overrideWith((ref) async* {
          yield dateKey(sevenDaysAgo);
        }),
      ]);
      addTearDown(c7.dispose);
      await c7.read(weekStartProvider.future);
      expect(c7.read(derivedDayProvider), 5);
    });
  });
}
```

- [ ] **Step 2: Run the test**

```bash
flutter test test/app_providers_test.dart
```

Expected: both tests pass.

- [ ] **Step 3: Commit**

```bash
git add test/app_providers_test.dart
git commit -m "test(providers): cover derivedDayProvider basics"
```

---

## Final Integration Check

### Task 99: Full test + analyze + manual smoke

**Files:** (none — verification only)

- [ ] **Step 1: Run the full test suite**

```bash
flutter test
```

Expected: every test passes.

- [ ] **Step 2: Run analyze across the project**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Install on a connected device and manually verify**

```bash
flutter devices   # confirm a device is listed
flutter run
```

Manual smoke checklist (user performs these):
- [ ] **Feature 2:** Open a workout block that has history — a `Last: Xkg × Y` line appears under each exercise that has prior data.
- [ ] **Feature 2:** Open a block for an exercise with no history — no `Last:` line appears.
- [ ] **Feature 3:** Open Settings, toggle **Rest timer alert** off then on (grant notification permission if prompted). In a workout, tick a set with a short rest (e.g. 3s), background the app; verify a notification with sound appears when the timer expires.
- [ ] **Feature 3:** Repeat the above with the toggle OFF — no notification.
- [ ] **Feature 3:** Repeat with the toggle ON but app in foreground — no notification; haptic + rest bar return to idle as before.
- [ ] **Feature 1:** On day N, background the app; change the device's local clock forward 24 hours (in a test environment); resume the app — active day tab is N+1 (clamped to 5).
- [ ] **Feature 1:** Manually tap a different day tab — it stays on that tap until the app is resumed or midnight is crossed.
- [ ] **Feature 1:** Tap **Start new week** — weekStartDate resets, day displays as 1.

- [ ] **Step 4: Tag the release (optional)**

```bash
git tag -a feat/three-features-2026-04-24 -m "Date-driven day, prev top set, rest timer alert"
```
