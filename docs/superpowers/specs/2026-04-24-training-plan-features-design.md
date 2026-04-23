# Training plan — three feature additions

Adds three independent features to the Protocol Flutter app:

1. **Date-driven active day** — the active day auto-advances at local midnight.
2. **Last session's top set** on the workout logging screen.
3. **Rest timer alert** — sound + background notification when rest ends, with a user-facing toggle.

The features share no code paths and can be implemented, tested, and reviewed independently. Recommended implementation order is Feature 2 → Feature 3 → Feature 1 (smallest to largest surface area).

---

## Feature 1 — Date-driven active day

### Goal

The "active day" shown on `TrainScreen` should reflect today's calendar date relative to the user's `weekStartDate`, so crossing local midnight advances the day without any manual action. Manual day-tab taps continue to work as a within-session override.

### Current state

- `currentDayProvider` is a `StateProvider<int>` seeded at `1`.
- `trainAutoAdvanceProvider` advances it to the first day with incomplete blocks (completion-based, not time-based).
- `_startNewWeek` in `train_screen.dart` sets `weekStartDate = todayKey()` and `currentDayProvider = 1`.
- `effectiveWeekStart` (in `lib/domain/util/week.dart`) defaults to "today minus 6 days" when no value is stored, which under date-driven logic would place a fresh install on day 5 (rest).

### Design

**New `derivedDayProvider`** — `Provider<int>`:
- Reads `weekStartProvider`.
- Computes `(today - weekStart).inDays + 1`, clamped to `[1, 5]`.
- After day 5 the value stays at 5; the existing rest-day UI handles "week complete" and the user taps **Start new week** to reset.

**New `dateTickerProvider`** — `StreamProvider<DateTime>`:
- Emits the current `DateTime` on subscription, then schedules a `Timer` for the next local midnight (`DateTime(y, m, d+1)`), emits again, and reschedules.
- Implemented with `ref.onDispose` to cancel the timer.
- Invalidates `derivedDayProvider` on each emission.

**`currentDayProvider`** — stays as `StateProvider<int>`, but:
- Its initial value is sourced from `derivedDayProvider` (not hardcoded to `1`). Because a `StateProvider` factory only runs once, `TrainScreen` also uses `ref.listen(derivedDayProvider, ...)` to catch the case where `weekStartProvider` was still loading at first read — when it resolves, the derived value becomes correct and we re-sync `currentDayProvider.state` to it.
- `TrainScreen` watches `dateTickerProvider` and on each event sets `currentDayProvider.state = ref.read(derivedDayProvider)`.
- `TrainScreen` also listens to `appLifecycleProvider` (see Cross-cutting section below) and re-syncs to derived when the state transitions to `AppLifecycleState.resumed`.
- Manual day-tab taps still write to `currentDayProvider.state` directly and remain in effect until the next midnight tick or resume.

**`trainAutoAdvanceProvider`** — removed. Date now determines the day.

**`effectiveWeekStart`** — default fallback changes from "today minus 6 days" to `todayKey()`. A fresh install with no `weekStartDate` thus starts on day 1.

**`_startNewWeek`** — unchanged logic (sets `weekStartDate = todayKey()`, then `currentDayProvider.state = 1`) since that is still the correct derived value for "today".

### Edge cases

- **App backgrounded across midnight** → `AppLifecycleState.resumed` handler re-syncs.
- **App killed across midnight** → cold start reads date fresh, `derivedDayProvider` seeds `currentDayProvider` correctly.
- **User reviewing day 1 while actually on day 3** → manual tap overrides until next midnight or resume, then snaps back to derived value.
- **More than 5 days since week start** → `derivedDayProvider` clamps to 5 (rest day); user taps **Start new week** to reset.
- **Device timezone change** → not explicitly handled; next resume/midnight-tick recomputes against the new local time, which is the pragmatic behavior for a personal tracker.

### Tests

- Unit test `derivedDayProvider`: given a `weekStartDate`, compute expected day for today / today+1 / today+5 / today+10.
- Unit test `dateTickerProvider` scheduling: the next-fire time equals the next local midnight.
- Widget test: mount `TrainScreen`, advance the ticker, assert `currentDayProvider` is the derived value.
- Widget test: manually tap day 1, advance the ticker, assert it re-syncs to derived.

---

## Feature 2 — Last session's top set on the workout screen

### Goal

Under each exercise on `WorkoutScreen`, display a line like `Last: 75 kg × 5` showing the top set (highest weight, tie-break highest reps) from the user's most recent completed session for that exercise. If no prior session exists, the line is omitted.

### Current state

- `WorkoutScreen._exerciseBlock` renders the exercise name, a target line (`3 × 3-5 reps • Rest 180s`), optional note, then the set rows.
- `WorkoutRepository.getSetsForExerciseName` already joins `exercise_sets` with `workout_logs` and returns all historical completed sets for a given name, used by the PR check.

### Design

**New `WorkoutRepository.getLastSessionTopSet(String exerciseName)`** — `Future<ExerciseSet?>`:
- Step 1: find the most recent `workoutLogs` id whose joined `exerciseSets` contains at least one row with `exerciseName = ?` AND `completed = true`. (Drift query with `orderBy date DESC, limit 1`.)
- Step 2: fetch all completed `exerciseSets` rows for that `logId` with the matching name (a handful of rows).
- Step 3: pick the top set in Dart. Sort key: `weightKg ?? 0` descending, tie-break by `reps ?? 0` descending. This avoids relying on `NULLS LAST` SQL ordering (SQLite's default `DESC` sorts NULLs first, which would incorrectly surface bodyweight sets over weighted ones).
- Returns `null` if no matching log exists.

**New `lastTopSetProvider`** — `FutureProvider.family<ExerciseSet?, String>`:
- Keyed on exercise name.
- Calls `workoutRepository.getLastSessionTopSet(name)`.
- Riverpod caches results, so repeated renders of the same screen don't re-query.

**UI in `WorkoutScreen._exerciseBlock`**:
- Replace the single target-line `Padding` with a `Consumer` that watches `lastTopSetProvider(ex.name)`.
- On `data` with a non-null `ExerciseSet`: append a line below the target line:
  - `Last: ${weightLabel} × ${reps}` where `weightLabel` is `"${weightKg} kg"` if `weightKg != null && weightKg > 0`, else `"BW"` (covers both null and user-entered `0`).
  - If `reps` is null (shouldn't happen for a completed set, but defensive) → omit the line.
  - Style: same size / slightly muted color as the target line, or a hair smaller.
- On loading / error / null: render nothing (no flash, no placeholder).

### Edge cases

- **No prior history for this exercise** → line omitted.
- **Bodyweight exercise (null or `0` weight)** → shows `Last: BW × 5`.
- **Exercise renamed in template** → matches by `exerciseName`, so a rename produces no match until the new name is logged (consistent with existing PR-check behavior).
- **Today's in-progress block** → not yet saved, so the query's "most recent log" is genuinely the previous session.
- **All sets in the most recent log are `completed = false`** → the `completed = 1` filter excludes them; we fall through to the next-most-recent log via the subquery condition. *(Note: the subquery picks the most recent log that has a completed set for this exercise, so this is handled.)*

### Tests

- Repo unit test: seed two logs for same exercise, assert top set comes from the most recent.
- Repo unit test: exercise with no history returns null.
- Repo unit test: bodyweight (null `weightKg`) set is returned correctly.
- Widget test: mount `WorkoutScreen` with seeded history, assert the `Last:` line renders with expected text.

---

## Feature 3 — Rest timer alert: sound + background notification + toggle

### Goal

When the rest timer reaches 0:
- In **foreground**: existing behavior (haptic + the in-app rest bar reverts to idle).
- In **background**: post a high-importance notification with the system default sound + vibration, provided the user has not disabled the "Rest timer alert" toggle.

The toggle is on by default and lives in the Settings screen alongside GTG reminders.

### Current state

- `RestTimerController._timer` fires `HapticFeedback.mediumImpact()` on expiry — no sound, no notification.
- `NotificationHelper` exposes one channel (`gtg_reminders`) and one `postGtgReminder()` method.
- `SettingsKeys` has `remindersEnabled`, `startHour`, `endHour` — no rest-alert key.
- There is no lifecycle observer; the app doesn't know whether it's foregrounded.

### Design

**`NotificationHelper` additions**:
- Constants: `_restChannelId = 'rest_timer_alerts'`, `_restChannelName = 'Rest timer alerts'`, `_restChannelDesc = 'Notifies when your rest timer is up.'`, `_restNotificationId = 1002`.
- Create the channel in `initialize()` with `Importance.high`, `playSound: true`, `enableVibration: true` (default sound).
- New method `postRestTimerAlert()`:
  ```dart
  const androidDetails = AndroidNotificationDetails(
    _restChannelId, _restChannelName,
    channelDescription: _restChannelDesc,
    importance: Importance.high,
    priority: Priority.high,
    autoCancel: true,
    playSound: true,
    enableVibration: true,
  );
  ```
  Posts title `"Rest over"`, body `"Time for your next set."`.

**`SettingsKeys` addition**:
- `restTimerAlertEnabled` — stored as bool, default **true**.

**Settings screen**:
- Add a new `Card` with a `SwitchListTile` titled `"Rest timer alert"`, subtitle `"Sound + notification when rest ends in the background."`.
- `value` reads `settings.watchBool(SettingsKeys.restTimerAlertEnabled, defaultValue: true)`.
- `onChanged(v)`: if `v == true`, request notification permission via the existing `NotificationHelper.requestPermissions()` (no exact-alarm ask needed — that's specific to GTG scheduling). If granted, persist the flag. If denied, revert UI.

**`appLifecycleProvider`** (new, `StateProvider<AppLifecycleState>`) — exposes the current lifecycle state:
- A `WidgetsBindingObserver` registered once in `ProtocolApp` (`app.dart`) writes every state change into this provider.
- Initial value: `AppLifecycleState.resumed` (the app is running when the provider is first read).

**`RestTimerController` refactor**:
- The controller currently extends `StateNotifier<RestTimerState>` and constructs itself with no args.
- Change: the provider factory injects an `onExpired` callback so the controller stays pure:
  ```dart
  final restTimerProvider = StateNotifierProvider<RestTimerController, RestTimerState>((ref) {
    return RestTimerController(onExpired: () async {
      final lifecycle = ref.read(appLifecycleProvider);
      final isBackground = lifecycle != AppLifecycleState.resumed;
      if (!isBackground) return;
      final enabled = await ref.read(settingsRepositoryProvider)
        .getBool(SettingsKeys.restTimerAlertEnabled, defaultValue: true);
      if (!enabled) return;
      await NotificationHelper.postRestTimerAlert();
    });
  });
  ```
- Inside `start`, when the periodic timer decrements to 0, after the existing haptic call, invoke `onExpired?.call()`.

### Edge cases

- **Permission denied** → toggle stays off (same pattern as the GTG switch).
- **Skip pressed** → existing `skip()` does not hit the expiry branch → no alert.
- **Multiple rest timers in quick succession** → each uses notification id `1002`, so a new one replaces the stale tray entry.
- **Phone on DND / silent** → channel uses default system sound; DND/volume is honored by the OS — this matches the product decision (Q3a: system notification sound).
- **App foregrounded just as timer expires** → lifecycle read synchronously at expiry; if it's `resumed`, we skip the notification. No race to worry about because the check is in-process.

### Dependencies

No new pub packages. Existing `flutter_local_notifications` and `permission_handler` cover this.

### Tests

- Unit test `NotificationHelper.postRestTimerAlert` posts the expected id/title/channel (can mock the plugin).
- Controller unit test: on expiry, `onExpired` is invoked exactly once.
- Controller unit test: `skip()` does not invoke `onExpired`.
- Widget test: toggle in Settings flips the stored bool.
- Widget test (optional): mock lifecycle = paused + toggle on → expiring controller triggers `postRestTimerAlert`.

---

## Cross-cutting: `appLifecycleProvider`

Used by both Feature 1 (resume → re-sync derived day) and Feature 3 (expiry → post notification only when backgrounded). Implemented once and shared.

- Location: `lib/app_providers.dart` (alongside other top-level providers).
- Type: `StateProvider<AppLifecycleState>`, initial value `AppLifecycleState.resumed`.
- Wired up by a `WidgetsBindingObserver` registered in `ProtocolApp`'s `initState` (converting `ProtocolApp` from `StatelessWidget` to `StatefulWidget`) and deregistered in `dispose`. The observer writes every `didChangeAppLifecycleState` event into the provider.
- Whichever feature is implemented first introduces this provider; the second feature reuses it. If features are built in the recommended order (2 → 3 → 1), Feature 3 introduces it and Feature 1 consumes it.

## Sequencing

Recommended implementation order:

1. **Feature 2** — smallest surface; new repo method + provider + small UI change in `WorkoutScreen`.
2. **Feature 3** — touches `NotificationHelper`, `SettingsScreen`, `RestTimerController`, and introduces `appLifecycleProvider`.
3. **Feature 1** — replaces completion-based auto-advance with date-driven, reuses `appLifecycleProvider` from Feature 3.

Each feature is shippable independently with its own tests.
