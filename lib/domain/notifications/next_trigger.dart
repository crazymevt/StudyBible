/// Computes the next wall-clock occurrence of [hour]:[minute] relative to
/// [now] — today if that time hasn't passed yet, otherwise tomorrow.
///
/// Pure and timezone-agnostic on purpose: the caller supplies `now` and
/// `hour`/`minute` already in whatever zone it cares about, and converts the
/// result into a `tz.TZDateTime` itself. Keeping this free of the `timezone`
/// package is what makes it trivially unit-testable.
DateTime computeNextTrigger({
  required DateTime now,
  required int hour,
  required int minute,
}) {
  final candidate = DateTime(now.year, now.month, now.day, hour, minute);
  if (candidate.isAfter(now)) return candidate;
  return candidate.add(const Duration(days: 1));
}
