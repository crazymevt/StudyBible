import 'family_tree.dart';

/// A node's position in the diagram's coordinate space — arbitrary units;
/// the UI scales/translates these to pixels.
class FamilyTreeNodePosition {
  final double x;
  final double y;
  const FamilyTreeNodePosition(this.x, this.y);
}

/// Horizontal gap between adjacent nodes at the same generation, and
/// vertical gap between generations, in layout units.
const double familyTreeColumnWidth = 1.0;
const double familyTreeRowHeight = 1.0;

/// Extra horizontal breathing room between adjacent sibling groups (children
/// of different couples) in the same generation, in layout units — makes the
/// family blocks read as blocks.
const double familyTreeGroupGap = 0.4;

/// One parental couple (or single known parent) and the children they share
/// within a tree — the unit the UI draws as a single connector: a marriage
/// join between the parents, one drop line, and a rail across the children.
class FamilyUnit {
  final int? fatherId;
  final int? motherId;

  /// In [FamilyTree.nodes] order. Empty for a recorded marriage of the root
  /// with no children inside the tree's window (in that case [fatherId] holds
  /// the root and [motherId] the partner, regardless of actual sex — the pair
  /// is only used as drawing anchors).
  final List<int> childIds;

  const FamilyUnit({this.fatherId, this.motherId, required this.childIds});

  List<int> get parentIds => [?fatherId, ?motherId];
}

/// Every parental couple in [tree] with the children they share, plus a
/// childless unit for each of the root's recorded partners that no shared
/// child already ties to the root — so a marriage is drawn even when the
/// couple has no children in the window.
List<FamilyUnit> familyUnitsOf(FamilyTree tree) {
  final childIdsByCouple = <String, List<int>>{};
  final coupleByKey = <String, FamilyTreeNode>{};
  for (final n in tree.nodes) {
    if (n.fatherNodeId == null && n.motherNodeId == null) continue;
    final key = '${n.fatherNodeId}|${n.motherNodeId}';
    coupleByKey[key] = n;
    childIdsByCouple.putIfAbsent(key, () => []).add(n.id);
  }
  final units = [
    for (final e in childIdsByCouple.entries)
      FamilyUnit(
        fatherId: coupleByKey[e.key]!.fatherNodeId,
        motherId: coupleByKey[e.key]!.motherNodeId,
        childIds: e.value,
      ),
  ];
  for (final partnerId in tree.rootPartnerIds) {
    final covered = units.any((u) =>
        u.parentIds.contains(tree.rootId) && u.parentIds.contains(partnerId));
    if (!covered) {
      units.add(FamilyUnit(
        fatherId: tree.rootId,
        motherId: partnerId,
        childIds: const [],
      ));
    }
  }
  return units;
}

/// Lays out [tree] on a 2D grid, one row per generation:
///
/// - Ancestor generations (negative) are placed relative to their own
///   child's already-known x: a father/mother sit `halfWidth` to either
///   side. The deepest ancestor generation is spaced a full column apart
///   and `halfWidth` halves per generation coming down, which always
///   centers a couple over the child they share and needs no data beyond
///   the father/mother links themselves.
/// - Generation 0 is the root (centered at x = 0), siblings to its left in
///   one block per parental couple, and spouses to its right — each spouse
///   directly above her own children's block so a marriage reads as one
///   column.
/// - Descendant generations (positive) use a tidy subtree layout: every
///   node's span is the width its own descendants need, children (grouped
///   into contiguous blocks per parental couple, via
///   [FamilyTreeNode.fatherNodeId]/[FamilyTreeNode.motherNodeId]) are
///   centered under their parent, and sibling subtrees never overlap — so
///   connectors stay short verticals however wide the deepest generation
///   gets.
Map<int, FamilyTreeNodePosition> layoutFamilyTree(FamilyTree tree) {
  final byGeneration = <int, List<FamilyTreeNode>>{};
  for (final n in tree.nodes) {
    byGeneration.putIfAbsent(n.generation, () => []).add(n);
  }

  final x = <int, double>{tree.rootId: 0};
  final y = <int, double>{tree.rootId: 0};

  // --- Ancestors: each parent is placed relative to its own child's
  // already-known x, halfWidth to either side. The straddle is sized so the
  // topmost ancestor generation ends up a full column apart (no card
  // overlap) and halves per generation coming back down toward the root —
  // couples stay centered over their child the whole way.
  final maxAncestorDepth = byGeneration.keys
      .where((g) => g < 0)
      .fold<int>(0, (max, g) => -g > max ? -g : max);
  for (var depth = 0; depth < maxAncestorDepth; depth++) {
    final halfWidth =
        familyTreeColumnWidth * (1 << (maxAncestorDepth - depth - 1)) / 2;
    for (final n in byGeneration[-depth] ?? const <FamilyTreeNode>[]) {
      final childX = x[n.id];
      if (childX == null) continue;
      if (n.fatherNodeId != null) {
        x[n.fatherNodeId!] = childX - halfWidth;
        y[n.fatherNodeId!] = -(depth + 1) * familyTreeRowHeight;
      }
      if (n.motherNodeId != null) {
        x[n.motherNodeId!] = childX + halfWidth;
        y[n.motherNodeId!] = -(depth + 1) * familyTreeRowHeight;
      }
    }
  }

  // --- Generation 0's non-ancestor nodes: spouses (right), siblings (left) ---
  final genZeroOthers = (byGeneration[0] ?? const <FamilyTreeNode>[])
      .where((n) => n.id != tree.rootId)
      .toList();
  // A recorded partner of the root is a spouse even when their own parent
  // happens to be in view too (Amram, in his wife Jochebed's tree, is still
  // her husband first — not one of her siblings). Anyone else with a parent
  // link shares that parent with the root: a sibling.
  final spouses = genZeroOthers
      .where((n) =>
          tree.rootPartnerIds.contains(n.id) ||
          (n.fatherNodeId == null && n.motherNodeId == null))
      .toList();
  final spouseIds = {for (final s in spouses) s.id};
  final siblings =
      genZeroOthers.where((n) => !spouseIds.contains(n.id)).toList();
  // Spouses are placed during the depth-1 pass below, each directly above
  // her own children's block, so a family reads as one column; spouses with
  // no children in the window line up after them.
  final spouseOrderOf = {
    for (var i = 0; i < spouses.length; i++) spouses[i].id: i,
  };
  // Siblings cluster by parental couple, like the descendant rows — full
  // siblings (sharing both of the root's parents) sit nearest the root,
  // then each half-sibling group as its own block, so one family's rail
  // never interleaves with another's.
  final rootNode = tree.nodes.firstWhere((n) => n.id == tree.rootId);
  final siblingGroups = <String, List<FamilyTreeNode>>{};
  for (final n in siblings) {
    siblingGroups
        .putIfAbsent('${n.fatherNodeId}|${n.motherNodeId}', () => [])
        .add(n);
  }
  final rootCoupleKey = '${rootNode.fatherNodeId}|${rootNode.motherNodeId}';
  final orderedSiblingKeys = [
    if (siblingGroups.containsKey(rootCoupleKey)) rootCoupleKey,
    ...siblingGroups.keys.where((k) => k != rootCoupleKey),
  ];
  var siblingCursor = familyTreeColumnWidth;
  for (final key in orderedSiblingKeys) {
    for (final n in siblingGroups[key]!) {
      x[n.id] = -siblingCursor;
      y[n.id] = 0;
      siblingCursor += familyTreeColumnWidth;
    }
    siblingCursor += familyTreeGroupGap;
  }

  // --- Descendants: tidy subtree layout, one block per parental couple ---
  // Every descendant is given the horizontal span its own descendants need
  // and each parent stands centered over its children, so connectors stay
  // short verticals — a wide grandchildren generation widens the spacing of
  // the generation above instead of sliding sideways out from under it.
  final generationOfNode = {for (final n in tree.nodes) n.id: n.generation};
  final childrenOfNode = <int, List<FamilyTreeNode>>{};
  for (final n in tree.nodes) {
    if (n.generation <= 1) continue; // generation 1 is the couple loop below
    // Allocate each child to one parent — the one a row above it, so the
    // recursion always steps one generation down even in aunt/uncle
    // marriages where the other parent sits higher.
    final candidates = [
      if (n.fatherNodeId != null) n.fatherNodeId!,
      if (n.motherNodeId != null) n.motherNodeId!,
    ];
    if (candidates.isEmpty) continue;
    final primary = candidates.firstWhere(
      (id) => generationOfNode[id] == n.generation - 1,
      orElse: () => candidates.first,
    );
    childrenOfNode.putIfAbsent(primary, () => []).add(n);
  }

  final subtreeWidthOf = <int, double>{};
  double subtreeWidth(FamilyTreeNode n) {
    final memo = subtreeWidthOf[n.id];
    if (memo != null) return memo;
    final kids = childrenOfNode[n.id] ?? const <FamilyTreeNode>[];
    var width = familyTreeColumnWidth;
    if (kids.isNotEmpty) {
      var sum = 0.0;
      for (final k in kids) {
        sum += subtreeWidth(k);
      }
      width = (sum < familyTreeColumnWidth ? familyTreeColumnWidth : sum) +
          familyTreeGroupGap;
    }
    return subtreeWidthOf[n.id] = width;
  }

  void placeSubtree(FamilyTreeNode n, double left) {
    final width = subtreeWidth(n);
    x[n.id] = left + width / 2;
    y[n.id] = n.generation * familyTreeRowHeight;
    final kids = childrenOfNode[n.id] ?? const <FamilyTreeNode>[];
    if (kids.isEmpty) return;
    var kidsSum = 0.0;
    for (final k in kids) {
      kidsSum += subtreeWidth(k);
    }
    // Children of the same couple stay contiguous, so each couple's rail
    // spans an unbroken run of cards.
    final grouped = <String, List<FamilyTreeNode>>{};
    for (final k in kids) {
      grouped.putIfAbsent('${k.fatherNodeId}|${k.motherNodeId}', () => []).add(k);
    }
    var cur = left + (width - kidsSum) / 2;
    for (final group in grouped.values) {
      for (final k in group) {
        placeSubtree(k, cur);
        cur += subtreeWidth(k);
      }
    }
  }

  // The root's own children: one block per parental couple, laid out
  // rightward from under the root — children with no recorded second parent
  // first, then one block per spouse — and each spouse placed *above her
  // own block's span*, so every marriage reads as a column.
  var gen0Cursor = 0.0; // rightmost occupied generation-0 slot (root is 0)
  final gen1Groups = <String, List<FamilyTreeNode>>{};
  for (final n in byGeneration[1] ?? const <FamilyTreeNode>[]) {
    gen1Groups
        .putIfAbsent('${n.fatherNodeId}|${n.motherNodeId}', () => [])
        .add(n);
  }
  int? spouseOf(List<FamilyTreeNode> children) {
    final c = children.first;
    for (final id in [c.fatherNodeId, c.motherNodeId]) {
      if (id != null && spouseOrderOf.containsKey(id)) return id;
    }
    return null;
  }

  final orderedGen1Groups = gen1Groups.values.toList()
    ..sort((a, b) {
      final sa = spouseOf(a), sb = spouseOf(b);
      return (sa == null ? -1 : spouseOrderOf[sa]!)
          .compareTo(sb == null ? -1 : spouseOrderOf[sb]!);
    });
  var cursor = 0.0;
  for (final children in orderedGen1Groups) {
    final blockLeft = cursor;
    for (final child in children) {
      placeSubtree(child, cursor);
      cursor += subtreeWidth(child);
    }
    final blockCenter = (blockLeft + cursor) / 2;
    final spouseId = spouseOf(children);
    if (spouseId != null) {
      final spouseX = blockCenter > gen0Cursor + familyTreeColumnWidth
          ? blockCenter
          : gen0Cursor + familyTreeColumnWidth;
      x[spouseId] = spouseX;
      y[spouseId] = 0;
      gen0Cursor = spouseX;
    }
    cursor += familyTreeGroupGap;
  }
  // Spouses with no children in the window (or no children row at all)
  // line up after the root and any block-anchored spouses.
  for (final s in spouses) {
    if (!x.containsKey(s.id)) {
      gen0Cursor += familyTreeColumnWidth;
      x[s.id] = gen0Cursor;
      y[s.id] = 0;
    }
  }

  return {
    for (final n in tree.nodes)
      if (x.containsKey(n.id))
        n.id: FamilyTreeNodePosition(x[n.id]!, y[n.id]!),
  };
}
