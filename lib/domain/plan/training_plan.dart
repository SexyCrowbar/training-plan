import 'models.dart';

/// Static port of `src/data/plan.js`. Used as:
/// 1. Seed for the "Default" template on first launch (see TemplateSeeder).
/// 2. Source for the editor's "Reset to default" overflow action.
/// 3. Canonical day metadata (name, theme, tag, gtgTarget, gtgEx) — these are
///    NOT editable per template; only the per-block exercises are.
class TrainingPlan {
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
}
