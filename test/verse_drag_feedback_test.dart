import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/verse_selection.dart';
import 'package:study_bible/ui/reader/verse_drag_feedback.dart';

void main() {
  const VerseSelection sel = (
    book: 'John',
    chapter: 3,
    numbers: [16, 17],
    verses: [
      (number: 16, text: 'For God so loved the world'),
      (number: 17, text: 'For God sent not his Son into the world'),
    ],
    abbreviation: 'KJV',
  );

  testWidgets('shows compact reference with version and first-verse snippet',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: VerseDragFeedback.fromSelection(sel)),
      ),
    );

    expect(find.text('John 3:16-17 (KJV)'), findsOneWidget);
    expect(find.text('For God so loved the world'), findsOneWidget);
    // Only the first verse previews; the payload itself carries the rest.
    expect(find.textContaining('sent not his Son'), findsNothing);
  });

  testWidgets('omits the snippet row when the selection has no text',
      (tester) async {
    const VerseSelection empty = (
      book: 'John',
      chapter: 3,
      numbers: [16],
      verses: [],
      abbreviation: null,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(child: VerseDragFeedback.fromSelection(empty)),
      ),
    );

    expect(find.text('John 3:16'), findsOneWidget);
    // Reference row only — no second text line.
    expect(find.byType(Text), findsOneWidget);
  });
}
