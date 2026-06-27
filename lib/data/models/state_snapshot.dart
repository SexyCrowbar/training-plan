/// Mirrors the JSON shape from `src/hooks/useDailyState.js:24` — the daily
/// state blob the React app persists to `data/state.json`. Used for one-shot
/// import/export.
///
/// Example:
/// ```json
/// {
///   "gtg": { "2026-04-18": { "2": 2 } },
///   "weekStartDate": "2026-04-13"
/// }
/// ```
///
/// [weekStartDate] was persisted in `localStorage` by the React app — it may
/// be absent from older `state.json` files. When absent, import callers should
/// leave the existing DB value alone.
class StateSnapshot {
  /// Map of `YYYY-MM-DD` → `dayId` → count.
  final Map<String, Map<int, int>> gtg;
  final String? weekStartDate;

  StateSnapshot({required this.gtg, this.weekStartDate});

  factory StateSnapshot.fromJson(Map<String, dynamic> json) {
    final rawGtg = json['gtg'] as Map<String, dynamic>? ?? const {};
    final gtg = <String, Map<int, int>>{};
    rawGtg.forEach((dateKey, dayMap) {
      final inner = (dayMap as Map).cast<String, dynamic>();
      gtg[dateKey] = {
        for (final entry in inner.entries)
          int.parse(entry.key): (entry.value as num).toInt(),
      };
    });
    return StateSnapshot(
      gtg: gtg,
      weekStartDate: json['weekStartDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'gtg': {
      for (final entry in gtg.entries)
        entry.key: {
          for (final inner in entry.value.entries)
            inner.key.toString(): inner.value,
        },
    },
    if (weekStartDate != null) 'weekStartDate': weekStartDate,
  };
}
