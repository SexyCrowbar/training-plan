import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/history/history_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stats/stats_screen.dart';
import 'features/templates/template_editor_screen.dart';
import 'features/templates/templates_screen.dart';
import 'features/train/train_screen.dart';
import 'features/workout/workout_screen.dart';
import 'widgets/bottom_nav.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNav(
              currentLocation: state.matchedLocation,
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TrainScreen()),
          ),
          GoRoute(
            path: '/stats',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: StatsScreen()),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            path: '/templates',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TemplatesScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/workout/:dayId/:blockId',
        builder: (context, state) {
          final dayId = int.parse(state.pathParameters['dayId']!);
          final blockId = state.pathParameters['blockId']!;
          return WorkoutScreen(dayId: dayId, blockId: blockId);
        },
      ),
      GoRoute(
        path: '/templates/:templateId',
        builder: (context, state) {
          final templateId = int.parse(state.pathParameters['templateId']!);
          return TemplateEditorScreen(templateId: templateId);
        },
      ),
    ],
  );
});
