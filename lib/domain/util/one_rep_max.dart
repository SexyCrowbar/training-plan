/// Epley formula, ported from `src/components/StatsScreen.jsx:11-16`.
/// Returns estimated 1RM rounded to 0.1 kg, or null when inputs are invalid.
double? estimatedOneRepMax(double? weight, int? reps) {
  if (weight == null || reps == null || weight <= 0 || reps <= 0) return null;
  return ((weight * (1 + reps / 30)) * 10).round() / 10;
}
