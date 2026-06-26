import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/domain/plan/models.dart';
import 'package:protocol/theme/colors.dart';

void main() {
  test('buildTheme covers all DayThemes incl. recovery', () {
    for (final t in DayTheme.values) {
      final theme = buildTheme(t);
      expect(theme.colorScheme, isNotNull, reason: t.name);
    }
  });

  test('recovery theme uses the emerald primary', () {
    final theme = buildTheme(DayTheme.recovery);
    expect(theme.colorScheme.primary, AppColors.recoveryPrimary);
    expect(theme.scaffoldBackgroundColor, AppColors.recoveryBackground);
  });
}
