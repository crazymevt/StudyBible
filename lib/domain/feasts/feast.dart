/// A biblical feast or appointed time (e.g. Passover, Pentecost), independent
/// of any particular year's Gregorian date — see [FeastOccurrence] for that.
class Feast {
  final String id;
  final String name;
  final String description;

  /// Scripture references for this feast, e.g. "Leviticus 23:5".
  final List<String> passages;

  const Feast({
    required this.id,
    required this.name,
    required this.description,
    required this.passages,
  });
}

/// One year's Gregorian date span for a [Feast], identified by [feastId].
/// [start] and [end] are equal for single-day feasts.
class FeastOccurrence {
  final String feastId;
  final int year;
  final DateTime start;
  final DateTime end;

  const FeastOccurrence({
    required this.feastId,
    required this.year,
    required this.start,
    required this.end,
  });

  bool includes(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}
