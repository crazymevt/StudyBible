import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/explorer/family_tree.dart';
import 'package:study_bible/domain/explorer/family_tree_layout.dart';

FamilyTreeNode _node(
  int id, {
  required int generation,
  int? fatherNodeId,
  int? motherNodeId,
}) =>
    FamilyTreeNode(
      id: id,
      displayTitle: 'Person $id',
      generation: generation,
      fatherNodeId: fatherNodeId,
      motherNodeId: motherNodeId,
    );

void main() {
  group('layoutFamilyTree', () {
    test('centers a couple over their child, however deep the chain', () {
      // root(0) <- father(1)/mother(2) <- father's parents(3,4)
      final tree = FamilyTree(
        rootId: 0,
        nodes: [
          _node(0, generation: 0, fatherNodeId: 1, motherNodeId: 2),
          _node(1, generation: -1, fatherNodeId: 3, motherNodeId: 4),
          _node(2, generation: -1),
          _node(3, generation: -2),
          _node(4, generation: -2),
        ],
      );

      final pos = layoutFamilyTree(tree);

      expect(pos[0]!.x, 0);
      expect(pos[0]!.y, 0);
      // Father/mother straddle the root, one row up. With two ancestor
      // generations, the straddle starts at a full column and halves going
      // up, so the topmost couple never overlaps.
      expect(pos[1]!.x, -1.0);
      expect(pos[2]!.x, 1.0);
      expect(pos[1]!.y, -familyTreeRowHeight);
      // Father's parents straddle the father, two rows up, a column apart.
      expect(pos[3]!.x, -1.5);
      expect(pos[4]!.x, -0.5);
      expect(pos[3]!.y, -2 * familyTreeRowHeight);
      // A couple is always centered over the child they share.
      expect((pos[1]!.x + pos[2]!.x) / 2, pos[0]!.x);
      expect((pos[3]!.x + pos[4]!.x) / 2, pos[1]!.x);
    });

    test('spouses go right of root, siblings go left, evenly spaced', () {
      final tree = FamilyTree(
        rootId: 0,
        nodes: [
          _node(0, generation: 0, fatherNodeId: 10, motherNodeId: 11),
          _node(1, generation: 0), // spouse (no parent link)
          _node(2, generation: 0), // spouse
          _node(3, generation: 0, fatherNodeId: 10, motherNodeId: 11), // sib
          _node(10, generation: -1),
          _node(11, generation: -1),
        ],
      );

      final pos = layoutFamilyTree(tree);

      expect(pos[0]!.x, 0);
      expect(pos[1]!.x, 1);
      expect(pos[2]!.x, 2);
      expect(pos[3]!.x, -1);
      expect(pos[1]!.y, 0);
      expect(pos[3]!.y, 0);
    });

    test('groups descendants under their actual parent, not by name order — '
        'stays correct for half-siblings from separate marriages', () {
      // root(0) has two children by different (untracked) partners: 1 (with
      // its own two kids 3,4) and 2 (with one kid 5). Grandchildren must
      // cluster under their real parent, in parent x-order.
      final tree = FamilyTree(
        rootId: 0,
        nodes: [
          _node(0, generation: 0),
          _node(1, generation: 1, fatherNodeId: 0),
          _node(2, generation: 1, fatherNodeId: 0),
          _node(3, generation: 2, fatherNodeId: 1),
          _node(4, generation: 2, fatherNodeId: 1),
          _node(5, generation: 2, fatherNodeId: 2),
        ],
      );

      final pos = layoutFamilyTree(tree);

      expect(pos[1]!.x, lessThan(pos[2]!.x));
      // 3 and 4 (under parent 1) both sit left of 5 (under parent 2).
      expect(pos[3]!.x, lessThan(pos[5]!.x));
      expect(pos[4]!.x, lessThan(pos[5]!.x));
      expect(pos[1]!.y, familyTreeRowHeight);
      expect(pos[3]!.y, 2 * familyTreeRowHeight);
      // Tidy subtree layout: each parent stands centered over its own
      // children, so connectors are short verticals.
      expect(pos[1]!.x, closeTo((pos[3]!.x + pos[4]!.x) / 2, 1e-9));
      expect(pos[2]!.x, closeTo(pos[5]!.x, 1e-9));
    });

    test('a node with no resolvable position (orphaned generation) is '
        'simply omitted rather than crashing', () {
      final tree = FamilyTree(
        rootId: 0,
        nodes: [_node(0, generation: 0)],
      );
      final pos = layoutFamilyTree(tree);
      expect(pos.keys, [0]);
    });

    test('children of the same father by different mothers form separate '
        'blocks, each ordered by its own mother, not interleaved by age', () {
      // root(0) married to 1 and 2; children 3,4 by wife 1 and 5,6 by wife 2,
      // listed in an age order that interleaves the two marriages.
      final tree = FamilyTree(
        rootId: 0,
        nodes: [
          _node(0, generation: 0),
          _node(1, generation: 0), // wife, placed at x=1
          _node(2, generation: 0), // wife, placed at x=2
          _node(3, generation: 1, fatherNodeId: 0, motherNodeId: 1),
          _node(5, generation: 1, fatherNodeId: 0, motherNodeId: 2),
          _node(4, generation: 1, fatherNodeId: 0, motherNodeId: 1),
          _node(6, generation: 1, fatherNodeId: 0, motherNodeId: 2),
        ],
      );

      final pos = layoutFamilyTree(tree);

      // Wife 1's children sit together, entirely left of wife 2's.
      expect(pos[3]!.x, lessThan(pos[4]!.x));
      expect(pos[4]!.x, lessThan(pos[5]!.x));
      expect(pos[5]!.x, lessThan(pos[6]!.x));
      // Adjacent blocks get extra separation beyond the in-block spacing.
      expect(
        pos[5]!.x - pos[4]!.x,
        greaterThan(pos[4]!.x - pos[3]!.x),
      );
    });

    test('generation-0 siblings cluster by parental couple: full siblings '
        'nearest the root, each half-sibling group as its own block', () {
      // Node order interleaves the two sibling groups by age; the layout
      // must unshuffle them. Root and full sibling 1 share parents 10+11;
      // 2 and 3 are by the father only.
      final tree = FamilyTree(
        rootId: 0,
        nodes: [
          _node(10, generation: -1),
          _node(11, generation: -1),
          _node(0, generation: 0, fatherNodeId: 10, motherNodeId: 11),
          _node(2, generation: 0, fatherNodeId: 10),
          _node(1, generation: 0, fatherNodeId: 10, motherNodeId: 11),
          _node(3, generation: 0, fatherNodeId: 10),
        ],
      );

      final pos = layoutFamilyTree(tree);

      // Full sibling adjacent to the root; half siblings contiguous beyond
      // it, separated by the block gap.
      expect(pos[1]!.x, -1);
      expect(pos[2]!.x, closeTo(-1 - 1 - familyTreeGroupGap, 1e-9));
      expect(pos[3]!.x, closeTo(pos[2]!.x - 1, 1e-9));
    });

    test("a recorded partner of the root stays on the spouse side even when "
        'their own parent is in view (Amram in Jochebed\'s tree)', () {
      // root(0) and sibling(1) are children of 10; the root's husband (2)
      // is the sibling's son — a partner link, so he must sit right of the
      // root with the spouses, not left with the siblings.
      final tree = FamilyTree(
        rootId: 0,
        rootPartnerIds: const [2],
        nodes: [
          _node(10, generation: -1),
          _node(0, generation: 0, fatherNodeId: 10),
          _node(1, generation: 0, fatherNodeId: 10),
          _node(2, generation: 0, fatherNodeId: 1),
        ],
      );

      final pos = layoutFamilyTree(tree);

      expect(pos[2]!.x, 1); // spouse side
      expect(pos[1]!.x, -1); // sibling side
    });

    test("each spouse of the root stands directly above her own children's "
        'block; children with no recorded second parent sit under the root',
        () {
      final tree = FamilyTree(
        rootId: 0,
        nodes: [
          _node(0, generation: 0),
          _node(1, generation: 0), // wife with four children
          _node(2, generation: 0), // wife with two children
          _node(9, generation: 1, fatherNodeId: 0), // mother unrecorded
          _node(3, generation: 1, fatherNodeId: 0, motherNodeId: 1),
          _node(4, generation: 1, fatherNodeId: 0, motherNodeId: 1),
          _node(5, generation: 1, fatherNodeId: 0, motherNodeId: 1),
          _node(6, generation: 1, fatherNodeId: 0, motherNodeId: 1),
          _node(7, generation: 1, fatherNodeId: 0, motherNodeId: 2),
          _node(8, generation: 1, fatherNodeId: 0, motherNodeId: 2),
        ],
      );

      final pos = layoutFamilyTree(tree);

      // The motherless child leads the row, under the root.
      expect(pos[9]!.x, lessThan(pos[3]!.x));
      expect(pos[9]!.x, closeTo(0.5, 1e-9));
      // Each wife sits over the center of her own block, wife 1 before
      // wife 2, all right of the root.
      expect(pos[1]!.x, closeTo((pos[3]!.x + pos[6]!.x) / 2, 1e-9));
      expect(pos[2]!.x, closeTo((pos[7]!.x + pos[8]!.x) / 2, 1e-9));
      expect(pos[1]!.x, greaterThan(0));
      expect(pos[2]!.x, greaterThan(pos[1]!.x));
    });
  });

  group('familyUnitsOf', () {
    test('groups children by parental couple and keeps single-parent links '
        'as their own unit', () {
      final tree = FamilyTree(
        rootId: 0,
        nodes: [
          _node(0, generation: 0),
          _node(1, generation: 0),
          _node(2, generation: 1, fatherNodeId: 0, motherNodeId: 1),
          _node(3, generation: 1, fatherNodeId: 0, motherNodeId: 1),
          _node(4, generation: 1, fatherNodeId: 0),
        ],
      );

      final units = familyUnitsOf(tree);

      expect(units, hasLength(2));
      final couple = units.firstWhere((u) => u.motherId == 1);
      expect(couple.fatherId, 0);
      expect(couple.childIds, [2, 3]);
      final single = units.firstWhere((u) => u.motherId == null);
      expect(single.fatherId, 0);
      expect(single.childIds, [4]);
    });

    test("emits a childless unit for a root partner no shared child covers, "
        'but not for one that is already a co-parent', () {
      final tree = FamilyTree(
        rootId: 0,
        rootPartnerIds: const [1, 2],
        nodes: [
          _node(0, generation: 0),
          _node(1, generation: 0),
          _node(2, generation: 0),
          _node(3, generation: 1, fatherNodeId: 0, motherNodeId: 1),
        ],
      );

      final units = familyUnitsOf(tree);

      expect(units, hasLength(2));
      final childless = units.firstWhere((u) => u.childIds.isEmpty);
      expect(childless.parentIds, containsAll([0, 2]));
      // Partner 1 is covered by the shared child — no duplicate unit.
      expect(
        units.where((u) => u.parentIds.contains(1)),
        hasLength(1),
      );
    });
  });
}
