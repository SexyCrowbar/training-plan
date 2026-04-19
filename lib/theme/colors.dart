import 'package:flutter/material.dart';

import '../domain/plan/models.dart';

class AppColors {
  static const ironPrimary = Color(0xFFF0C040);
  static const ironSurface = Color(0xFF1A1F2E);
  static const ironBackground = Color(0xFF0F1117);

  static const bodyPrimary = Color(0xFF22D3EE);
  static const bodySurface = Color(0xFF0D2535);
  static const bodyBackground = Color(0xFF081520);

  static const restPrimary = Color(0xFF818CF8);
  static const restSurface = Color(0xFF1C1D2E);
  static const restBackground = Color(0xFF0F1019);

  static const onSurfaceHi = Color(0xFFE5E7EB);
  static const onSurfaceMid = Color(0xFF94A3B8);
  static const onSurfaceLow = Color(0xFF475569);
}

ColorScheme _schemeFor(DayTheme theme) {
  switch (theme) {
    case DayTheme.iron:
      return ColorScheme.dark(
        primary: AppColors.ironPrimary,
        onPrimary: const Color(0xFF1A1400),
        surface: AppColors.ironSurface,
        onSurface: AppColors.onSurfaceHi,
        surfaceContainerHighest: const Color(0xFF242A38),
        secondary: AppColors.ironPrimary,
        onSecondary: const Color(0xFF1A1400),
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      );
    case DayTheme.body:
      return ColorScheme.dark(
        primary: AppColors.bodyPrimary,
        onPrimary: const Color(0xFF002028),
        surface: AppColors.bodySurface,
        onSurface: AppColors.onSurfaceHi,
        surfaceContainerHighest: const Color(0xFF152F42),
        secondary: AppColors.bodyPrimary,
        onSecondary: const Color(0xFF002028),
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      );
    case DayTheme.rest:
      return ColorScheme.dark(
        primary: AppColors.restPrimary,
        onPrimary: const Color(0xFF0A0B1A),
        surface: AppColors.restSurface,
        onSurface: AppColors.onSurfaceHi,
        surfaceContainerHighest: const Color(0xFF272842),
        secondary: AppColors.restPrimary,
        onSecondary: const Color(0xFF0A0B1A),
        error: const Color(0xFFEF4444),
        onError: Colors.white,
      );
  }
}

ThemeData buildTheme(DayTheme theme) {
  final scheme = _schemeFor(theme);
  final bg = switch (theme) {
    DayTheme.iron => AppColors.ironBackground,
    DayTheme.body => AppColors.bodyBackground,
    DayTheme.rest => AppColors.restBackground,
  };
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.4,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.onSurface.withValues(alpha: 0.08),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8),
    ),
  );
}
