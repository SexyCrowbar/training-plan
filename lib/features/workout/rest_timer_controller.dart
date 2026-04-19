import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestTimerState {
  final int remainingSeconds;
  final int totalSeconds;
  final bool running;

  const RestTimerState({
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.running,
  });

  double get progress => totalSeconds == 0 ? 0 : remainingSeconds / totalSeconds;
  bool get isActive => running && remainingSeconds > 0;

  const RestTimerState.idle() : remainingSeconds = 0, totalSeconds = 0, running = false;

  RestTimerState copyWith({int? remainingSeconds, int? totalSeconds, bool? running}) =>
      RestTimerState(
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        running: running ?? this.running,
      );
}

class RestTimerController extends StateNotifier<RestTimerState> {
  RestTimerController() : super(const RestTimerState.idle());

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
    StateNotifierProvider<RestTimerController, RestTimerState>((ref) => RestTimerController());
