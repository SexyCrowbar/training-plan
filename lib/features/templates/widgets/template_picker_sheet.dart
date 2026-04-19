import 'package:flutter/material.dart';

import '../../../data/db/app_database.dart';

/// Bottom sheet that lets the user pick the active template.
/// Returns the selected [Template] or null if dismissed.
Future<Template?> showTemplatePickerSheet({
  required BuildContext context,
  required List<Template> templates,
  required int? activeId,
}) {
  return showModalBottomSheet<Template>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final scheme = Theme.of(context).colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Active template',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            for (final t in templates)
              ListTile(
                leading: Icon(
                  t.id == activeId
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: scheme.primary,
                ),
                title: Text(t.name),
                onTap: () => Navigator.of(context).pop(t),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
