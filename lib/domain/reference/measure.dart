/// A unit of length, weight, volume, or money referenced in scripture, with
/// its approximate modern equivalent.
///
/// [modernEquivalent] is necessarily approximate — ancient units varied by
/// era and region, and scholars differ on exact conversions — so it's given
/// as a display string ("≈ 18 inches (45 cm)"), not a precise numeric
/// conversion factor.
///
/// [citations] are scripture reference strings in the same "Book C:V",
/// "Book C:V-V", or whole-chapter "Book C" form the Prophecies/Kings & Reigns
/// data use, validated against `kjvVersification` by
/// `reference_data_test.dart`.
class Measure {
  final String id;
  final String name;
  final MeasureCategory category;
  final String modernEquivalent;

  /// A sentence or two of context — where the unit shows up and what for.
  final String notes;

  final List<String> citations;

  const Measure({
    required this.id,
    required this.name,
    required this.category,
    required this.modernEquivalent,
    required this.notes,
    required this.citations,
  });
}

/// Grouping key for browsing, ordered smallest concept to money last.
enum MeasureCategory {
  length('Length'),
  weight('Weight'),
  volume('Volume'),
  money('Money');

  const MeasureCategory(this.label);

  final String label;
}
