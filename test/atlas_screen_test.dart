import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/app/atlas_providers.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/people_providers.dart';
import 'package:study_bible/app/place_providers.dart';
import 'package:study_bible/app/topic_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/ui/reader/atlas_screen.dart';

/// Smoke-tests the fullscreen Atlas: general browse renders every place,
/// selecting a person (directly or via search) switches to journey mode with
/// its waypoints and playback controls, degraded states (no journey, a single
/// waypoint) render without controls, and the help dialog opens and closes.
void main() {
  late ContentStore store;

  Future<void> place(int id, String name, double lat, double lng) =>
      store.into(store.places).insert(PlacesCompanion(
            id: Value(id),
            name: Value(name),
            lat: Value(lat),
            lng: Value(lng),
          ));

  Future<void> placeVerse(
          int id, int placeId, String book, int chapter, int verse) =>
      store.into(store.placeVerses).insert(PlaceVersesCompanion(
            id: Value(id),
            placeId: Value(placeId),
            bookName: Value(book),
            chapter: Value(chapter),
            verse: Value(verse),
          ));

  Future<void> person(int id, String name) =>
      store.into(store.biblePeople).insert(BiblePeopleCompanion(
            id: Value(id),
            slug: Value(name.toLowerCase()),
            name: Value(name),
            displayTitle: Value(name),
            verseCount: const Value(50),
          ));

  Future<void> event(int id, String title, double sortKey, int startYear) =>
      store.into(store.timelineEvents).insert(TimelineEventsCompanion(
            id: Value(id),
            title: Value(title),
            sortKey: Value(sortKey),
            startYear: Value(startYear),
          ));

  Future<void> eventVerse(
          int id, int eventId, String book, int chapter, int verse) =>
      store.into(store.eventVerses).insert(EventVersesCompanion(
            id: Value(id),
            eventId: Value(eventId),
            ord: const Value(0),
            bookName: Value(book),
            chapter: Value(chapter),
            verse: Value(verse),
          ));

  Future<void> participant(int id, int eventId, int personId) => store
      .into(store.eventParticipants)
      .insert(EventParticipantsCompanion(
        id: Value(id),
        eventId: Value(eventId),
        personId: Value(personId),
      ));

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());

    await place(1, 'Damascus', 33.5, 36.3);
    await place(2, 'Antioch', 36.2, 36.15);

    // Paul: a two-waypoint journey.
    await person(1, 'Paul');
    await event(1, 'Conversion', 35.0, 35);
    await eventVerse(1, 1, 'Acts', 9, 3);
    await placeVerse(1, 1, 'Acts', 9, 3);
    await event(2, 'Sent out from Antioch', 46.0, 46);
    await eventVerse(2, 2, 'Acts', 13, 1);
    await placeVerse(2, 2, 'Acts', 13, 1);
    await participant(1, 1, 1);
    await participant(2, 2, 1);

    // Barnabas: a single-waypoint journey (no animation/controls expected).
    await person(2, 'Barnabas');
    await participant(3, 2, 2);

    // Silas: no dated, mappable events at all (empty journey).
    await person(3, 'Silas');

    // A wide-scale journey (Italy to Jerusalem, ~3000km), mirroring the
    // geographic spread — and low CameraFit zoom — of a real multi-leg
    // journey like Paul's, rather than the tight two-city hop above.
    await person(4, 'Wide Traveler');
    await place(3, 'Italy', 41.9, 12.5);
    await place(4, 'Crete', 35.24, 24.81);
    await place(5, 'Caesarea', 32.5, 34.9);
    final wideEvents = [
      (eventId: 10, placeId: 3, chapter: 27, verse: 6),
      (eventId: 11, placeId: 4, chapter: 27, verse: 7),
      (eventId: 12, placeId: 5, chapter: 27, verse: 8),
      (eventId: 13, placeId: 1, chapter: 27, verse: 9), // Damascus (place 1)
    ];
    for (final e in wideEvents) {
      await event(e.eventId, 'Wide event ${e.eventId}', e.eventId.toDouble(),
          2000 + e.eventId);
      await eventVerse(e.eventId, e.eventId, 'Acts', e.chapter, e.verse);
      await placeVerse(e.eventId, e.placeId, 'Acts', e.chapter, e.verse);
      await participant(e.eventId + 100, e.eventId, 4);
    }
  });

  tearDown(() async {
    await store.close();
  });

  Future<void> pump(WidgetTester tester, {int? initialPersonId}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentStoreProvider.overrideWithValue(store),
          peopleReadyProvider.overrideWith((ref) async => true),
          placesReadyProvider.overrideWith((ref) async => true),
          topicalIndexReadyProvider.overrideWith((ref) async => true),
          // This suite's synthetic DB has no Elijah/Elisha rows for the real
          // curated importer to find — it's exercised for real in
          // curated_journeys_importer_test.dart instead.
          curatedJourneysReadyProvider.overrideWith((ref) async => true),
        ],
        child: MaterialApp(
          home: AtlasScreen(initialPersonId: initialPersonId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('browse mode renders with the seeded places', (tester) async {
    await pump(tester);

    expect(find.text('Atlas'), findsOneWidget);
    expect(find.byTooltip("Follow a person's journey"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      "the traveler icon starts exactly on the first waypoint's own pin",
      (tester) async {
    await pump(tester, initialPersonId: 1);

    final travelerCenter =
        tester.getCenter(find.byIcon(Icons.directions_walk));
    final pinCenter = tester.getCenter(find.descendant(
      of: find.byKey(const ValueKey('marker-1')),
      matching: find.byIcon(Icons.location_on),
    ));

    // A small tolerance for the location_on glyph's own internal shape
    // (its "pin tip" isn't dead-center of its icon box) — anything beyond
    // that means the traveler and the waypoint it's supposedly standing on
    // have drifted apart on screen.
    expect((travelerCenter - pinCenter).distance, lessThan(40));
  });

  testWidgets(
      'the traveler icon coincides with its pin on a wide, low-zoom journey '
      '(Italy to Jerusalem, mirroring a real multi-leg route)',
      (tester) async {
    await pump(tester, initialPersonId: 4);

    final travelerCenter =
        tester.getCenter(find.byIcon(Icons.directions_walk));
    final pinCenter = tester.getCenter(find.descendant(
      of: find.byKey(const ValueKey('marker-10')),
      matching: find.byIcon(Icons.location_on),
    ));

    expect((travelerCenter - pinCenter).distance, lessThan(40));
  });

  testWidgets('opening with initialPersonId enters journey mode directly',
      (tester) async {
    await pump(tester, initialPersonId: 1);

    expect(find.text('Conversion'), findsOneWidget);
    expect(find.byTooltip('Back to browse'), findsOneWidget);
    // Two waypoints -> playback controls present.
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('selecting a person via search enters journey mode',
      (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip("Follow a person's journey"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Paul');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Paul'));
    await tester.pumpAndSettle();

    expect(find.text('Conversion'), findsOneWidget);
  });

  testWidgets('play/pause and step controls advance and rewind the journey',
      (tester) async {
    await pump(tester, initialPersonId: 1);

    expect(find.text('Conversion'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.pumpAndSettle();
    expect(find.text('Sent out from Antioch'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.skip_previous));
    await tester.pumpAndSettle();
    expect(find.text('Conversion'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'pausing mid-leg settles at the nearer waypoint instead of freezing '
      'between them', (tester) async {
    await pump(tester, initialPersonId: 1);

    expect(find.text('Conversion'), findsOneWidget);

    // Past the halfway point of the 2200ms leg -> pausing should settle
    // forward onto the destination waypoint, not freeze mid-transit.
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();

    expect(find.text('Sent out from Antioch'), findsOneWidget);
    expect(find.text('Conversion'), findsNothing);
  });

  testWidgets(
      'playback bar sits above the system navigation bar/gesture inset',
      (tester) async {
    // Regression: the journey controls (step card + playback bar) were
    // rendered directly in the body's Column with no SafeArea, so on a
    // device with on-screen nav buttons/gesture bar (simulated here via the
    // view's bottom padding) they were drawn underneath the system UI.
    // view.padding is in physical pixels; use the test device's pixel ratio
    // so the simulated inset is exactly 48 *logical* pixels.
    const insetLogical = 48.0;
    final dpr = tester.view.devicePixelRatio;
    final originalPadding = tester.view.padding;
    tester.view.padding = FakeViewPadding(bottom: insetLogical * dpr);
    addTearDown(() => tester.view.padding = originalPadding);

    await pump(tester, initialPersonId: 1);

    final screenBottom =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final controlsBottom =
        tester.getBottomLeft(find.byKey(const Key('atlas-journey-controls'))).dy;

    expect(screenBottom - controlsBottom, greaterThanOrEqualTo(insetLogical));
  });

  testWidgets('a single-waypoint journey has no playback controls',
      (tester) async {
    await pump(tester, initialPersonId: 2);

    expect(find.text('Sent out from Antioch'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });

  testWidgets('a person with no mappable events shows the empty state',
      (tester) async {
    await pump(tester, initialPersonId: 3);

    expect(find.text('No journey to show'), findsOneWidget);
  });

  testWidgets('help dialog opens and closes', (tester) async {
    await pump(tester);

    await tester.tap(find.byTooltip('About the Atlas'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsOneWidget);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Got it'), findsNothing);
  });
}
