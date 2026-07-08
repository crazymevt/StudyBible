/// The kinds of things the Explorer can open as a page. [browse] is a
/// browsable A-Z listing of one of the other kinds (see [ExplorerRef.browse]),
/// not an entity itself.
enum ExplorerEntityType { person, place, event, topic, passage, tag, browse }

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

  /// Which entity kind a browse page lists; null unless [type] is
  /// [ExplorerEntityType.browse].
  final ExplorerEntityType? browseKind;

  /// For a topic browse page, the curated category it's restricted to
  /// ('feast' or 'story'); null lists the plain (Nave's) topics — and always
  /// null for every other [type].
  final String? browseCategory;

  final String label;

  const ExplorerRef.person(int this.id, this.label)
      : type = ExplorerEntityType.person,
        book = null,
        chapter = null,
        tagId = null,
        browseKind = null,
        browseCategory = null;

  const ExplorerRef.place(int this.id, this.label)
      : type = ExplorerEntityType.place,
        book = null,
        chapter = null,
        tagId = null,
        browseKind = null,
        browseCategory = null;

  const ExplorerRef.event(int this.id, this.label)
      : type = ExplorerEntityType.event,
        book = null,
        chapter = null,
        tagId = null,
        browseKind = null,
        browseCategory = null;

  const ExplorerRef.topic(int this.id, this.label)
      : type = ExplorerEntityType.topic,
        book = null,
        chapter = null,
        tagId = null,
        browseKind = null,
        browseCategory = null;

  ExplorerRef.passage(String this.book, int this.chapter)
      : type = ExplorerEntityType.passage,
        id = null,
        tagId = null,
        browseKind = null,
        browseCategory = null,
        label = '$book $chapter';

  /// [label] should carry the leading `#` (e.g. `#faith`) so tag crumbs read
  /// as tags in the breadcrumb trail.
  const ExplorerRef.tag(String this.tagId, this.label)
      : type = ExplorerEntityType.tag,
        id = null,
        book = null,
        chapter = null,
        browseKind = null,
        browseCategory = null;

  /// A browsable index over every entity of one kind (the pages behind the
  /// Explorer home's dataset chips). [kind] must be one of the id-addressed
  /// entity kinds (person/place/event/topic). For topics, [category]
  /// restricts the index to one curated category ('feast' or 'story');
  /// null lists the plain (Nave's) topics.
  const ExplorerRef.browse(ExplorerEntityType kind, this.label,
      {String? category})
      : assert(kind == ExplorerEntityType.person ||
            kind == ExplorerEntityType.place ||
            kind == ExplorerEntityType.event ||
            kind == ExplorerEntityType.topic),
        assert(category == null || kind == ExplorerEntityType.topic),
        type = ExplorerEntityType.browse,
        browseKind = kind,
        browseCategory = category,
        id = null,
        book = null,
        chapter = null,
        tagId = null;

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
      other.tagId == tagId &&
      other.browseKind == browseKind &&
      other.browseCategory == browseCategory;

  @override
  int get hashCode =>
      Object.hash(type, id, book, chapter, tagId, browseKind, browseCategory);

  @override
  String toString() => 'ExplorerRef(${type.name}, $label)';
}
