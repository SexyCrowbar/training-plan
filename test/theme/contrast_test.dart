import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/domain/plan/models.dart';
import 'package:protocol/theme/colors.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('onSurfaceMid WCAG AA contrast', () {
    for (final t in DayTheme.values) {
      test('${t.name}: onSurfaceMid >= 4.5:1 on surface and scaffold', () {
        final theme = buildTheme(t);
        expect(
          _contrast(AppColors.onSurfaceMid, theme.colorScheme.surface),
          greaterThanOrEqualTo(4.5),
          reason: '${t.name} surface',
        );
        expect(
          _contrast(AppColors.onSurfaceMid, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
          reason: '${t.name} scaffold',
        );
      });
    }
  });

  group('Regression: old blended muted color fails AA', () {
    test('iron: onSurface.withValues(alpha:0.35) blended on surface < 4.5', () {
      final theme = buildTheme(DayTheme.iron);
      final blended = Color.alphaBlend(
        AppColors.onSurfaceHi.withValues(alpha: 0.35),
        theme.colorScheme.surface,
      );
      expect(
        _contrast(blended, theme.colorScheme.surface),
        lessThan(4.5),
        reason: 'alpha:0.35 blend should fail WCAG AA — verifying old code was broken',
      );
    });
  });

  group('TextEmphasis extension', () {
    test('textMid == AppColors.onSurfaceMid for iron theme', () {
      final theme = buildTheme(DayTheme.iron);
      expect(theme.colorScheme.textMid, AppColors.onSurfaceMid);
    });
  });
}
