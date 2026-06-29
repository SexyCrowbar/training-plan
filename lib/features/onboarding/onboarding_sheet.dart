import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../data/repositories/settings_repository.dart';
import '../../notifications/notification_helper.dart';
import '../../notifications/reminder_scheduler.dart';
import '../../theme/colors.dart';

/// One-time first-run intro sheet. Shows the 7-day rotation overview and
/// offers a single-tap to enable GTG reminders.
///
/// Callers must NOT make this sheet dismissible by back-swipe because the
/// caller already persists [SettingsKeys.onboardingSeen] before showing —
/// pass `isDismissible: false` and `enableDrag: false` to [showModalBottomSheet].
class OnboardingSheet extends ConsumerStatefulWidget {
  const OnboardingSheet({super.key});

  @override
  ConsumerState<OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends ConsumerState<OnboardingSheet> {
  bool _loading = false;

  Future<void> _enableReminders() async {
    setState(() => _loading = true);
    try {
      final granted = await NotificationHelper.requestPermissions();
      if (!mounted) return;
      if (granted) {
        final settings = ref.read(settingsRepositoryProvider);
        await settings.setBool(SettingsKeys.remindersEnabled, true);
        // Ensure default window hours exist so the scheduler has valid values.
        final startHour = await settings.getInt(SettingsKeys.startHour);
        if (startHour == null) {
          await settings.setInt(SettingsKeys.startHour, 9);
        }
        final endHour = await settings.getInt(SettingsKeys.endHour);
        if (endHour == null) {
          await settings.setInt(SettingsKeys.endHour, 18);
        }
        await ReminderScheduler.scheduleNext(
          enabled: true,
          startHour: startHour ?? 9,
          endHour: endHour ?? 18,
        );
      }
    } finally {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle indicator
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to Protocol',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your 7-day rotation',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: scheme.textHi),
            ),
            const SizedBox(height: 8),
            Text(
              'Days 1–3 & 5 are full training days. '
              'Days 4 & 6 are active recovery — light movement only, no logging. '
              'Day 7 is complete rest. The cycle then repeats.',
              style: TextStyle(
                fontSize: 14,
                color: scheme.textMid,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Grease the Groove (GTG)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: scheme.textHi),
            ),
            const SizedBox(height: 8),
            Text(
              'Spread a handful of easy, sub-maximal sets through your day — '
              'never to failure, never fatiguing. GTG builds practice volume without '
              'recovery cost. Tap the counter on the main screen to log each set. '
              'Hourly reminders keep you on track.',
              style: TextStyle(
                fontSize: 14,
                color: scheme.textMid,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _loading ? null : _enableReminders,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enable reminders'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: const Text('Maybe later'),
            ),
          ],
        ),
      ),
    );
  }
}
