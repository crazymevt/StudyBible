import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:drift/native.dart';
import 'package:study_bible/app/atlas_providers.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/importer/curated_journeys_data.dart';
import 'package:study_bible/data/importer/curated_journeys_importer.dart';
import "package:study_bible/data/importer/theographic_importer.dart";
import "package:study_bible/data/importer/places_importer.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('check heuristics', () async {
    final store = ContentStore(NativeDatabase.memory());
    final container = ProviderContainer(overrides: [
      contentStoreProvider.overrideWithValue(store),
    ]);

    final theographic = TheographicImporter(store);
    await theographic.ensureLoaded();
    final places = PlacesImporter(store);
    await places.ensureLoaded();
    final curated = CuratedJourneysImporter(store);
    await curated.ensureLoaded();

    int totalMismatches = 0;
    int totalChecked = 0;
    
    for (final journey in curatedPersonJourneys) {
      final person = await (store.select(store.biblePeople)
            ..where((p) => p.slug.equals(journey.personSlug)))
          .getSingle();

      final resolvedJourney = await container.read(personJourneyProvider(person.id).future);

      
      
      
      if (person.slug == 'barnabas_1722') {
        final allEvents = await store.customSelect('SELECT e.title, ep.person_id FROM timeline_events e JOIN event_participants ep ON e.id = ep.event_id').get();
        for (var row in allEvents) {
          if (row.read<String>('title').contains('Salamis')) {
             print('FOUND SALAMIS PARTICIPANT: ${row.read<int>('person_id')} (expected ${person.id})');
          }
        }
      }

      if (person.slug == 'barnabas_1722') {
        final allEvents = await store.customSelect('SELECT title FROM timeline_events').get();
        for (var row in allEvents) {
          if (row.read<String>('title').contains('Salamis')) {
             print('FOUND SALAMIS IN DB: ${row.read<String>('title')}');
          }
        }
      }

      
      if (person.slug == 'barnabas_1722') {
        final allEvents = await store.customSelect('SELECT e.title, ep.person_id FROM timeline_events e JOIN event_participants ep ON e.id = ep.event_id').get();
        for (var row in allEvents) {
          if (row.read<String>('title').contains('Salamis')) {
             print('FOUND SALAMIS PARTICIPANT: ${row.read<int>('person_id')} (expected ${person.id})');
          }
        }
      }

      if (person.slug == 'barnabas_1722') {
        print('RESOLVED WAYPOINTS FOR BARNABAS:');
        for (var w in resolvedJourney!.waypoints) {
          print('  - ${w.title} (${w.placeName})');
        }
      }

      for (final curatedWp in journey.waypoints) {
        final resolvedWp = resolvedJourney!.waypoints.firstWhere(
            (w) => w.title == curatedWp.title, 
            orElse: () => throw Exception('Waypoint ${curatedWp.title} not found for ${person.slug}'));
        
        totalChecked++;
        if (resolvedWp.placeName != curatedWp.placeName) {
          print("POTENTIAL HEURISTIC MISS in ${journey.personSlug}: '${curatedWp.title}' expected '${curatedWp.placeName}' but got '${resolvedWp.placeName}'");
          totalMismatches++;
        }
      }
    }
    
    print("Checked ${totalChecked} waypoints, found ${totalMismatches} mismatches.");
    await store.close();
  });
}
