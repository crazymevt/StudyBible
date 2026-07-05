import "package:drift/native.dart";
import "package:drift/drift.dart";
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/importer/curated_journeys_data.dart';
import 'package:study_bible/data/importer/theographic_importer.dart';
import 'package:study_bible/data/importer/places_importer.dart';

import "package:flutter_test/flutter_test.dart";
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test("find multi", () async {
  final store = ContentStore(NativeDatabase.memory());

  final theographic = TheographicImporter(store);
  await theographic.ensureLoaded();
  final places = PlacesImporter(store);
  await places.ensureLoaded();

  for (final journey in curatedPersonJourneys) {
    if (journey.personSlug == 'david_994' || journey.personSlug == 'elijah_1131' || journey.personSlug == 'paul_2479' || journey.personSlug == 'jesus_1603' || journey.personSlug == 'moses_2120') {
      continue;
    }

    for (final wp in journey.waypoints) {
      if (wp.placeName == null) continue; // Skip waypoints without places
      
      final versePlaces = await store.customSelect(
        'SELECT p.name AS place_name '
        'FROM place_verses pv '
        'JOIN places p ON p.id = pv.place_id '
        'WHERE pv.book_name = ? AND pv.chapter = ? AND pv.verse = ?',
        variables: [Variable.withString(wp.bookName), Variable.withInt(wp.chapter), Variable.withInt(wp.verse)],
      ).get();

      if (versePlaces.length > 1) {
        final placesList = versePlaces.map((r) => r.read<String>('place_name')).toList();
        print("POTENTIAL HEURISTIC MISS in ${journey.personSlug}, event '${wp.title}' (${wp.bookName} ${wp.chapter}:${wp.verse}):");
        print("  Curated place (auto-derived): ${wp.placeName}");
        print("  All places in verse: $placesList");
      }
    }
  }

  await store.close();
  });
}
