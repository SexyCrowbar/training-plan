import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';

class GtgCounter extends ConsumerWidget {
  const GtgCounter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.watch(currentDayMetaProvider);
    final counts = ref.watch(todayGtgProvider).valueOrNull ?? const {};
    final count = counts[meta.id] ?? 0;
    final scheme = Theme.of(context).colorScheme;
    final gtg = ref.read(gtgRepositoryProvider);
    final disabled = meta.isRestDay;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meta.gtgEx,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            if (meta.gtgTarget > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Target: ${meta.gtgTarget} sets today',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                _RoundButton(
                  icon: Icons.remove,
                  onTap: disabled || count == 0
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          gtg.adjust(meta.id, -1);
                        },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: disabled
                              ? scheme.onSurface.withValues(alpha: 0.3)
                              : scheme.primary,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (meta.gtgTarget > 0)
                        Wrap(
                          spacing: 4,
                          children: List.generate(
                            meta.gtgTarget,
                            (i) => Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i < count
                                    ? scheme.primary
                                    : scheme.onSurface.withValues(alpha: 0.2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _RoundButton(
                  icon: Icons.add,
                  onTap: disabled
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          gtg.adjust(meta.id, 1);
                        },
                  filled: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;

  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;
    final bg = filled ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = filled ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: enabled ? bg : bg.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: enabled ? fg : fg.withValues(alpha: 0.4),
            size: 24,
          ),
        ),
      ),
    );
  }
}
