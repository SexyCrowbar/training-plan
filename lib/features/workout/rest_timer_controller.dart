import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../notifications/notification_helper.dart';

class RestTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool running;

  const RestTimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.running,
  });

  double get progress =>
      totalSeconds == 0 ? 0 : remainingSeconds / totalSeconds;
  bool get isActive => running && remainingSeconds > 0;

  const RestTimerState.idle()
    : remainingSeconds = 0,
      totalSeconds = 0,
      running = false;

  RestTimerState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? running,
  }) => RestTimerState(
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    totalSeconds: totalSeconds ?? this.totalSeconds,
    running: running ?? this.running,
  );
}

class RestTimerController extends StateNotifier<RestTimerState> {
  RestTimerController({this.onExpired}) : super(const RestTimerState.idle());

  final Future<void> Function()? onExpired;
  Timer? _timer;

  void start(int seconds) {
    if (seconds <= 0) {
      stop();
      return;
    }
    _timer?.cancel();
    state = RestTimerState(
      remainingSeconds: seconds,
      totalSeconds: seconds,
      running: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final next = state.remainingSeconds - 1;
      if (next <= 0) {
        _timer?.cancel();
        HapticFeedback.mediumImpact();
        state = state.copyWith(remainingSeconds: 0, running: false);
        onExpired?.call();
      } else {
        state = state.copyWith(remainingSeconds: next);
      }
    });
  }

  void stop() {
    _timer?.cancel();
    state = const RestTimerState.idle();
  }

  void skip() {
    _timer?.cancel();
    state = state.copyWith(remainingSeconds: 0, running: false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerController, RestTimerState>((ref) {
      return RestTimerController(
        onExpired: () async {
          final lifecycle = ref.read(appLifecycleProvider);
          if (lifecycle == AppLifecycleState.resumed) return;
          final enabled = await ref
              .read(settingsRepositoryProvider)
              .getBool(SettingsKeys.restTimerAlertEnabled, defaultValue: true);
          if (!enabled) return;
          await NotificationHelper.postRestTimerAlert();
        },
      );
    });
