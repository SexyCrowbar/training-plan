// Smoke test for the Protocol app. Spins up `ProtocolApp` inside a
// `ProviderScope` and waits one frame. Full feature coverage lives in
// per-feature widget/unit tests alongside the implementations.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/app.dart';

void main() {
  testWidgets('App boots and shows a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ProtocolApp()));
    // Boot is async (DB + seeders); just confirm the root MaterialApp mounted.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
