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

    test('counts up over the 7-day cycle and wraps', () async {
      final now = DateTime.now();
      DateTime ago(int days) =>
          DateTime(now.year, now.month, now.day).subtract(Duration(days: days));

      Future<int> dayFor(DateTime weekStart) async {
        final c = ProviderContainer(overrides: [
          weekStartProvider.overrideWith((ref) async* {
            yield dateKey(weekStart);
          }),
        ]);
        addTearDown(c.dispose);
        await c.read(weekStartProvider.future);
        return c.read(derivedDayProvider);
      }

      expect(await dayFor(ago(3)), 4); // day 4 (recovery)
      expect(await dayFor(ago(6)), 7); // day 7 (rest)
      expect(await dayFor(ago(7)), 1); // wraps to day 1
      expect(await dayFor(ago(13)), 7);
    });
  });
}
