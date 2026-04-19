import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';
import 'colors.dart';

final themeProvider = Provider<ThemeData>((ref) {
  final meta = ref.watch(currentDayMetaProvider);
  return buildTheme(meta.theme);
});
