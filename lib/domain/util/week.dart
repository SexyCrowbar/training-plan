// Date helpers ported from `src/hooks/useDailyState.js:6-20`.

String _pad(int n) => n.toString().padLeft(2, '0');

String dateKey(DateTime d) {
  final local = d.toLocal();
  return '${local.year}-${_pad(local.month)}-${_pad(local.day)}';
}

String todayKey() => dateKey(DateTime.now());

/// Effective week-start: the stored value, or today as the default.
/// A fresh install lands on day 1 of the plan because (today - today).inDays == 0,
/// which the derivedDayProvider clamps to day 1.
String effectiveWeekStart(String? stored) {
  if (stored != null && stored.isNotEmpty) return stored;
  return todayKey();
}

/// Parse "YYYY-MM-DD" to a DateTime at local midnight (00:00).
DateTime parseDateKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

/// Day of the 7-day training cycle (1..7) for [day], anchored to [weekStart].
/// Wraps continuously, so day 8 == day 1. Dart's `%` is non-negative for a
/// positive divisor, so no guard is needed for `day` before `weekStart`.
int dayOfCycle(DateTime day, DateTime weekStart) {
  final d = DateTime(day.year, day.month, day.day);
  final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
  final diff = d.difference(start).inDays;
  return (diff % 7) + 1;
}
