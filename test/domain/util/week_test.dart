import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/domain/util/week.dart';

void main() {
  group('effectiveWeekStart', () {
    test('returns the stored value when provided', () {
      expect(effectiveWeekStart('2026-04-20'), '2026-04-20');
    });

    test('returns todayKey when stored is null', () {
      expect(effectiveWeekStart(null), todayKey());
    });

    test('returns todayKey when stored is empty string', () {
      expect(effectiveWeekStart(''), todayKey());
    });
  });

  group('dateKey / parseDateKey', () {
    test('round-trips a date', () {
      final d = DateTime(2026, 4, 24);
      expect(parseDateKey(dateKey(d)), d);
    });
  });
}
