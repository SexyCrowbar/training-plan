import 'package:flutter/material.dart';

import '../data/db/app_database.dart';
import '../domain/plan/models.dart';
import '../theme/colors.dart';
import '../theme/tokens.dart';

class BlockCard extends StatelessWidget {
  final String blockId;
  final List<TemplateExercise> exercises;
  final bool done;
  final VoidCallback onTap;

  const BlockCard({
    super.key,
    required this.blockId,
    required this.exercises,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = kBlockIcons[blockId] ?? '•';
    final name = kBlockNames[blockId] ?? blockId;
    final empty = exercises.isEmpty;

    final cardBg = done
        ? Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.10),
            scheme.surface,
          )
        : scheme.surface;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(Radii.card),
      child: InkWell(
        onTap: empty ? null : onTap,
        borderRadius: BorderRadius.circular(Radii.card),
        child: Container(
          decoration: done
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(Radii.card),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.4),
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                          if (exercises.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                exercises.map((e) => e.name).join(' · '),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.textMid,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (done)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: Spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(Radii.chip),
                        ),
                        child: Text(
                          'DONE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: scheme.primary,
                          ),
                        ),
                      )
                    else if (empty)
                      Text(
                        'empty',
                        style: TextStyle(fontSize: 11, color: scheme.textMid),
                      )
                    else
                      Icon(
                        Icons.chevron_right,
                        color: scheme.onSurface.withValues(alpha: 0.5),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
