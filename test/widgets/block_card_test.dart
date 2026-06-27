import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/domain/plan/models.dart';
import 'package:protocol/theme/colors.dart';
import 'package:protocol/widgets/block_card.dart';

void main() {
  testWidgets('BlockCard empty label uses AppColors.onSurfaceMid', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(DayTheme.iron),
        home: Scaffold(
          body: BlockCard(
            blockId: 'unknown_block',
            exercises: const [],
            done: false,
            onTap: () {},
          ),
        ),
      ),
    );

    final emptyText = tester.widget<Text>(find.text('empty'));
    final resolvedColor = emptyText.style?.color;
    expect(
      resolvedColor,
      AppColors.onSurfaceMid,
      reason: 'BlockCard empty label must use the AA-safe textMid token',
    );
  });
}
