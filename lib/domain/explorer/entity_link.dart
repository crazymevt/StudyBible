import 'dart:convert';

import 'explorer_ref.dart';

/// Turns an explicit "Link to Explorer" pick (from a notebook page) into a
/// tappable link, and lets Explorer entity pages find their way back to any
/// notebook page that links to them.
///
/// Unlike scripture references (auto-detected from typed text via
/// [BibleReferenceScanner]), person/place/event/topic mentions aren't
/// auto-detected — dataset names collide too often with ordinary prose (a
/// person named "Grace", a topic named "Love") to scan for safely. Instead the
/// editor's "Link to Explorer" action inserts one of these links explicitly,
/// so backlink lookups can match on the stored link exactly instead of
/// re-scanning prose.

const String entityLinkScheme = 'sbent';

/// Must be passed to `QuillEditorConfig.customLinkPrefixes` wherever these
/// links are shown, for the same reason `referenceLinkPrefixes` is.
const List<String> entityLinkPrefixes = <String>[entityLinkScheme];

/// Encodes [ref] (person/place/event/topic only — [ref.id] must be set) as
/// `sbent:<type>|<id>`.
String buildEntityLinkUrl(ExplorerRef ref) {
  assert(ref.id != null, 'entity links are only defined for id-addressed refs');
  return '$entityLinkScheme:${ref.type.name}|${ref.id}';
}

/// A `sbent:` link parsed back out of stored Delta content.
class ParsedEntityLink {
  final ExplorerEntityType type;
  final int id;
  const ParsedEntityLink(this.type, this.id);

  @override
  bool operator ==(Object other) =>
      other is ParsedEntityLink && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);
}

/// Parses an `sbent:` URL, or returns null if [url] isn't one of ours.
ParsedEntityLink? parseEntityLinkUrl(String url) {
  if (!url.startsWith('$entityLinkScheme:')) return null;
  final body = url.substring(entityLinkScheme.length + 1);
  final parts = body.split('|');
  if (parts.length != 2) return null;
  ExplorerEntityType? type;
  for (final t in ExplorerEntityType.values) {
    if (t.name == parts[0]) {
      type = t;
      break;
    }
  }
  final id = int.tryParse(parts[1]);
  if (type == null || id == null) return null;
  return ParsedEntityLink(type, id);
}

/// Scans a Quill Delta JSON string (as stored in `NotebookPages.content`) for
/// `sbent:` link attributes. Hand-rolled over the raw ops rather than parsing
/// a full Quill `Document`, mirroring `deltaToPlainText`'s approach — this way
/// the domain layer stays free of the Flutter-side `flutter_quill` package.
List<ParsedEntityLink> extractEntityLinksFromDelta(String deltaJson) {
  if (deltaJson.isEmpty) return const [];
  try {
    final decoded = jsonDecode(deltaJson);
    if (decoded is! List) return const [];
    final links = <ParsedEntityLink>[];
    for (final op in decoded) {
      if (op is Map) {
        final url = op['attributes'] is Map ? op['attributes']['link'] : null;
        if (url is String) {
          final parsed = parseEntityLinkUrl(url);
          if (parsed != null) links.add(parsed);
        }
      }
    }
    return links;
  } catch (_) {
    return const [];
  }
}
