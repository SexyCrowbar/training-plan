# Protocol

Native Android app for the 5-day distributed micro-dose training protocol. Flutter-based, fully offline, with optional hourly Grease-the-Groove reminders.

## Stack

- **Framework**: Flutter 3.24+ / Dart 3.5+ (`minSdk=24`, `targetSdk=34`, `compileSdk=35`)
- **State**: Riverpod 2
- **Routing**: go_router with `ShellRoute` bottom nav
- **DB**: Drift (SQLite), on-device
- **Charts**: fl_chart
- **Notifications**: `flutter_local_notifications` + `android_alarm_manager_plus` (chain-scheduled exact alarms)

## Install

Requires [Flutter](https://docs.flutter.dev/get-started/install) 3.24+ with the Android toolchain configured (Android Studio or standalone SDK with platform-tools in `PATH`).

```bash
git clone https://github.com/SexyCrowbar/training-plan.git
cd training-plan
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

The `build_runner` step generates Drift's `.g.dart` files and must be re-run after schema or freezed-model changes.

## Run

### Debug on a connected device

```bash
flutter devices            # confirm the target device is listed
flutter run
```

Hot-reload works while the dart VM is attached.

### Release APK

```bash
flutter build apk --release --split-per-abi
```

The ABI-split outputs land in `build/app/outputs/flutter-apk/`. For a typical modern phone, install `app-arm64-v8a-release.apk`:

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

### Launcher icon

`pubspec.yaml` has a `flutter_launcher_icons` section. After editing `assets/icons/icon.png` or `assets/icons/icon_foreground.png` (regenerate via `python tool/generate_icon.py`), run:

```bash
dart run flutter_launcher_icons
```

## Features

- **5-day rotating protocol** — 4 active days + 1 full rest day, theme-per-day (iron/body/rest)
- **Editable templates** — create / duplicate / rename / delete named templates; each week points to an active template. "Default" is seeded from the stock plan and is resettable.
- **Grease-the-Groove counter** — per-day sub-maximal set tally that resets at midnight
- **GTG hourly reminders** — exact-alarm notifications within a configurable active window, automatically suppressed on rest days and re-armed after reboot
- **Rest timer** — auto-starts on set-complete; per-exercise duration
- **e1RM tracking** — estimated 1-rep max per lift, Epley formula, chart + recent-sessions view
- **History snapshot** — workout logs preserve block + exercise names at save time, so editing a template never rewrites past sessions
- **JSON import/export** — pick the legacy `history.json` / `state.json` from the old web app to migrate; Settings → Data has symmetric export
- **Auto-seed** — on first launch with no history, the bundled `assets/seed/history.json` is imported once

## Project layout

```
lib/
  main.dart                # bootstrap: AlarmManager + notifications + ProviderScope
  app.dart                 # MaterialApp.router
  router.dart              # GoRouter + ShellRoute (5-tab bottom nav)
  app_providers.dart       # top-level Riverpod providers

  data/
    db/                    # Drift tables, DAOs, codegen
    models/                # plain Dart DTOs for import/export JSON
    repositories/          # Drift-backed repositories

  domain/
    plan/                  # Default plan constant + models
    util/                  # week math, one-rep-max formula

  features/
    train/                 # Train screen + auto-advance controller
    workout/               # Active-block screen + rest timer
    history/               # Session list
    stats/                 # e1RM chart + recent sessions
    settings/              # Reminder config + import/export
    templates/             # Template list + editor + picker sheet

  notifications/           # AlarmManager callback + reminder scheduler
  theme/                   # ColorSchemes + theme-per-day provider
  widgets/                 # Shared widgets (bottom nav, set row, modals)

assets/
  icons/                   # Launcher icon source PNGs
  seed/history.json        # First-run seed

tool/
  generate_icon.py         # Regenerates launcher PNGs from the dumbbell design

docs/
  ARCHITECTURE.md          # Reminder algorithm + state flow reference
  ui-mockup.html           # Visual reference
  Plan.md                  # Original planning notes
```

## Development notes

- The Drift schema lives in `lib/data/db/app_database.dart`. Bumping `schemaVersion` requires a matching migration step in `onUpgrade`.
- `lib/domain/plan/training_plan.dart` is the immutable seed source. Editing it only affects fresh installs and "Reset to default" in the template editor.
- `workout_logs` snapshot `block_name`, `block_icon`, `theme`, and each `exercise_name`. Template edits never rewrite past sessions.
- `exercise_id` is a stable token generated on exercise creation; it joins history across rename edits.
- GTG reminders chain-schedule one alarm at a time (`android_alarm_manager_plus.oneShotAt`). The callback posts a notification then enqueues the next one, so the chain self-heals on reboot via `onBoot`.
