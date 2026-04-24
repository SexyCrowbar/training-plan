import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../app_providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../notifications/notification_helper.dart';
import '../../notifications/reminder_scheduler.dart';
import '../../widgets/confirm_modal.dart';
import 'import_export_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsRepositoryProvider);
    final enabled = ref.watch(_remindersEnabledProvider).valueOrNull ?? false;
    final startHour = ref.watch(_startHourProvider).valueOrNull ?? 9;
    final endHour = ref.watch(_endHourProvider).valueOrNull ?? 18;
    final restAlertEnabled = ref.watch(_restAlertEnabledProvider).valueOrNull ?? true;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Card(
            child: SwitchListTile(
              title: const Text('GTG hourly reminders'),
              subtitle: const Text('Hourly notification to do a quick set within your active window.'),
              value: enabled,
              onChanged: (v) async {
                if (v) {
                  final granted = await _requestPermissions();
                  if (!granted) return;
                }
                await settings.setBool(SettingsKeys.remindersEnabled, v);
                await ReminderScheduler.scheduleNext(
                  enabled: v,
                  startHour: startHour,
                  endHour: endHour,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active hours',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reminders only fire between these hours.',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _HourPicker(
                          label: 'Start',
                          hour: startHour,
                          onChanged: (h) async {
                            await settings.setInt(SettingsKeys.startHour, h);
                            if (enabled) {
                              await ReminderScheduler.scheduleNext(
                                enabled: true,
                                startHour: h,
                                endHour: endHour,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HourPicker(
                          label: 'End',
                          hour: endHour,
                          onChanged: (h) async {
                            await settings.setInt(SettingsKeys.endHour, h);
                            if (enabled) {
                              await ReminderScheduler.scheduleNext(
                                enabled: true,
                                startHour: startHour,
                                endHour: h,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PreviewRow(startHour: startHour, endHour: endHour),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Test reminder now'),
                  subtitle: const Text('Posts a notification immediately.'),
                  trailing: const Icon(Icons.notifications_active),
                  onTap: () async {
                    final granted = await _requestPermissions();
                    if (granted) {
                      await NotificationHelper.postGtgReminder();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: SwitchListTile(
              title: const Text('Rest timer alert'),
              subtitle: const Text(
                'Sound + notification when rest ends (while app is backgrounded).',
              ),
              value: restAlertEnabled,
              onChanged: (v) async {
                if (v) {
                  final granted = await NotificationHelper.requestPermissions();
                  if (!granted) return;
                }
                await settings.setBool(SettingsKeys.restTimerAlertEnabled, v);
              },
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Data',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                ListTile(
                  title: const Text('Import from web app'),
                  subtitle: const Text(
                    'Pick a history.json or state.json file exported from the old PWA.',
                  ),
                  trailing: const Icon(Icons.file_upload),
                  onTap: () => _import(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Export history.json'),
                  subtitle: const Text('Save workout logs as JSON.'),
                  trailing: const Icon(Icons.save_alt),
                  onTap: () => _exportHistory(context, ref),
                ),
                ListTile(
                  title: const Text('Export state.json'),
                  subtitle: const Text('Save GTG counts + week-start.'),
                  trailing: const Icon(Icons.save_alt),
                  onTap: () => _exportState(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(importExportControllerProvider);
    final text = await ctrl.pickJsonText();
    if (text == null || !context.mounted) return;
    try {
      final trimmed = text.trimLeft();
      if (trimmed.startsWith('[')) {
        final stats = await ctrl.importHistory(text);
        if (!context.mounted) return;
        await showInfoModal(
          context: context,
          title: 'Import complete',
          message:
              'Imported ${stats.logs} workout log${stats.logs == 1 ? '' : 's'} '
              '(${stats.sets} sets).',
        );
      } else {
        final stats = await ctrl.importState(text);
        if (!context.mounted) return;
        await showInfoModal(
          context: context,
          title: 'Import complete',
          message:
              'Imported ${stats.rows} GTG count row${stats.rows == 1 ? '' : 's'}'
              '${stats.weekStartApplied ? '. Week start updated.' : '.'}',
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      await showInfoModal(
        context: context,
        title: 'Import failed',
        message: '$e',
      );
    }
  }

  Future<void> _exportHistory(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(importExportControllerProvider);
    final json = await ctrl.buildHistoryJson();
    final path = await ctrl.saveToFile(
      suggestedName: 'history.json',
      content: json,
    );
    if (!context.mounted || path == null) return;
    await showInfoModal(
      context: context,
      title: 'Exported',
      message: 'Saved to:\n$path',
    );
  }

  Future<void> _exportState(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(importExportControllerProvider);
    final json = await ctrl.buildStateJson();
    final path = await ctrl.saveToFile(
      suggestedName: 'state.json',
      content: json,
    );
    if (!context.mounted || path == null) return;
    await showInfoModal(
      context: context,
      title: 'Exported',
      message: 'Saved to:\n$path',
    );
  }

  Future<bool> _requestPermissions() async {
    final notifGranted = await NotificationHelper.requestPermissions();
    if (!notifGranted) return false;
    // SCHEDULE_EXACT_ALARM on Android 12+
    final exactStatus = await Permission.scheduleExactAlarm.request();
    return exactStatus.isGranted || exactStatus.isLimited;
  }
}

final _remindersEnabledProvider = StreamProvider<bool>((ref) {
  return ref.watch(settingsRepositoryProvider).watchBool(SettingsKeys.remindersEnabled);
});
final _restAlertEnabledProvider = StreamProvider<bool>((ref) {
  return ref
      .watch(settingsRepositoryProvider)
      .watchBool(SettingsKeys.restTimerAlertEnabled, defaultValue: true);
});
final _startHourProvider = StreamProvider<int>((ref) async* {
  final stream = ref.watch(settingsRepositoryProvider).watchInt(SettingsKeys.startHour);
  await for (final v in stream) {
    yield v ?? 9;
  }
});
final _endHourProvider = StreamProvider<int>((ref) async* {
  final stream = ref.watch(settingsRepositoryProvider).watchInt(SettingsKeys.endHour);
  await for (final v in stream) {
    yield v ?? 18;
  }
});

class _HourPicker extends StatelessWidget {
  final String label;
  final int hour;
  final ValueChanged<int> onChanged;
  const _HourPicker({required this.label, required this.hour, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: 0),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked.hour);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final int startHour;
  final int endHour;
  const _PreviewRow({required this.startHour, required this.endHour});

  @override
  Widget build(BuildContext context) {
    final hours = <int>[];
    if (endHour > startHour) {
      for (var h = startHour; h < endHour; h++) hours.add(h);
    }
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final h in hours)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${h.toString().padLeft(2, '0')}:00',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ),
        if (hours.isEmpty)
          Text(
            'End must be after start.',
            style: TextStyle(
              fontSize: 12,
              color: scheme.error,
            ),
          ),
      ],
    );
  }
}
