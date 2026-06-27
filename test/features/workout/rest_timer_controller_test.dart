import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/features/workout/rest_timer_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('RestTimerController', () {
    test('onExpired fires exactly once when the timer reaches zero', () {
      fakeAsync((async) {
        var calls = 0;
        final ctrl = RestTimerController(
          onExpired: () async {
            calls++;
          },
        );

        ctrl.start(3);
        // Advance past the full duration.
        async.elapse(const Duration(seconds: 4));

        expect(calls, 1);
        expect(ctrl.state.running, isFalse);
        expect(ctrl.state.remainingSeconds, 0);
      });
    });

    test('skip() does not trigger onExpired', () {
      fakeAsync((async) {
        var calls = 0;
        final ctrl = RestTimerController(
          onExpired: () async {
            calls++;
          },
        );

        ctrl.start(10);
        async.elapse(const Duration(seconds: 2));
        ctrl.skip();
        async.elapse(const Duration(seconds: 20));

        expect(calls, 0);
      });
    });

    test('onExpired null (legacy construction) does not throw', () {
      fakeAsync((async) {
        final ctrl = RestTimerController();
        ctrl.start(1);
        async.elapse(const Duration(seconds: 2));
        expect(ctrl.state.running, isFalse);
      });
    });
  });
}
