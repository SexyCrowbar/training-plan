import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNav extends StatelessWidget {
  final String currentLocation;
  const BottomNav({super.key, required this.currentLocation});

  static const _destinations = [
    ('/', Icons.fitness_center, 'Train'),
    ('/stats', Icons.show_chart, 'Stats'),
    ('/history', Icons.history, 'History'),
    ('/templates', Icons.grid_view, 'Templates'),
    ('/settings', Icons.settings, 'Settings'),
  ];

  int _indexFor(String loc) {
    for (var i = 0; i < _destinations.length; i++) {
      if (loc == _destinations[i].$1) return i;
      if (_destinations[i].$1 != '/' && loc.startsWith(_destinations[i].$1))
        return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final idx = _indexFor(currentLocation);
    return NavigationBar(
      backgroundColor: scheme.surface,
      selectedIndex: idx,
      onDestinationSelected: (i) => context.go(_destinations[i].$1),
      destinations: [
        for (final (_, icon, label) in _destinations)
          NavigationDestination(icon: Icon(icon), label: label),
      ],
    );
  }
}
