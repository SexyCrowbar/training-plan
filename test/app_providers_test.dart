import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/app_providers.dart';
import 'package:protocol/domain/util/week.dart';

void main() {
  group('derivedDayProvider', () {
    test('returns 1 when weekStart is today', () async {
      final container = ProviderContainer(overrides: [
        weekStartProvider.overrideWith((ref) async* {
          yield todayKey();
        }),
      ]);
      addTearDown(container.dispose);

      // Wait for the stream to emit.
      await container.read(weekStartProvider.future);
      expect(container.read(derivedDayProvider), 1);
    });

    test('returns (diff + 1) when weekStart is N days ago, clamped to 5', () async {
      final now = DateTime.now();
      final threeDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3));
      final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));

      final c3 = ProviderContainer(overrides: [
        weekStartProvider.overrideWith((ref) async* {
          yield dateKey(threeDaysAgo);
        }),
      ]);
      addTearDown(c3.dispose);
      await c3.read(weekStartProvider.future);
      expect(c3.read(derivedDayProvider), 4);

      final c7 = ProviderContainer(overrides: [
        weekStartProvider.overrideWith((ref) async* {
          yield dateKey(sevenDaysAgo);
        }),
      ]);
      addTearDown(c7.dispose);
      await c7.read(weekStartProvider.future);
      expect(c7.read(derivedDayProvider), 5);
    });
  });
}
