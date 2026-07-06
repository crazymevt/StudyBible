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

/// Lays out [tree] on a 2D grid, one row per generation:
///
/// - Ancestor generations (negative) are placed relative to their own
///   child's already-known x: a father/mother sit `halfWidth` to either
///   side, where `halfWidth` halves every generation further back. That
///   always centers a couple over the child they share, however deep the
///   chain goes, and needs no data beyond the father/mother links
///   themselves.
/// - Generation 0 is the root (centered at x = 0), with spouses placed to
///   its right and siblings to its left, evenly spaced.
/// - Descendant generations (positive) are laid out top-down: each
///   generation's nodes are grouped by their actual parent (via
///   [FamilyTreeNode.fatherNodeId]/[FamilyTreeNode.motherNodeId]) in the
///   parent's x order, and evenly spaced left-to-right within each group
///   ("comb" layout) — correct for half-siblings from multiple marriages,
///   since grouping comes from the real parent link rather than name order.
///   Earlier generations are never moved to re-center under their children.
Map<int, FamilyTreeNodePosition> layoutFamilyTree(FamilyTree tree) {
  final byGeneration = <int, List<FamilyTreeNode>>{};
  for (final n in tree.nodes) {
    byGeneration.putIfAbsent(n.generation, () => []).add(n);
  }

  final x = <int, double>{tree.rootId: 0};
  final y = <int, double>{tree.rootId: 0};

  // --- Ancestors: each parent is placed relative to its own child's
  // already-known x, halfWidth to either side. halfWidth halves every
  // generation further back so a deeper couple never strays outside the
  // horizontal span their child already claimed one row down.
  final maxAncestorDepth = byGeneration.keys
      .where((g) => g < 0)
      .fold<int>(0, (max, g) => -g > max ? -g : max);
  for (var depth = 0; depth < maxAncestorDepth; depth++) {
    final halfWidth = familyTreeColumnWidth / (1 << (depth + 1));
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
  // Spouses share a partner link with the root; siblings share a parent.
  final spouses = genZeroOthers
      .where((n) => n.fatherNodeId == null && n.motherNodeId == null)
      .toList();
  final siblings = genZeroOthers
      .where((n) => n.fatherNodeId != null || n.motherNodeId != null)
      .toList();
  for (var i = 0; i < spouses.length; i++) {
    x[spouses[i].id] = (i + 1) * familyTreeColumnWidth;
    y[spouses[i].id] = 0;
  }
  for (var i = 0; i < siblings.length; i++) {
    x[siblings[i].id] = -(i + 1) * familyTreeColumnWidth;
    y[siblings[i].id] = 0;
  }

  // --- Descendants: comb layout, grouped by actual parent ---
  final maxDescendantDepth = byGeneration.keys
      .where((g) => g > 0)
      .fold<int>(0, (max, g) => g > max ? g : max);
  for (var depth = 1; depth <= maxDescendantDepth; depth++) {
    final generationNodes = byGeneration[depth] ?? const <FamilyTreeNode>[];
    // Group by (parent node already placed in the previous generation),
    // ordered by that parent's x so groups read left-to-right.
    final groups = <int, List<FamilyTreeNode>>{};
    for (final n in generationNodes) {
      final parentId = n.fatherNodeId ?? n.motherNodeId;
      groups.putIfAbsent(parentId ?? -1, () => []).add(n);
    }
    final orderedParentIds = groups.keys.toList()
      ..sort((a, b) => (x[a] ?? 0).compareTo(x[b] ?? 0));
    var cursor = 0.0;
    for (final parentId in orderedParentIds) {
      final children = groups[parentId]!;
      for (final child in children) {
        x[child.id] = cursor;
        y[child.id] = depth * familyTreeRowHeight;
        cursor += familyTreeColumnWidth;
      }
    }
  }

  return {
    for (final n in tree.nodes)
      if (x.containsKey(n.id))
        n.id: FamilyTreeNodePosition(x[n.id]!, y[n.id]!),
  };
}
