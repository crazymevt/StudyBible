import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:study_bible/data/content_store.dart';
import 'package:study_bible/app/content_providers.dart';
import 'package:study_bible/app/people_providers.dart';
import 'package:study_bible/app/family_tree_providers.dart';

/// Exercises the family tree fetch: ancestor/descendant depth capping,
/// spouse/sibling inclusion at generation 0, and which people are excluded
/// entirely (a sibling's unrelated other parent; anyone beyond the window).
void main() {
  late ContentStore store;
  late ProviderContainer container;

  Future<void> person(
    int id,
    String name, {
    int? father,
    int? mother,
  }) => store
      .into(store.biblePeople)
      .insert(
        BiblePeopleCompanion(
          id: Value(id),
          slug: Value(name.toLowerCase()),
          name: Value(name),
          displayTitle: Value(name),
          fatherId: Value(father),
          motherId: Value(mother),
          verseCount: const Value(0),
        ),
      );

  setUp(() async {
    store = ContentStore(NativeDatabase.memory());

    // Ancestor chain, depth-capped at 2: Isaac -> Abraham -> Terah (kept),
    // Terah -> Nahor (one generation too far, must be excluded).
    await person(1, 'Nahor');
    await person(6, 'Terah', father: 1);
    await person(2, 'Abraham', father: 6);
    await person(3, 'Sarah');
    await person(10, 'Isaac', father: 2, mother: 3);

    // Sibling (shares Isaac's father, different mother) — the mother herself
    // is unrelated to Isaac and must not appear in his tree at all.
    await person(5, 'Hagar');
    await person(4, 'Ishmael', father: 2, mother: 5);

    // Spouse.
    await person(11, 'Rebekah');
    await store
        .into(store.personPartners)
        .insert(
          const PersonPartnersCompanion(
            id: Value(1),
            personId: Value(10),
            partnerId: Value(11),
          ),
        );

    // Descendants, depth-capped at 2: Isaac's two sons (depth 1), each with
    // one child of their own (depth 2, correctly grouped by their actual
    // father) — and one generation further (depth 3), which must be excluded.
    await person(20, 'Esau', father: 10, mother: 11);
    await person(21, 'Jacob', father: 10, mother: 11);
    await person(30, 'Eliphaz', father: 20);
    await person(31, 'Reuben', father: 21);
    await person(40, 'Amalek', father: 30);

    container = ProviderContainer(
      overrides: [
        contentStoreProvider.overrideWithValue(store),
        peopleReadyProvider.overrideWith((ref) async => true),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await store.close();
  });

  test('caps ancestors at the configured depth', () async {
    final tree = (await container.read(familyTreeProvider(10).future))!;
    final byName = {for (final n in tree.nodes) n.displayTitle: n};

    expect(byName['Abraham']!.generation, -1);
    expect(byName['Terah']!.generation, -2);
    expect(byName.containsKey('Nahor'), isFalse);
  });

  test('caps descendants at the configured depth', () async {
    final tree = (await container.read(familyTreeProvider(10).future))!;
    final byName = {for (final n in tree.nodes) n.displayTitle: n};

    expect(byName['Esau']!.generation, 1);
    expect(byName['Eliphaz']!.generation, 2);
    expect(byName.containsKey('Amalek'), isFalse);
  });

  test('descendants link to their actual parent, not just any ancestor',
      () async {
    final tree = (await container.read(familyTreeProvider(10).future))!;
    final byName = {for (final n in tree.nodes) n.displayTitle: n};

    expect(byName['Eliphaz']!.fatherNodeId, byName['Esau']!.id);
    expect(byName['Reuben']!.fatherNodeId, byName['Jacob']!.id);
  });

  test('includes the root\'s spouse and siblings at generation 0, but not '
      'a sibling\'s unrelated other parent', () async {
    final tree = (await container.read(familyTreeProvider(10).future))!;
    final byName = {for (final n in tree.nodes) n.displayTitle: n};

    expect(byName['Rebekah']!.generation, 0);
    expect(byName['Ishmael']!.generation, 0);
    expect(byName.containsKey('Hagar'), isFalse);
  });

  test('unknown person id resolves to null', () async {
    final tree = await container.read(familyTreeProvider(999).future);
    expect(tree, null);
  });

  group('cross-generation marriage (Amram & his aunt Jochebed)', () {
    setUp(() async {
      // Levi(50) -> Kohath(51) and Jochebed(53); Kohath -> Amram(52);
      // Amram + Jochebed -> Moses(54). Moses is reachable from Levi in two
      // steps via his mother, but sits three father-steps down.
      await person(50, 'Levi');
      await person(51, 'Kohath', father: 50);
      await person(53, 'Jochebed', father: 50);
      await person(52, 'Amram', father: 51);
      await person(54, 'Moses', father: 52, mother: 53);
    });

    test("a child sits one generation below its lowest parent, so it falls "
        'outside a window that includes that parent at the edge', () async {
      final tree = (await container.read(familyTreeProvider(50).future))!;
      final byName = {for (final n in tree.nodes) n.displayTitle: n};

      expect(byName['Amram']!.generation, 2);
      expect(byName['Jochebed']!.generation, 1);
      // Moses is generation 3 from Levi (below Amram), not 2 via Jochebed —
      // which puts him past the 2-generation window entirely.
      expect(byName.containsKey('Moses'), isFalse);
    });

    test('re-centered a generation closer, the child appears below both '
        'parents', () async {
      final tree = (await container.read(familyTreeProvider(51).future))!;
      final byName = {for (final n in tree.nodes) n.displayTitle: n};

      expect(byName['Jochebed']!.generation, 0); // Kohath's sibling
      expect(byName['Amram']!.generation, 1);
      expect(byName['Moses']!.generation, 2);
      expect(byName['Moses']!.fatherNodeId, 52);
      expect(byName['Moses']!.motherNodeId, 53);
    });
  });
}
