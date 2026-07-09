/// One of scripture's major covenants — a formal, binding promise between
/// God and people, with its own parties, terms, and (usually) a physical
/// sign.
///
/// [citations] are scripture reference strings in the same "Book C:V",
/// "Book C:V-V", or whole-chapter "Book C" form the Kings & Reigns/Measures
/// data use, validated against `kjvVersification` by
/// `reference_data_test.dart`.
class Covenant {
  final String id;
  final String name;

  /// Who the covenant is between, e.g. "God and Abraham (and his
  /// descendants)".
  final String parties;

  /// What was promised or required.
  final String terms;

  /// The covenant's physical sign, e.g. "The rainbow" — null if scripture
  /// doesn't name one (the Davidic covenant has none).
  final String? sign;

  /// A sentence or two of further context.
  final String notes;

  final List<String> citations;

  const Covenant({
    required this.id,
    required this.name,
    required this.parties,
    required this.terms,
    this.sign,
    required this.notes,
    required this.citations,
  });
}
