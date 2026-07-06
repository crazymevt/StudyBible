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

    Offset pixelCenter(int id) {
      final p = positions[id]!;
      return Offset(originX + p.x * _pxPerColumn, originY + p.y * _pxPerRow);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // The root's own card, centered in the viewport this screen opened
        // with — otherwise a deep ancestor/descendant window lands the
        // person you actually asked for off-screen, at the canvas's origin.
        final viewport = constraints.biggest;
        final rootCenter = pixelCenter(tree.rootId);
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
                    pixelCenter: pixelCenter,
                    lineColor: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                for (final node in tree.nodes)
                  if (positions.containsKey(node.id))
                    Positioned(
                      left: pixelCenter(node.id).dx - _nodeWidth / 2,
                      top: pixelCenter(node.id).dy - _nodeHeight / 2,
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

class _FamilyTreeEdgePainter extends CustomPainter {
  _FamilyTreeEdgePainter({
    required this.tree,
    required this.pixelCenter,
    required this.lineColor,
  });

  final FamilyTree tree;
  final Offset Function(int id) pixelCenter;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5;
    for (final node in tree.nodes) {
      final childCenter = pixelCenter(node.id);
      if (node.fatherNodeId != null) {
        canvas.drawLine(childCenter, pixelCenter(node.fatherNodeId!), paint);
      }
      if (node.motherNodeId != null) {
        canvas.drawLine(childCenter, pixelCenter(node.motherNodeId!), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_FamilyTreeEdgePainter old) => old.tree != tree;
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
