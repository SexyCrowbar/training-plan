import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';
import '../theme/tokens.dart';

class DayTabs extends ConsumerWidget {
  const DayTabs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentDayProvider);
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.sm),
        itemBuilder: (context, i) {
          final dayId = i + 1;
          final selected = dayId == current;
          final label = dayId == 7 ? 'Rest' : 'Day $dayId';
          return GestureDetector(
            onTap: () => ref.read(currentDayProvider.notifier).state = dayId,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.lg,
                vertical: Spacing.md,
              ),
              decoration: BoxDecoration(
                color: selected ? scheme.primary : scheme.surface,
                borderRadius: BorderRadius.circular(Radii.pill),
                border: Border.all(
                  color: selected
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
