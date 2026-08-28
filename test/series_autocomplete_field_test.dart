import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/ui/sermons/series_autocomplete_field.dart';

void main() {
  Future<void> pumpField(
    WidgetTester tester, {
    required TextEditingController controller,
    List<String> options = const [],
    VoidCallback? onSubmitted,
  }) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeriesAutocompleteField(
            controller: controller,
            focusNode: focusNode,
            options: options,
            onSubmitted: onSubmitted,
          ),
        ),
      ),
    );
  }

  testWidgets('Enter invokes onSubmitted with the typed text', (tester) async {
    // Regression: the rename dialog's confirm action hung off the button only,
    // so Enter in the field was a dead key — RawAutocomplete's own
    // onFieldSubmitted just commits a highlighted suggestion, and with no
    // suggestions showing it does nothing at all.
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var submitted = 0;
    await pumpField(
      tester,
      controller: controller,
      onSubmitted: () => submitted++,
    );

    await tester.enterText(find.byType(TextField), 'Christmas');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, 1);
    expect(controller.text, 'Christmas');
  });

  testWidgets('Enter commits the highlighted suggestion first', (tester) async {
    // onSubmitted runs after the autocomplete has had its turn, so a dialog
    // confirming on Enter sees the suggestion the user was looking at, not the
    // partial text they had typed.
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? seen;
    await pumpField(
      tester,
      controller: controller,
      options: const ['Advent'],
      onSubmitted: () => seen = controller.text,
    );

    await tester.enterText(find.byType(TextField), 'Adv');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(controller.text, 'Advent');
    expect(seen, 'Advent');
  });

  testWidgets('Enter is harmless when no onSubmitted is given', (tester) async {
    // The editor and the new-sermon dialog leave it null.
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpField(tester, controller: controller);

    await tester.enterText(find.byType(TextField), 'Adv');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(controller.text, 'Adv');
  });
}
