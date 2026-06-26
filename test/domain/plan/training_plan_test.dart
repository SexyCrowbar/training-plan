import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/domain/plan/models.dart';
import 'package:protocol/domain/plan/training_plan.dart';

void main() {
  group('TrainingPlan (7-day)', () {
    test('has exactly 7 days numbered 1..7', () {
      expect(TrainingPlan.days.length, 7);
      expect(TrainingPlan.days.keys.toList()..sort(), [1, 2, 3, 4, 5, 6, 7]);
    });

    test('gtg targets follow the plan', () {
      final targets = [for (var i = 1; i <= 7; i++) TrainingPlan.days[i]!.gtgTarget];
      expect(targets, [5, 5, 5, 4, 5, 3, 0]);
    });

    test('themes: recovery on 4 & 6, rest on 7', () {
      expect(TrainingPlan.days[4]!.theme, DayTheme.recovery);
      expect(TrainingPlan.days[6]!.theme, DayTheme.recovery);
      expect(TrainingPlan.days[7]!.theme, DayTheme.rest);
      expect(TrainingPlan.days[7]!.isRestDay, isTrue);
      expect(TrainingPlan.days[4]!.isRestDay, isFalse);
    });

    test('day 4 has a single recovery block; days 6 & 7 have none', () {
      expect(TrainingPlan.days[4]!.blocks.length, 1);
      expect(TrainingPlan.days[6]!.blocks, isEmpty);
      expect(TrainingPlan.days[7]!.blocks, isEmpty);
    });

    test('training days carry power exercises', () {
      for (final id in [1, 2, 3, 5]) {
        final power = TrainingPlan.days[id]!.blocks.firstWhere((b) => b.id == 'power');
        expect(power.exercises, isNotEmpty, reason: 'day $id power');
      }
    });
  });
}
