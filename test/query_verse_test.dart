import 'package:drift/native.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/importer/theographic_importer.dart';
import 'package:study_bible/data/importer/places_importer.dart';

import "package:flutter_test/flutter_test.dart";
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test("query", () async {
  final store = ContentStore(NativeDatabase.memory());
  final theographic = TheographicImporter(store);
  await theographic.ensureLoaded();
  final places = PlacesImporter(store);
  await places.ensureLoaded();
  
  final versePlaces = await store.customSelect(
    'SELECT p.name AS place_name '
    'FROM place_verses pv '
    'JOIN places p ON p.id = pv.place_id '
    'WHERE pv.book_name = ? AND pv.chapter = ? AND pv.verse = ?',
    variables: [Variable.withString('Matthew'), Variable.withInt(3), Variable.withInt(1)],
  ).get();
  
  print("Places for Matthew 3:1:");
  for (final row in versePlaces) {
    print(row.read<String>('place_name'));
  }
  await store.close();
  });
}
