import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/ui/common/place_marker_map.dart';

/// Exercises the map widget shared by the Places panel, Explorer pages, and
/// the Atlas: both marker styles render and fire onTapPoint, the expand icon
/// only shows when wired up, and a single point doesn't hit the
/// CameraFit.coordinates zero-area-bounds assertion.
void main() {
  test('MapPoint equality is content-based, so a freshly-built list of the '
      'same points reads as unchanged', () {
    const a = MapPoint(1, 'Damascus', 33.5, 36.3);
    const b = MapPoint(1, 'Damascus', 33.5, 36.3);
    expect(a, equals(b));
    expect(a.hashCode, b.hashCode);
    expect(<MapPoint>[a], equals(<MapPoint>[b]));
  });

  testWidgets('labeledPin shows a name label and fires onTapPoint', (
    tester,
  ) async {
    MapPoint? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: PlaceMarkerMap(
          points: const [
            MapPoint(1, 'Jerusalem', 31.78, 35.23),
            MapPoint(2, 'Bethlehem', 31.70, 35.20),
          ],
          onTapPoint: (p) => tapped = p,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jerusalem'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('marker-1')));
    expect(tapped?.id, 1);
  });

  testWidgets('dot style has no label and fires onTapPoint', (tester) async {
    MapPoint? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: PlaceMarkerMap(
          points: const [
            MapPoint(1, 'Damascus', 33.5, 36.3),
            MapPoint(2, 'Antioch', 36.2, 36.15),
          ],
          style: PlaceMarkerStyle.dot,
          onTapPoint: (p) => tapped = p,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Damascus'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('marker-2')));
    expect(tapped?.id, 2);
  });

  testWidgets('a single point renders without hitting the zero-area guard', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlaceMarkerMap(points: [MapPoint(1, 'Only Place', 10, 20)]),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the expand icon only renders when onExpand is provided', (
    tester,
  ) async {
    var expanded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PlaceMarkerMap(
          points: const [MapPoint(1, 'A', 10, 20), MapPoint(2, 'B', 12, 22)],
          onExpand: () => expanded = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Open fullscreen atlas'), findsOneWidget);
    await tester.tap(find.byTooltip('Open fullscreen atlas'));
    expect(expanded, isTrue);
  });

  testWidgets('no expand icon when onExpand is omitted', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PlaceMarkerMap(points: [MapPoint(1, 'A', 10, 20)]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Open fullscreen atlas'), findsNothing);
  });
}
