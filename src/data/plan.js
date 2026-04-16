export const DAYS = {
  1: {
    theme: 'iron',
    name: 'Day 1: Horizontal Push',
    tag: 'Arms & Shoulders',
    gtgTarget: 5,
    gtgEx: 'Strict Underhand Chin-ups',
    blocks: [
      {
        id: 'warmup',
        icon: '🌅',
        name: 'Morning Prep',
        exercises: [
          { name: 'Desk-to-Barbell Warmup', sets: 1, target: '3 min', rest: 0, note: 'Arm circles, shoulder twists, deep squats.' }
        ]
      },
      {
        id: 'power',
        icon: '⚡',
        name: 'Morning Power',
        exercises: [
          { name: 'Barbell Bench Press', sets: 3, target: '3-5 reps', rest: 180, note: '60–70% max effort. Leave 2 reps in the tank.' }
        ]
      },
      {
        id: 'hypertrophy',
        icon: '💪',
        name: 'Afternoon Hypertrophy',
        exercises: [
          { name: 'Parallel Bar Dips', sets: 3, target: 'AMRAP', rest: 60, note: 'Superset 1 — go to near failure, controlled descent.' },
          { name: 'EZ-Bar Skullcrushers', sets: 3, target: '8-12 reps', rest: 90, note: 'Superset 2 — elbows tucked, full extension.' }
        ]
      },
      {
        id: 'endurance',
        icon: '🔥',
        name: 'Evening Endurance',
        exercises: [
          { name: 'KB Swings (16kg)', sets: 1, target: '10 min', rest: 0, note: 'EMOM — 15 reps at the top of every minute.' }
        ]
      }
    ]
  },

  2: {
    theme: 'body',
    name: 'Day 2: Vertical Pull',
    tag: 'Bicep Focus',
    gtgTarget: 5,
    gtgEx: 'Strict Underhand Chin-ups',
    blocks: [
      {
        id: 'warmup',
        icon: '🌅',
        name: 'Morning Prep',
        exercises: [
          { name: 'Desk-to-Barbell Warmup', sets: 1, target: '3 min', rest: 0, note: 'Dead hangs, scap pull-ups, wrist rotations.' }
        ]
      },
      {
        id: 'power',
        icon: '⚡',
        name: 'Morning Power',
        exercises: [
          { name: 'Weighted Pull-Ups', sets: 3, target: '3-5 reps', rest: 180, note: 'Use dip belt. Strict form — dead hang start.' }
        ]
      },
      {
        id: 'hypertrophy',
        icon: '💪',
        name: 'Afternoon Hypertrophy',
        exercises: [
          { name: 'EZ-Bar Curls', sets: 3, target: '8-12 reps', rest: 60, note: 'Superset 1 — full range, squeeze at top.' },
          { name: 'Ring Face Pulls', sets: 3, target: '12-15 reps', rest: 90, note: 'Superset 2 — high attachment, rear delts.' }
        ]
      },
      {
        id: 'endurance',
        icon: '🔥',
        name: 'Evening Endurance',
        exercises: [
          { name: 'Bodyweight AMRAP', sets: 1, target: '10 min', rest: 0, note: '5 Pull-ups → 10 Push-ups → 15 Squats. Repeat.' }
        ]
      }
    ]
  },

  3: {
    theme: 'iron',
    name: 'Day 3: Heavy Legs',
    tag: 'Core Stability',
    gtgTarget: 5,
    gtgEx: 'Strict Underhand Chin-ups',
    blocks: [
      {
        id: 'warmup',
        icon: '🌅',
        name: 'Morning Prep',
        exercises: [
          { name: 'Desk-to-Barbell Warmup', sets: 1, target: '3 min', rest: 0, note: 'Hip openers, Cossack squats, leg swings.' }
        ]
      },
      {
        id: 'power',
        icon: '⚡',
        name: 'Morning Power',
        exercises: [
          { name: 'Barbell Zercher Squats', sets: 3, target: '3-5 reps', rest: 180, note: 'Raw core power & leg drive. Brace hard.' }
        ]
      },
      {
        id: 'hypertrophy',
        icon: '💪',
        name: 'Afternoon Hypertrophy',
        exercises: [
          { name: 'Barbell Overhead Press', sets: 3, target: '8-10 reps', rest: 90, note: 'Strict standing — zero leg drive.' },
          { name: 'EZ-Bar Reverse Curls', sets: 3, target: '10-12 reps', rest: 90, note: 'Brachialis focus. Slow eccentric.' }
        ]
      },
      {
        id: 'endurance',
        icon: '🔥',
        name: 'Evening Endurance',
        exercises: [
          { name: 'KB Goblet Squats (16kg)', sets: 3, target: '15-20 reps', rest: 0, note: 'Superset with Planks — no rest between.' },
          { name: 'Planks', sets: 3, target: '60 sec', rest: 60, note: 'Superset — full body tension, squeeze glutes.' }
        ]
      }
    ]
  },

  4: {
    theme: 'body',
    name: 'Day 4: Arm Annihilation',
    tag: 'Functional Flow',
    gtgTarget: 5,
    gtgEx: 'Strict Underhand Chin-ups',
    blocks: [
      {
        id: 'warmup',
        icon: '🌅',
        name: 'Morning Prep',
        exercises: [
          { name: 'Desk-to-Barbell Warmup', sets: 1, target: '3 min', rest: 0, note: 'Wrist circles, shoulder dislocates, band pull-aparts.' }
        ]
      },
      {
        id: 'power',
        icon: '⚡',
        name: 'Morning Power',
        exercises: [
          { name: 'Close-Grip Bench', sets: 3, target: '3-5 reps', rest: 180, note: 'Tricep focused — elbows tucked tight.' }
        ]
      },
      {
        id: 'hypertrophy',
        icon: '💪',
        name: 'Afternoon Hypertrophy',
        exercises: [
          { name: 'Gymnastic Ring Dips', sets: 3, target: 'AMRAP', rest: 90, note: 'Use parallel bars if rings are unstable.' },
          { name: 'KB Upright Rows (16kg)', sets: 3, target: '10-12 reps', rest: 90, note: 'Controlled descent. Elbows lead.' }
        ]
      },
      {
        id: 'endurance',
        icon: '🔥',
        name: 'Evening Endurance',
        exercises: [
          { name: 'KB Clean & Press (16kg)', sets: 2, target: '5 min each', rest: 0, note: '5 min Right arm continuous, then 5 min Left.' }
        ]
      }
    ]
  },

  5: {
    theme: 'rest',
    name: 'Full Rest',
    tag: 'Recovery & Reset',
    gtgTarget: 0,
    gtgEx: 'No GtG today — full rest',
    blocks: []
  }
}
