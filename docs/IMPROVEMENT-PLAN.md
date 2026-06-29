# Protocol — Improvement Plan

> Tracked backlog from the 2026-06-26 full-app audit (design/workflow + architecture/technical).
> Findings were produced by parallel reviewers and **independently verified against the source** —
> 43 of 44 confirmed, 1 partial (the exact-alarm SDK details were corrected, see **T6**).
>
> **How to use:** each item is self-contained (Problem / Fix / Done-when) and copy-pasteable into a
> GitHub issue. Check the box when merged. Severity 🔴 critical · 🟠 high · 🟡 polish.
> Effort: `quick` (<1h) · `M` (a focused session) · `L` (multi-session).

---

## Status — updated 2026-06-28

> After the 7-day schedule feature + three improvement waves shipped & pushed to `master`.
> Legend: **[x]** shipped · **[~]** moot/partial · **[ ]** open. Per-item sections below are the original reference specs.

**P0 — data safety & the core promise**
- [x] **T1** Unify the day model — ✅ (delivered by the 7-day schedule)
- [x] **T2** GTG midnight reset + resume re-sync — ✅
- [x] **T3** Guard `saveWorkout` — ✅
- [x] **T4** Drift migration safety net + indices — ✅ (schema v2 + SchemaVerifier migration test)
- [~] **T5** Re-arm the 48h reminder window — ❌ MOOT (master's chain design self-heals via `oneShotAt` re-arm + `rescheduleOnReboot`; the 48h-batch problem was in stashed code)
- [x] **T9** Replace the fictional `ARCHITECTURE.md` — ✅

**P1 — high-value UX & correctness**
- [x] **DW2** Logging-loop friction (save SnackBar, keyboard traversal, weight prefill) — ✅
- [x] **DW4** Template-editor fake "Save" & silent field reverts — ✅
- [x] **DW5** Import: confirm + dedup/replace + warning — ✅
- [x] **DW6** First-run onboarding + notification-permission priming — ✅
- [x] **DW7** Train screen error/empty states — ✅
- [x] **T6** Inexact GTG alarms; drop `USE_EXACT_ALARM` — ✅
- [~] **T7** `tz.local` DST — ❌ MOOT (no `timezone`/`zonedSchedule` code on master)
- [x] **T13** Test the highest-risk untested code (import/export round-trip) — ✅

**P2 — polish & hygiene**
- [x] **DW3** stale "Last:" hint — ✅
- [x] **DW8** WCAG contrast — ✅
- [~] **DW9** token enforcement — ✅ Radii/Spacing/`textMid`/display tokens shipped; ⏳ typography-hierarchy sweep deferred (changes rendered sizes, wants on-device review)
- [x] **DW10** restore mockup identity — ✅
- [x] **DW11** polish backlog — ✅ (⏳ except the history-card per-rebuild flicker sub-item)
- [~] **T8** retire `android_alarm_manager_plus` — ❌ MOOT (it is the live scheduler; only residual — drop the unused `timezone` dep — was done with T6)
- [x] **T10** `exercise_id` join+fallback — ✅ (PR/Last unified across renames; ⏳ Stats lift *picker* not yet unified by id)
- [x] **T11** route import/export through repositories — ✅
- [x] **T12** lints + GitHub Actions CI — ✅
- [ ] **T14** low-priority cleanups — ⏳ (dayName ✅ via T13; the rest open)

### Remaining after this work
⏳ **DW9** typography-hierarchy sweep · **T10** Stats-picker id unification · **DW11** history-card flicker · **T14** cleanups (dead `clearAll`, unused bundled `state.json`, React-port comments, `TrainScreen` over-broad watches, midnight theme-tag edge case, stream-idiom).

---

# Part 1 — Design & Workflow

### [ ] DW1 — Reminders fire on the wrong rest day 🔴
**Symptom (user-facing):** GTG nudges arrive on your rest day, or go silent on a training day. This is the lived symptom of the day-model split — **the fix is tracked in `T1`.** Listed here because it is the most-felt design defect.

### [ ] DW2 — Reduce mid-workout logging friction 🟠 `M`
The set-logging screen is used one-handed, mid-workout — friction here costs the most.
- **No save confirmation.** Finishing a block with no PR just pops back to Train with no toast/snackbar. For an offline app where the DB write *is* the session, silent success is a trust gap. `lib/features/workout/workout_screen.dart:309-331`
- **No keyboard traversal.** Weight/reps `TextField`s have no `textInputAction`, no focus-next, no `onSubmitted`; the keyboard can cover the active field and the Finish button (no keyboard-aware scroll). `lib/widgets/set_row.dart:88-116`, `lib/features/workout/workout_screen.dart:91-110`
- **Weight isn't prefilled** from last session (the "Last:" hint is display-only), so every set is retyped.

**Fix.** Add a non-blocking SnackBar on successful save (e.g. "Block saved — 4 sets logged"). Wire `TextInputAction.next` weight→reps and `FocusNode` chaining; ensure the active field scrolls above the keyboard. Prefill weight from the already-fetched last top set. Optionally a +/- weight stepper for gloved input.
**Done when.** A user can log a multi-set block without re-tapping into each field, sees a save confirmation, and the keyboard never hides the Finish button.

### [ ] DW3 — Refresh the stale "Last: weight × reps" hint 🟡 `quick`
**Problem.** `lastTopSetProvider` is a non-`autoDispose` `FutureProvider.family` that is never invalidated after a save, so the hint meant to help pick today's weight shows pre-save data until app restart. `lib/app_providers.dart:152-156`
**Fix.** Add `.autoDispose` and `ref.invalidate(lastTopSetProvider)` after `saveWorkout` in `_finish`, or convert it to a `StreamProvider` over the repo query.
**Done when.** Re-opening an exercise after logging it shows the just-saved top set.

### [ ] DW4 — Fix the template editor's fake "Save" & silent field reverts 🟠 `quick`
**Problem.** Every edit already commits live to the DB on blur; the AppBar ✓ only shows a 1-second "Plan saved" snackbar and pops — teaching a false "edits are pending" mental model and implying back = discard. `lib/features/templates/template_editor_screen.dart:31-43`. Separately, inline `Sets`/`Rest` fields silently revert invalid input with no feedback, while name/target fields ignore-empty but leave the field visually blank (display ≠ stored value). `lib/features/templates/widgets/exercise_row_editor.dart:77-103`
**Fix.** Rename the ✓ action to "Done" (pure pop) and add a persistent "Changes save automatically" caption. On invalid numeric input show an inline `errorText` instead of a silent revert; on emptied name/target restore the prior text so display matches data.
**Done when.** Users understand edits auto-save, and no edit silently vanishes or desyncs from what's shown.

### [ ] DW5 — Import: confirm, warn, and dedup 🟠 `M`
**Problem.** "Import from web app" writes to the DB immediately (format guessed by a leading `[`), silently overwrites `weekStartDate`, and history import **appends with no dedup** — so restoring the same backup twice doubles the entire training log and pollutes the e1RM chart. No confirm, no undo. `lib/features/settings/import_export_controller.dart:127-198`, `lib/features/settings/settings_screen.dart:189-224`
**Fix.** Add a confirmation modal stating detected type and effect ("Adds N logs" / "changes your week-start date"). Treat history import as **replace-all** behind a clear confirmation (matches a single-user restore mental model), or dedup on `(date, blockId, dayId)`.
**Done when.** Re-importing a backup does not duplicate history, and the user confirms the effect before any write.

### [ ] DW6 — First-run onboarding + permission priming 🟠 `M`
**Problem.** First launch drops straight onto Day 1 with no explanation of the rotation/GTG, and notification permission is *only* requested if the user happens to toggle reminders in Settings — so a user who never opens Settings silently never gets the app's headline feature. `lib/features/train/train_screen.dart:33-36`, `lib/features/settings/settings_screen.dart:34-45,256-262`
**Fix.** Add a lightweight first-run sheet (gated by a new settings flag) explaining the rotation + GTG with a single "Enable reminders" button that runs the permission flow and sets `remindersEnabled`.
**Done when.** A fresh install gets a one-screen intro and a one-tap path to enabling reminders.

### [ ] DW7 — Train screen error / empty states 🟠 `M`
**Problem.** Only `boot.isLoading` is handled; a failed first-run seed or corrupt DB leaves a permanent spinner / blank scaffold with no retry. `activeTemplateProvider` is read via `valueOrNull`, swallowing errors. WorkoutScreen spins forever on a null template. `lib/features/train/train_screen.dart:33-39`, `lib/features/workout/workout_screen.dart:60-62`
**Fix.** Add `hasError` branches with a message + retry (invalidate the seed providers); guard the null/errored active-template case.
**Done when.** A seed/DB failure surfaces an actionable error instead of hanging.

### [ ] DW8 — Fix muted-text contrast to WCAG AA 🟡 `M`
**Problem.** Secondary text uses `onSurface` at alpha 0.35–0.5 → ~2.8:1 for the block-card "empty" label (unreadable) and ~4.3:1 for headers, below the 4.5:1 AA threshold. The ideal token already exists but is unused: `AppColors.onSurfaceMid` (`0xFF94A3B8`) measures 6.1–6.5:1. `lib/widgets/block_card.dart:92`, `lib/features/workout/workout_screen.dart:170,214`
**Fix.** Route secondary text through `onSurfaceMid`; reserve alpha ≤0.4 for decorative/disabled only.
**Done when.** All readable labels clear 4.5:1 on iron/body/rest surfaces.

### [ ] DW9 — Enforce the typography & color token system 🟡 `M`
**Problem.** A full `TextTheme` and `onSurfaceMid/Low` tokens are defined but bypassed — the same "card title" is 14/15/16px across screens and the tokens are dead; ~49 ad-hoc `onSurface.withValues(alpha:)` calls across 16 files; radius/spacing are scattered magic numbers (14/10/8/6/20; padding 14 vs 16). `lib/theme/colors.dart:18-20,108-115`
**Fix.** Route text through `Theme.of(context).textTheme` roles (+ a `display` role for the 44px GTG counter). Add a tiny tokens file (`Radii`, `Spacing`) and a `ColorScheme` extension (`textHi/textMid/textLow`). Standardize card inner padding.
**Done when.** A grep finds no inline `fontSize`/raw-radius in feature widgets; the scale is real.

### [ ] DW10 — Restore the mockup's visual identity 🟡 `M`
**Problem.** The opinionated `docs/ui-mockup.html` personality was flattened to stock Material: pill tabs → 10px rects; the tinted "done" card → a tiny chip (done vs pending barely differ); green GTG overflow dots not drawn; rest-timer accent border gone; per-day block progress bar gone. `lib/widgets/{day_tabs,block_card,gtg_counter,rest_timer_bar}.dart`
**Fix.** Restore the high-signal cues: tint completed `BlockCard` surfaces (primary @~0.10 + subtle border), render overflow GTG dots in success green and keep drawing past target, give the timer bar a thin primary top border, add the day progress bar.
**Done when.** Completed blocks and over-target GTG are obvious at a glance; the app reads as purpose-built.

### [ ] DW11 — Polish backlog 🟡 `quick` each
- [ ] Day-tab touch targets are <48dp; extract a shared tab chip (duplicated in the template editor). `lib/widgets/day_tabs.dart:14,28`
- [ ] Templates list shows an **infinite spinner** instead of an empty state when genuinely empty. `lib/features/templates/templates_screen.dart:37-38`
- [ ] e1RM chart has no axis labels/scale — a 1kg and 30kg gain look identical; add min/max Y labels and a tappable-dots hint. `lib/features/stats/e1rm_chart.dart:57-58`
- [ ] Duplicate templates collide silently as "X copy"; prompt for a name or auto-suffix. `lib/features/templates/templates_screen.dart:160-161`
- [ ] History cards re-fetch sets per-rebuild (`FutureBuilder` + `ref.read`) → flicker; move to a `StreamProvider.family`. `lib/features/history/history_screen.dart:229-263`
- [ ] `fontFamily: 'monospace'` is unregistered; use `FontFeature.tabularFigures()` via one shared style. `lib/widgets/rest_timer_bar.dart:45`
- [ ] "Add exercise" appends a generically-named row off-screen with no scroll-to/autofocus. `lib/features/templates/template_editor_screen.dart:190-204`

---

# Part 2 — Architecture & Technical

### [ ] T1 — Unify the day model (single source of truth) 🔴 `M`
**Problem (root cause of DW1).** The UI computes the day from the user's `weekStartDate` (`(today − weekStart).inDays + 1`, clamped 1–5) while the notification scheduler uses an unrelated epoch formula `(daysSinceEpoch % 5) + 1`. They only agree by coincidence. Verified divergence: `weekStart = 2026-06-26` → on `2026-07-01` the UI shows Day 5 (rest) while the scheduler computes Day 1 (training). The UI also clamps at 5 indefinitely, and "Start new week" never reschedules notifications. `lib/app_providers.dart:125-134` vs `lib/notifications/reminder_scheduler.dart:38-41`, gated at `lib/notifications/notification_helper.dart:92`, `lib/features/train/train_screen.dart:162-167`
**Fix.** Extract one pure `dayOfCycle(DateTime, weekStart)` into `lib/domain/util/week.dart`; call it from both `derivedDayProvider` and the scheduler. Pass `weekStartDate` into `scheduleGtgWindow`. Call `scheduleNext()` from the "Start new week" path.
**Done when.** A test asserts UI day == scheduler day for arbitrary `weekStart` offsets, and reminders suppress on the same day the UI labels "rest."
> **Note (2026-06-27):** now delivered by the **7-day schedule** change (`docs/superpowers/specs/2026-06-27-seven-day-schedule-design.md`), which moves both UI and scheduler onto a single `dayOfCycle()`. Don't implement T1 standalone.

### [ ] T2 — GTG midnight reset + day re-sync on resume 🔴 `M`
**Problem.** (a) `todayGtgProvider` → `watchTodayCounts()` snapshots `todayKey()` once at stream creation and filters that fixed date forever; the midnight ticker rebuilds `derivedDayProvider` but not this stream, so after midnight the displayed count reads yesterday's row while +/- writes today's. `lib/data/repositories/gtg_repository.dart:10-15`, `lib/app_providers.dart:145-147` (b) `derivedDayProvider` rides a Dart `Timer` that doesn't survive Doze/kill; `appLifecycleProvider`'s doc claims a resume re-sync that nothing implements. `lib/app_providers.dart:76-82,99-134`, `lib/app.dart:31-36`
**Fix.** Make `todayGtgProvider` depend on `dateTickerProvider` (or pass a fresh `dateKey` into a `watchCountsFor(dateKey)` query). On `AppLifecycleState.resumed`, invalidate `dateTickerProvider`/`derivedDayProvider` (and either wire or fix the `appLifecycleProvider` doc). **Do this together with T1 — same subsystem.**
**Done when.** Leaving the app open across midnight resets the GTG counter and advances the day; reopening the next morning shows today.

### [ ] T3 — Guard `saveWorkout` against DB failure 🔴 `quick`
**Problem.** `_finish` awaits `saveWorkout` then immediately `context.pop()` with no try/catch. A failed transactional insert (disk full, lock) throws unhandled, the screen pops, and the just-completed block is lost with no message — yet every *other* DB action in the app is guarded. `lib/features/workout/workout_screen.dart:309-331` (contrast `settings_screen.dart:216`, `templates_screen.dart:205,229`)
**Fix.** Wrap `saveWorkout` (and the preceding PR query) in try/catch; on failure keep the screen open and show a "Couldn't save — try again" modal.
**Done when.** A simulated save failure keeps the entered sets on screen with a retry path.

### [ ] T4 — Drift migration safety net + indices 🔴 `M`
**Problem.** (a) `schemaVersion = 1`, `MigrationStrategy` has only `onCreate`/`beforeOpen`, **no `onUpgrade`**, no `drift_schemas/` dump, no migration test — the first column add ships a broken update against the only user with real data. `lib/data/db/app_database.dart:103-111` (b) **Zero secondary indices** — every Stats/PR/last-set query full-scans free-text `exerciseName` and joins unindexed `logId`; runs per exercise card on every WorkoutScreen open. `lib/data/repositories/workout_repository.dart:86-148`
**Fix.** Add an `onUpgrade` (even a no-op asserting `from==to` today) and adopt Drift's schema workflow (`drift_dev schema dump` → `drift_schemas/` + a `SchemaVerifier` test). Add `@TableIndex` on `ExerciseSets(logId)`, `ExerciseSets(exerciseName)`, `WorkoutLogs(date)` — which *is* the first migration, so ship them together.
**Done when.** A v1→v2 migration test passes and the indices exist in the generated schema.

### [ ] T5 — Re-arm the reminder window in the background / after reboot 🔴 `M`
**Problem.** The reminder design was rewritten from the documented "self-healing chain + onBoot" to **batch-scheduling 48h of `zonedSchedule` notifications**, re-armed only on app-resume or settings change. Nothing re-arms in the background, so >2 days without opening the app = reminders silently stop. No boot receiver, so a reboot wipes the pending window. `lib/notifications/notification_helper.dart:78-101`, `lib/app.dart:33-53`
**Fix.** Add a background re-arm: one `android_alarm_manager_plus` `oneShotAt` ~24h out whose callback re-runs `scheduleGtgWindow` and re-arms itself (this also justifies keeping the dependency — see T8), plus a reboot re-arm. Alternatively widen `hoursAhead` and document the gap.
**Done when.** Reminders keep firing across several days of not opening the app, and survive a reboot.

### [ ] T6 — Inexact alarms + drop `USE_EXACT_ALARM` 🟠 `quick`
**Problem.** Hourly "do a pushup" nudges are scheduled with `exactAllowWhileIdle`, and the manifest declares `USE_EXACT_ALARM` — which Google Play restricts to alarm-clock/calendar apps (rejection risk if ever published) and depends on a grant Android revokes by default. Exactness is the wrong tool for fuzzy hourly nudges. `lib/notifications/notification_helper.dart:124`, `android/app/src/main/AndroidManifest.xml:7-8`
> **Verification correction:** the build targets **SDK 36 / Android 15** on **Flutter 3.41.7** (not API 34 / 3.24 as first stated) — the policy concern is *more* current, not less. The rest-timer notification may keep exactness if desired.
**Fix.** Switch GTG to `AndroidScheduleMode.inexactAllowWhileIdle`; remove `USE_EXACT_ALARM` (keep at most `SCHEDULE_EXACT_ALARM` for the rest timer).
**Done when.** GTG reminders schedule without the exact-alarm grant; manifest no longer claims `USE_EXACT_ALARM`.

### [ ] T7 — Set `tz.local` for DST-correct scheduling 🟠 `M`
**Problem.** `main.dart` calls `initializeTimeZones()` but never `setLocalLocation(...)`, so `tz.local` stays UTC; `_scheduleGtgAt` works around it with `now + duration`, which is blind to DST — the active window drifts an hour on spring-forward/fall-back days. `lib/main.dart:15`, `lib/notifications/notification_helper.dart:103-128`
**Fix.** Add `flutter_timezone`, resolve the device zone once at startup, `tz.setLocalLocation(...)`, and schedule with genuine `TZDateTime` values (delete the workaround).
**Done when.** Window hours stay correct across a simulated DST transition.

### [ ] T8 — Retire or repurpose `android_alarm_manager_plus` 🟡 `M`
**Problem.** Initialized at startup and only used to `cancel()` a legacy id it never schedules, while still dragging in `RECEIVE_BOOT_COMPLETED` + `FOREGROUND_SERVICE` manifest cost (a Play-review liability and missing `foregroundServiceType` on Android 14+). `lib/main.dart:16`, `lib/notifications/reminder_scheduler.dart:21,31`
**Fix.** Either repurpose it for the T5 background re-arm (preferred — sequence after T5), or remove the dep + `initialize()` + the now-unneeded permissions, keeping a one-time guarded legacy cancel.
**Done when.** The dependency either does real work (T5) or is gone along with its permissions.

### [ ] T9 — Replace the fictional `ARCHITECTURE.md` and fix README 🔴/🟠 `quick`
**Problem.** `docs/ARCHITECTURE.md` documents a **Kotlin / Jetpack Compose / Room / AlarmManager MVVM** app that does not exist (the app is Flutter/Riverpod/Drift/go_router/fl_chart). README also still describes the obsolete "chain-scheduled + onBoot" reminder design. Highest-leverage hazard for a solo repo: future decisions made on false docs. `docs/ARCHITECTURE.md` (whole file), `README.md:12,63,119`
**Fix.** Rewrite `ARCHITECTURE.md` to the real stack (or delete + point to README with a STALE banner). Update README's reminder section to describe `zonedSchedule` batch scheduling + resume re-arm; remove the `oneShotAt`/`onBoot` claims.
**Done when.** No doc describes a stack or algorithm the code doesn't implement.

### [ ] T10 — Decide `exercise_id`: load-bearing or drop 🟡 `M`
**Problem.** `exercise_id` (a stable UUID) is written everywhere but joined nowhere — Stats/PR/last-set all key on free-text `exerciseName`, so renaming an exercise splits its history into two unrelated series. Imported history hard-codes `exerciseId=''`. `lib/data/db/app_database.dart:61`, writes at `workout_screen.dart:258` etc.
**Fix.** Either make it load-bearing (join on `exerciseId` when present, fall back to name so renames keep one series) — recommended — or document name-keying as deliberate and drop the unused column.
**Done when.** Renaming an exercise either preserves one history series, or the column is gone and the design is documented.

### [ ] T11 — Stop the UI/import path depending on raw Drift types 🟡 `M`
**Problem.** Eight feature/widget files import `data/db/app_database.dart` to consume generated row classes directly, and `import_export_controller.dart` imports `package:drift` and runs `_db.select/into/transaction` itself, bypassing the repositories — a second, parallel data-access path. Schema/codegen changes ripple straight into widgets. `lib/features/settings/import_export_controller.dart:33,75,138,182,210`
**Fix.** Lowest-cost win: route the controller's raw `_db.*` through the repositories (or a dedicated `BackupRepository`). Longer term, thin domain models for the handful of UI-consumed types.
**Done when.** All SQL lives behind the repository layer.

### [ ] T12 — Lints + minimal CI 🟡 `quick`
**Problem.** `analysis_options.yaml` is the bare `flutter_lints` template (empty `rules:`); no CI, no format/test gate; style drift already present (brace-less for-loop at `settings_screen.dart:344`). `analysis_options.yaml:23-25`
**Fix.** Add high-value lints (`prefer_const_constructors`, `unawaited_futures`, `curly_braces_in_flow_control_structures`, `require_trailing_commas`, `always_declare_return_types`) and a one-job GitHub Action: `pub get` → `build_runner build` → `flutter analyze` → `dart format --set-exit-if-changed` → `flutter test --coverage`.
**Done when.** CI fails on analyze/format/test regressions.

### [ ] T13 — Test the highest-risk untested code 🟠/🔴 `M` (multiple PRs)
**Problem.** 5 test files (~264 LOC) cover ~5,600 LOC; the riskiest code is the untested code — and two confirmed bugs already live there. Existing tests are good (real in-memory Drift, `fakeAsync`); build on that harness.
**Fix — in priority order:**
- [ ] **Import/export round-trip** (the only data-loss surface): seed → export → import into fresh DB → assert equality; `'—'`/empty-string → null coercion; would have caught the `dayName = blockName` export bug. `import_export_controller.dart:32-203`
- [ ] **Notification window** as a pure function: window filtering, midnight crossing, `startHour>=endHour` early-return, the 100-slot id cap, rest-day skip with the *correct* (T1) day source. `notification_helper.dart:78-101`
- [ ] **Day-rollover state machine**: manual pick survives resume; midnight overrides it; "Start new week" resets to 1. (`ProviderContainer` + injected ticker.) `app_providers.dart:64-74`, `train_screen.dart:25-29`
- [ ] **e1RM/Epley + PR boundary** (equal-e1RM, bodyweight null). `lib/domain/util/one_rep_max.dart`
- [ ] **Template seed/reorder reindexing & GTG clamp/midnight**; **Drift schema-verify** (pairs with T4).
**Done when.** Each bullet has a passing test; CI (T12) gates them.

### [ ] T14 — Low-priority backlog 🟡 `quick` each
- [ ] `GtgRepository.clearAll()` is dead code with a stale "Used by Start new week" comment — delete it or wire it intentionally. `gtg_repository.dart:38-41`
- [ ] Export `dayName` is mis-populated with `blockName`; derive from `TrainingPlan.days[dayId].name` instead (zero schema change). `import_export_controller.dart:46-47`
- [ ] Bundled `assets/seed/state.json` is shipped but never auto-seeded — remove it or add a guarded `autoSeedFromBundledState`. `import_export_controller.dart:327`
- [ ] React-port comments cite `src/*.js:line` for code that now lives only under `.claude/worktrees/` — replace with rule descriptions. `week.dart:1`, `one_rep_max.dart:1`, `history_entry.dart:1`
- [ ] `TrainScreen` over-broad watches rebuild the whole sliver tree on any GTG/done/ticker change — scope the watches. `train_screen.dart:25-42`
- [ ] Workout saved across midnight tags the log with the *new* day's theme (`currentDayMetaProvider` read at finish) instead of `widget.dayId`'s. `workout_screen.dart:240,312`
- [ ] Standardize the two hand-rolled stream-merge idioms (`async*`/`await for` vs manual `StreamController`). `stats_screen.dart:94-124`

---

## Appendix A — Strengths to preserve (don't regress these)
- **Per-day theming engine** — `DayTheme` → `buildTheme()` swapping `ColorScheme`, all hex centralized in `colors.dart`. Genuinely good.
- **History-snapshot integrity** — logs freeze `blockName/blockIcon/theme/exerciseName` at save time; template edits never rewrite past sessions; `templateId` nullable with `onDelete: setNull`.
- **Atomic writes** — `saveWorkout`, import, template create/duplicate/reset/reorder all wrapped in `db.transaction`; `PRAGMA foreign_keys = ON` actually enabled.
- **Leak-safe timers** — `dateTickerProvider` uses `StreamController` + `Timer` + `ref.onDispose`; `RestTimerController` is a clean, unit-tested `StateNotifier`.
- **Deliberate day-selection seam** — `currentDayProvider` seeds via `ref.read` (not `watch`) so a manual day pick survives resume. *(T1/T2 must not break this; the 3 change channels stay: manual tap, midnight tick, Start new week.)*
- **Idempotent seeding** with explicitly ordered seed chains (history awaits template seed).

## Appendix B — ~~Open product question~~ RESOLVED (2026-06-27)
`docs/Plan.md` specifies a **7-day** schedule, but the app implemented a **5-day** rotation. **Decision: adopt the 7-day schedule** (literal `Plan.md` content, auto-wrap cycle, distinct active-recovery Days 4 & 6, full rest Day 7). This is now its own change — see `docs/superpowers/specs/2026-06-27-seven-day-schedule-design.md`. It **subsumes `T1`** (the day-model unification is delivered as part of it).
