/// A single Old Testament prophecy paired with its New Testament fulfillment.
///
/// [prophecy] and [fulfillment] are scripture reference strings in the same
/// "Book C:V", "Book C:V-V", or whole-chapter "Book C" form the Feasts and
/// curated-topic data use, so the reader's passage navigation can parse them
/// with the shared reference regex. Book names are the canonical KJV display
/// names (e.g. "Micah", "1 Samuel", "Song of Solomon") — every reference is
/// validated against `kjvVersification` by `prophecy_data_test.dart`.
class Prophecy {
  final String id;

  /// Short headline, e.g. "The Messiah born in Bethlehem".
  final String title;

  /// Grouping key for browsing — see [ProphecyCategory].
  final ProphecyCategory category;

  /// What the Old Testament foretold.
  final String prophecyText;

  /// Old Testament reference(s), e.g. ["Micah 5:2"].
  final List<String> prophecy;

  /// How the New Testament records its fulfillment.
  final String fulfillmentText;

  /// New Testament reference(s), e.g. ["Matthew 2:1", "John 7:42"].
  final List<String> fulfillment;

  const Prophecy({
    required this.id,
    required this.title,
    required this.category,
    required this.prophecyText,
    required this.prophecy,
    required this.fulfillmentText,
    required this.fulfillment,
  });
}

/// Browsable groupings for the prophecy list, ordered roughly along the arc of
/// redemptive history so the "By theme" view reads as a progression.
///
/// Categories are limited to arcs the New Testament itself quotes or applies,
/// so every fulfillment reference lands on a real NT passage — prophecies whose
/// fulfillment is purely historical (the fall of nations and cities) are out of
/// scope for this OT→NT tool.
enum ProphecyCategory {
  birth('Birth & Incarnation'),
  ministry('Life & Ministry'),
  passion('Betrayal, Trial & Suffering'),
  crucifixion('Crucifixion & Death'),
  resurrection('Resurrection & Ascension'),
  church('The Church & New Covenant'),
  kingdom('His Reign & Return'),

  /// Old Testament predictions whose fulfillment is recorded within the Old
  /// Testament itself (Cyrus named, the 70-year exile, Josiah foretold). For
  /// these — and only these — the [Prophecy.fulfillment] references point to Old
  /// Testament narrative rather than the New Testament.
  oldTestament('Fulfilled in the Old Testament');

  const ProphecyCategory(this.label);

  /// Human-readable section heading.
  final String label;
}
