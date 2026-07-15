import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_bible/app/shared_prefs.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/ui/reader/flowing_paragraph_view.dart';
import 'package:study_bible/ui/reader/parallel_view.dart';

// Note/tag/ribbon verse indicators must show in every reader layout, not just
// the single-version verse list (they were silently dropped by the parallel
// and flowing views when the feature shipped).

Verse _verse(int num, String text) => Verse(
      id: num,
      bookId: 1,
      chapter: 1,
      verse: num,
      textContent: text,
      segments: '[]',
    );

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrap(Widget child) => ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('parallel verse-by-verse view shows note/tag/ribbon markers',
      (tester) async {
    await tester.pumpWidget(wrap(ParallelView(
      versesMap: {
        'KJV': [_verse(1, 'In the beginning'), _verse(2, 'And the earth')],
        'BSB': [_verse(1, 'In the beginning'), _verse(2, 'Now the earth')],
      },
      selectedVerses: const {},
      savedHighlights: const {},
      versesWithNotes: const {1},
      versesWithTags: const {1},
      versesWithRibbons: const {2},
      onVerseTap: (_) {},
      showFooter: false,
    )));
    await tester.pump();

    // Markers show after the verse number in every translation column.
    expect(find.byIcon(Icons.edit_note), findsNWidgets(2));
    expect(find.byIcon(Icons.label), findsNWidgets(2));
    expect(find.byIcon(Icons.bookmark), findsNWidgets(2));
  });

  testWidgets('flowing paragraph view shows note/tag/ribbon markers',
      (tester) async {
    await tester.pumpWidget(wrap(FlowingParagraphView(
      verses: [_verse(1, 'In the beginning'), _verse(2, 'And the earth')],
      selectedVerses: const {},
      savedHighlights: const {},
      versesWithNotes: const {1},
      versesWithTags: const {2},
      versesWithRibbons: const {2},
      onVerseTap: (_) {},
      showFooter: false,
    )));
    await tester.pump();

    expect(find.byIcon(Icons.edit_note), findsOneWidget);
    expect(find.byIcon(Icons.label), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });
}
