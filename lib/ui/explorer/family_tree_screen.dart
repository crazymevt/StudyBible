import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/family_tree_providers.dart';
import '../../domain/explorer/explorer_ref.dart';
import '../../domain/explorer/family_tree.dart';
import '../../domain/explorer/family_tree_layout.dart';
import '../common/skeleton.dart';
import 'explorer_common.dart';
import 'explorer_screen.dart';

const double _pxPerColumn = 170;
const double _pxPerRow = 130;
const double _nodeWidth = 140;
const double _nodeHeight = 64;

/// Route name every [FamilyTreeScreen] push is tagged with (both the initial
/// entry point and every re-center) so the "close" action can pop all of
/// them at once, however many re-centers deep — see [FamilyTreeScreen].
const familyTreeRouteName = 'family_tree';

/// A [MaterialPageRoute] to [FamilyTreeScreen], tagged with
/// [familyTreeRouteName]. Use this everywhere a family tree is opened or
/// re-centered so "Close family tree" can find its way back out in one tap.
Route<void> familyTreeRoute(int personId) => MaterialPageRoute(
      settings: const RouteSettings(name: familyTreeRouteName),
      builder: (_) => FamilyTreeScreen(personId: personId),
    );

/// Opens [node] in a fresh Explorer view — the full person page (bio,
/// events, places, stories), not just this chart's summary card.
void _openInExplorer(BuildContext context, WidgetRef ref, FamilyTreeNode node) {
  openInFreshExplorer(
    context,
    ref,
    ExplorerRef.person(node.id, node.displayTitle),
  );
}

/// Full-screen pedigree chart for a person: [FamilyTree.rootId]'s ancestors
/// above, descendants below, spouses/siblings alongside on the center row.
/// Tapping any other node re-centers the chart on them by pushing a new
/// instance of this screen — the bounded window (see
/// `family_tree_providers.dart`) never needs to render an entire, possibly
/// 75-generation-deep line at once.
class FamilyTreeScreen extends ConsumerWidget {
  const FamilyTreeScreen({super.key, required this.personId});

  final int personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(familyTreeProvider(personId));
    final root = treeAsync.asData?.value?.nodes
        .where((n) => n.id == personId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(root?.displayTitle ?? 'Family tree'),
        actions: [
          if (root != null)
            IconButton(
              icon: const Icon(Icons.explore_outlined),
              tooltip: 'Open ${root.displayTitle} in Explorer',
              onPressed: () => _openInExplorer(context, ref, root),
            ),
          // The back arrow only steps up one re-center at a time (to the
          // previous person); this jumps out of the whole family-tree stack
          // in one tap, back to wherever it was opened from.
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close family tree',
            onPressed: () => Navigator.of(context)
                .popUntil((route) => route.settings.name != familyTreeRouteName),
          ),
        ],
      ),
      body: treeAsync.when(
        loading: () => const SkeletonList(),
        error: (e, _) => Center(child: Text('Couldn\'t load this family: $e')),
        data: (tree) {
          if (tree == null || tree.nodes.length <= 1) {
            return const Center(
              child: Text('No recorded family for this person.'),
            );
          }
          return _FamilyTreeChart(
            tree: tree,
            onOpenInExplorer: (node) => _openInExplorer(context, ref, node),
          );
        },
      ),
    );
  }
}

class _FamilyTreeChart extends StatefulWidget {
  const _FamilyTreeChart({required this.tree, required this.onOpenInExplorer});

  final FamilyTree tree;

  /// Opens a node's full Explorer page — wired to the root card's tap (the
  /// person you've navigated to) and to every node's long-press (so any
  /// visible ancestor/descendant can be opened directly, without first
  /// re-centering the chart on them).
  final void Function(FamilyTreeNode node) onOpenInExplorer;

  @override
  State<_FamilyTreeChart> createState() => _FamilyTreeChartState();
}

class _FamilyTreeChartState extends State<_FamilyTreeChart> {
  // Set once, on the first build, from that build's viewport size — not
  // re-centered on later resizes, since by then the user may have panned
  // deliberately.
  TransformationController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tree = widget.tree;
    final positions = layoutFamilyTree(tree);

    var minX = 0.0, maxX = 0.0, minY = 0.0, maxY = 0.0;
    for (final p in positions.values) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    const padding = 40.0;
    final originX = padding + -minX * _pxPerColumn + _nodeWidth / 2;
    final originY = padding + -minY * _pxPerRow + _nodeHeight / 2;
    final canvasWidth = (maxX - minX) * _pxPerColumn + _nodeWidth + padding * 2;
    final canvasHeight = (maxY - minY) * _pxPerRow + _nodeHeight + padding * 2;

    final centers = <int, Offset>{
      for (final e in positions.entries)
        e.key: Offset(
          originX + e.value.x * _pxPerColumn,
          originY + e.value.y * _pxPerRow,
        ),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        // The root's own card, centered in the viewport this screen opened
        // with — otherwise a deep ancestor/descendant window lands the
        // person you actually asked for off-screen, at the canvas's origin.
        final viewport = constraints.biggest;
        final rootCenter = centers[tree.rootId]!;
        _controller ??= TransformationController(
          Matrix4.translationValues(
            viewport.width / 2 - rootCenter.dx,
            viewport.height / 2 - rootCenter.dy,
            0,
          ),
        );

        return InteractiveViewer(
          transformationController: _controller,
          constrained: false,
          minScale: 0.3,
          maxScale: 2,
          boundaryMargin: const EdgeInsets.all(200),
          child: SizedBox(
            width: canvasWidth,
            height: canvasHeight,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size(canvasWidth, canvasHeight),
                  painter: _FamilyTreeEdgePainter(
                    tree: tree,
                    centers: centers,
                    brightness: Theme.of(context).brightness,
                  ),
                ),
                for (final node in tree.nodes)
                  if (centers.containsKey(node.id))
                    Positioned(
                      left: centers[node.id]!.dx - _nodeWidth / 2,
                      top: centers[node.id]!.dy - _nodeHeight / 2,
                      width: _nodeWidth,
                      height: _nodeHeight,
                      child: _FamilyTreeNodeCard(
                        node: node,
                        isRoot: node.id == tree.rootId,
                        onTap: node.id == tree.rootId
                            ? () => widget.onOpenInExplorer(node)
                            : () => Navigator.of(context)
                                .push(familyTreeRoute(node.id)),
                        onLongPress: () => widget.onOpenInExplorer(node),
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Hues for the family connectors — every family unit gets its own, cycled
/// when a chart has more couples than colors, so adjacent families always
/// read apart (children of a multi-marriage patriarch, many sibling blocks
/// on the grandchildren row).
const _coupleBaseColors = <MaterialColor>[
  Colors.blue,
  Colors.orange,
  Colors.green,
  Colors.purple,
  Colors.pink,
  Colors.teal,
  Colors.indigo,
  Colors.brown,
];

/// Draws one orthogonal "family bus" per parental couple instead of a
/// diagonal line per child-parent pair: short stubs down from each parent
/// meet a marriage join, a single drop line falls to a horizontal rail above
/// the children's row, and a stub rises into each child. Sibling groups read
/// as blocks, and every family gets its own color.
class _FamilyTreeEdgePainter extends CustomPainter {
  _FamilyTreeEdgePainter({
    required this.tree,
    required this.centers,
    required this.brightness,
  });

  final FamilyTree tree;
  final Map<int, Offset> centers;
  final Brightness brightness;

  /// Marriage join's distance below the parents' row.
  static const _junctionDrop = 12.0;

  /// Extra join depth per level, for joins that overlap horizontally (one
  /// person's several marriages, or families pushed right of their parents).
  static const _junctionStagger = 8.0;

  /// How many join depth levels fit in the gap between two rows.
  static const _junctionLevels = 5;

  /// Sibling rail's distance above the children's row.
  static const _railRise = 16.0;

  /// Horizontal gap between marriage stubs leaving the same parent card.
  static const _stubSpread = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final generationOf = {for (final n in tree.nodes) n.id: n.generation};
    final palette = [
      for (final c in _coupleBaseColors)
        brightness == Brightness.dark ? c.shade300 : c.shade600,
    ];

    // Bucket units by the row their children live on (for a childless
    // marriage of the root, the row below generation 0): colors and join
    // stagger are assigned within a row, since that's where families can
    // visually collide.
    final byRow = <int, List<FamilyUnit>>{};
    for (final unit in familyUnitsOf(tree)) {
      if (!unit.parentIds.any(centers.containsKey)) continue;
      if (_isSameRowParentChild(unit)) continue;
      final row = unit.childIds.isNotEmpty
          ? generationOf[unit.childIds.first]!
          : generationOf[unit.parentIds.first]! + 1;
      byRow.putIfAbsent(row, () => []).add(unit);
    }

    // Row order top-to-bottom, so color assignment is stable and reads in
    // the same order the eye scans the chart.
    final rows = byRow.keys.toList()..sort();
    var colorIndex = 0;
    for (final row in rows) {
      final rowUnits = byRow[row]!;
      double anchorX(FamilyUnit u) {
        final xs = [
          for (final p in u.parentIds)
            if (centers[p] != null) centers[p]!.dx,
        ];
        return xs.reduce((a, b) => a + b) / xs.length;
      }

      rowUnits.sort((a, b) => anchorX(a).compareTo(anchorX(b)));

      // Stub slot per (parent, unit): a person with several marriages gets
      // side-by-side stubs under their card instead of one overdrawn line.
      final unitCountByParent = <int, int>{};
      final slotByParent = <FamilyUnit, Map<int, int>>{};
      for (final unit in rowUnits) {
        for (final p in unit.parentIds) {
          if (!centers.containsKey(p)) continue;
          slotByParent.putIfAbsent(unit, () => {})[p] =
              unitCountByParent[p] ?? 0;
          unitCountByParent[p] = (unitCountByParent[p] ?? 0) + 1;
        }
      }

      // Join depth per unit, assigned like an interval schedule: a level is
      // reused only once the previous join on it ends left of the next
      // one's start. Nested joins (one person's marriages) stack downward;
      // long chains of families pushed right of their parents reuse the
      // shallow levels instead of colliding on them.
      final levelEnds =
          List<double>.filled(_junctionLevels, double.negativeInfinity);
      for (var i = 0; i < rowUnits.length; i++) {
        final unit = rowUnits[i];
        final (start, end) = _joinSpanOf(unit);
        var level = -1;
        for (var l = 0; l < _junctionLevels; l++) {
          if (levelEnds[l] + 40 <= start) {
            level = l;
            break;
          }
        }
        if (level == -1) level = i % _junctionLevels;
        if (end > levelEnds[level]) levelEnds[level] = end;
        _drawUnit(
          canvas,
          unit,
          color: palette[colorIndex++ % palette.length],
          staggerIndex: level,
          slots: slotByParent[unit]!,
          counts: unitCountByParent,
        );
      }
    }
  }

  void _drawUnit(
    Canvas canvas,
    FamilyUnit unit, {
    required Color color,
    required int staggerIndex,
    required Map<int, int> slots,
    required Map<int, int> counts,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final parentCenters = [
      for (final p in unit.parentIds)
        if (centers[p] != null) (p, centers[p]!),
    ];
    final childCenters = [
      for (final c in unit.childIds)
        if (centers[c] != null) centers[c]!,
    ];
    if (parentCenters.isEmpty) return;
    if (childCenters.isEmpty && parentCenters.length < 2) return;

    // The join sits below the *lowest* parent row — partners aren't always
    // level (Amram married his aunt Jochebed, one generation up).
    var lowestParentBottomY = double.negativeInfinity;
    for (final (_, center) in parentCenters) {
      final bottom = center.dy + _nodeHeight / 2;
      if (bottom > lowestParentBottomY) lowestParentBottomY = bottom;
    }

    final junctionY = lowestParentBottomY +
        _junctionDrop +
        (staggerIndex % _junctionLevels) * _junctionStagger;

    const maxStubOffset = _nodeWidth / 2 - 10;
    final stubXs = <double>[];
    for (final (p, center) in parentCenters) {
      final slotCount = counts[p]!;
      final offset = ((slots[p]! - (slotCount - 1) / 2) * _stubSpread)
          .clamp(-maxStubOffset, maxStubOffset);
      final stubX = center.dx + offset;
      final stubTopY = center.dy + _nodeHeight / 2;
      // An off-row partner reaches the join with a long stub, but only when
      // no card sits in its path — a line disappearing under an unrelated
      // card would read as that card's marriage instead.
      if (stubTopY < lowestParentBottomY &&
          _stubBlocked(stubX, center.dy, junctionY)) {
        continue;
      }
      stubXs.add(stubX);
      canvas.drawLine(Offset(stubX, stubTopY), Offset(stubX, junctionY), paint);
    }
    if (stubXs.isEmpty) return;
    stubXs.sort();

    if (childCenters.isEmpty) {
      // A recorded marriage with no children inside the window: the join
      // between the couple is the whole drawing.
      canvas.drawLine(
        Offset(stubXs.first, junctionY),
        Offset(stubXs.last, junctionY),
        paint,
      );
      return;
    }

    final childXs = childCenters.map((c) => c.dx).toList()..sort();
    final railY = childCenters.first.dy - _nodeHeight / 2 - _railRise;
    final dropX = (stubXs.reduce((a, b) => a + b) / stubXs.length)
        .clamp(childXs.first, childXs.last);

    final joinLeft = stubXs.first < dropX ? stubXs.first : dropX;
    final joinRight = stubXs.last > dropX ? stubXs.last : dropX;
    if (joinRight > joinLeft) {
      canvas.drawLine(
        Offset(joinLeft, junctionY),
        Offset(joinRight, junctionY),
        paint,
      );
    }
    canvas.drawLine(Offset(dropX, junctionY), Offset(dropX, railY), paint);
    if (childXs.last > childXs.first) {
      canvas.drawLine(
        Offset(childXs.first, railY),
        Offset(childXs.last, railY),
        paint,
      );
    }
    for (final child in childCenters) {
      canvas.drawLine(
        Offset(child.dx, railY),
        Offset(child.dx, child.dy - _nodeHeight / 2),
        paint,
      );
    }
  }

  /// The horizontal span [unit]'s join will occupy: from its leftmost to
  /// its rightmost of (parent stubs, drop line). Approximate — it ignores
  /// the few-pixel stub slot offsets — but plenty for level scheduling.
  (double, double) _joinSpanOf(FamilyUnit unit) {
    final parentXs = [
      for (final p in unit.parentIds)
        if (centers[p] != null) centers[p]!.dx,
    ];
    var dropX = parentXs.reduce((a, b) => a + b) / parentXs.length;
    final childXs = [
      for (final c in unit.childIds)
        if (centers[c] != null) centers[c]!.dx,
    ];
    if (childXs.isNotEmpty) {
      childXs.sort();
      dropX = dropX.clamp(childXs.first, childXs.last);
    }
    var start = dropX, end = dropX;
    for (final px in parentXs) {
      if (px < start) start = px;
      if (px > end) end = px;
    }
    return (start, end);
  }

  /// Whether one of [unit]'s children sits level with (or above) one of its
  /// own parents — it happens when someone married across generations
  /// (Kohath shares a row with his son Amram in Jochebed's tree, where
  /// Kohath is her brother and Amram her husband). No line between two
  /// same-row cards can read as parent-child, so these units are left to
  /// the re-centered charts, where the pair lands on separate rows.
  bool _isSameRowParentChild(FamilyUnit unit) {
    var lowestParentBottomY = double.negativeInfinity;
    for (final parentId in unit.parentIds) {
      final center = centers[parentId];
      if (center != null && center.dy + _nodeHeight / 2 > lowestParentBottomY) {
        lowestParentBottomY = center.dy + _nodeHeight / 2;
      }
    }
    for (final childId in unit.childIds) {
      final center = centers[childId];
      if (center != null && center.dy <= lowestParentBottomY) return true;
    }
    return false;
  }

  /// Whether a vertical stub from a card at [parentCenterY] down to
  /// [junctionY] would pass through any other node's card.
  bool _stubBlocked(double stubX, double parentCenterY, double junctionY) {
    for (final center in centers.values) {
      if (center.dy <= parentCenterY + 1) continue;
      if (center.dy - _nodeHeight / 2 >= junctionY) continue;
      if ((center.dx - stubX).abs() < _nodeWidth / 2 + 8) return true;
    }
    return false;
  }

  @override
  bool shouldRepaint(_FamilyTreeEdgePainter old) =>
      old.tree != tree || old.brightness != brightness;
}

class _FamilyTreeNodeCard extends StatelessWidget {
  const _FamilyTreeNodeCard({
    required this.node,
    required this.isRoot,
    required this.onTap,
    required this.onLongPress,
  });

  final FamilyTreeNode node;
  final bool isRoot;
  final VoidCallback? onTap;

  /// Long-pressing any node — root or not — opens it in the Explorer
  /// directly, without first re-centering the chart on them.
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final years = <String>[
      if (node.birthYear != null && node.deathYear != null)
        '${explorerYearLabel(node.birthYear!)} – '
            '${explorerYearLabel(node.deathYear!)}'
      else if (node.birthYear != null)
        'b. ${explorerYearLabel(node.birthYear!)}'
      else if (node.deathYear != null)
        'd. ${explorerYearLabel(node.deathYear!)}',
    ];
    return Material(
      color: isRoot ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isRoot ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      node.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight:
                                isRoot ? FontWeight.w700 : FontWeight.w600,
                          ),
                    ),
                  ),
                  if (isRoot)
                    Icon(Icons.explore_outlined, size: 14, color: scheme.primary),
                ],
              ),
              if (years.isNotEmpty)
                Text(
                  years.first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
