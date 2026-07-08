import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/reading_plan/today_reading_resolver.dart';

void main() {
  final today = DateTime(2026, 7, 8, 14, 0); // afternoon; time-of-day shouldn't matter

  group('resolveTodaysDay', () {
    test('returns null when there are no days', () {
      expect(resolveTodaysDay(days: [], today: today), isNull);
    });

    test('returns null when the plan has not started yet', () {
      final days = [
        ReadingPlanDaySummary(
          planId: 'p1',
          dayId: 'd1',
          dateEpochMs: DateTime(2026, 7, 10).millisecondsSinceEpoch,
        ),
      ];
      expect(resolveTodaysDay(days: days, today: today), isNull);
    });

    test('returns null when the plan has already finished', () {
      final days = [
        ReadingPlanDaySummary(
          planId: 'p1',
          dayId: 'd1',
          dateEpochMs: DateTime(2026, 7, 1).millisecondsSinceEpoch,
        ),
      ];
      expect(resolveTodaysDay(days: days, today: today), isNull);
    });

    test('returns null when days have no date at all', () {
      final days = [
        ReadingPlanDaySummary(planId: 'p1', dayId: 'd1', dateEpochMs: null),
      ];
      expect(resolveTodaysDay(days: days, today: today), isNull);
    });

    test('matches the day whose date is today, ignoring time-of-day', () {
      final days = [
        ReadingPlanDaySummary(
          planId: 'p1',
          dayId: 'd1',
          dateEpochMs: DateTime(2026, 7, 7).millisecondsSinceEpoch,
        ),
        ReadingPlanDaySummary(
          planId: 'p1',
          dayId: 'd2',
          dateEpochMs: DateTime(2026, 7, 8, 3, 0).millisecondsSinceEpoch,
        ),
        ReadingPlanDaySummary(
          planId: 'p1',
          dayId: 'd3',
          dateEpochMs: DateTime(2026, 7, 9).millisecondsSinceEpoch,
        ),
      ];
      final result = resolveTodaysDay(days: days, today: today);
      expect(result?.dayId, 'd2');
    });

    test('picks the matching day across multiple active plans', () {
      final days = [
        ReadingPlanDaySummary(
          planId: 'planA',
          dayId: 'a-d1',
          dateEpochMs: DateTime(2026, 7, 9).millisecondsSinceEpoch,
        ),
        ReadingPlanDaySummary(
          planId: 'planB',
          dayId: 'b-d3',
          dateEpochMs: DateTime(2026, 7, 8).millisecondsSinceEpoch,
        ),
      ];
      final result = resolveTodaysDay(days: days, today: today);
      expect(result?.planId, 'planB');
      expect(result?.dayId, 'b-d3');
    });
  });

  group('formatPassageSummary', () {
    test('formats a single-chapter passage without a range', () {
      final summary = formatPassageSummary([
        ReadingPlanPassageSummary(bookName: 'Genesis', startChapter: 1, endChapter: 1),
      ]);
      expect(summary, 'Genesis 1');
    });

    test('formats a multi-chapter passage as a range', () {
      final summary = formatPassageSummary([
        ReadingPlanPassageSummary(bookName: 'Genesis', startChapter: 1, endChapter: 3),
      ]);
      expect(summary, 'Genesis 1-3');
    });

    test('joins multiple passages with a comma', () {
      final summary = formatPassageSummary([
        ReadingPlanPassageSummary(bookName: 'Genesis', startChapter: 1, endChapter: 3),
        ReadingPlanPassageSummary(bookName: 'Psalm', startChapter: 4, endChapter: 4),
      ]);
      expect(summary, 'Genesis 1-3, Psalm 4');
    });
  });
}
