import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/domain/plan/training_plan.dart';
import 'package:protocol/domain/util/week.dart';
import 'package:protocol/notifications/reminder_scheduler.dart';

void main() {
  group('ReminderScheduler.rotationDayId', () {
    test('matches dayOfCycle / derivedDay math for a fortnight', () {
      const weekStart = '2026-06-27';
      final start = parseDateKey(weekStart);
      for (var i = 0; i < 14; i++) {
        final day = start.add(Duration(days: i));
        expect(
          ReminderScheduler.rotationDayId(day, weekStart),
          dayOfCycle(day, start),
        );
      }
    });

    test(
      'only the full-rest day (7) suppresses; recovery day (4) still fires',
      () {
        const weekStart = '2026-06-27';
        final start = parseDateKey(weekStart);

        final restDay = start.add(const Duration(days: 6)); // => day 7
        final d7 = ReminderScheduler.rotationDayId(restDay, weekStart);
        expect(d7, 7);
        expect(TrainingPlan.days[d7]!.gtgTarget, 0);

        final recDay = start.add(const Duration(days: 3)); // => day 4
        final d4 = ReminderScheduler.rotationDayId(recDay, weekStart);
        expect(d4, 4);
        expect(TrainingPlan.days[d4]!.gtgTarget, greaterThan(0));
      },
    );
  });
}
