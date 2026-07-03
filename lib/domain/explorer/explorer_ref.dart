/// The kinds of things the Explorer can open as a page.
enum ExplorerEntityType { person, place, event, topic, passage, tag }

/// An addressable Explorer destination — one entry in the exploration trail.
///
/// People, places, events, and topics are addressed by their content-store row
/// id; a passage is addressed by canonical book name + chapter; a user tag is
/// addressed by its uuid in the user store. [label] is the human-readable name
/// shown in breadcrumbs, captured at push time so the trail can render
/// without re-querying.
class ExplorerRef {
  final ExplorerEntityType type;

  /// Row id for person/place/event/topic refs; null otherwise.
  final int? id;

  /// Canonical book name for passage refs; null otherwise.
  final String? book;

  /// Chapter for passage refs; null otherwise.
  final int? chapter;

  /// Tag uuid for tag refs; null otherwise.
  final String? tagId;

  final String label;

  const ExplorerRef.person(int this.id, this.label)
      : type = ExplorerEntityType.person,
        book = null,
        chapter = null,
        tagId = null;

  const ExplorerRef.place(int this.id, this.label)
      : type = ExplorerEntityType.place,
        book = null,
        chapter = null,
        tagId = null;

  const ExplorerRef.event(int this.id, this.label)
      : type = ExplorerEntityType.event,
        book = null,
        chapter = null,
        tagId = null;

  const ExplorerRef.topic(int this.id, this.label)
      : type = ExplorerEntityType.topic,
        book = null,
        chapter = null,
        tagId = null;

  ExplorerRef.passage(String this.book, int this.chapter)
      : type = ExplorerEntityType.passage,
        id = null,
        tagId = null,
        label = '$book $chapter';

  /// [label] should carry the leading `#` (e.g. `#faith`) so tag crumbs read
  /// as tags in the breadcrumb trail.
  const ExplorerRef.tag(String this.tagId, this.label)
      : type = ExplorerEntityType.tag,
        id = null,
        book = null,
        chapter = null;

  /// Same destination (ignores [label], which is display-only — except for
  /// tags, whose label is their identity-bearing name only in display terms;
  /// the uuid still decides equality).
  @override
  bool operator ==(Object other) =>
      other is ExplorerRef &&
      other.type == type &&
      other.id == id &&
      other.book == book &&
      other.chapter == chapter &&
      other.tagId == tagId;

  @override
  int get hashCode => Object.hash(type, id, book, chapter, tagId);

  @override
  String toString() => 'ExplorerRef(${type.name}, $label)';
}
