# 7-Day Training Schedule (replace the 5-day rotation)

> Design spec · 2026-06-27 · supersedes the open product question in `docs/IMPROVEMENT-PLAN.md` (Appendix B)
> and subsumes audit item **T1** (unify the day model).

## Context

The app currently implements a **5-day rotation** (4 training days + 1 full rest), which is a lossy
compression of the original `docs/Plan.md` — the 2 active-recovery days (Plan Days 4 & 6) were dropped
and full rest was moved to Day 5. The owner wants the app to follow the **original 7-day schedule**:
4 training days, 2 active-recovery days, 1 full rest day, repeating continuously.

This also forces a fix to a real bug surfaced in the audit (**T1**): the UI and the notification scheduler
use two different day-of-cycle formulas, so GtG reminders can fire/suppress on the wrong day. Both will be
moved onto a single shared function as part of this change.

## Decisions (settled in brainstorming)

1. **Content:** literal `Plan.md` for all 7 days (e.g. Day 2 power = Barbell Pendlay Rows, not Weighted Pull-Ups).
2. **Cycle:** auto-wrap weekly — `day = ((today − weekStart).inDays % 7) + 1`, repeating 1→7→1 forever.
3. **Recovery days:** distinct `recovery` theme; Days 4 & 6 keep reduced GtG **and** reminders; only Day 7 silences GtG.
4. **Migration (Option C):** on upgrade, **wipe & reseed templates** from the new plan, **keep all history**.

## 1. Plan data — the seven days

Day metadata (name, theme, tag, `gtgTarget`, `gtgEx`) stays canonical in `training_plan.dart` and is **not**
per-template editable; only block exercises are editable, as today. A generic warm-up block is kept on
training days (Plan.md implies a warm-up before working sets). iron/body assignment is cosmetic.

| Day | Theme | GtG | Power | Hypertrophy (superset) | Endurance / Block 3 |
|---|---|---|---|---|---|
| **1** Chest Power & Tricep/Shoulder | iron | 5 | Barbell Bench Press 3×3–5 | Parallel Bar Dips 3×AMRAP · EZ-Bar Skullcrushers 3×8–12 | KB Swings (16kg) EMOM 10 min, 15/min |
| **2** Back Power & Bicep | body | 5 | Barbell Pendlay Rows 3×3–5 | EZ-Bar Curls 3×8–12 · Ring Face Pulls 3×12–15 | BW AMRAP 10 min — 10 push / 15 squat / 20 JJ |
| **3** Legs & Shoulder Density | iron | 5 | Barbell Zercher Squats 3×3–5 | Standing Barbell OHP 3×8–10 · EZ-Bar Reverse Curls 3×10–12 | KB Goblet Squats 3×15 · Planks 3×60s (superset) |
| **4** Active Recovery & Joint Health | **recovery** | 4 | *(off)* | *(off)* | Shadowboxing / animal-flow mobility, 10–15 min |
| **5** Tricep Power & Functional Flow | body | 5 | Close-Grip Barbell Bench 3×3–5 | Gymnastic Ring Dips 3×AMRAP · KB Upright Rows (16kg) 3×10–12 | KB Clean & Press (16kg) flow, 5 min/side |
| **6** Active Recovery | **recovery** | 3 | *(off)* | *(off)* | Walk / stretch / light mobility (nothing to log) |
| **7** Full Rest & Reset | rest | 0 | *(off)* | *(off)* | *(off)* |

GtG exercise is "Strict Underhand Chin-ups" on Days 1–6; Day 7 = "No GtG today — full rest". The reduced
targets (4 on Day 4, 3 on Day 6) reflect Plan.md's "3-4" and "2-3" guidance.

## 2. Day-of-cycle model — auto-wrap

Add one pure function and route **both** the UI and the scheduler through it (this is the T1 fix):

```dart
// lib/domain/util/week.dart
/// Day of the 7-day cycle (1..7) for [day], anchored to [weekStart].
/// Dart's % is non-negative for positive divisors, so no negative guard is needed.
int dayOfCycle(DateTime day, DateTime weekStart) {
  final diff = DateTime(day.year, day.month, day.day)
      .difference(DateTime(weekStart.year, weekStart.month, weekStart.day))
      .inDays;
  return (diff % 7) + 1;
}
```

- `derivedDayProvider` (`app_providers.dart:125-134`) replaces `(diff + 1).clamp(1, 5)` with `dayOfCycle(...)`.
- The 3-channel day-change machinery (manual tab, midnight `derivedDay` listener, re-anchor) and the
  deliberate `ref.read`-seed of `currentDayProvider` are **unchanged** — only the formula and the tab count
  (5→7) change. (Preserves the Decision-Log invariant in `.wolf/cerebrum.md`.)
- Fresh install still lands on Day 1 (`effectiveWeekStart` defaults to today → `diff == 0` → Day 1).
- **"Start new week" → "Restart cycle (Day 1 today)"** (`train_screen.dart:147-168`): sets `weekStart = today`,
  `currentDay = 1`, and now **also reschedules notifications** (today it doesn't). Optional action; auto-wrap
  no longer requires it.

## 3. Themes — new `recovery` tier

- Add `recovery` to `enum DayTheme` (`models.dart:1`).
- Add a `recovery` `ColorScheme` in `_schemeFor()` (`colors.dart`). Proposed palette: emerald primary
  `#34D399` on deep green-slate surface `#0E2A22` / background `#08160F` — distinct from iron (gold),
  body (cyan), rest (neutral). Tweakable. The existing `themeProvider` → `currentDayMetaProvider` plumbing
  recolors the whole app automatically.

## 4. GtG & notifications — data-driven suppression (closes T1)

- Suppression rule becomes **data-driven**: a day participates in GtG iff `day.gtgTarget > 0`. Only Day 7
  (target 0) is silenced. Days 4 & 6 still fire reminders at their reduced targets.
- `reminder_scheduler.dart` `currentRotationDayId` (the epoch-`%5` formula) is **removed**; the scheduler
  receives `weekStart` and computes each candidate hour's day via `dayOfCycle(...)`, suppressing when that
  day's `gtgTarget == 0`. `scheduleGtgWindow` (`notification_helper.dart:78-101`) takes `weekStart` and the
  plan lookup. All call sites that schedule (`app.dart` resume, `settings_screen.dart`, the repurposed
  "Restart cycle") pass the stored `weekStart`.
- Train screen: the GtG counter already hides when `theme == rest`, so Day 7 hides it; recovery days
  (`theme == recovery`, target > 0) show it. Day 6 has no blocks → show the GtG counter plus a short
  "Active recovery — walk, stretch, light mobility" message in place of block cards. Day 4 shows its single
  mobility block.

## 5. Templates — 7×4 grid

- `TemplateSeeder.createTemplateFromPlan` builds **7 days × 4 blocks** from `TrainingPlan.days`. Recovery
  Day 4 seeds only the mobility (endurance) block; Days 6 & 7 seed empty.
- Import/export grid pre-creation (`import_export_controller.dart:278-316`) expands 5→7 dayIds. The export
  JSON shape is unchanged (keyed by `dayId`/`blockId`); older 5-day exports still import (days 6–7 land empty).
- The editor continues to show the standard 4 blocks per day; canonical name/theme/GtG remain fixed, block
  exercises remain editable. `day_tabs` and the editor day strip iterate `TrainingPlan.days`, so they pick up
  7 days automatically — **verify horizontal scroll fits 7 tabs** during implementation.

## 6. Migration — Option C (wipe & reseed templates, keep history)

A **one-time data migration**, gated by a new `planVersion` settings flag (NOT a Drift `schemaVersion` bump —
the real Drift migration framework remains audit item T4, out of scope here). No schema change is required;
this is data + code only.

On boot, if stored `planVersion < kCurrentPlanVersion` (e.g. 1):
1. Delete all rows from `Templates` (cascade removes blocks + exercises).
2. Reseed the "Default" template from the new 7-day `TrainingPlan` via the seeder.
3. Set `activeTemplateId` to the new Default's id (the old active id now points at a deleted row).
4. Set `weekStartDate = today` (re-anchor the cycle to Day 1 today — clean slate for the new plan).
5. Set `planVersion = kCurrentPlanVersion`.
6. Reschedule notifications from the new `weekStart`.

**History is untouched.** `workout_logs`/`exercise_sets` freeze `block_name`/`block_icon`/`theme`/
`exercise_name` at save time, and Stats group by exercise *name*, so every past session still displays and
charts correctly even though dayId meanings shifted. GtG history rows are date-keyed and unaffected.

Fresh installs: the flag is unset → the same path runs; the wipe is a no-op (no templates yet), the seeder
creates Default, `weekStart` is already today. This unifies first-run seeding and upgrade under one guard.

## 7. Out of scope (stay in `IMPROVEMENT-PLAN.md`)

T2 (GtG midnight stream re-subscribe + resume re-sync), T3 (`saveWorkout` guard), T4 (Drift migration
framework + indices), T5 (reminder re-arm), and all design/UX items. This spec is the 7-day model + the T1
unification only.

## 8. Files to change

- `lib/domain/plan/training_plan.dart` — rewrite to 7 days (table §1).
- `lib/domain/plan/models.dart` — add `DayTheme.recovery`.
- `lib/domain/util/week.dart` — add `dayOfCycle()`.
- `lib/app_providers.dart` — `derivedDayProvider` uses `dayOfCycle`.
- `lib/theme/colors.dart` — `recovery` `ColorScheme`.
- `lib/notifications/reminder_scheduler.dart` + `notification_helper.dart` — remove epoch formula; take `weekStart`; suppress on `gtgTarget == 0`.
- `lib/app.dart`, `lib/features/settings/settings_screen.dart`, `lib/features/train/train_screen.dart` — pass `weekStart` to scheduling; repurpose "Start new week" → "Restart cycle"; recovery/no-blocks message.
- `lib/data/repositories/template_seeder.dart` — 7×4 seed + one-time plan migration.
- `lib/data/repositories/settings_repository.dart` — add `planVersion` key (`SettingsKeys`).
- `lib/features/settings/import_export_controller.dart` — 5→7 day grid pre-creation.
- `test/` — see §9.

## 9. Testing & acceptance criteria

**Tests**
- `dayOfCycle()`: `weekStart==today` → 1; +6 days → 7; +7 → wraps to 1; +13 → 7; negative-safe.
- UI/scheduler agreement: for several `weekStart` offsets, the scheduler's day == `dayOfCycle` (T1 regression guard).
- `TrainingPlan`: 7 days; targets `[5,5,5,4,5,3,0]`; Day 4 has only the mobility block; Days 6 & 7 empty; themes correct.
- Notification window: suppresses **only** Day 7; fires on Days 4 & 6.
- Seeder: builds a 7×4 grid; `planVersion` migration wipes existing templates, reseeds Default, sets active id, leaves `workout_logs` intact (assert history row count unchanged).

**Acceptance criteria**
- App shows 7 day tabs; advancing through a week lands on the correct day each day and wraps after Day 7.
- Reminders arrive on training and recovery days, never on Day 7.
- A returning user keeps all prior history and stats; their templates are reset to the new 7-day Default.
- `flutter analyze` and `flutter test` pass.

## 10. Assumptions

- This is a single-user personal app; replacing custom templates on upgrade (Option C) is acceptable to the owner.
- The block structure (warmup/power/hypertrophy/endurance) is retained; recovery content lives in the endurance/mobility block slot.
- iron/body assignment per training day is cosmetic and may be adjusted without affecting logic.
