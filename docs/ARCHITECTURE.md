# Architecture: Protocol — Android App

## Stack

| Layer | Technology |
|---|---|
| Language | Dart 3.11 |
| UI | Flutter 3.41 (Material 3) |
| State / DI | Riverpod 2 (providers + repositories — no separate VM layer) |
| Database | Drift 2 / SQLite, on-device only |
| Navigation | go_router 14 — `ShellRoute` (5-tab bottom nav) |
| Charts | fl_chart |
| Notifications | `flutter_local_notifications` + `android_alarm_manager_plus` |
| Build | Flutter Gradle Plugin (Gradle DSL); compileSdk/targetSdk via `flutter.compileSdkVersion` (36 on Flutter 3.41), minSdk = 24 |

No server, no network. All data stays on the device.

---

## Project Layout

```
lib/
  main.dart                # bootstrap: AlarmManager init + notifications + ProviderScope
  app.dart                 # MaterialApp.router
  router.dart              # GoRouter + ShellRoute (5-tab bottom nav)
  app_providers.dart       # top-level Riverpod providers

  data/
    db/                    # Drift tables, DAOs, codegen (app_database.dart + *.g.dart)
    models/                # plain Dart DTOs for import/export JSON
    repositories/          # Drift-backed repositories (template, workout, gtg, settings)

  domain/
    plan/                  # TrainingPlan constant, DayTheme enum, Day/Block/Exercise models
    util/                  # week math (dayOfCycle, parseDateKey), e1RM formula

  features/
    train/                 # Train screen + day-advance controller
    workout/               # Active-block screen + rest timer
    history/               # Session list
    stats/                 # e1RM chart + recent sessions
    settings/              # Reminder config + import/export (JSON)
    templates/             # Template list + editor + picker sheet

  notifications/           # _alarmCallback entry-point + ReminderScheduler
  theme/                   # ColorSchemes + theme-per-day provider
  widgets/                 # Shared widgets (BottomNav, SetRow, modals)

assets/
  icons/                   # Launcher icon source PNGs
  seed/history.json        # First-run seed data

docs/
  ARCHITECTURE.md          # This file
  ui-mockup.html           # Visual reference
```

---

## Data Model (Drift / SQLite, schemaVersion = 1)

| Table | Key Columns | Notes |
|---|---|---|
| `Templates` | `id`, `name`, `createdAt`, `updatedAt` | Named workout templates |
| `TemplateBlocks` | `id`, `templateId` → Templates, `dayId`, `blockId` | Unique on (templateId, dayId, blockId) |
| `TemplateExercises` | `id`, `blockRefId` → TemplateBlocks, `position`, `exerciseId`, `name`, `sets`, `target`, `restSeconds`, `note` | Ordered exercise list within a block |
| `WorkoutLogs` | `id`, `date` (epoch ms), `templateId` nullable, `dayId`, `blockId`, `blockName`, `blockIcon`, `theme` | Freezes block name + icon + theme at save time — template edits never rewrite history |
| `ExerciseSets` | `id`, `logId` → WorkoutLogs, `exerciseId`, `exerciseName`, `setNumber`, `weightKg` nullable, `reps` nullable, `completed` | Freezes exercise name at save time |
| `GtgLogs` | PK (`date` "YYYY-MM-DD", `dayId`), `count` | Daily GTG tally; resets at midnight |
| `AppSettings` | PK `key`, `value` | Key/value store: activeTemplateId, weekStartDate, remindersEnabled, startHour, endHour |

Foreign keys use cascade-delete (TemplateBlocks → Templates, TemplateExercises → TemplateBlocks, ExerciseSets → WorkoutLogs); WorkoutLogs.templateId is set-null on template delete.

---

## Training Plan (7-day cycle)

Defined statically in `lib/domain/plan/training_plan.dart`. Day metadata (name, theme, tag, gtgTarget, gtgEx) is NOT editable per template — only the per-block exercise list is.

| Day | Theme | Summary |
|---|---|---|
| 1 | `iron` | Chest Power |
| 2 | `body` | Back Power |
| 3 | `iron` | Leg Maintenance / Shoulder Density |
| 4 | `recovery` | Active Recovery (reduced GTG target) |
| 5 | `body` | Tricep Power |
| 6 | `recovery` | Active Recovery — walk & mobility (reduced GTG target) |
| 7 | `rest` | Full Rest — no GTG (gtgTarget == 0) |

`DayTheme` enum: `iron`, `body`, `recovery`, `rest`. The UI switches Material 3 color schemes based on the current day's theme.

---

## State Flow (Riverpod)

```
AppDatabase (Provider)
       ↓
Repository Providers (template, workout, gtg, settings — each a Provider wrapping a Drift-backed class)
       ↓
StreamProviders / FutureProviders (activeTemplateProvider, todayGtgProvider, weekStartProvider, …)
       ↓
StateProviders (currentDayProvider — seeded once from derivedDayProvider via ref.read)
       ↓
ConsumerWidget screens (watch providers, rebuild on change)
```

Key providers in `app_providers.dart`:

- **`dateTickerProvider`** — emits `DateTime.now()` on startup then at each local midnight; drives day advancement without polling.
- **`derivedDayProvider`** — computes `dayOfCycle(now, weekStart)` from `dateTickerProvider` + `weekStartProvider`. Uses the same `dayOfCycle` helper as the alarm callback so the UI and reminders always agree on which day it is.
- **`currentDayProvider`** — `StateProvider<int>` seeded once from `derivedDayProvider` via `ref.read` (not `ref.watch`) so lifecycle events (minimize / resume) do not reset the displayed day. A listener in `TrainScreen` advances it when `derivedDay` crosses midnight.
- **`activeTemplateProvider`** — streams `ResolvedTemplate?` from the active template ID stored in `AppSettings`.
- **`todayGtgProvider`** — streams today's GTG counts per dayId; re-subscribes at each `dateTickerProvider` tick.
- **`seedBootProvider`** — `FutureProvider` that runs `TemplateSeeder.seedOrMigrate()` once on first launch.

---

## GTG Reminder Chain

`ReminderScheduler.scheduleNext` arms a single `AndroidAlarmManager.oneShotAt` alarm (inexact, `wakeup: true`, `rescheduleOnReboot: true`, `allowWhileIdle: true`). There is no periodic alarm and no separate boot receiver — `rescheduleOnReboot` re-arms the alarm automatically after reboot.

When the alarm fires it executes `_alarmCallback` — a top-level function marked `@pragma('vm:entry-point')` that runs in a background isolate:

1. Opens its own short-lived `AppDatabase` connection (isolates cannot share the main app's DB).
2. Reads `remindersEnabled`, `startHour`, `endHour`, and `weekStartDate` from `AppSettings`.
3. Checks whether now is within the active window (`startHour ≤ now.hour < endHour`).
4. Computes `dayId = rotationDayId(now, weekStart)` (same `dayOfCycle` math as the UI).
5. Skips the notification if `TrainingPlan.days[dayId].gtgTarget == 0` (i.e., day 7 full rest).
6. Posts the GTG notification via `NotificationHelper` if the window + rest-day checks pass.
7. Calls `ReminderScheduler.scheduleNext` to arm the next alarm (self-healing chain).
8. Closes the DB.

This chain approach is more reliable than `PeriodicWorkRequest` (minimum 15-minute interval, drifts) and more battery-friendly than a persistent background service.

---

## Navigation

`lib/router.dart` defines a single `GoRouter` with a top-level `ShellRoute` that renders the 5-tab `BottomNav`. The shell contains five `NoTransitionPage` destinations:

```
/           → TrainScreen   (default)
/stats      → StatsScreen
/history    → HistoryScreen
/templates  → TemplatesScreen
/settings   → SettingsScreen
```

Two modal-push routes outside the shell:

```
/workout/:dayId/:blockId   → WorkoutScreen
/templates/:templateId     → TemplateEditorScreen
```

---

## Theming

Two Material 3 dark color schemes (iron: gold primary; body: cyan primary) selected by `DayTheme`. `recovery` days use the `iron` scheme with muted accents; `rest` days use a neutral scheme. All muted / secondary text is routed through an AA-safe `textMid` token to meet WCAG contrast requirements.
