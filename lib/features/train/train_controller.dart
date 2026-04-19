import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../domain/plan/models.dart';

/// Auto-advance to the first incomplete day when the app first loads data.
/// Ported from `src/App.jsx:39-54`.
final trainAutoAdvanceProvider = Provider<void>((ref) {
  final template = ref.watch(activeTemplateProvider).valueOrNull;
  final done = ref.watch(doneBlocksProvider).valueOrNull;
  if (template == null || done == null) return;

  for (var d = 1; d <= 5; d++) {
    final blocks = template.byDayBlock[d];
    if (blocks == null) continue;
    final totalWithExercises = kBlockIds
        .where((id) => (blocks[id] ?? const []).isNotEmpty)
        .toList();
    if (totalWithExercises.isEmpty) continue; // rest day or empty day
    final doneForDay = done[d] ?? const <String>{};
    if (doneForDay.length < totalWithExercises.length) {
      final notifier = ref.read(currentDayProvider.notifier);
      if (notifier.state != d) notifier.state = d;
      return;
    }
  }
});
