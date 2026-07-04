import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/content_providers.dart';
import '../../app/explorer_providers.dart';
import '../../domain/explorer/entity_link.dart';
import '../../domain/explorer/explorer_ref.dart';
import '../explorer/explorer_screen.dart';

/// Tap handling for `sbent:` entity links inserted by "Link to Explorer" (see
/// `insert_entity_link_dialog.dart`) — the counterpart to
/// `reference_autolink.dart`'s handling of `sbref:` scripture links.

/// A [QuillEditorConfig.customLinkPrefixes]-style hook for tap handling, for
/// the same reason `referenceRecognizerBuilder` needs one: flutter_quill only
/// wires tap-to-launch for read-only/desktop, not editable mobile.
GestureRecognizer? Function(Attribute, Leaf) entityRecognizerBuilder(
  WidgetRef ref,
  BuildContext context,
) {
  return (attribute, leaf) {
    if (attribute.key != Attribute.link.key) return null;
    final value = attribute.value;
    if (value is! String || parseEntityLinkUrl(value) == null) return null;
    return TapGestureRecognizer()
      ..onTap = () => handleEntityLinkLaunch(ref, context, value);
  };
}

Future<String?> _entityLabel(
  WidgetRef ref,
  ExplorerEntityType type,
  int id,
) async {
  final store = ref.read(contentStoreProvider);
  switch (type) {
    case ExplorerEntityType.person:
      final p = await (store.select(store.biblePeople)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      return p?.displayTitle;
    case ExplorerEntityType.place:
      final p = await (store.select(store.places)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      return p?.name;
    case ExplorerEntityType.event:
      final e = await (store.select(store.timelineEvents)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      return e?.title;
    case ExplorerEntityType.topic:
      final t = await (store.select(store.topics)
            ..where((x) => x.id.equals(id)))
          .getSingleOrNull();
      return t?.name;
    case ExplorerEntityType.passage:
    case ExplorerEntityType.tag:
      return null;
  }
}

/// Handles a tapped `sbent:` link: opens the Explorer straight to that entity.
/// Looks up the current display name rather than trusting stale link text, in
/// case the entity was renamed since the link was inserted (the bundled
/// datasets are static, but this keeps the two sources of truth honest).
Future<void> handleEntityLinkLaunch(
  WidgetRef ref,
  BuildContext context,
  String url,
) async {
  final parsed = parseEntityLinkUrl(url);
  if (parsed == null) return;
  final label = await _entityLabel(ref, parsed.type, parsed.id);
  if (label == null || !context.mounted) return;

  final entityRef = switch (parsed.type) {
    ExplorerEntityType.person => ExplorerRef.person(parsed.id, label),
    ExplorerEntityType.place => ExplorerRef.place(parsed.id, label),
    ExplorerEntityType.event => ExplorerRef.event(parsed.id, label),
    ExplorerEntityType.topic => ExplorerRef.topic(parsed.id, label),
    ExplorerEntityType.passage || ExplorerEntityType.tag => null,
  };
  if (entityRef == null) return;

  ref.read(explorerTrailProvider.notifier)
    ..clear()
    ..open(entityRef);
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ExplorerScreen()));
}
