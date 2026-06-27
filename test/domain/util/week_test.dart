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

  group('dayOfCycle', () {
    DateTime d(int y, int m, int day) => DateTime(y, m, day);

    test('day 0 from start is day 1', () {
      expect(dayOfCycle(d(2026, 6, 27), d(2026, 6, 27)), 1);
    });

    test('counts up through day 7', () {
      final start = d(2026, 6, 27);
      expect(dayOfCycle(d(2026, 6, 28), start), 2);
      expect(dayOfCycle(d(2026, 6, 30), start), 4);
      expect(dayOfCycle(d(2026, 7, 3), start), 7); // +6 days
    });

    test('wraps after day 7', () {
      final start = d(2026, 6, 27);
      expect(dayOfCycle(d(2026, 7, 4), start), 1); // +7 days wraps
      expect(dayOfCycle(d(2026, 7, 10), start), 7); // +13 days
      expect(dayOfCycle(d(2026, 7, 11), start), 1); // +14 days
    });

    test('ignores time-of-day component', () {
      expect(
        dayOfCycle(DateTime(2026, 6, 28, 23, 59), DateTime(2026, 6, 27, 0, 1)),
        2,
      );
    });
  });
}
