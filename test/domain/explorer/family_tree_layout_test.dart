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
      // Father/mother straddle the root, one row up.
      expect(pos[1]!.x, -0.5);
      expect(pos[2]!.x, 0.5);
      expect(pos[1]!.y, -familyTreeRowHeight);
      // Father's parents straddle the father, two rows up, at half spacing.
      expect(pos[3]!.x, -0.75);
      expect(pos[4]!.x, -0.25);
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
  });
}
