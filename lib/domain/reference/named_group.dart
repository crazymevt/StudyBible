/// One member of a named biblical group — a tribe, apostle, judge, or
/// prophet. All four sub-lists share this shape rather than four separate
/// model classes, since each is just "a name, a short fact, and a
/// citation" ordered within its list.
///
/// [citations] are scripture reference strings in the same "Book C:V",
/// "Book C:V-V", or whole-chapter "Book C" form the rest of the Reference
/// data uses, validated against `kjvVersification` by
/// `reference_data_test.dart`.
class NamedGroupEntry {
  final String id;
  final NamedGroupList list;
  final String name;

  /// A short descriptor shown under the name in the list, e.g. "Brother of
  /// Peter, first called disciple" or "Major Prophet, 8th century BC".
  final String subtitle;

  /// A sentence or two of further context.
  final String notes;

  final List<String> citations;

  /// Position within [list] — birth order for tribes, the Matthew 10 list
  /// order for apostles, chronological order for judges and prophets.
  final int order;

  const NamedGroupEntry({
    required this.id,
    required this.list,
    required this.name,
    required this.subtitle,
    required this.notes,
    required this.citations,
    required this.order,
  });
}

/// Which of the four curated sub-lists an entry belongs to.
enum NamedGroupList {
  tribes('12 Tribes of Israel'),
  apostles('12 Apostles'),
  judges('Judges of Israel'),
  prophets('Major & Minor Prophets');

  const NamedGroupList(this.label);

  final String label;
}
