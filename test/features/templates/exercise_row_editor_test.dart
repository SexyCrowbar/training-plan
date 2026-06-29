import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:protocol/data/db/app_database.dart';
import 'package:protocol/domain/plan/models.dart';
import 'package:protocol/features/templates/widgets/exercise_row_editor.dart';
import 'package:protocol/theme/colors.dart';

// A minimal TemplateExercise for test use.
TemplateExercise _exercise({
  int sets = 3,
  String name = 'Bench Press',
  String target = '8-10 reps',
  int restSeconds = 90,
}) => TemplateExercise(
  id: 1,
  blockRefId: 1,
  position: 0,
  exerciseId: 'bench_press',
  name: name,
  sets: sets,
  target: target,
  restSeconds: restSeconds,
  note: '',
);

/// Pumps [ExerciseRowEditor] inside a minimal Material app with no providers.
Future<void> _pump(
  WidgetTester tester, {
  required TemplateExercise exercise,
  required void Function({
    String? name,
    int? sets,
    String? target,
    int? restSeconds,
    String? note,
  })
  onCommit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(DayTheme.iron),
      home: Scaffold(
        body: ExerciseRowEditor(
          exercise: exercise,
          onCommit: onCommit,
          onDelete: () {},
        ),
      ),
    ),
  );
}

void main() {
  group('ExerciseRowEditor — Sets field validation', () {
    testWidgets('entering "0" shows errorText and does NOT call onCommit', (
      tester,
    ) async {
      bool commitCalled = false;
      final ex = _exercise(sets: 3);
      await _pump(
        tester,
        exercise: ex,
        onCommit: ({name, sets, target, restSeconds, note}) {
          commitCalled = true;
        },
      );

      // Find the Sets field (first numeric field in the second row).
      // The Sets field has hintText '3'; locate by controller text '3'.
      final setsField = find.widgetWithText(TextField, '3').first;
      await tester.tap(setsField);
      await tester.pump();

      // Clear and type "0".
      await tester.enterText(setsField, '0');
      // Trigger onEditingComplete via TextInputAction.done to fire _commitSets.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        commitCalled,
        isFalse,
        reason: 'onCommit must not be called for sets = 0',
      );
      expect(
        find.text('Must be > 0'),
        findsOneWidget,
        reason: 'errorText should appear',
      );
    });

    testWidgets(
      'entering empty string shows errorText and does NOT call onCommit',
      (tester) async {
        bool commitCalled = false;
        final ex = _exercise(sets: 3);
        await _pump(
          tester,
          exercise: ex,
          onCommit: ({name, sets, target, restSeconds, note}) {
            commitCalled = true;
          },
        );

        final setsField = find.widgetWithText(TextField, '3').first;
        await tester.tap(setsField);
        await tester.pump();

        await tester.enterText(setsField, '');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        expect(commitCalled, isFalse);
        expect(find.text('Must be > 0'), findsOneWidget);
      },
    );

    testWidgets('entering a valid value clears error and calls onCommit', (
      tester,
    ) async {
      int? committedSets;
      final ex = _exercise(sets: 3);
      await _pump(
        tester,
        exercise: ex,
        onCommit: ({name, sets, target, restSeconds, note}) {
          if (sets != null) committedSets = sets;
        },
      );

      // First make it error.
      final setsField = find.widgetWithText(TextField, '3').first;
      await tester.tap(setsField);
      await tester.pump();
      await tester.enterText(setsField, '0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Must be > 0'), findsOneWidget);

      // Now enter valid value.
      await tester.enterText(setsField, '5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        find.text('Must be > 0'),
        findsNothing,
        reason: 'error should clear on valid input',
      );
      expect(
        committedSets,
        equals(5),
        reason: 'onCommit should be called with the valid sets value',
      );
    });
  });

  group('ExerciseRowEditor — name field: display == stored after empty blur', () {
    testWidgets(
      'clearing name and blurring restores display to prior committed value',
      (tester) async {
        bool nameClearCommitted = false;
        final ex = _exercise(name: 'Bench Press');
        await _pump(
          tester,
          exercise: ex,
          onCommit: ({name, sets, target, restSeconds, note}) {
            if (name != null && name.isEmpty) nameClearCommitted = true;
          },
        );

        // Find the name TextField by its initial text.
        final nameField = find.widgetWithText(TextField, 'Bench Press');
        await tester.tap(nameField);
        await tester.pump();

        // Clear the name.
        await tester.enterText(nameField, '');

        // Programmatically unfocus to trigger Focus.onFocusChange → _commitName.
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();

        // onCommit must NOT have been called with an empty name.
        expect(
          nameClearCommitted,
          isFalse,
          reason: 'onCommit must not fire with empty name',
        );

        // The displayed text must be restored to the stored value (not blank).
        // _commitName restores _nameCtrl.text to widget.exercise.name when empty.
        // Locate the TextField by its restored text.
        final restoredField = find.widgetWithText(TextField, 'Bench Press');
        expect(
          restoredField,
          findsOneWidget,
          reason:
              'name field must display the stored value after empty blur, not remain blank',
        );
      },
    );
  });
}
