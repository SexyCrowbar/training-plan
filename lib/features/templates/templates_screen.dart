import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app_providers.dart';
import '../../data/db/app_database.dart';
import '../../data/repositories/settings_repository.dart';
import '../../widgets/confirm_modal.dart';

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(allTemplatesProvider).valueOrNull ?? const [];
    final activeId = ref.watch(activeTemplateIdProvider).valueOrNull;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New'),
        onPressed: () => _createTemplate(context, ref),
      ),
      body: templates.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final t = templates[i];
                final active = t.id == activeId;
                return Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push('/templates/${t.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        t.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (active)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.primary.withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.8,
                                            color: scheme.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  'Updated ${DateFormat('d MMM yyyy').format(
                                    DateTime.fromMillisecondsSinceEpoch(t.updatedAt),
                                  )}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: scheme.onSurface.withValues(alpha: 0.55),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (action) =>
                                _onAction(context, ref, action, t, active),
                            itemBuilder: (_) => [
                              if (!active)
                                const PopupMenuItem(
                                  value: 'activate',
                                  child: Text('Set active'),
                                ),
                              const PopupMenuItem(
                                value: 'rename',
                                child: Text('Rename'),
                              ),
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Text('Duplicate'),
                              ),
                              if (!active)
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    Template t,
    bool active,
  ) async {
    final repo = ref.read(templateRepositoryProvider);
    final settings = ref.read(settingsRepositoryProvider);
    switch (action) {
      case 'activate':
        await settings.setInt(SettingsKeys.activeTemplateId, t.id);
        break;
      case 'rename':
        final name = await _promptName(context, initial: t.name, title: 'Rename template');
        if (name != null && name.isNotEmpty) await repo.rename(t.id, name);
        break;
      case 'duplicate':
        await repo.duplicate(t.id, '${t.name} copy');
        break;
      case 'delete':
        final ok = await showConfirmModal(
          context: context,
          title: 'Delete template?',
          message: 'Workout history stays, but this template will be gone.',
          confirmLabel: 'Delete',
          danger: true,
        );
        if (ok) await repo.delete(t.id);
        break;
    }
  }

  Future<void> _createTemplate(BuildContext context, WidgetRef ref) async {
    final name = await _promptName(context, initial: '', title: 'New template');
    if (name == null || name.isEmpty) return;
    final repo = ref.read(templateRepositoryProvider);
    final newId = await repo.createEmpty(name);
    if (context.mounted) context.push('/templates/$newId');
  }
}

Future<String?> _promptName(
  BuildContext context, {
  required String initial,
  required String title,
}) async {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Template name'),
        onSubmitted: (v) => Navigator.of(context).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
