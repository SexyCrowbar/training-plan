/// Mirrors the JSON shape written by the React app's `useHistory` hook —
/// see `src/hooks/useHistory.js:36-45`. Used for one-shot import/export.
///
/// Example record:
/// ```json
/// {
///   "date": "2026-04-17T17:51:52.803Z",
///   "day": 2,
///   "dayName": "Day 2: Vertical Pull",
///   "blockId": "hypertrophy",
///   "blockName": "Afternoon Hypertrophy",
///   "blockIcon": "💪",
///   "theme": "body",
///   "exercises": [
///     {
///       "name": "EZ-Bar Curls",
///       "sets": [{"done": true, "weight": "27", "reps": "14"}]
///     }
///   ],
///   "totalSets": 6
/// }
/// ```
class HistoryEntry {
  final DateTime date;
  final int day;
  final String dayName;
  final String blockId;
  final String blockName;
  final String blockIcon;
  final String theme;
  final List<HistoryExercise> exercises;

  HistoryEntry({
    required this.date,
    required this.day,
    required this.dayName,
    required this.blockId,
    required this.blockName,
    required this.blockIcon,
    required this.theme,
    required this.exercises,
  });

  int get totalSets => exercises.fold<int>(0, (n, ex) => n + ex.sets.length);

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      date: DateTime.parse(json['date'] as String),
      day: (json['day'] as num).toInt(),
      dayName: json['dayName'] as String? ?? '',
      blockId: json['blockId'] as String,
      blockName: json['blockName'] as String? ?? '',
      blockIcon: json['blockIcon'] as String? ?? '',
      theme: json['theme'] as String? ?? 'iron',
      exercises: [
        for (final e in (json['exercises'] as List? ?? const []))
          HistoryExercise.fromJson(e as Map<String, dynamic>),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toUtc().toIso8601String(),
    'day': day,
    'dayName': dayName,
    'blockId': blockId,
    'blockName': blockName,
    'blockIcon': blockIcon,
    'theme': theme,
    'exercises': [for (final e in exercises) e.toJson()],
    'totalSets': totalSets,
  };
}

class HistoryExercise {
  final String name;
  final List<HistorySet> sets;

  HistoryExercise({required this.name, required this.sets});

  factory HistoryExercise.fromJson(Map<String, dynamic> json) {
    return HistoryExercise(
      name: json['name'] as String? ?? '',
      sets: [
        for (final s in (json['sets'] as List? ?? const []))
          HistorySet.fromJson(s as Map<String, dynamic>),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'sets': [for (final s in sets) s.toJson()],
  };
}

class HistorySet {
  final bool done;

  /// Stored as strings in the JSON — can be "—" for unrecorded values.
  final String weight;
  final String reps;

  HistorySet({required this.done, required this.weight, required this.reps});

  factory HistorySet.fromJson(Map<String, dynamic> json) {
    return HistorySet(
      done: json['done'] as bool? ?? false,
      weight: json['weight']?.toString() ?? '',
      reps: json['reps']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'done': done,
    'weight': weight,
    'reps': reps,
  };

  double? get weightKg {
    if (weight.isEmpty || weight == '—') return null;
    return double.tryParse(weight);
  }

  int? get repsInt {
    if (reps.isEmpty || reps == '—') return null;
    return int.tryParse(reps);
  }
}
