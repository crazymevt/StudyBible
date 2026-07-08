/// A single reading-plan day, reduced to the fields the reminder needs.
///
/// Kept separate from the Drift-generated `ReadingPlanDay` row so this file
/// stays pure Dart — the app layer maps rows into these before calling in.
class ReadingPlanDaySummary {
  final String planId;
  final String dayId;
  final int? dateEpochMs;

  ReadingPlanDaySummary({
    required this.planId,
    required this.dayId,
    required this.dateEpochMs,
  });
}

/// A single reading-plan passage, reduced to the fields needed to format a
/// notification body (e.g. "Genesis 1-3").
class ReadingPlanPassageSummary {
  final String bookName;
  final int startChapter;
  final int endChapter;

  ReadingPlanPassageSummary({
    required this.bookName,
    required this.startChapter,
    required this.endChapter,
  });
}

class TodayReadingDay {
  final String planId;
  final String dayId;
  final List<ReadingPlanPassageSummary> passages;

  TodayReadingDay({
    required this.planId,
    required this.dayId,
    required this.passages,
  });
}

/// Finds the day (if any) across [days] whose calendar date matches [today],
/// comparing at local-midnight granularity so time-of-day never matters.
///
/// Unlike the reader's "what should I read next" logic (which picks the
/// first incomplete day), this answers "what's assigned to today," which is
/// what a reminder notification needs — it ignores `completed` entirely.
/// Returns null if no day's date matches (plan hasn't started yet, has
/// already finished, or has no dated days).
ReadingPlanDaySummary? resolveTodaysDay({
  required List<ReadingPlanDaySummary> days,
  required DateTime today,
}) {
  final todayMidnight = DateTime(today.year, today.month, today.day);
  for (final day in days) {
    final dateEpochMs = day.dateEpochMs;
    if (dateEpochMs == null) continue;
    final date = DateTime.fromMillisecondsSinceEpoch(dateEpochMs);
    final dateMidnight = DateTime(date.year, date.month, date.day);
    if (dateMidnight == todayMidnight) return day;
  }
  return null;
}

/// Formats passages into a short human-readable summary, e.g. "Genesis 1-3"
/// or "Genesis 1-3, Psalm 4" for multiple passages.
String formatPassageSummary(List<ReadingPlanPassageSummary> passages) {
  return passages
      .map((p) {
        if (p.startChapter == p.endChapter) return '${p.bookName} ${p.startChapter}';
        return '${p.bookName} ${p.startChapter}-${p.endChapter}';
      })
      .join(', ');
}
