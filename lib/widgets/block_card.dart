import 'package:flutter/material.dart';

import '../data/db/app_database.dart';
import '../domain/plan/models.dart';
import '../theme/colors.dart';

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

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: empty ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
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
    );
  }
}
