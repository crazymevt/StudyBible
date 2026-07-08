import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/sermon_providers.dart';
import '../../data/user_store.dart';
import '../sermons/sermon_editor_screen.dart';

/// A compact "return to the sermon you were editing" pill anchored at the bottom
/// of the reader on compact layouts (phone / portrait tablet). There the sermon
/// editor is a full-screen route, so consulting the reader — or stepping through
/// a sermon's scripture-navigation route — hides the sermon with no quick way
/// back. One tap reopens the exact sermon full-screen.
///
/// Renders nothing when no sermon was opened this session, and retires itself if
/// that sermon is gone (deleted or synced away). Never shown on wide layouts,
/// where the sermon is already docked beside the reader — the caller gates on
/// width; the widget only handles the "is there a target" question.
class ReturnToSermonChip extends ConsumerWidget {
  const ReturnToSermonChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ref.watch(lastOpenedSermonIdProvider);
    if (id == null) return const SizedBox.shrink();

    // Resolve the title live so a rename shows through. allSermonsProvider
    // already excludes deleted rows, so a missing match means the sermon is
    // genuinely gone — drop the stale target and hide.
    final sermons = ref.watch(allSermonsProvider).value;
    Sermon? sermon;
    if (sermons != null) {
      for (final s in sermons) {
        if (s.id == id) {
          sermon = s;
          break;
        }
      }
      if (sermon == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(lastOpenedSermonIdProvider.notifier).clear();
        });
        return const SizedBox.shrink();
      }
    }

    final rawTitle = sermon?.title.trim() ?? '';
    final label = rawTitle.isEmpty ? 'Untitled Sermon' : rawTitle;
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.secondaryContainer,
      elevation: 3,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                SermonEditorScreen(sermonId: id, isFullScreen: true),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_note,
                size: 20,
                color: theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                tooltip: 'Dismiss',
                color: theme.colorScheme.onSecondaryContainer,
                onPressed: () =>
                    ref.read(lastOpenedSermonIdProvider.notifier).clear(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
