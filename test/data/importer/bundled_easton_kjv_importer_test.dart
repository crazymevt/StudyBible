import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/data/importer/bundled_easton_importer.dart';
import 'package:study_bible/data/importer/bundled_kjv_importer.dart';

/// A minimal [PathProviderPlatform] fake so the importers' real
/// `getTemporaryDirectory()` calls resolve under `flutter test`, which has no
/// platform channel behind path_provider by default. Points at the process's
/// own system temp dir — good enough for a short-lived extract-then-delete.
class _FakePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
}

/// Runs the real importers against the real bundled SWORD module zips: zip
/// extraction, .conf parsing, and import via the shared SwordDictionaryImporter
/// / SwordBibleImporter code paths — the exact route a fresh install takes the
/// first time either resource is needed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = _FakePathProvider();

  late ContentStore store;

  setUp(() {
    store = ContentStore(NativeDatabase.memory());
  });

  tearDown(() async {
    await store.close();
  });

  test(
    'BundledEastonImporter installs Easton\'s and is idempotent',
    () async {
      final importer = BundledEastonImporter(store);
      await importer.ensureLoaded();

      final dicts = await store.select(store.dictionaries).get();
      expect(dicts, hasLength(1));
      expect(dicts.single.abbreviation, 'EASTON');

      final entries = await store.select(store.dictionaryEntries).get();
      expect(entries.length, greaterThan(1000));
      expect(entries.any((e) => e.word.toUpperCase() == 'AARON'), isTrue);

      // Second call is a no-op, not a duplicate import.
      await importer.ensureLoaded();
      expect(await store.select(store.dictionaries).get(), hasLength(1));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('BundledKjvImporter installs KJV with paragraph breaks and is idempotent', () async {
    final importer = BundledKjvImporter(store);
    await importer.ensureLoaded();

    final versions = await store.select(store.versions).get();
    expect(versions, hasLength(1));
    expect(versions.single.abbreviation, 'KJV');

    final books = await store.select(store.books).get();
    expect(books.length, 66);

    final verses = await store.select(store.verses).get();
    expect(verses.length, greaterThan(30000));

    // At least one verse carries a backfilled paragraph-break segment —
    // Genesis 1:1 is in every paragraph-break edition, including AV's.
    final genesisBook =
        books.firstWhere((b) => b.name == 'Genesis');
    final gen1 = verses.firstWhere(
      (v) => v.bookId == genesisBook.id && v.chapter == 1 && v.verse == 1,
    );
    expect(gen1.segments, contains('"pb":true'));

    // Second call is a no-op, not a duplicate import.
    await importer.ensureLoaded();
    expect(await store.select(store.versions).get(), hasLength(1));
  }, timeout: const Timeout(Duration(minutes: 2)));
}
