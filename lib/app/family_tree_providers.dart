import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/content_store.dart';
import '../domain/explorer/family_tree.dart';
import 'content_providers.dart';
import 'people_providers.dart';

/// How many generations of ancestors/descendants to fetch around the root.
/// The family tree screen lets the user re-center on any node instead of
/// ever needing to fetch or render an unbounded tree — some ancestor chains
/// in the bundled dataset run 75+ generations deep, and some people have
/// upwards of 20 recorded children.
const familyTreeAncestorGenerations = 2;
const familyTreeDescendantGenerations = 2;

/// Fetches a bounded window of [rootId]'s family — [familyTreeAncestorGenerations]
/// generations up, [familyTreeDescendantGenerations] down, plus the root's
/// own spouses and siblings — from the content store. Ancestors are the
/// root's own blood line only (not a spouse's side); descendants are the
/// root's own blood descendants (not, say, a sibling's children).
final familyTreeProvider = FutureProvider.family<FamilyTree?, int>((
  ref,
  rootId,
) async {
  await ref.watch(peopleReadyProvider.future);
  final store = ref.watch(contentStoreProvider);

  final root = await personByIdOrNull(store, rootId);
  if (root == null) return null;

  final people = <int, BiblePerson>{root.id: root};
  final generationOf = <int, int>{root.id: 0};

  // --- Ancestors: root's own father/mother chain ---
  var ancestorFrontier = [root];
  for (var depth = 1; depth <= familyTreeAncestorGenerations; depth++) {
    final parentIds = <int>{
      for (final p in ancestorFrontier) ...[
        if (p.fatherId != null) p.fatherId!,
        if (p.motherId != null) p.motherId!,
      ],
    };
    if (parentIds.isEmpty) break;
    final parents = await peopleByIdsYearSorted(store, parentIds.toList());
    for (final parent in parents) {
      people[parent.id] = parent;
      generationOf[parent.id] = -depth;
    }
    ancestorFrontier = parents;
  }

  // --- Generation 0: root's spouses and siblings ---
  final partnerLinks = await (store.select(store.personPartners)..where(
        (r) => r.personId.equals(rootId) | r.partnerId.equals(rootId),
      ))
      .get();
  final partnerIds = {
    for (final r in partnerLinks)
      r.personId == rootId ? r.partnerId : r.personId,
  }..remove(rootId);
  for (final spouse in await peopleByIdsYearSorted(store, partnerIds.toList())) {
    people[spouse.id] = spouse;
    generationOf[spouse.id] = 0;
  }
  final siblingIds = await siblingIdsOf(store, root);
  for (final sibling in await peopleByIdsYearSorted(store, siblingIds.toList())) {
    people[sibling.id] = sibling;
    generationOf[sibling.id] = 0;
  }

  // --- Descendants: root's own blood line only ---
  var descendantFrontier = [root];
  for (var depth = 1; depth <= familyTreeDescendantGenerations; depth++) {
    final frontierIds = descendantFrontier.map((p) => p.id).toList();
    final childRows = await (store.select(store.biblePeople)..where(
          (p) => p.fatherId.isIn(frontierIds) | p.motherId.isIn(frontierIds),
        ))
        .get();
    if (childRows.isEmpty) break;
    final children = await peopleByIdsYearSorted(
      store,
      childRows.map((c) => c.id).toList(),
    );
    for (final child in children) {
      people[child.id] = child;
      generationOf[child.id] = depth;
    }
    descendantFrontier = children;
  }

  final nodes = [
    for (final id in people.keys)
      FamilyTreeNode(
        id: id,
        displayTitle: people[id]!.displayTitle,
        birthYear: people[id]!.birthYear,
        deathYear: people[id]!.deathYear,
        generation: generationOf[id]!,
        fatherNodeId:
            people[id]!.fatherId != null && people.containsKey(people[id]!.fatherId)
                ? people[id]!.fatherId
                : null,
        motherNodeId:
            people[id]!.motherId != null && people.containsKey(people[id]!.motherId)
                ? people[id]!.motherId
                : null,
      ),
  ];

  return FamilyTree(rootId: rootId, nodes: nodes);
});
