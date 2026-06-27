import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/domain/plan/models.dart';
import 'package:protocol/widgets/set_row.dart';
import 'package:protocol/theme/colors.dart';

void main() {
  group('SetRow keyboard traversal', () {
    testWidgets('weight TextField has textInputAction.next', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(DayTheme.iron),
          home: Scaffold(
            body: SetRow(
              setNumber: 1,
              data: const SetRowData(done: false, weightText: '', repsText: ''),
              onChanged: (_, {required triggeredByCheckbox}) {},
            ),
          ),
        ),
      );

      final weightField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(
        weightField.textInputAction,
        TextInputAction.next,
        reason:
            'Weight field must use TextInputAction.next for keyboard traversal',
      );
    });

    testWidgets('reps TextField has textInputAction.done', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(DayTheme.iron),
          home: Scaffold(
            body: SetRow(
              setNumber: 1,
              data: const SetRowData(done: false, weightText: '', repsText: ''),
              onChanged: (_, {required triggeredByCheckbox}) {},
            ),
          ),
        ),
      );

      final repsField = tester.widget<TextField>(find.byType(TextField).last);
      expect(
        repsField.textInputAction,
        TextInputAction.done,
        reason: 'Reps field must use TextInputAction.done',
      );
    });
  });

  group('SetRow weight prefill', () {
    testWidgets('empty weightText is prefilled from suggestedWeight', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(DayTheme.iron),
          home: Scaffold(
            body: SetRow(
              setNumber: 1,
              data: const SetRowData(done: false, weightText: '', repsText: ''),
              suggestedWeight: 60.0,
              onChanged: (_, {required triggeredByCheckbox}) {},
            ),
          ),
        ),
      );

      final weightField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(
        weightField.controller?.text,
        '60',
        reason:
            'Weight field should be prefilled with the formatted suggestedWeight when weightText is empty',
      );
    });

    testWidgets('non-empty weightText is NOT overwritten by suggestedWeight', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(DayTheme.iron),
          home: Scaffold(
            body: SetRow(
              setNumber: 1,
              data: const SetRowData(
                done: false,
                weightText: '80',
                repsText: '',
              ),
              suggestedWeight: 60.0,
              onChanged: (_, {required triggeredByCheckbox}) {},
            ),
          ),
        ),
      );

      final weightField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(
        weightField.controller?.text,
        '80',
        reason:
            'Existing weightText must not be overwritten by suggestedWeight',
      );
    });

    testWidgets('decimal suggestedWeight is formatted correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(DayTheme.iron),
          home: Scaffold(
            body: SetRow(
              setNumber: 1,
              data: const SetRowData(done: false, weightText: '', repsText: ''),
              suggestedWeight: 62.5,
              onChanged: (_, {required triggeredByCheckbox}) {},
            ),
          ),
        ),
      );

      final weightField = tester.widget<TextField>(
        find.byType(TextField).first,
      );
      expect(
        weightField.controller?.text,
        '62.5',
        reason:
            'Decimal suggestedWeight must be formatted with one decimal place',
      );
    });
  });
}
