/// A monarch referenced in scripture, with a short account of the reign.
///
/// Covers the united kingdom and the divided kingdoms of Israel and Judah,
/// plus foreign rulers scripture names directly (Egyptian, Assyrian,
/// Babylonian, Persian, and Roman). Appointed governors/procurators (Pilate,
/// Felix, Festus) are out of scope — this is monarchs only.
///
/// [citations] are scripture reference strings in the same "Book C:V",
/// "Book C:V-V", or whole-chapter "Book C" form the Prophecies/Feasts/
/// curated-topic data use, so the reader's passage navigation can parse them
/// with the shared reference regex. Book names are the canonical KJV display
/// names — every reference is validated against `kjvVersification` by
/// `reference_data_test.dart`.
///
/// [reignSummary] is a display string rather than structured start/end years:
/// biblical chronology (especially the divided-kingdom synchronisms) is
/// genuinely disputed among scholars, so dates are given as approximate
/// ("c.") ranges for context, not asserted as settled fact. [sortKey] is a
/// separate int used purely to order the list chronologically — it doesn't
/// claim precision beyond ordering.
class KingReign {
  final String id;
  final String name;
  final Realm realm;

  /// e.g. "King", "Queen", "Pharaoh", "Emperor", "Tetrarch".
  final String title;

  /// Display text, e.g. "c. 1010–970 BC (40 years)".
  final String reignSummary;

  /// Chronological sort order within the full list; lower is earlier.
  final int sortKey;

  /// Scripture's own verdict on the reign — null for foreign rulers scripture
  /// doesn't morally evaluate.
  final Verdict? verdict;

  /// A sentence or two of context — what the reign is known for.
  final String notes;

  final List<String> citations;

  /// The content store's `BiblePeople.id` for this king, hand-verified
  /// against `assets/data/theographic.json` (name collisions there make
  /// automatic matching unsafe — see the Reference Phase 5 plan notes) —
  /// null unless individually confirmed. Powers the "Open in Explorer"
  /// button and the Explorer passage-page facet.
  final int? explorerPersonId;

  const KingReign({
    required this.id,
    required this.name,
    required this.realm,
    required this.title,
    required this.reignSummary,
    required this.sortKey,
    this.verdict,
    required this.notes,
    required this.citations,
    this.explorerPersonId,
  });
}

/// Grouping key for browsing, ordered as the kingdoms actually succeed one
/// another so the list reads as a single timeline.
enum Realm {
  united('United Kingdom'),
  israel('Northern Kingdom (Israel)'),
  judah('Southern Kingdom (Judah)'),
  egypt('Egypt'),
  assyria('Assyria'),
  babylon('Babylon'),
  persia('Persia'),
  rome('Rome');

  const Realm(this.label);

  final String label;
}

/// Scripture's verdict on a king of Israel or Judah — the repeated "did
/// [right/evil] in the eyes/sight of the LORD" refrain of Kings/Chronicles.
enum Verdict {
  good('Did right in the eyes of the LORD'),
  bad('Did evil in the eyes of the LORD'),
  mixed('Began well, but not wholly — a mixed reign');

  const Verdict(this.label);

  final String label;
}
