import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/plan/models.dart';
import '../../domain/util/week.dart';
import '../../theme/colors.dart';
import '../../widgets/block_card.dart';
import '../../widgets/day_tabs.dart';
import '../../widgets/gtg_counter.dart';
import '../settings/import_export_controller.dart';
import '../templates/widgets/template_picker_sheet.dart';

class TrainScreen extends ConsumerWidget {
  const TrainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Re-sync the displayed day to today's derived day only when the ticker
    // fires (midnight crossing) or weekStart changes (Start new week). App
    // lifecycle transitions (minimize/resume/switch) must NOT reset the day —
    // manual day-tab taps stay in effect until one of those two events.
    ref.listen<int>(derivedDayProvider, (prev, next) {
      if (prev != next) {
        ref.read(currentDayProvider.notifier).state = next;
      }
    });

    // historyAutoSeedProvider transitively awaits seedBootProvider, so
    // watching it covers both first-launch seeds in one boot gate.
    final boot = ref.watch(historyAutoSeedProvider);
    if (boot.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final template = ref.watch(activeTemplateProvider).valueOrNull;
    final templates =
        ref.watch(allTemplatesProvider).valueOrNull ?? const <Template>[];
    final activeId = ref.watch(activeTemplateIdProvider).valueOrNull;
    final meta = ref.watch(currentDayMetaProvider);
    final done =
        ref.watch(doneBlocksProvider).valueOrNull?[meta.id] ?? const <String>{};
    // Blocks that have at least one exercise. Doubles as the recovery-day
    // detector: when this is empty on a non-rest day (e.g. Day 6), the screen
    // shows an active-recovery note instead of block cards.
    final populatedBlocks = [
      for (final b in kBlockIds)
        if ((template?.exercisesFor(meta.id, b) ?? const []).isNotEmpty) b,
    ];
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.name,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          Text(
                            meta.tag,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurface.withValues(alpha: 0.6),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TemplateChip(
                      templates: templates,
                      activeId: activeId,
                      activeName: template?.template.name,
                      onPicked: (picked) async {
                        await ref
                            .read(settingsRepositoryProvider)
                            .setInt(SettingsKeys.activeTemplateId, picked.id);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            const SliverToBoxAdapter(child: DayTabs()),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (!meta.isRestDay)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: GtgCounter()),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            if (meta.isRestDay)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Full rest day — recovery & reset.\nNo training today.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              )
            else if (populatedBlocks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Active recovery — walk, stretch, light mobility.\n'
                    'Keep your GtG sets going, but nothing to log today.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Builder(
                    builder: (context) {
                      final doneCount = populatedBlocks
                          .where(done.contains)
                          .length;
                      final total = populatedBlocks.length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$doneCount / $total done',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.textMid,
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: total == 0 ? 0 : doneCount / total,
                            minHeight: 4,
                            color: scheme.primary,
                            backgroundColor: scheme.primary.withValues(
                              alpha: 0.15,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.separated(
                  itemCount: populatedBlocks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final blockId = populatedBlocks[i];
                    final exercises =
                        template?.exercisesFor(meta.id, blockId) ?? const [];
                    return BlockCard(
                      blockId: blockId,
                      exercises: exercises,
                      done: done.contains(blockId),
                      onTap: () => context.push('/workout/${meta.id}/$blockId'),
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart cycle (Day 1 today)'),
                  onPressed: () =>
                      _startNewWeek(context, ref, templates, activeId),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Future<void> _startNewWeek(
    BuildContext context,
    WidgetRef ref,
    List<Template> templates,
    int? currentActiveId,
  ) async {
    final result = await showDialog<_NewWeekResult>(
      context: context,
      builder: (context) => _NewWeekDialog(
        templates: templates,
        initialTemplateId: currentActiveId,
      ),
    );
    if (result == null) return;

    final settings = ref.read(settingsRepositoryProvider);
    if (result.templateId != null) {
      await settings.setInt(SettingsKeys.activeTemplateId, result.templateId!);
    }
    await settings.set(SettingsKeys.weekStartDate, todayKey());
    ref.read(currentDayProvider.notifier).state = 1;
  }
}

class _TemplateChip extends StatelessWidget {
  final List<Template> templates;
  final int? activeId;
  final String? activeName;
  final void Function(Template) onPicked;

  const _TemplateChip({
    required this.templates,
    required this.activeId,
    required this.activeName,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = activeName ?? 'Default';
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final picked = await showTemplatePickerSheet(
          context: context,
          templates: templates,
          activeId: activeId,
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: scheme.onSurface),
          ],
        ),
      ),
    );
  }
}

class _NewWeekResult {
  final int? templateId;
  _NewWeekResult({this.templateId});
}

class _NewWeekDialog extends StatefulWidget {
  final List<Template> templates;
  final int? initialTemplateId;
  const _NewWeekDialog({
    required this.templates,
    required this.initialTemplateId,
  });

  @override
  State<_NewWeekDialog> createState() => _NewWeekDialogState();
}

class _NewWeekDialogState extends State<_NewWeekDialog> {
  int? _templateId;

  @override
  void initState() {
    super.initState();
    _templateId = widget.initialTemplateId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restart the cycle?'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Resets to Day 1 today. Block checkmarks reset; workout history is kept.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Template for this week:',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _templateId,
            isExpanded: true,
            items: [
              for (final t in widget.templates)
                DropdownMenuItem(value: t.id, child: Text(t.name)),
            ],
            onChanged: (v) => setState(() => _templateId = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(_NewWeekResult(templateId: _templateId)),
          child: const Text('Start fresh'),
        ),
      ],
    );
  }
}
