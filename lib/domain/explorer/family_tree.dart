/// One person in a [FamilyTree] — a plain projection of the fields the
/// layout and UI need, independent of how the data was fetched.
class FamilyTreeNode {
  final int id;
  final String displayTitle;
  final int? birthYear;
  final int? deathYear;

  /// Negative = an ancestor generation (-1 = parents, -2 = grandparents...),
  /// 0 = the root, its spouses, and its siblings, positive = a descendant
  /// generation (1 = children, 2 = grandchildren...).
  final int generation;

  /// This node's father/mother, when that parent is itself a node in this
  /// tree (used to draw the diagram's connecting lines). Null otherwise —
  /// e.g. a generation-0 spouse's own parents aren't part of this tree.
  final int? fatherNodeId;
  final int? motherNodeId;

  const FamilyTreeNode({
    required this.id,
    required this.displayTitle,
    this.birthYear,
    this.deathYear,
    required this.generation,
    this.fatherNodeId,
    this.motherNodeId,
  });
}

/// A bounded window of a person's family: a few generations of ancestors and
/// descendants around [rootId], plus the root's own spouses and siblings at
/// generation 0. See `family_tree_providers.dart` (app layer) for how this is
/// built from the content store, and `family_tree_layout.dart` for how it's
/// turned into an on-screen diagram.
class FamilyTree {
  final int rootId;
  final List<FamilyTreeNode> nodes;

  /// The root's recorded spouses/partners (all of whom are generation-0
  /// nodes) — lets the diagram draw a marriage connector even for a couple
  /// with no shared children inside this window.
  final List<int> rootPartnerIds;

  const FamilyTree({
    required this.rootId,
    required this.nodes,
    this.rootPartnerIds = const [],
  });
}
