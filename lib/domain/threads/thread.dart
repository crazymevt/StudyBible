/// A thematic thread: one biblical motif walked passage-by-passage from
/// Genesis to Revelation — the Explorer's guided-traversal counterpart to the
/// Atlas's geographic journeys and the reading plans' calendar routes.
///
/// [ThreadStop.passage] uses the same "Book C", "Book C:V", or "Book C:V-V"
/// scripture-reference form the Prophecies and curated-topic data use, with
/// canonical KJV display book names — every reference is validated against
/// `kjvVersification` by `thread_data_test.dart`, which also enforces that a
/// thread's stops run in canonical book order (the walk always moves forward
/// through the canon).
class ThreadStop {
  /// Short headline for this stop, e.g. "God will provide himself a lamb".
  final String title;

  /// The passage to read at this stop.
  final String passage;

  /// The connective tissue: one or two sentences on why the thread jumps
  /// here — what this passage adds to the motif and how it links back to the
  /// previous stop. This is what turns a reference list into a guided walk.
  final String note;

  const ThreadStop({
    required this.title,
    required this.passage,
    required this.note,
  });
}

/// Browsable groupings for the thread list.
enum ThreadCategory {
  motif('Motifs & Symbols'),
  covenant('Covenants & Promises'),
  typology('Types & Shadows'),
  name('Names of God');

  const ThreadCategory(this.label);

  /// Human-readable section heading.
  final String label;
}

class Thread {
  final String id;

  /// Short display title, e.g. "The Lamb".
  final String title;

  final ThreadCategory category;

  /// One-paragraph overview of the motif and where the walk leads.
  final String description;

  /// The walk itself, in canonical order, Genesis → Revelation. Aim for
  /// 6-12 stops: enough to feel the arc, short enough to finish in a sitting.
  final List<ThreadStop> stops;

  const Thread({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.stops,
  });
}
