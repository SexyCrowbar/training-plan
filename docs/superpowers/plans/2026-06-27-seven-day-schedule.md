# 7-Day Training Schedule Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the app's 5-day rotation with the original 7-day schedule (4 training days, 2 active-recovery days, 1 full rest), wrapping continuously, with reminders suppressed only on the full-rest day.

**Architecture:** A single pure `dayOfCycle()` in `domain/util/week.dart` becomes the one source of truth for "what day of the cycle is it," consumed by both the UI (`derivedDayProvider`) and the reminder background callback — which closes the audit's T1 divergent-day bug. The static `TrainingPlan` grows from 5 to 7 days and gains a `recovery` `DayTheme`. A one-time `planVersion`-gated migration wipes & reseeds templates and re-anchors the week start, preserving all workout history.

**Tech Stack:** Flutter, Riverpod, Drift (SQLite), `android_alarm_manager_plus` + `flutter_local_notifications` (chain-scheduled reminders). **No Drift schema change** (the migration flag is a row in `app_settings`, not a column), so `build_runner` is NOT required.

**Spec:** `docs/superpowers/specs/2026-06-27-seven-day-schedule-design.md`

> **Baseline note (read first):** This plan targets the committed `master`/`feat/seven-day-schedule` baseline (commit `fffd349`), where GTG reminders use the **`android_alarm_manager_plus` chain-scheduling** design: `ReminderScheduler.scheduleNext` arms one `oneShotAt`, and the top-level `_alarmCallback` (background isolate) reads settings, decides whether to post, and re-arms the next alarm. (An in-progress `zonedSchedule` rewrite was set aside in `git stash@{0}`.) Because the callback already opens its own DB, the T1 fix is localized to it and `scheduleNext`'s signature does not change.

---

## Working agreement

- Run all commands from the repo root: `D:\Projects\Training plan\training-plan`.
- Branch is already `feat/seven-day-schedule` (off `master`). Commit after each task.
- Test runner: `flutter test`. Static check: `flutter analyze`.
- Adding `DayTheme.recovery` makes the two exhaustive `switch`es in `colors.dart` fail to compile until Task 3 — that's expected; Tasks 2 and 3 should land back-to-back, though each task's own unit test passes independently.

---

## Task 1: `dayOfCycle()` — the shared day-of-cycle function

**Files:**
- Modify: `lib/domain/util/week.dart`
- Test: `test/domain/util/week_test.dart`

- [ ] **Step 1: Write the failing tests**

Add this group inside `main()` in `test/domain/util/week_test.dart` (after the existing `dateKey / parseDateKey` group):

```dart
  group('dayOfCycle', () {
    DateTime d(int y, int m, int day) => DateTime(y, m, day);

    test('day 0 from start is day 1', () {
      expect(dayOfCycle(d(2026, 6, 27), d(2026, 6, 27)), 1);
    });

    test('counts up through day 7', () {
      final start = d(2026, 6, 27);
      expect(dayOfCycle(d(2026, 6, 28), start), 2);
      expect(dayOfCycle(d(2026, 6, 30), start), 4);
      expect(dayOfCycle(d(2026, 7, 3), start), 7); // +6 days
    });

    test('wraps after day 7', () {
      final start = d(2026, 6, 27);
      expect(dayOfCycle(d(2026, 7, 4), start), 1); // +7 days wraps
      expect(dayOfCycle(d(2026, 7, 10), start), 7); // +13 days
      expect(dayOfCycle(d(2026, 7, 11), start), 1); // +14 days
    });

    test('ignores time-of-day component', () {
      expect(dayOfCycle(DateTime(2026, 6, 28, 23, 59), DateTime(2026, 6, 27, 0, 1)), 2);
    });
  });
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/domain/util/week_test.dart`
Expected: FAIL — "The method 'dayOfCycle' isn't defined".

- [ ] **Step 3: Implement `dayOfCycle`**

Append to `lib/domain/util/week.dart`:

```dart
/// Day of the 7-day training cycle (1..7) for [day], anchored to [weekStart].
/// Wraps continuously, so day 8 == day 1. Dart's `%` is non-negative for a
/// positive divisor, so no guard is needed for `day` before `weekStart`.
int dayOfCycle(DateTime day, DateTime weekStart) {
  final d = DateTime(day.year, day.month, day.day);
  final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
  final diff = d.difference(start).inDays;
  return (diff % 7) + 1;
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/domain/util/week_test.dart`
Expected: PASS (all groups).

- [ ] **Step 5: Commit**

```bash
git add lib/domain/util/week.dart test/domain/util/week_test.dart
git commit -m "feat(week): add 7-day dayOfCycle() shared day function"
```

---

## Task 2: 7-day plan data + `recovery` theme

**Files:**
- Modify: `lib/domain/plan/models.dart`
- Modify: `lib/domain/plan/training_plan.dart`
- Test: `test/domain/plan/training_plan_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/domain/plan/training_plan_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/domain/plan/models.dart';
import 'package:protocol/domain/plan/training_plan.dart';

void main() {
  group('TrainingPlan (7-day)', () {
    test('has exactly 7 days numbered 1..7', () {
      expect(TrainingPlan.days.length, 7);
      expect(TrainingPlan.days.keys.toList()..sort(), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('gtg targets follow the plan', () {
      final targets = [for (var i = 1; i <= 7; i++) TrainingPlan.days[i]!.gtgTarget];
      expect(targets, [5, 5, 5, 4, 5, 3, 0]);
    });

    test('themes: recovery on 4 & 6, rest on 7', () {
      expect(TrainingPlan.days[4]!.theme, DayTheme.recovery);
      expect(TrainingPlan.days[6]!.theme, DayTheme.recovery);
      expect(TrainingPlan.days[7]!.theme, DayTheme.rest);
      expect(TrainingPlan.days[7]!.isRestDay, isTrue);
      expect(TrainingPlan.days[4]!.isRestDay, isFalse);
    });

    test('day 4 has a single recovery block; days 6 & 7 have none', () {
      expect(TrainingPlan.days[4]!.blocks.length, 1);
      expect(TrainingPlan.days[6]!.blocks, isEmpty);
      expect(TrainingPlan.days[7]!.blocks, isEmpty);
    });

    test('training days carry power exercises', () {
      for (final id in [1, 2, 3, 5]) {
        final power = TrainingPlan.days[id]!.blocks.firstWhere((b) => b.id == 'power');
        expect(power.exercises, isNotEmpty, reason: 'day $id power');
      }
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/domain/plan/training_plan_test.dart`
Expected: FAIL — `TrainingPlan.days.length` is 5; `DayTheme.recovery` is undefined.

- [ ] **Step 3: Add `recovery` to the `DayTheme` enum**

In `lib/domain/plan/models.dart`, line 1, change `enum DayTheme { iron, body, rest }` to:

```dart
enum DayTheme { iron, body, recovery, rest }
```

(`isRestDay` stays `theme == DayTheme.rest` — recovery days are deliberately NOT rest days.)

- [ ] **Step 4: Replace the plan data with the 7-day schedule**

Replace the entire `static const Map<int, Day> days = { ... };` in `lib/domain/plan/training_plan.dart` with:

```dart
  static const Map<int, Day> days = {
    1: Day(
      id: 1,
      theme: DayTheme.iron,
      name: 'Day 1: Chest Power',
      tag: 'Tricep & Shoulder Volume',
      gtgTarget: 5,
      gtgEx: 'Strict Underhand Chin-ups',
      blocks: [
        Block(id: 'warmup', icon: '🌅', name: 'Morning Prep', exercises: [
          Exercise(name: 'Desk-to-Barbell Warmup', sets: 1, target: '3 min', restSeconds: 0,
              note: 'Arm circles, shoulder twists, deep squats.'),
        ]),
        Block(id: 'power', icon: '⚡', name: 'Morning Power', exercises: [
          Exercise(name: 'Barbell Bench Press', sets: 3, target: '3-5 reps', restSeconds: 180,
              note: '60–70% max effort. Leave 2 reps in the tank.'),
        ]),
        Block(id: 'hypertrophy', icon: '💪', name: 'Afternoon Hypertrophy', exercises: [
          Exercise(name: 'Parallel Bar Dips', sets: 3, target: 'AMRAP', restSeconds: 60,
              note: 'Superset 1 — near failure, controlled descent.'),
          Exercise(name: 'EZ-Bar Skullcrushers', sets: 3, target: '8-12 reps', restSeconds: 90,
              note: 'Superset 2 — elbows tucked, full extension.'),
        ]),
        Block(id: 'endurance', icon: '🔥', name: 'Evening Endurance', exercises: [
          Exercise(name: 'KB Swings (16kg)', sets: 1, target: '10 min', restSeconds: 0,
              note: 'EMOM — 15 reps at the top of every minute.'),
        ]),
      ],
    ),
    2: Day(
      id: 2,
      theme: DayTheme.body,
      name: 'Day 2: Back Power',
      tag: 'Bicep Annihilation',
      gtgTarget: 5,
      gtgEx: 'Strict Underhand Chin-ups',
      blocks: [
        Block(id: 'warmup', icon: '🌅', name: 'Morning Prep', exercises: [
          Exercise(name: 'Desk-to-Barbell Warmup', sets: 1, target: '3 min', restSeconds: 0,
              note: 'Dead hangs, scap pull-ups, wrist rotations.'),
        ]),
        Block(id: 'power', icon: '⚡', name: 'Morning Power', exercises: [
          Exercise(name: 'Barbell Pendlay Rows', sets: 3, target: '3-5 reps', restSeconds: 180,
              note: 'Explosive pull to the lower ribs. Saves elbows vs daily pull-ups.'),
        ]),
        Block(id: 'hypertrophy', icon: '💪', name: 'Afternoon Hypertrophy', exercises: [
          Exercise(name: 'EZ-Bar Curls', sets: 3, target: '8-12 reps', restSeconds: 60,
              note: 'Superset 1 — full range, squeeze at top.'),
          Exercise(name: 'Ring Face Pulls', sets: 3, target: '12-15 reps', restSeconds: 90,
              note: 'Superset 2 — high attachment, rear delts.'),
        ]),
        Block(id: 'endurance', icon: '🔥', name: 'Evening Endurance', exercises: [
          Exercise(name: 'Bodyweight AMRAP', sets: 1, target: '10 min', restSeconds: 0,
              note: '10 Push-ups → 15 Squats → 20 Jumping Jacks. Repeat.'),
        ]),
      ],
    ),
    3: Day(
      id: 3,
      theme: DayTheme.iron,
      name: 'Day 3: Leg Maintenance',
      tag: 'Shoulder Density',
      gtgTarget: 5,
      gtgEx: 'Strict Underhand Chin-ups',
      blocks: [
        Block(id: 'warmup', icon: '🌅', name: 'Morning Prep', exercises: [
          Exercise(name: 'Desk-to-Barbell Warmup', sets: 1, target: '3 min', restSeconds: 0,
              note: 'Hip openers, Cossack squats, leg swings.'),
        ]),
        Block(id: 'power', icon: '⚡', name: 'Morning Power', exercises: [
          Exercise(name: 'Barbell Zercher Squats', sets: 3, target: '3-5 reps', restSeconds: 180,
              note: 'Raw core power & leg drive. Brace hard.'),
        ]),
        Block(id: 'hypertrophy', icon: '💪', name: 'Afternoon Hypertrophy', exercises: [
          Exercise(name: 'Standing Barbell Overhead Press', sets: 3, target: '8-10 reps', restSeconds: 90,
              note: 'Strict standing — zero leg drive.'),
          Exercise(name: 'EZ-Bar Reverse Curls', sets: 3, target: '10-12 reps', restSeconds: 90,
              note: 'Brachialis focus. Slow eccentric.'),
        ]),
        Block(id: 'endurance', icon: '🔥', name: 'Evening Endurance', exercises: [
          Exercise(name: 'KB Goblet Squats (16kg)', sets: 3, target: '15 reps', restSeconds: 0,
              note: 'Superset with Planks — no rest between.'),
          Exercise(name: 'Planks', sets: 3, target: '60 sec', restSeconds: 60,
              note: 'Superset — full-body tension, squeeze glutes.'),
        ]),
      ],
    ),
    4: Day(
      id: 4,
      theme: DayTheme.recovery,
      name: 'Day 4: Active Recovery',
      tag: 'Joint Health',
      gtgTarget: 4,
      gtgEx: 'Strict Underhand Chin-ups (reduced)',
      blocks: [
        Block(id: 'endurance', icon: '🧘', name: 'Active Recovery', exercises: [
          Exercise(name: 'Shadowboxing / Animal Flow', sets: 1, target: '10-15 min', restSeconds: 0,
              note: 'Light mobility — flush lactic acid, loosen hips. Never sweat.'),
        ]),
      ],
    ),
    5: Day(
      id: 5,
      theme: DayTheme.body,
      name: 'Day 5: Tricep Power',
      tag: 'Functional Flow',
      gtgTarget: 5,
      gtgEx: 'Strict Underhand Chin-ups',
      blocks: [
        Block(id: 'warmup', icon: '🌅', name: 'Morning Prep', exercises: [
          Exercise(name: 'Desk-to-Barbell Warmup', sets: 1, target: '3 min', restSeconds: 0,
              note: 'Wrist circles, shoulder dislocates, band pull-aparts.'),
        ]),
        Block(id: 'power', icon: '⚡', name: 'Morning Power', exercises: [
          Exercise(name: 'Close-Grip Bench Press', sets: 3, target: '3-5 reps', restSeconds: 180,
              note: 'Tricep focused — elbows tucked tight.'),
        ]),
        Block(id: 'hypertrophy', icon: '💪', name: 'Afternoon Hypertrophy', exercises: [
          Exercise(name: 'Gymnastic Ring Dips', sets: 3, target: 'AMRAP', restSeconds: 90,
              note: 'Use parallel bars if rings are unstable.'),
          Exercise(name: 'KB Upright Rows (16kg)', sets: 3, target: '10-12 reps', restSeconds: 90,
              note: 'Controlled descent. Elbows lead.'),
        ]),
        Block(id: 'endurance', icon: '🔥', name: 'Evening Endurance', exercises: [
          Exercise(name: 'KB Clean & Press (16kg)', sets: 2, target: '5 min each', restSeconds: 0,
              note: '5 min Right arm continuous, then 5 min Left.'),
        ]),
      ],
    ),
    6: Day(
      id: 6,
      theme: DayTheme.recovery,
      name: 'Day 6: Active Recovery',
      tag: 'Walk & Mobility',
      gtgTarget: 3,
      gtgEx: 'Strict Underhand Chin-ups (reduced)',
      blocks: [],
    ),
    7: Day(
      id: 7,
      theme: DayTheme.rest,
      name: 'Full Rest',
      tag: 'Recovery & Reset',
      gtgTarget: 0,
      gtgEx: 'No GtG today — full rest',
      blocks: [],
    ),
  };
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/domain/plan/training_plan_test.dart`
Expected: PASS. (`flutter analyze` will still report the two `colors.dart` switches as non-exhaustive — fixed in Task 3.)

- [ ] **Step 6: Commit**

```bash
git add lib/domain/plan/models.dart lib/domain/plan/training_plan.dart test/domain/plan/training_plan_test.dart
git commit -m "feat(plan): 7-day schedule + recovery day theme"
```

---

## Task 3: `recovery` color scheme

**Files:**
- Modify: `lib/theme/colors.dart`
- Test: `test/theme/colors_test.dart` (create)

- [ ] **Step 1: Write the failing test**

Create `test/theme/colors_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/domain/plan/models.dart';
import 'package:protocol/theme/colors.dart';

void main() {
  test('buildTheme covers all DayThemes incl. recovery', () {
    for (final t in DayTheme.values) {
      final theme = buildTheme(t);
      expect(theme.colorScheme, isNotNull, reason: t.name);
    }
  });

  test('recovery theme uses the emerald primary', () {
    final theme = buildTheme(DayTheme.recovery);
    expect(theme.colorScheme.primary, AppColors.recoveryPrimary);
    expect(theme.scaffoldBackgroundColor, AppColors.recoveryBackground);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/theme/colors_test.dart`
Expected: FAIL — `AppColors.recoveryPrimary` undefined; `_schemeFor`/`buildTheme` switches non-exhaustive.

- [ ] **Step 3: Add the recovery palette constants**

In `lib/theme/colors.dart`, inside `class AppColors`, after the `rest*` constants (line 16), add:

```dart
  static const recoveryPrimary = Color(0xFF34D399);
  static const recoverySurface = Color(0xFF0E2A22);
  static const recoveryBackground = Color(0xFF08160F);
```

- [ ] **Step 4: Add the `recovery` case to `_schemeFor`**

In `_schemeFor`, after the `case DayTheme.body:` block and before `case DayTheme.rest:` (around line 49), add:

```dart
    case DayTheme.recovery:
      return ColorScheme.dark(
        primary: AppColors.recoveryPrimary,
        onPrimary: const Color(0xFF052E22),
        surface: AppColors.recoverySurface,
        onSurface: AppColors.onSurfaceHi,
        surfaceContainerHighest: const Color(0xFF143A2E),
        secondary: AppColors.recoveryPrimary,
        onSecondary: const Color(0xFF052E22),
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      );
```

- [ ] **Step 5: Add the `recovery` arm to the `buildTheme` background switch**

Update the `bg` switch (around line 66) to:

```dart
  final bg = switch (theme) {
    DayTheme.iron => AppColors.ironBackground,
    DayTheme.body => AppColors.bodyBackground,
    DayTheme.recovery => AppColors.recoveryBackground,
    DayTheme.rest => AppColors.restBackground,
  };
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/theme/colors_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/theme/colors.dart test/theme/colors_test.dart
git commit -m "feat(theme): add recovery color scheme"
```

---

## Task 4: `derivedDayProvider` auto-wraps over 7 days

**Files:**
- Modify: `lib/app_providers.dart:123-134`
- Test: `test/app_providers_test.dart` (update existing expectations)

- [ ] **Step 1: Update the existing test to the wrapping expectations**

In `test/app_providers_test.dart`, replace the second test (`'returns (diff + 1) when weekStart is N days ago, clamped to 5'`) with:

```dart
    test('counts up over the 7-day cycle and wraps', () async {
      final now = DateTime.now();
      DateTime ago(int days) =>
          DateTime(now.year, now.month, now.day).subtract(Duration(days: days));

      Future<int> dayFor(DateTime weekStart) async {
        final c = ProviderContainer(overrides: [
          weekStartProvider.overrideWith((ref) async* {
            yield dateKey(weekStart);
          }),
        ]);
        addTearDown(c.dispose);
        await c.read(weekStartProvider.future);
        return c.read(derivedDayProvider);
      }

      expect(await dayFor(ago(3)), 4); // day 4 (recovery)
      expect(await dayFor(ago(6)), 7); // day 7 (rest)
      expect(await dayFor(ago(7)), 1); // wraps to day 1
      expect(await dayFor(ago(13)), 7);
    });
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/app_providers_test.dart`
Expected: FAIL — `ago(7)` returns 5 (old clamp), expected 1.

- [ ] **Step 3: Switch `derivedDayProvider` to `dayOfCycle`**

In `lib/app_providers.dart`, replace the doc comment + body (lines 123-134) with:

```dart
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
```

(`parseDateKey` and `dayOfCycle` are already exported from the imported `domain/util/week.dart`.)

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/app_providers_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/app_providers.dart test/app_providers_test.dart
git commit -m "feat(state): derive day via 7-day auto-wrap dayOfCycle"
```

---

## Task 5: Fix reminder rest-day suppression to match the UI day (closes T1)

**Files:**
- Modify: `lib/notifications/reminder_scheduler.dart`
- Test: `test/notifications/reminder_scheduler_test.dart` (create)

**Context:** Reminders use `android_alarm_manager_plus` chain-scheduling. `scheduleNext` arms one `oneShotAt`; the top-level `_alarmCallback` (background isolate) opens its own DB, reads settings, decides whether to post, and re-arms. Today it suppresses via the epoch-based `currentRotationDayId(now) == 5`, which disagrees with the UI's `weekStart`-based day (the T1 bug). The fix: compute the day from the stored `weekStartDate` via `dayOfCycle`, and suppress when that day's plan `gtgTarget == 0` (Day 7). `scheduleNext`'s signature is unchanged, so no call sites change.

- [ ] **Step 1: Write the failing test**

Create `test/notifications/reminder_scheduler_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/domain/plan/training_plan.dart';
import 'package:protocol/domain/util/week.dart';
import 'package:protocol/notifications/reminder_scheduler.dart';

void main() {
  group('ReminderScheduler.rotationDayId', () {
    test('matches dayOfCycle / derivedDay math for a fortnight', () {
      const weekStart = '2026-06-27';
      final start = parseDateKey(weekStart);
      for (var i = 0; i < 14; i++) {
        final day = start.add(Duration(days: i));
        expect(ReminderScheduler.rotationDayId(day, weekStart), dayOfCycle(day, start));
      }
    });

    test('only the full-rest day (7) suppresses; recovery day (4) still fires', () {
      const weekStart = '2026-06-27';
      final start = parseDateKey(weekStart);

      final restDay = start.add(const Duration(days: 6)); // => day 7
      final d7 = ReminderScheduler.rotationDayId(restDay, weekStart);
      expect(d7, 7);
      expect(TrainingPlan.days[d7]!.gtgTarget, 0);

      final recDay = start.add(const Duration(days: 3)); // => day 4
      final d4 = ReminderScheduler.rotationDayId(recDay, weekStart);
      expect(d4, 4);
      expect(TrainingPlan.days[d4]!.gtgTarget, greaterThan(0));
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/notifications/reminder_scheduler_test.dart`
Expected: FAIL — `ReminderScheduler.rotationDayId` is not defined.

- [ ] **Step 3: Add the day imports and replace `currentRotationDayId`**

In `lib/notifications/reminder_scheduler.dart`, add these imports (with the other `../` imports near the top):

```dart
import '../domain/plan/training_plan.dart';
import '../domain/util/week.dart';
```

Replace the `currentRotationDayId` method (lines 70-76) with:

```dart
  /// Day of the 7-day cycle for [now], anchored to the stored [weekStart] key
  /// ("YYYY-MM-DD"). Same math as the UI's derivedDayProvider, so reminders and
  /// the displayed day always agree on which day is the rest day.
  static int rotationDayId(DateTime now, String weekStart) =>
      dayOfCycle(now, parseDateKey(weekStart));
```

- [ ] **Step 4: Use the weekStart-based day in `_alarmCallback`**

In `_alarmCallback`, replace the line:

```dart
    final isRestDay = ReminderScheduler.currentRotationDayId(now) == 5;
```
with:

```dart
    final weekStart = effectiveWeekStart(await settings.get(SettingsKeys.weekStartDate));
    final dayId = ReminderScheduler.rotationDayId(now, weekStart);
    final isRestDay = (TrainingPlan.days[dayId]?.gtgTarget ?? 0) == 0;
```

(`effectiveWeekStart` comes from the newly-imported `domain/util/week.dart`.)

- [ ] **Step 5: Run the test to verify it passes**

Run: `flutter test test/notifications/reminder_scheduler_test.dart`
Expected: PASS.

- [ ] **Step 6: Verify the project compiles**

Run: `flutter analyze`
Expected: no errors about `currentRotationDayId` (the only caller was `_alarmCallback`, now updated).

- [ ] **Step 7: Commit**

```bash
git add lib/notifications/reminder_scheduler.dart test/notifications/reminder_scheduler_test.dart
git commit -m "fix(notifications): suppress GTG only on the weekStart-derived rest day"
```

---

## Task 6: UI — 7 day tabs, recovery/empty-day rendering, button rename

**Files:**
- Modify: `lib/widgets/day_tabs.dart`
- Modify: `lib/features/templates/template_editor_screen.dart:85,90`
- Modify: `lib/features/train/train_screen.dart`

- [ ] **Step 1: Update `day_tabs.dart` to 7 days**

In `lib/widgets/day_tabs.dart`, change `itemCount: 5,` (line 18) to `itemCount: 7,`, and change the label line (23) from `final label = dayId == 5 ? 'Rest' : 'Day $dayId';` to:

```dart
          final label = dayId == 7 ? 'Rest' : 'Day $dayId';
```

- [ ] **Step 2: Update the template editor's day strip to 7 days**

In `lib/features/templates/template_editor_screen.dart`, change `itemCount: 5,` (line 85) to `itemCount: 7,` and the label (line 90) from `dayId == 5 ? 'Rest'` to `dayId == 7 ? 'Rest'`.

- [ ] **Step 3: Handle recovery/empty days on the Train screen**

In `lib/features/train/train_screen.dart`, after the `done` line (line 42), add:

```dart
    final populatedBlocks = [
      for (final b in kBlockIds)
        if ((template?.exercisesFor(meta.id, b) ?? const []).isNotEmpty) b,
    ];
```

Then replace the rest-day / block-list section (the `if (meta.isRestDay) SliverToBoxAdapter(...) else SliverPadding(...)`, currently lines 97-128) with:

```dart
            if (meta.isRestDay)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Full rest day — recovery & reset.\nNo training today.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              )
            else if (populatedBlocks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Active recovery — walk, stretch, light mobility.\n'
                    'Keep your GtG sets going, but nothing to log today.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: populatedBlocks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final blockId = populatedBlocks[i];
                    final exercises = template?.exercisesFor(meta.id, blockId) ?? const [];
                    return BlockCard(
                      blockId: blockId,
                      exercises: exercises,
                      done: done.contains(blockId),
                      onTap: () => context.push('/workout/${meta.id}/$blockId'),
                    );
                  },
                ),
              ),
```

- [ ] **Step 4: Rename the "Start new week" button to reflect auto-wrap**

In `lib/features/train/train_screen.dart`, change the `OutlinedButton.icon` label (line 135) from `const Text('Start new week')` to:

```dart
                  label: const Text('Restart cycle (Day 1 today)'),
```

And in `_NewWeekDialog.build`, change the title `const Text('Start a new week?')` to `const Text('Restart the cycle?')` and the body text `'Block checkmarks reset. Workout history is kept.'` to `'Resets to Day 1 today. Block checkmarks reset; workout history is kept.'`.

(The reminder chain self-heals: the next `_alarmCallback` reads the new `weekStartDate` from the DB, so no explicit reschedule is needed here.)

- [ ] **Step 5: Verify it compiles**

Run: `flutter analyze`
Expected: clean (no new errors).

- [ ] **Step 6: Commit**

```bash
git add lib/widgets/day_tabs.dart lib/features/templates/template_editor_screen.dart lib/features/train/train_screen.dart
git commit -m "feat(ui): 7 day tabs + recovery-day rendering + restart-cycle label"
```

---

## Task 7: Expand template grids 5 → 7 days

**Files:**
- Modify: `lib/data/repositories/template_repository.dart:85`
- Modify: `lib/features/settings/import_export_controller.dart:279`

- [ ] **Step 1: Update `createEmpty`**

In `lib/data/repositories/template_repository.dart`, change line 85 from `for (var dayId = 1; dayId <= 5; dayId++) {` to:

```dart
      for (var dayId = 1; dayId <= 7; dayId++) {
```

- [ ] **Step 2: Update `importTemplate` grid pre-creation**

In `lib/features/settings/import_export_controller.dart`, change line 279 from `for (var dayId = 1; dayId <= 5; dayId++) {` to:

```dart
      for (var dayId = 1; dayId <= 7; dayId++) {
```

(`TemplateSeeder.createTemplateFromPlan`, `resetTemplateToDefault`, and `TemplateRepository.duplicate` already iterate `TrainingPlan.days`/the source rows, so they pick up 7 days automatically.)

- [ ] **Step 3: Verify it compiles**

Run: `flutter analyze`
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add lib/data/repositories/template_repository.dart lib/features/settings/import_export_controller.dart
git commit -m "feat(templates): expand empty/import template grid to 7 days"
```

---

## Task 8: One-time migration (Option C) — wipe & reseed templates, keep history

**Files:**
- Modify: `lib/data/repositories/settings_repository.dart` (add `planVersion` key)
- Modify: `lib/data/repositories/template_seeder.dart` (replace `seedIfEmpty` with `seedOrMigrate`)
- Modify: `lib/app_providers.dart:43-45` (`seedBootProvider` calls `seedOrMigrate`)
- Test: `test/data/repositories/template_seeder_test.dart` (create)

- [ ] **Step 1: Add the `planVersion` settings key**

In `lib/data/repositories/settings_repository.dart`, add to `class SettingsKeys` (after `restTimerAlertEnabled`):

```dart
  static const planVersion = 'plan_version';
```

- [ ] **Step 2: Write the failing migration test**

Create `test/data/repositories/template_seeder_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/data/db/app_database.dart';
import 'package:protocol/data/repositories/settings_repository.dart';
import 'package:protocol/data/repositories/template_seeder.dart';
import 'package:protocol/domain/util/week.dart';

void main() {
  late AppDatabase db;
  late TemplateSeeder seeder;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    seeder = TemplateSeeder(db);
  });

  tearDown(() async => db.close());

  Future<int> templateCount() async => (await db.select(db.templates).get()).length;
  Future<String?> setting(String key) async =>
      (await (db.select(db.appSettings)..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  test('fresh install seeds a 7-day Default and stamps planVersion', () async {
    await seeder.seedOrMigrate();
    expect(await templateCount(), 1);
    final blocks = await db.select(db.templateBlocks).get();
    expect(blocks.length, 7 * 4); // 7 days x 4 block slots
    expect((blocks.map((b) => b.dayId).toSet().toList()..sort()), [1, 2, 3, 4, 5, 6, 7]);
    expect(await setting(SettingsKeys.activeTemplateId), isNotNull);
    expect(await setting(SettingsKeys.planVersion), TemplateSeeder.currentPlanVersion.toString());
    expect(await setting(SettingsKeys.weekStartDate), todayKey());
  });

  test('upgrade wipes old templates, reseeds, and KEEPS workout history', () async {
    await db.into(db.templates).insert(
        TemplatesCompanion.insert(name: 'Old', createdAt: 1, updatedAt: 1));
    await db.into(db.workoutLogs).insert(WorkoutLogsCompanion.insert(
        date: 1000, dayId: 4, blockId: 'power', blockName: 'X', blockIcon: '', theme: 'body'));

    await seeder.seedOrMigrate();

    expect(await templateCount(), 1); // old one wiped, single Default reseeded
    expect((await db.select(db.templates).get()).single.name, 'Default');
    expect((await db.select(db.workoutLogs).get()).length, 1); // history preserved
  });

  test('second run is a no-op once migrated', () async {
    await seeder.seedOrMigrate();
    final firstActive = await setting(SettingsKeys.activeTemplateId);
    await seeder.seedOrMigrate();
    expect(await templateCount(), 1);
    expect(await setting(SettingsKeys.activeTemplateId), firstActive);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/data/repositories/template_seeder_test.dart`
Expected: FAIL — `seedOrMigrate` / `currentPlanVersion` undefined.

- [ ] **Step 4: Replace `seedIfEmpty` with `seedOrMigrate`**

In `lib/data/repositories/template_seeder.dart`, add the import (after `import '../../domain/plan/training_plan.dart';`):

```dart
import '../../domain/util/week.dart';
```

Replace the `seedIfEmpty` method (lines 14-26) with:

```dart
  /// Current plan-data version. Bump when the canonical 7-day plan or day
  /// numbering changes in a way that must overwrite users' seeded templates.
  static const currentPlanVersion = 1;

  Future<int?> _settingInt(String key) async {
    final row = await (db.select(db.appSettings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return int.tryParse(row?.value ?? '');
  }

  Future<void> _setSetting(String key, String value) async {
    await db.into(db.appSettings).insertOnConflictUpdate(
          AppSettingsCompanion.insert(key: key, value: value),
        );
  }

  /// Run once per plan version. On a fresh install this seeds the 7-day Default.
  /// On upgrade from an older plan version it WIPES all templates and reseeds
  /// Default (Option C), then re-anchors the cycle to today. Workout history and
  /// GTG logs are never touched. Idempotent: a no-op once stamped current.
  Future<void> seedOrMigrate() async {
    final stored = await _settingInt('plan_version') ?? 0;
    if (stored >= currentPlanVersion) return;

    // Wipe templates (and their blocks/exercises) explicitly — does not depend
    // on FK cascade being enabled.
    await db.delete(db.templateExercises).go();
    await db.delete(db.templateBlocks).go();
    await db.delete(db.templates).go();

    final templateId = await createTemplateFromPlan('Default');
    await _setSetting('active_template_id', templateId.toString());
    await _setSetting('weekStartDate', todayKey());
    await _setSetting('plan_version', currentPlanVersion.toString());
  }
```

- [ ] **Step 5: Point `seedBootProvider` at the new method**

In `lib/app_providers.dart`, change `seedBootProvider` (line 44) from `await ref.watch(templateSeederProvider).seedIfEmpty();` to:

```dart
  await ref.watch(templateSeederProvider).seedOrMigrate();
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/data/repositories/template_seeder_test.dart`
Expected: PASS (all three tests).

- [ ] **Step 7: Commit**

```bash
git add lib/data/repositories/settings_repository.dart lib/data/repositories/template_seeder.dart lib/app_providers.dart test/data/repositories/template_seeder_test.dart
git commit -m "feat(migration): planVersion-gated wipe+reseed to 7-day plan, keep history"
```

---

## Task 9: Full verification

**Files:** none (verification only)

- [ ] **Step 1: Static analysis**

Run: `flutter analyze`
Expected: No errors. (Pre-existing warnings unrelated to this change are acceptable.)

- [ ] **Step 2: Full test suite**

Run: `flutter test`
Expected: All tests pass, including the new `week_test`, `training_plan_test`, `colors_test`, `app_providers_test`, `reminder_scheduler_test`, and `template_seeder_test`.

- [ ] **Step 3: Manual smoke test on a device/emulator**

Run: `flutter run`
Verify by observation:
1. The Train screen shows **7 day tabs** (Day 1–6 + Rest); tapping each recolors the screen; Days 4 & 6 use the **emerald recovery** theme.
2. Day 4 shows the single "Active Recovery" block + the GtG counter (target 4).
3. Day 6 shows the "Active recovery — walk, stretch…" message + the GtG counter (target 3).
4. Day 7 (Rest) shows the full-rest message and **no** GtG counter.
5. A returning user's **workout history and Stats are intact**; their template is the new 7-day Default.
6. Settings → enable reminders → "Test reminder now" still posts; toggling hours does not error.
7. "Restart cycle (Day 1 today)" sets the day to 1.

- [ ] **Step 4: Update docs, then commit**

- Update `README.md` (it says "5-day rotating protocol — 4 active days + 1 full rest day") to describe the **7-day** schedule (4 training + 2 active recovery + 1 full rest).
- Tick `T1` and Appendix B in `docs/IMPROVEMENT-PLAN.md` as delivered.
- Append a `.wolf/memory.md` entry; add a `.wolf/cerebrum.md` learning if anything surprised you; log any bug hit to `.wolf/buglog.json`.

```bash
git add README.md docs/IMPROVEMENT-PLAN.md
git commit -m "docs: describe the 7-day schedule"
```

---

## Self-review (completed by author, post-discard re-plan)

- **Baseline:** re-based onto the committed chain-scheduling design (the in-progress `zonedSchedule` rewrite + muted-text tokens were stashed). Confirmed each touched file against `HEAD`: `colors.dart` has no `textMid` (Task 6 uses `onSurface.withValues(alpha:)`); `reminder_scheduler.dart` is the `oneShotAt` + `_alarmCallback` design (Task 5 fixes the callback; `scheduleNext` signature unchanged, so no call-site task).
- **Spec coverage:** §1 plan data → Task 2; §2 auto-wrap → Tasks 1+4; §3 recovery theme → Tasks 2+3; §4 GtG suppression + T1 unification → Tasks 1+5; §5 templates 7×4 → Tasks 7+8 (seeder auto-scales); §6 Option-C migration → Task 8; §7 out-of-scope respected; §9 tests → Tasks 1,2,3,4,5,8.
- **Placeholder scan:** none — every code step shows complete code; every command shows expected output.
- **Type/name consistency:** `dayOfCycle(DateTime, DateTime)` used identically in Tasks 1, 4, 5. `ReminderScheduler.rotationDayId(DateTime, String)` defined in Task 5 and used by its own test + `_alarmCallback`. `seedOrMigrate`/`currentPlanVersion` defined in Task 8 and referenced in the same task's test and `seedBootProvider`. `populatedBlocks` defined and consumed within Task 6.
- **Note:** Tasks 2 and 3 must land back-to-back (adding `DayTheme.recovery` breaks `colors.dart`'s exhaustive switches until Task 3); their individual unit tests still pass independently.
