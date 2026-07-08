import 'package:flutter_test/flutter_test.dart';
import 'package:study_bible/domain/notifications/next_trigger.dart';

void main() {
  group('computeNextTrigger', () {
    test('schedules for today when the time has not passed yet', () {
      final now = DateTime(2026, 7, 8, 6, 30);
      final next = computeNextTrigger(now: now, hour: 8, minute: 0);
      expect(next, DateTime(2026, 7, 8, 8, 0));
    });

    test('schedules for tomorrow when the time has already passed', () {
      final now = DateTime(2026, 7, 8, 9, 0);
      final next = computeNextTrigger(now: now, hour: 8, minute: 0);
      expect(next, DateTime(2026, 7, 9, 8, 0));
    });

    test('exactly now counts as already passed', () {
      final now = DateTime(2026, 7, 8, 8, 0);
      final next = computeNextTrigger(now: now, hour: 8, minute: 0);
      expect(next, DateTime(2026, 7, 9, 8, 0));
    });

    test('one minute before the trigger still fires today', () {
      final now = DateTime(2026, 7, 8, 7, 59);
      final next = computeNextTrigger(now: now, hour: 8, minute: 0);
      expect(next, DateTime(2026, 7, 8, 8, 0));
    });
  });
}
