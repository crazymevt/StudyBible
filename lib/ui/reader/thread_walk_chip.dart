import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/thread_walk_providers.dart';
import '../../domain/explorer/explorer_ref.dart';
import '../explorer/explorer_screen.dart';

/// The thread walk's cockpit: a compact pill anchored at the bottom of the
/// reader while a thematic thread is being walked (see
/// `thread_walk_providers.dart`). Prev/next step the reader through the
/// thread's stops — the notifier navigates and paints the same temporary
/// highlight sermon routes use, with no verse selection, so hops never leave
/// selections to clean up. Tapping the label opens a sheet with the current
/// stop's connective note — the "why are we here" a guided walk lives on.
///
/// Renders nothing when no walk is active. Unlike [ReturnToSermonChip] the
/// walk is persisted, so the chip survives a restart mid-walk; the close
/// button ends the walk.
class ThreadWalkChip extends ConsumerWidget {
  const ThreadWalkChip({super.key});

  void _finish(BuildContext context, WidgetRef ref, ThreadWalk walk) {
    ref.read(threadWalkProvider.notifier).clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Walked the whole thread: ${walk.thread.title} '
          '(${walk.thread.stops.length} stops)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walk = ref.watch(threadWalkProvider);
    if (walk == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onColor = scheme.onSecondaryContainer;
    final total = walk.thread.stops.length;

    return Material(
      color: scheme.secondaryContainer,
      elevation: 3,
      borderRadius: BorderRadius.circular(24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _showStopSheet(context, ref, walk),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.route_outlined, size: 20, color: onColor),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      '${walk.thread.title} · ${walk.stop + 1}/$total',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: onColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: 'Previous stop',
            color: onColor,
            onPressed: walk.isFirst
                ? null
                : ref.read(threadWalkProvider.notifier).back,
          ),
          IconButton(
            icon: Icon(walk.isLast ? Icons.flag : Icons.chevron_right),
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            tooltip: walk.isLast ? 'Finish the walk' : 'Next stop',
            color: onColor,
            onPressed: () {
              if (walk.isLast) {
                _finish(context, ref, walk);
                return;
              }
              ref.read(threadWalkProvider.notifier).advance();
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            tooltip: 'End the walk',
            color: onColor,
            onPressed: () => ref.read(threadWalkProvider.notifier).clear(),
          ),
        ],
      ),
    );
  }

  /// The current stop's note, in a sheet: thread title, stop headline, the
  /// connective note, and doors back to the passage and the thread's
  /// Explorer page.
  void _showStopSheet(BuildContext context, WidgetRef ref, ThreadWalk walk) {
    final stop = walk.currentStop;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final scheme = theme.colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${walk.thread.title} · stop ${walk.stop + 1} of '
                  '${walk.thread.stops.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stop.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stop.passage,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  stop.note,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.route_outlined, size: 18),
                      label: const Text('Open thread'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        openInFreshExplorer(
                          context,
                          ref,
                          ExplorerRef.thread(
                            walk.threadIndex,
                            walk.thread.title,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.menu_book, size: 18),
                      label: const Text('Read the passage'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        ref
                            .read(threadWalkProvider.notifier)
                            .goToCurrentStop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
