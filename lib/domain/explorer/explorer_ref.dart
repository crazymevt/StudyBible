/// The kinds of things the Explorer can open as a page.
enum ExplorerEntityType { person, place, event, topic, passage }

/// An addressable Explorer destination — one entry in the exploration trail.
///
/// People, places, events, and topics are addressed by their content-store row
/// id; a passage is addressed by canonical book name + chapter. [label] is the
/// human-readable name shown in breadcrumbs, captured at push time so the
/// trail can render without re-querying.
class ExplorerRef {
  final ExplorerEntityType type;

  /// Row id for person/place/event/topic refs; null for passages.
  final int? id;

  /// Canonical book name for passage refs; null otherwise.
  final String? book;

  /// Chapter for passage refs; null otherwise.
  final int? chapter;

  final String label;

  const ExplorerRef.person(int this.id, this.label)
      : type = ExplorerEntityType.person,
        book = null,
        chapter = null;

  const ExplorerRef.place(int this.id, this.label)
      : type = ExplorerEntityType.place,
        book = null,
        chapter = null;

  const ExplorerRef.event(int this.id, this.label)
      : type = ExplorerEntityType.event,
        book = null,
        chapter = null;

  const ExplorerRef.topic(int this.id, this.label)
      : type = ExplorerEntityType.topic,
        book = null,
        chapter = null;

  ExplorerRef.passage(String this.book, int this.chapter)
      : type = ExplorerEntityType.passage,
        id = null,
        label = '$book $chapter';

  /// Same destination (ignores [label], which is display-only).
  @override
  bool operator ==(Object other) =>
      other is ExplorerRef &&
      other.type == type &&
      other.id == id &&
      other.book == book &&
      other.chapter == chapter;

  @override
  int get hashCode => Object.hash(type, id, book, chapter);

  @override
  String toString() => 'ExplorerRef(${type.name}, $label)';
}
